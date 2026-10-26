package app.nazzel

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import java.util.UUID
import java.util.concurrent.Executors

// Invisible receiver for ACTION_SEND: opens the quality sheet, or queues the best quality right away.
class ShareEntry : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val url = SharedLink.extract(intent.getStringExtra(Intent.EXTRA_TEXT))
        if (url == null) {
            Toast.makeText(applicationContext, "مفيش رابط في النص ده", Toast.LENGTH_SHORT).show()
            finish()
            return
        }
        val ask = getSharedPreferences("app", Context.MODE_PRIVATE).getString("ask_quality", "1") != "0"
        if (ask) {
            startActivity(Intent(this, ShareActivity::class.java).putExtra(Intent.EXTRA_TEXT, url))
        } else {
            val app = applicationContext
            Executors.newSingleThreadExecutor().execute {
                Store.get(app).insert(UUID.randomUUID().toString(), url, "", null, "best")
                DownloadService.start(app)
            }
            Toast.makeText(applicationContext, "بدأ التحميل بأعلى جودة", Toast.LENGTH_SHORT).show()
        }
        finish()
    }
}
