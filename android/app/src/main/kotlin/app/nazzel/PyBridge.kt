package app.nazzel

import android.content.Context
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import org.json.JSONObject

interface ProgressCallback {
    // Returns true to cancel the download.
    fun onProgress(percent: Double, speed: Double): Boolean
}

object PyBridge {
    private const val DAY_MS = 24L * 60 * 60 * 1000

    @Synchronized
    private fun engine(ctx: Context): com.chaquo.python.PyObject {
        if (!Python.isStarted()) Python.start(AndroidPlatform(ctx.applicationContext))
        val module = loader(ctx).callAttr("engine", dataDir(ctx), appBuild(ctx))
        if (!configured) {
            module.callAttr("configure", dataDir(ctx), ctx.applicationInfo.nativeLibraryDir + "/libqjs.so")
            configured = true
        }
        return module
    }

    @Volatile private var configured = false

    private fun loader(ctx: Context): com.chaquo.python.PyObject {
        if (!Python.isStarted()) Python.start(AndroidPlatform(ctx.applicationContext))
        return Python.getInstance().getModule("loader")
    }

    private fun dataDir(ctx: Context) = ctx.applicationContext.filesDir.absolutePath

    fun appBuild(ctx: Context): Long = ctx.packageManager.getPackageInfo(ctx.packageName, 0).longVersionCode

    fun engineNote(ctx: Context): String =
        runCatching { engine(ctx); loader(ctx).callAttr("note").toString() }.getOrDefault("unavailable")

    fun info(ctx: Context, url: String, log: (String) -> Unit = {}): JSONObject = repairing(ctx, log) {
        JSONObject(engine(ctx).callAttr("info", url).toString())
    }

    fun download(
        ctx: Context, url: String, optionId: String, outDir: String, cb: ProgressCallback, log: (String) -> Unit = {},
    ): JSONObject = repairing(ctx, log) {
        JSONObject(engine(ctx).callAttr("download", url, optionId, outDir, cb).toString())
    }

    fun update(ctx: Context): JSONObject = JSONObject(engine(ctx).callAttr("update").toString())

    fun version(ctx: Context): String =
        runCatching { JSONObject(engine(ctx).callAttr("version").toString()).optString("version", "?") }.getOrDefault("unavailable")

    // A site changing its pages is the usual reason extraction breaks; a newer yt-dlp normally fixes it.
    private fun repairing(ctx: Context, log: (String) -> Unit, call: () -> JSONObject): JSONObject {
        val first = call()
        if (first.optBoolean("ok") || first.optString("code") != "extractor") return first
        log("extraction failed, trying an engine update: ${first.optString("message")}")
        val updated = runCatching { update(ctx) }.getOrElse {
            log("engine update crashed: $it")
            return first
        }
        log("engine update result: $updated")
        if (!updated.optBoolean("ok") || !updated.optBoolean("updated")) return first
        stamp(ctx)
        log("retrying with the new engine")
        return call()
    }

    fun maybeUpdate(ctx: Context) {
        val prefs = ctx.getSharedPreferences("engine", Context.MODE_PRIVATE)
        if (System.currentTimeMillis() - prefs.getLong("last_check", 0L) < DAY_MS) return
        val res = runCatching { update(ctx) }.getOrNull() ?: return
        // Our own extraction logic also updates itself from the signed release, without a new APK.
        runCatching { engine(ctx); loader(ctx).callAttr("update", dataDir(ctx), appBuild(ctx)) }
        if (res.optBoolean("ok")) stamp(ctx)
    }

    private fun stamp(ctx: Context) {
        ctx.getSharedPreferences("engine", Context.MODE_PRIVATE).edit()
            .putLong("last_check", System.currentTimeMillis()).apply()
    }
}
