package app.nazzel

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var engineChannel: EngineChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val store = Store.get(this)
        if (!DownloadService.active.get()) store.failInterrupted()
        Executors.newSingleThreadExecutor().execute {
            store.purgeExpired().forEach { File(cacheDir, "dl/$it").deleteRecursively() }
            if (store.hasQueued()) DownloadService.start(this)
            MediaSaver.purgeOldLogs(this)
            if (!BuildConfig.STORE) {
                PyBridge.maybeUpdate(this)
                AppUpdater.maybeCheck(this)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engineChannel = EngineChannel(this, flutterEngine.dartExecutor.binaryMessenger, attachEvents = true)
    }

    // Android only lets the focused app read the clipboard, and reading shows a system toast, so the clip
    // is read only when its timestamp is newer than the last one handled.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) return
        val cm = getSystemService(android.content.ClipboardManager::class.java) ?: return
        val desc = cm.primaryClipDescription ?: return
        if (!desc.hasMimeType("text/*")) return
        val prefs = getSharedPreferences("app", MODE_PRIVATE)
        if (desc.timestamp <= prefs.getLong("clip_stamp", 0L)) return
        prefs.edit().putLong("clip_stamp", desc.timestamp).apply()
        val text = cm.primaryClip?.takeIf { it.itemCount > 0 }?.getItemAt(0)?.coerceToText(this)?.toString()
        SharedLink.extract(text)?.let { engineChannel?.push("clipboardUrl", it) }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        engineChannel?.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        engineChannel?.dispose()
        super.onDestroy()
    }
}
