package app.nazzel

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.json.JSONArray
import org.json.JSONObject

data class Row(val id: String, val url: String, val title: String, val optionId: String)

// Single writer for download state. The service keeps running with the UI closed, so Dart only reads.
class Store private constructor(ctx: Context) : SQLiteOpenHelper(ctx, "downloads.db", null, 5) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """CREATE TABLE downloads(
                id TEXT PRIMARY KEY, url TEXT NOT NULL, title TEXT, thumb TEXT, option_id TEXT NOT NULL,
                status TEXT NOT NULL, percent REAL NOT NULL DEFAULT 0, speed REAL NOT NULL DEFAULT 0,
                path TEXT, mime TEXT, error TEXT, detail TEXT, batch_id TEXT, batch_title TEXT, size INTEGER,
                created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)"""
        )
        db.execSQL("CREATE INDEX downloads_status ON downloads(status, created_at)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) db.execSQL("ALTER TABLE downloads ADD COLUMN detail TEXT")
        if (oldVersion < 4) {
            db.execSQL("ALTER TABLE downloads ADD COLUMN batch_id TEXT")
            db.execSQL("ALTER TABLE downloads ADD COLUMN batch_title TEXT")
            db.execSQL("ALTER TABLE downloads ADD COLUMN size INTEGER")
        }
        // Diagnostics logs were removed in 1.3.0; nothing keeps engine output or links any more.
        if (oldVersion < 5) {
            db.execSQL("DROP TABLE IF EXISTS log_lines")
            db.execSQL("DROP TABLE IF EXISTS log_runs")
        }
    }

    fun insert(
        id: String, url: String, title: String, thumb: String?, optionId: String,
        batchId: String? = null, batchTitle: String? = null, createdAt: Long = System.currentTimeMillis(),
    ) {
        writableDatabase.insertOrThrow("downloads", null, ContentValues().apply {
            put("id", id); put("url", url); put("title", title); put("thumb", thumb)
            put("option_id", optionId); put("status", "queued"); put("batch_id", batchId); put("batch_title", batchTitle)
            put("created_at", createdAt); put("updated_at", createdAt)
        })
    }

    // Items get increasing timestamps so the queue (oldest first) follows the playlist order.
    fun insertBatch(batchId: String, batchTitle: String, optionId: String, items: List<Triple<String, String, String?>>) {
        val db = writableDatabase
        val base = System.currentTimeMillis()
        db.beginTransaction()
        try {
            items.forEachIndexed { i, (url, title, thumb) ->
                insert(java.util.UUID.randomUUID().toString(), url, title, thumb, optionId, batchId, batchTitle, base + i)
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    fun cancelBatchQueued(batchId: String): Int = writableDatabase.update("downloads", ContentValues().apply {
        put("status", "canceled"); put("updated_at", System.currentTimeMillis())
    }, "batch_id=? AND status='queued'", arrayOf(batchId))

    fun runningInBatch(batchId: String): List<String> {
        val ids = mutableListOf<String>()
        readableDatabase.rawQuery("SELECT id FROM downloads WHERE batch_id=? AND status='running'", arrayOf(batchId)).use { c ->
            while (c.moveToNext()) ids.add(c.getString(0))
        }
        return ids
    }

    fun setSize(id: String, size: Long) {
        writableDatabase.update("downloads", ContentValues().apply { put("size", size) }, "id=?", arrayOf(id))
    }

    fun stats(): JSONObject = readableDatabase.rawQuery(
        "SELECT COUNT(*), COALESCE(SUM(size), 0) FROM downloads WHERE status='done'", null
    ).use { c ->
        c.moveToFirst()
        JSONObject().put("saved", c.getLong(0)).put("bytes", c.getLong(1))
    }

    fun claimNext(): Row? = synchronized(this) {
        val db = writableDatabase
        db.rawQuery(
            "SELECT id, url, title, option_id FROM downloads WHERE status='queued' ORDER BY created_at LIMIT 1", null
        ).use { c ->
            if (!c.moveToFirst()) return null
            val row = Row(c.getString(0), c.getString(1), c.getString(2) ?: "", c.getString(3))
            val n = db.update("downloads", ContentValues().apply {
                put("status", "running"); put("updated_at", System.currentTimeMillis())
            }, "id=? AND status='queued'", arrayOf(row.id))
            return if (n == 1) row else null
        }
    }

    fun progress(id: String, percent: Double, speed: Double) {
        writableDatabase.update("downloads", ContentValues().apply {
            put("percent", percent); put("speed", speed); put("updated_at", System.currentTimeMillis())
        }, "id=? AND status='running'", arrayOf(id))
    }

    fun finish(
        id: String, status: String, path: String? = null, mime: String? = null,
        error: String? = null, detail: String? = null, title: String? = null,
    ) {
        writableDatabase.update("downloads", ContentValues().apply {
            put("status", status); put("path", path); put("mime", mime); put("error", error); put("detail", detail)
            if (!title.isNullOrBlank()) put("title", title)
            put("speed", 0.0); if (status == "done") put("percent", 100.0)
            put("updated_at", System.currentTimeMillis())
        }, "id=?", arrayOf(id))
    }

    fun requeue(id: String): Boolean = writableDatabase.update("downloads", ContentValues().apply {
        put("status", "queued"); put("percent", 0.0); put("speed", 0.0); putNull("error"); putNull("detail")
        put("created_at", System.currentTimeMillis()); put("updated_at", System.currentTimeMillis())
    }, "id=? AND status IN ('failed','canceled')", arrayOf(id)) == 1

    fun cancelQueued(id: String): Boolean = writableDatabase.update("downloads", ContentValues().apply {
        put("status", "canceled"); put("updated_at", System.currentTimeMillis())
    }, "id=? AND status='queued'", arrayOf(id)) == 1

    fun delete(id: String) {
        writableDatabase.delete("downloads", "id=?", arrayOf(id))
    }

    fun get(id: String): JSONObject? = query("SELECT * FROM downloads WHERE id=?", arrayOf(id)).let {
        if (it.length() == 0) null else it.getJSONObject(0)
    }

    fun hasQueued(): Boolean =
        android.database.DatabaseUtils.queryNumEntries(readableDatabase, "downloads", "status='queued'") > 0

    fun list(): JSONArray = query("SELECT * FROM downloads ORDER BY created_at DESC", null)

    // A process that died mid-download leaves rows marked running; nothing is working on them anymore.
    fun failInterrupted() {
        writableDatabase.update("downloads", ContentValues().apply {
            put("status", "failed"); put("error", "interrupted"); put("detail", "process ended while downloading"); put("speed", 0.0)
            put("updated_at", System.currentTimeMillis())
        }, "status='running'", null)
    }

    // Transient states expire after 24h; finished downloads stay until the user deletes them.
    fun purgeExpired(): List<String> {
        val cutoff = System.currentTimeMillis() - 24L * 60 * 60 * 1000
        val db = writableDatabase
        val ids = mutableListOf<String>()
        db.rawQuery(
            "SELECT id FROM downloads WHERE status IN ('queued','failed','canceled') AND updated_at < ?",
            arrayOf(cutoff.toString())
        ).use { c -> while (c.moveToNext()) ids.add(c.getString(0)) }
        ids.forEach { db.delete("downloads", "id=?", arrayOf(it)) }
        return ids
    }

    private fun query(sql: String, args: Array<String>?): JSONArray {
        val out = JSONArray()
        readableDatabase.rawQuery(sql, args).use { c ->
            while (c.moveToNext()) {
                out.put(JSONObject().apply {
                    put("id", c.getString(c.getColumnIndexOrThrow("id")))
                    put("url", c.getString(c.getColumnIndexOrThrow("url")))
                    put("title", c.getString(c.getColumnIndexOrThrow("title")) ?: "")
                    put("thumb", c.getString(c.getColumnIndexOrThrow("thumb")) ?: JSONObject.NULL)
                    put("optionId", c.getString(c.getColumnIndexOrThrow("option_id")))
                    put("status", c.getString(c.getColumnIndexOrThrow("status")))
                    put("percent", c.getDouble(c.getColumnIndexOrThrow("percent")))
                    put("speed", c.getDouble(c.getColumnIndexOrThrow("speed")))
                    put("path", c.getString(c.getColumnIndexOrThrow("path")) ?: JSONObject.NULL)
                    put("mime", c.getString(c.getColumnIndexOrThrow("mime")) ?: JSONObject.NULL)
                    put("error", c.getString(c.getColumnIndexOrThrow("error")) ?: JSONObject.NULL)
                    put("detail", c.getString(c.getColumnIndexOrThrow("detail")) ?: JSONObject.NULL)
                    put("batchId", c.getString(c.getColumnIndexOrThrow("batch_id")) ?: JSONObject.NULL)
                    put("batchTitle", c.getString(c.getColumnIndexOrThrow("batch_title")) ?: JSONObject.NULL)
                    put("createdAt", c.getLong(c.getColumnIndexOrThrow("created_at")))
                })
            }
        }
        return out
    }

    companion object {
        @Volatile private var instance: Store? = null
        fun get(ctx: Context): Store = instance ?: synchronized(this) {
            instance ?: Store(ctx.applicationContext).also { instance = it }
        }
    }
}
