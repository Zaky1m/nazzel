package app.nazzel

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.nio.ByteBuffer

// Remuxes into MP4 without re-encoding, so no ffmpeg is needed. Covers separate video + audio
// streams and single HLS downloads, which arrive as MPEG-TS with an .mp4 name.
object Muxer {
    private const val BUFFER_SIZE = 4 shl 20

    private class Source(val extractor: MediaExtractor, val outTrack: Int)

    fun isMpegTs(file: File): Boolean = runCatching {
        file.inputStream().use { input ->
            val head = ByteArray(189)
            input.read(head) == 189 && head[0] == 0x47.toByte() && head[188] == 0x47.toByte()
        }
    }.getOrDefault(false)

    /** Takes the first video track found and the last audio track found across [inputs]. */
    fun mux(inputs: List<File>, out: File) {
        val muxer = MediaMuxer(out.path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val opened = mutableListOf<MediaExtractor>()
        val sources = mutableListOf<Source>()
        var started = false
        try {
            var video: Pair<MediaExtractor, Int>? = null
            var audio: Pair<MediaExtractor, Int>? = null
            for (file in inputs) {
                val ex = MediaExtractor().apply { setDataSource(file.path) }
                opened.add(ex)
                for (i in 0 until ex.trackCount) {
                    val mime = ex.getTrackFormat(i).getString(MediaFormat.KEY_MIME) ?: continue
                    if (mime.startsWith("video/") && video == null) video = ex to i
                    if (mime.startsWith("audio/")) audio = ex to i
                }
            }
            // One extractor per selected track keeps their read positions independent.
            for (pick in listOfNotNull(video, audio)) {
                val (owner, track) = pick
                val path = inputs[opened.indexOf(owner)].path
                val ex = MediaExtractor().apply { setDataSource(path) }
                opened.add(ex)
                ex.selectTrack(track)
                sources.add(Source(ex, muxer.addTrack(ex.getTrackFormat(track))))
            }
            check(sources.isNotEmpty()) { "no audio or video track" }
            muxer.start()
            started = true
            interleave(sources, muxer)
        } finally {
            if (started) runCatching { muxer.stop() }
            runCatching { muxer.release() }
            opened.forEach { runCatching { it.release() } }
        }
    }

    // Writing in timestamp order keeps the output playable while it is still being read.
    private fun interleave(sources: List<Source>, muxer: MediaMuxer) {
        val buf = ByteBuffer.allocate(BUFFER_SIZE)
        val info = MediaCodec.BufferInfo()
        while (true) {
            val next = sources.filter { it.extractor.sampleTime >= 0 }.minByOrNull { it.extractor.sampleTime } ?: break
            val ex = next.extractor
            buf.clear()
            val n = ex.readSampleData(buf, 0)
            if (n >= 0) {
                info.set(0, n, ex.sampleTime, ex.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC)
                muxer.writeSampleData(next.outTrack, buf, info)
            }
            ex.advance()
        }
    }
}
