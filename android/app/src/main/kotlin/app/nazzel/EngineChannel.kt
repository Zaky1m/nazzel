package app.nazzel

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import java.util.concurrent.Executors

// One channel implementation shared by the main app and the share sheet so both see the same SQLite store.
class EngineChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
    private val sharedUrl: String? = null,
    private val attachEvents: Boolean = false,
) {
    private val ctx: Context = activity.applicationContext
    private val store = Store.get(ctx)
    private val worker = Executors.newCachedThreadPool()
    private val main = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, "app.nazzel/engine")
    private var pendingPick: MethodChannel.Result? = null

    init {
        if (attachEvents) Events.sink = { id -> main.post { channel.invokeMethod("changed", id) } }
        channel.setMethodCallHandler { call, result -> handle(call, result) }
    }

    fun push(method: String, arg: Any?) {
        main.post { channel.invokeMethod(method, arg) }
    }

    fun onActivityResult(code: Int, resultCode: Int, data: Intent?) {
        if (code != PICK_FOLDER) return
        val pending = pendingPick ?: return
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending.success(null)
            return
        }
        ctx.contentResolver.takePersistableUriPermission(
            uri, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        )
        MediaSaver.setTree(ctx, uri)
        pending.success(MediaSaver.label(ctx))
    }

    fun dispose() {
        if (attachEvents) Events.sink = null
        worker.shutdown()
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "info" -> background(result) {
                val url = call.argument<String>("url")!!
                val notes = mutableListOf<String>()
                val res = PyBridge.info(ctx, url) { notes.add(it) }
                if (!res.optBoolean("ok")) {
                    val runId = store.logStart("info", "info", url, "")
                    store.logLines(runId, notes + "engine returned code=${res.optString("code")} message=${res.optString("message")}" +
                        List(res.optJSONArray("log")?.length() ?: 0) { "py ${res.optJSONArray("log")!!.getString(it)}" })
                    store.logEnd(runId, "failed")
                }
                res.remove("log")
                res.toString()
            }
            "enqueue" -> background(result) {
                val id = UUID.randomUUID().toString()
                store.insert(
                    id, call.argument<String>("url")!!, call.argument<String>("title") ?: "",
                    call.argument<String>("thumb"), call.argument<String>("optionId")!!
                )
                DownloadService.start(ctx)
                Events.changed(id)
                id
            }
            "enqueueBatch" -> background(result) {
                val batchId = UUID.randomUUID().toString()
                val items = call.argument<List<Map<String, Any?>>>("items")!!.map {
                    Triple(it["url"] as String, it["title"] as? String ?: "", it["thumb"] as? String)
                }
                store.insertBatch(batchId, call.argument<String>("title") ?: "", call.argument<String>("optionId")!!, items)
                DownloadService.start(ctx)
                Events.changed(batchId)
                batchId
            }
            "cancelBatch" -> background(result) {
                val batchId = call.argument<String>("batchId")!!
                store.cancelBatchQueued(batchId)
                store.runningInBatch(batchId).forEach { id ->
                    ctx.startService(
                        Intent(ctx, DownloadService::class.java).setAction(DownloadService.ACTION_CANCEL)
                            .putExtra(DownloadService.EXTRA_ID, id)
                    )
                }
                Events.changed(batchId)
                true
            }
            "stats" -> background(result) {
                val p = prefs()
                store.stats().put("lifetime", p.getLong("lifetime_count", 0))
                    .put("lifetimeBytes", p.getLong("lifetime_bytes", 0)).toString()
            }
            "appInfo" -> background(result) {
                val info = ctx.packageManager.getPackageInfo(ctx.packageName, 0)
                org.json.JSONObject().put("version", info.versionName).put("build", info.longVersionCode).toString()
            }
            "updateInfo" -> background(result) {
                val json = if (call.argument<Boolean>("refresh") == true) AppUpdater.check(ctx) else AppUpdater.available(ctx)
                json?.toString()
            }
            "list" -> background(result) { store.list().toString() }
            "cancel" -> background(result) {
                val id = call.argument<String>("id")!!
                if (!store.cancelQueued(id)) ctx.startService(
                    Intent(ctx, DownloadService::class.java).setAction(DownloadService.ACTION_CANCEL)
                        .putExtra(DownloadService.EXTRA_ID, id)
                )
                Events.changed(id)
                true
            }
            "retry" -> background(result) {
                val id = call.argument<String>("id")!!
                if (store.requeue(id)) DownloadService.start(ctx)
                Events.changed(id)
                true
            }
            "delete" -> background(result) {
                val id = call.argument<String>("id")!!
                val row = store.get(id)
                if (row != null && row.optString("status") == "done") {
                    row.optString("path").takeIf { it.isNotEmpty() && it != "null" }?.let { MediaSaver.delete(ctx, it) }
                }
                store.delete(id)
                Events.changed(id)
                true
            }
            "deleteMany" -> background(result) {
                call.argument<List<String>>("ids")!!.forEach { id ->
                    val row = store.get(id)
                    if (row != null && row.optString("status") == "done") {
                        row.optString("path").takeIf { it.isNotEmpty() && it != "null" }?.let { MediaSaver.delete(ctx, it) }
                    }
                    store.delete(id)
                }
                Events.changed("many")
                true
            }
            "saveLocation" -> result.success(MediaSaver.label(ctx))
            "pickFolder" -> {
                pendingPick?.success(null)
                pendingPick = result
                activity.startActivityForResult(
                    Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                            Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                    ), PICK_FOLDER
                )
            }
            "resetSaveLocation" -> {
                MediaSaver.setTree(ctx, null)
                result.success(MediaSaver.label(ctx))
            }
            "open" -> result.success(viewOrShare(call.argument<String>("id")!!, share = false))
            "share" -> result.success(viewOrShare(call.argument<String>("id")!!, share = true))
            "sharedUrl" -> result.success(sharedUrl)
            "exportLog" -> background(result) {
                val share = call.argument<Boolean>("share") == true
                val stamp = java.text.SimpleDateFormat("yyyyMMdd-HHmmss", java.util.Locale.US).format(java.util.Date())
                val name = "nazzel-log-$stamp.txt"
                val uri = MediaSaver.saveText(ctx, store.logRender(logHeader()), name)
                if (share) main.post {
                    activity.startActivity(
                        Intent.createChooser(
                            Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_STREAM, uri)
                                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION), null
                        )
                    )
                }
                "Download/Nazzel/$name"
            }
            "clearLog" -> background(result) {
                store.logClear()
                true
            }
            "logCount" -> background(result) { store.logCount() }
            "closeShare" -> {
                activity.finish()
                result.success(true)
            }
            "getPref" -> result.success(prefs().getString(call.argument<String>("key"), null))
            "setPref" -> {
                prefs().edit().putString(call.argument<String>("key"), call.argument<String>("value")).apply()
                result.success(true)
            }
            "askNotifications" -> {
                if (activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                    activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7)
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun background(result: MethodChannel.Result, block: () -> Any?) {
        worker.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("native", e.message, null) }
            }
        }
    }

    private fun logHeader(): String {
        val info = ctx.packageManager.getPackageInfo(ctx.packageName, 0)
        return listOf(
            "Nazzel ${info.versionName} (${info.longVersionCode})",
            "Android ${android.os.Build.VERSION.RELEASE} (API ${android.os.Build.VERSION.SDK_INT})",
            "Device ${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL} abi=${android.os.Build.SUPPORTED_ABIS.firstOrNull()}",
            "yt-dlp ${PyBridge.version(ctx)}",
            PyBridge.engineNote(ctx),
            "Free space ${ctx.cacheDir.usableSpace / 1048576} MB",
            "Exported ${java.util.Date()}",
        ).joinToString("\n")
    }

    private fun prefs() = ctx.getSharedPreferences("app", Context.MODE_PRIVATE)

    private fun viewOrShare(id: String, share: Boolean): Boolean {
        val row = store.get(id) ?: return false
        val path = row.optString("path")
        if (path.isEmpty() || path == "null") return false
        val uri = Uri.parse(path)
        val mime = row.optString("mime").ifEmpty { "video/*" }
        val intent = if (share) {
            Intent.createChooser(
                Intent(Intent.ACTION_SEND).setType(mime).putExtra(Intent.EXTRA_STREAM, uri)
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION), null
            )
        } else {
            Intent(Intent.ACTION_VIEW).setDataAndType(uri, mime).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            activity.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    private companion object {
        const val PICK_FOLDER = 41
    }
}
