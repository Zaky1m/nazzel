package app.nazzel

object SharedLink {
    private val pattern = Regex("https?://\\S+")

    fun extract(text: String?): String? =
        text?.let { pattern.find(it)?.value?.trimEnd('.', ',', ')', ']', '}', '>', '"', '\'') }
}
