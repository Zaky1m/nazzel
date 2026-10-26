package app.nazzel

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine

// Translucent Flutter sheet drawn over the app that shared the link, so the user never leaves it.
class ShareActivity : FlutterActivity() {
    private var engineChannel: EngineChannel? = null

    override fun getDartEntrypointFunctionName(): String = "shareMain"

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val url = SharedLink.extract(intent.getStringExtra(Intent.EXTRA_TEXT))
        engineChannel = EngineChannel(this, flutterEngine.dartExecutor.binaryMessenger, sharedUrl = url)
    }

    override fun onDestroy() {
        engineChannel?.dispose()
        super.onDestroy()
    }
}
