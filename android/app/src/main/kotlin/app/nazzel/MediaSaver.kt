package app.nazzel

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.MediaStore
import java.io.File

object MediaSaver {
    const val DEFAULT_LABEL = "Movies/Nazzel"
    private const val TREE_KEY = "save_tree"

    private fun prefs(ctx: Context) = ctx.getSharedPreferences("app", Context.MODE_PRIVATE)

    /** Folder chosen by the user, or null when downloads go to the default MediaStore folders. */
    fun tree(ctx: Context): Uri? = prefs(ctx).getString(TREE_KEY, null)?.let { Uri.parse(it) }

    fun setTree(ctx: Context, uri: Uri?) {
        tree(ctx)?.let { old ->
            if (old != uri) runCatching {
                ctx.contentResolver.releasePersistableUriPermission(
                    old, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
            }
        }
        prefs(ctx).edit().apply { if (uri == null) remove(TREE_KEY) else putString(TREE_KEY, uri.toString()) }.apply()
    }

    fun label(ctx: Context): String {
        val tree = tree(ctx) ?: return DEFAULT_LABEL
        val id = runCatching { DocumentsContract.getTreeDocumentId(tree) }.getOrNull() ?: return DEFAULT_LABEL
        val (volume, path) = id.split(":", limit = 2).let { it[0] to it.getOrElse(1) { "" } }
        return if (volume == "primary") path.ifEmpty { "/" } else "$volume/$path"
    }

    fun save(ctx: Context, file: File, displayName: String, mime: String): Uri {
        val tree = tree(ctx)
        if (tree != null) {
            runCatching { return saveToTree(ctx, tree, file, displayName, mime) }
        }
        return saveToMediaStore(ctx, file, displayName, mime)
    }

    private fun saveToTree(ctx: Context, tree: Uri, file: File, displayName: String, mime: String): Uri {
        val resolver = ctx.contentResolver
        val root = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        // A generic type keeps the provider from appending its own extension to names like .m4a.
        val doc = DocumentsContract.createDocument(resolver, root, "application/octet-stream", displayName)
            ?: error("could not create $displayName in the chosen folder")
        try {
            resolver.openOutputStream(doc)!!.use { out -> file.inputStream().use { it.copyTo(out) } }
        } catch (e: Exception) {
            runCatching { DocumentsContract.deleteDocument(resolver, doc) }
            throw e
        }
        val id = DocumentsContract.getDocumentId(doc)
        if (id.startsWith("primary:")) {
            MediaScannerConnection.scanFile(
                ctx, arrayOf("/storage/emulated/0/" + id.removePrefix("primary:")), arrayOf(mime), null
            )
        }
        return doc
    }

    private fun saveToMediaStore(ctx: Context, file: File, displayName: String, mime: String): Uri {
        val audio = mime.startsWith("audio/")
        val resolver = ctx.contentResolver
        val collection = if (audio) MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        else MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(MediaStore.MediaColumns.RELATIVE_PATH, if (audio) "Music/Nazzel" else "Movies/Nazzel")
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values) ?: error("MediaStore insert failed")
        try {
            resolver.openOutputStream(uri)!!.use { out -> file.inputStream().use { it.copyTo(out) } }
            resolver.update(uri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
        return uri
    }

    fun saveText(ctx: Context, text: String, displayName: String): Uri {
        val resolver = ctx.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, "text/plain")
            put(MediaStore.MediaColumns.RELATIVE_PATH, "Download/Nazzel")
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: error("MediaStore insert failed")
        resolver.openOutputStream(uri)!!.use { it.write(text.toByteArray(Charsets.UTF_8)) }
        return uri
    }

    fun delete(ctx: Context, uri: String): Boolean {
        val target = Uri.parse(uri)
        return runCatching {
            if (DocumentsContract.isDocumentUri(ctx, target)) DocumentsContract.deleteDocument(ctx.contentResolver, target)
            else ctx.contentResolver.delete(target, null, null) > 0
        }.getOrDefault(false)
    }
}
