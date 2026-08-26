package rs.`in`.dbase.downloader

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Stores the user-imported cookies.txt content encrypted at rest with an
 * Android Keystore AES/GCM key. yt-dlp can only read cookies from a plain
 * file, so [materialize] decrypts into a short-lived file that the caller
 * must delete after the yt-dlp process finishes.
 */
object CookieVault {
    private const val KEY_ALIAS = "rs.in.dbase.downloader.cookies"
    private const val KEYSTORE = "AndroidKeyStore"
    private const val FILE_NAME = "cookies.enc"
    private const val GCM_TAG_BITS = 128
    private const val IV_BYTES = 12

    fun isConfigured(context: Context): Boolean = vaultFile(context).isFile

    @Synchronized
    fun store(context: Context, content: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, obtainKey())
        val ciphertext = cipher.doFinal(content.toByteArray(Charsets.UTF_8))
        vaultFile(context).writeBytes(cipher.iv + ciphertext)
    }

    @Synchronized
    fun clear(context: Context) {
        vaultFile(context).delete()
    }

    /**
     * Decrypts the stored cookies into [directory] and returns the plain
     * file, or null when no cookies are stored. The caller must delete the
     * returned file after use.
     */
    @Synchronized
    fun materialize(context: Context, directory: File): File? {
        val encrypted = vaultFile(context)
        if (!encrypted.isFile) {
            return null
        }

        val payload = encrypted.readBytes()
        require(payload.size > IV_BYTES) { "Stored cookie payload is corrupt." }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            obtainKey(),
            GCMParameterSpec(GCM_TAG_BITS, payload, 0, IV_BYTES),
        )
        val plain = cipher.doFinal(payload, IV_BYTES, payload.size - IV_BYTES)

        directory.mkdirs()
        val target = File(directory, "cookies-${System.nanoTime()}.txt")
        target.writeBytes(plain)
        return target
    }

    private fun vaultFile(context: Context): File {
        return File(context.noBackupFilesDir, FILE_NAME)
    }

    private fun obtainKey(): SecretKey {
        val keyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }

        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            KEYSTORE,
        )
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .build(),
        )
        return generator.generateKey()
    }
}
