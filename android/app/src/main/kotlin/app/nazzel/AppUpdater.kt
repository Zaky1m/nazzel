package app.nazzel

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

// Self-update from the latest GitHub release. Android only accepts the new APK if it carries the same
// signing key, so the manifest only has to guard against corrupt downloads (SHA-256).
object AppUpdater {
    private const val MANIFEST = "https://github.com/Zaky1m/nazzel/releases/latest/download/update.json"
    private const val DAY_MS = 24L * 60 * 60 * 1000

    private fun prefs(ctx: Context) = ctx.getSharedPreferences("updates", Context.MODE_PRIVATE)

    private fun open(url: String): HttpURLConnection =
        (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 20_000
            readTimeout = 30_000
            setRequestProperty("User-Agent", "nazzel")
        }

    /** The pending update, if one newer than this build was seen. */
    fun available(ctx: Context): JSONObject? {
        val raw = prefs(ctx).getString("manifest", null) ?: return null
        val json = runCatching { JSONObject(raw) }.getOrNull() ?: return null
        return if (json.optLong("build") > PyBridge.appBuild(ctx)) json else null
    }

    fun check(ctx: Context): JSONObject? {
        val conn = open(MANIFEST)
        try {
            if (conn.responseCode != 200) return available(ctx)
            val json = JSONObject(conn.inputStream.bufferedReader().readText())
            prefs(ctx).edit().putString("manifest", json.toString()).putLong("checked_at", System.currentTimeMillis()).apply()
        } finally {
            conn.disconnect()
        }
        return available(ctx)
    }

    fun maybeCheck(ctx: Context) {
        if (System.currentTimeMillis() - prefs(ctx).getLong("checked_at", 0) < DAY_MS) return
        runCatching { check(ctx) }.onFailure { Log.w("Nazzel", "update check failed", it) }
    }

    fun download(ctx: Context, manifest: JSONObject, progress: (Int) -> Unit): File {
        val dir = File(ctx.cacheDir, "update").apply { deleteRecursively(); mkdirs() }
        val file = File(dir, "nazzel.apk")
        val conn = open(manifest.getString("apk"))
        try {
            val total = conn.contentLengthLong.takeIf { it > 0 } ?: manifest.optLong("size", 0)
            val digest = MessageDigest.getInstance("SHA-256")
            conn.inputStream.use { input ->
                file.outputStream().use { out ->
                    val buf = ByteArray(64 * 1024)
                    var done = 0L
                    var last = -1
                    while (true) {
                        val n = input.read(buf)
                        if (n < 0) break
                        out.write(buf, 0, n)
                        digest.update(buf, 0, n)
                        done += n
                        val pct = if (total > 0) (done * 100 / total).toInt() else 0
                        if (pct != last) {
                            last = pct
                            progress(pct)
                        }
                    }
                }
            }
            val hex = digest.digest().joinToString("") { "%02x".format(it) }
            check(hex.equals(manifest.getString("sha256"), ignoreCase = true)) { "checksum mismatch" }
        } finally {
            conn.disconnect()
        }
        return file
    }

    /** Returns "permission" when the user still has to allow installs from Nazzel, else "started". */
    fun install(activity: Activity, file: File): String {
        val pm = activity.packageManager
        if (!pm.canRequestPackageInstalls()) {
            activity.runOnUiThread {
                activity.startActivity(
                    Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}"))
                )
            }
            return "permission"
        }
        val installer = pm.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
            .apply { setAppPackageName(activity.packageName) }
        val id = installer.createSession(params)
        installer.openSession(id).use { session ->
            session.openWrite("base.apk", 0, file.length()).use { out ->
                file.inputStream().use { it.copyTo(out) }
                session.fsync(out)
            }
            val intent = Intent(activity, InstallReceiver::class.java)
            // Mutable so the installer can attach its status and confirmation intent.
            val pi = PendingIntent.getBroadcast(activity, id, intent, PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            session.commit(pi.intentSender)
        }
        return "started"
    }
}

class InstallReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        when (intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                val confirm = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_INTENT)
                }
                confirm?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)?.let { ctx.startActivity(it) }
            }
            PackageInstaller.STATUS_SUCCESS -> Unit
            else -> {
                val msg = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
                Log.w("Nazzel", "update install failed: $msg")
                Toast.makeText(ctx, "التحديث ماتثبّتش", Toast.LENGTH_LONG).show()
            }
        }
    }
}
