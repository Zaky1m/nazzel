package app.nazzel

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.os.IBinder
import android.util.Log
import org.json.JSONObject
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

class DownloadService : Service() {
    private val executor = Executors.newSingleThreadExecutor()
    private val cancels = ConcurrentHashMap<String, AtomicBoolean>()
    private val pending = AtomicInteger(0)
    private val timedOut = AtomicBoolean(false)
    private lateinit var store: Store
    private lateinit var manager: NotificationManager

    override fun onCreate() {
        super.onCreate()
        store = Store.get(this)
        manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(CHANNEL, "التحميلات", NotificationManager.IMPORTANCE_LOW))
        manager.createNotificationChannel(NotificationChannel(CHANNEL_DONE, "اكتمال التحميل", NotificationManager.IMPORTANCE_DEFAULT))
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_CANCEL) {
            val id = intent.getStringExtra(EXTRA_ID)
            if (id != null && cancels[id] != null) {
                cancels[id]?.set(true)
                // The engine may sit in a network call for a while before it sees the flag; the row reads canceled right away.
                store.finish(id, "canceled")
                Events.changed(id)
            }
            return START_NOT_STICKY
        }
        startForeground(NOTIF_ID, progressNotification("نزّل", 0, true), ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        active.set(true)
        pending.incrementAndGet()
        executor.execute {
            try {
                drain()
            } finally {
                if (pending.decrementAndGet() == 0) {
                    active.set(false)
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
            }
        }
        return START_NOT_STICKY
    }

    // Android 15 limits dataSync services to 6h/day; stop promptly instead of being killed.
    override fun onTimeout(startId: Int, fgsType: Int) {
        timedOut.set(true)
        cancels.values.forEach { it.set(true) }
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }

    private fun drain() {
        while (!timedOut.get()) {
            val row = store.claimNext() ?: break
            Events.changed(row.id)
            run(row)
        }
    }

    private fun run(row: Row) {
        val flag = AtomicBoolean(false)
        cancels[row.id] = flag
        val outDir = File(cacheDir, "dl/${row.id}")
        var lastPush = 0L
        val runId = store.logStart(row.id, "download", row.url, row.optionId)
        val log = { text: String -> store.logLines(runId, listOf(text)) }
        log("start id=${row.id} title='${row.title}' free=${cacheDir.usableSpace / 1048576}MB")
        try {
            manager.notify(NOTIF_ID, progressNotification(row.title, 0, true, row.id))
            val res = PyBridge.download(this, row.url, row.optionId, outDir.path, DownloadProgress { percent, speed ->
                if (percent < 0) return@DownloadProgress flag.get()
                val now = System.currentTimeMillis()
                if (now - lastPush >= 600) {
                    lastPush = now
                    store.progress(row.id, percent, speed)
                    Events.changed(row.id)
                    manager.notify(NOTIF_ID, progressNotification(row.title, percent.toInt(), false, row.id))
                }
                flag.get()
            }, log)
            val engineLog = res.optJSONArray("log")
            store.logLines(runId, List(engineLog?.length() ?: 0) { "py ${engineLog!!.getString(it)}" })
            log("engine returned ok=${res.optBoolean("ok")} code=${res.optString("code")} message=${res.optString("message")}")
            when {
                flag.get() || res.optString("code") == "canceled" ->
                    store.finish(row.id, if (timedOut.get()) "failed" else "canceled", error = if (timedOut.get()) "timeout" else null)
                !res.optBoolean("ok") -> store.finish(
                    row.id, "failed", error = res.optString("code", "unknown"), detail = res.optString("message")
                )
                else -> finalize(row, res, outDir, log)
            }
        } catch (e: Throwable) {
            Log.e(TAG, "download ${row.id} failed", e)
            log("exception: ${describe(e)}")
            store.finish(
                row.id, "failed", error = if (e is java.io.IOException) "save" else "unknown",
                detail = describe(e)
            )
        } finally {
            cancels.remove(row.id)
            outDir.deleteRecursively()
            store.logEnd(runId, store.get(row.id)?.optString("status") ?: "unknown")
            Events.changed(row.id)
        }
    }

    private fun finalize(row: Row, res: JSONObject, outDir: File, log: (String) -> Unit) {
        val files = res.getJSONArray("files").let { a -> List(a.length()) { File(a.getString(it)) } }
        log("files: " + files.joinToString { "${it.name}=${it.length()}B ts=${Muxer.isMpegTs(it)}" })
        val audioOnly = res.optBoolean("audio_only")
        val needsMux = files.size >= 2 || Muxer.isMpegTs(files[0])
        val source = if (needsMux) {
            val merged = File(outDir, if (audioOnly) "merged.m4a" else "merged.mp4")
            val t0 = System.currentTimeMillis()
            try {
                Muxer.mux(files, merged)
                log("muxed ${files.joinToString { it.name }} in ${System.currentTimeMillis() - t0}ms -> ${merged.length()}B")
            } catch (e: Throwable) {
                Log.e(TAG, "merge ${row.id} failed", e)
                log("merge failed: ${describe(e)}")
                store.finish(row.id, "failed", error = "merge", detail = describe(e))
                return
            }
            merged
        } else files[0]
        val ext = source.extension.lowercase()
        val mime = mimeFor(ext).let { if (audioOnly && it.startsWith("video/")) it.replace("video/", "audio/") else it }
        val name = safeName(res.optString("title").ifBlank { row.title }) + "." + ext
        log("saving as '$name' mime=$mime")
        val uri = MediaSaver.save(this, source, name, mime)
        log("saved uri=$uri")
        store.finish(row.id, "done", path = uri.toString(), mime = mime, title = res.optString("title"))
        store.setSize(row.id, source.length())
        val stats = getSharedPreferences("app", Context.MODE_PRIVATE)
        stats.edit().putLong("lifetime_count", stats.getLong("lifetime_count", 0) + 1)
            .putLong("lifetime_bytes", stats.getLong("lifetime_bytes", 0) + source.length()).apply()
        manager.notify(
            row.id.hashCode(),
            Notification.Builder(this, CHANNEL_DONE)
                .setSmallIcon(Icon.createWithResource(this, R.drawable.ic_stat_nazzel))
                .setContentTitle("تم التحميل")
                .setContentText(row.title.ifBlank { res.optString("title") })
                .setContentIntent(openApp())
                .setAutoCancel(true)
                .build()
        )
    }

    private fun progressNotification(title: String, percent: Int, indeterminate: Boolean, id: String? = null): Notification {
        val builder = Notification.Builder(this, CHANNEL)
            .setSmallIcon(Icon.createWithResource(this, R.drawable.ic_stat_nazzel))
            .setContentTitle(title)
            .setContentText(if (indeterminate) "جاري التجهيز" else "$percent%")
            .setProgress(100, percent, indeterminate)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openApp())
        if (id != null) {
            val cancel = Intent(this, DownloadService::class.java).setAction(ACTION_CANCEL).putExtra(EXTRA_ID, id)
            val pi = PendingIntent.getService(this, 1, cancel, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            builder.addAction(Notification.Action.Builder(Icon.createWithResource(this, R.drawable.ic_stat_nazzel), "إلغاء", pi).build())
        }
        return builder.build()
    }

    private fun openApp(): PendingIntent = PendingIntent.getActivity(
        this, 0, Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )

    private fun describe(e: Throwable): String =
        (listOf(e.toString()) + e.stackTrace.take(4).map { "  at $it" }).joinToString("\n").take(900)

    private fun mimeFor(ext: String) = when (ext) {
        "mp4", "m4v" -> "video/mp4"
        "webm" -> "video/webm"
        "mkv" -> "video/x-matroska"
        "mov" -> "video/quicktime"
        "m4a" -> "audio/mp4"
        "mp3" -> "audio/mpeg"
        "aac" -> "audio/aac"
        "flac" -> "audio/flac"
        "wav" -> "audio/wav"
        "opus", "ogg" -> "audio/ogg"
        else -> "video/mp4"
    }

    private fun safeName(title: String): String =
        title.replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), " ").replace(Regex("\\s+"), " ").trim().take(80).ifBlank { "nazzel" }

    companion object {
        private const val TAG = "Nazzel"
        const val ACTION_CANCEL = "app.nazzel.CANCEL"
        const val EXTRA_ID = "id"
        private const val CHANNEL = "downloads"
        private const val CHANNEL_DONE = "downloads_done"
        private const val NOTIF_ID = 1
        val active = AtomicBoolean(false)

        fun start(ctx: Context) {
            ctx.startForegroundService(Intent(ctx, DownloadService::class.java))
        }
    }
}

// Public named class: Python reaches it through reflection, which anonymous classes do not allow.
class DownloadProgress(private val onTick: (Double, Double) -> Boolean) : ProgressCallback {
    override fun onProgress(percent: Double, speed: Double): Boolean = onTick(percent, speed)
}
