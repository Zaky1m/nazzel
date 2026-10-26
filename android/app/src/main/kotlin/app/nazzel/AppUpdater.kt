package app.nazzel

import android.content.Context
import android.util.Log
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

// Looks up the latest GitHub release so Settings can show when a newer version exists. Installing is left to the user.
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
}
