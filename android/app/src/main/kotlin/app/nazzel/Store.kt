package app.nazzel

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.json.JSONArray
import org.json.JSONObject

data class Row(val id: String, val url: String, val title: String, val optionId: String)

// Single writer for download state. The service keeps running with the UI closed, so Dart only reads.
class Store private constructor(ctx: Context) : SQLiteOpenHelper(ctx, "downloads.db", null, 4) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """CREATE TABLE downloads(
                id TEXT PRIMARY KEY, url TEXT NOT NULL, title TEXT, thumb TEXT, option_id TEXT NOT NULL,
                status TEXT NOT NULL, percent REAL NOT NULL DEFAULT 0, speed REAL NOT NULL DEFAULT 0,
                path TEXT, mime TEXT, error TEXT, detail TEXT, batch_id TEXT, batch_title TEXT, size INTEGER,
                created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)"""
        )
        db.execSQL("CREATE INDEX downloads_status ON downloads(status, created_at)")
        createLogTables(db)
    }

    private fun createLogTables(db: SQLiteDatabase) {
        db.execSQL(
            """CREATE TABLE log_runs(id INTEGER PRIMARY KEY AUTOINCREMENT, download_id TEXT NOT NULL, kind TEXT NOT NULL,
                started_at INTEGER NOT NULL, url TEXT, option_id TEXT, status TEXT)"""
        )
        db.execSQL("CREATE TABLE log_lines(run_id INTEGER NOT NULL, ts INTEGER NOT NULL, line TEXT NOT NULL)")
        db.execSQL("CREATE INDEX log_lines_run ON log_lines(run_id)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) db.execSQL("ALTER TABLE downloads ADD COLUMN detail TEXT")
        if (oldVersion < 3) createLogTables(db)
        if (oldVersion < 4) {
            db.execSQL("ALTER TABLE downloads ADD COLUMN batch_id TEXT")
            db.execSQL("ALTER TABLE downloads ADD COLUMN batch_title TEXT")
            db.execSQL("ALTER TABLE downloads ADD COLUMN size INTEGER")
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

    // Diagnostics for the last LOG_KEEP runs; older runs are deleted whenever a new one starts.
    fun logStart(downloadId: String, kind: String, url: String, optionId: String): Long {
        val db = writableDatabase
        val id = db.insertOrThrow("log_runs", null, ContentValues().apply {
            put("download_id", downloadId); put("kind", kind); put("started_at", System.currentTimeMillis())
            put("url", url); put("option_id", optionId); put("status", "running")
        })
        db.execSQL("DELETE FROM log_runs WHERE id NOT IN (SELECT id FROM log_runs ORDER BY id DESC LIMIT $LOG_KEEP)")
        db.execSQL("DELETE FROM log_lines WHERE run_id NOT IN (SELECT id FROM log_runs)")
        return id
    }

    fun logLines(runId: Long, lines: List<String>) {
        if (lines.isEmpty()) return
        val db = writableDatabase
        db.beginTransaction()
        try {
            val now = System.currentTimeMillis()
            lines.forEach { line ->
                db.insert("log_lines", null, ContentValues().apply {
                    put("run_id", runId); put("ts", now); put("line", line.take(2000))
                })
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    fun logEnd(runId: Long, status: String) {
        writableDatabase.update("log_runs", ContentValues().apply { put("status", status) }, "id=?", arrayOf(runId.toString()))
    }

    fun logClear() {
        writableDatabase.execSQL("DELETE FROM log_lines")
        writableDatabase.execSQL("DELETE FROM log_runs")
    }

    fun logCount(): Int = android.database.DatabaseUtils.queryNumEntries(readableDatabase, "log_runs").toInt()

    fun logRender(header: String): String {
        val fmt = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.US)
        val out = StringBuilder(header).append("\n\n")
        val db = readableDatabase
        db.rawQuery("SELECT id, download_id, kind, started_at, url, option_id, status FROM log_runs ORDER BY id DESC", null).use { runs ->
            while (runs.moveToNext()) {
                val id = runs.getLong(0)
                out.append("=== #").append(id).append(' ').append(runs.getString(2)).append(" | ")
                    .append(fmt.format(java.util.Date(runs.getLong(3)))).append(" | status=").append(runs.getString(6)).append('\n')
                out.append("url: ").append(runs.getString(4)).append("  option: ").append(runs.getString(5)).append('\n')
                db.rawQuery("SELECT line FROM log_lines WHERE run_id=? ORDER BY rowid", arrayOf(id.toString())).use { lines ->
                    while (lines.moveToNext()) out.append(lines.getString(0)).append('\n')
                }
                out.append('\n')
            }
        }
        return out.toString()
    }

    companion object {
        private const val LOG_KEEP = 100
        @Volatile private var instance: Store? = null
        fun get(ctx: Context): Store = instance ?: synchronized(this) {
            instance ?: Store(ctx.applicationContext).also { instance = it }
        }
    }
}
