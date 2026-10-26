package app.nazzel

// Bridges service-side changes to the Flutter UI when it is attached; dropped silently when it is not.
object Events {
    @Volatile var sink: ((String) -> Unit)? = null
    fun changed(id: String) {
        sink?.invoke(id)
    }
}
