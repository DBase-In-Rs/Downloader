package rs.`in`.dbase.downloader

import android.content.Context
import android.content.Intent
import android.content.ContentValues
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Size
import java.io.ByteArrayOutputStream
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.youtubedl_android.mapper.VideoFormat
import com.yausername.youtubedl_android.mapper.VideoInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val mediaExecutor = Executors.newSingleThreadExecutor()
    private val controlExecutor = Executors.newCachedThreadPool()
    private val scheduler = Executors.newSingleThreadScheduledExecutor()
    private val initLock = Any()
    private val downloadLock = Any()
    private val activeDownloadIds = mutableSetOf<String>()
    private val canceledDownloadIds = mutableSetOf<String>()

    private var downloaderEvents: EventChannel.EventSink? = null
    private var shareEvents: EventChannel.EventSink? = null
    private var initialSharedText: String? = null
    private var pendingFolderPick: MethodChannel.Result? = null

    @Volatile
    private var youtubeDlInitialized = false

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        initialSharedText = sharedTextFromIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DOWNLOADER_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInfo" -> {
                    val url = call.argument<String>("url")
                    val useCookies = call.argument<Boolean>("useCookies") ?: false
                    if (url.isNullOrBlank()) {
                        result.error("invalid_url", "URL is required.", null)
                    } else {
                        mediaExecutor.execute {
                            try {
                                ensureYoutubeDlInitialized()
                                val info = fetchMediaInfo(url, useCookies)
                                mainHandler.post { result.success(videoInfoToMap(info, url)) }
                            } catch (error: Throwable) {
                                mainHandler.post {
                                    result.error(
                                        "metadata_failed",
                                        sanitizeNativeError(error),
                                        null,
                                    )
                                }
                            }
                        }
                    }
                }

                "getPlaylistInfo" -> {
                    val url = call.argument<String>("url")
                    val useCookies = call.argument<Boolean>("useCookies") ?: false
                    if (url.isNullOrBlank()) {
                        result.error("invalid_url", "URL is required.", null)
                    } else {
                        mediaExecutor.execute {
                            try {
                                ensureYoutubeDlInitialized()
                                val playlist = fetchPlaylistInfo(url, useCookies)
                                mainHandler.post { result.success(playlist) }
                            } catch (error: Throwable) {
                                mainHandler.post {
                                    result.error(
                                        "metadata_failed",
                                        sanitizeNativeError(error),
                                        null,
                                    )
                                }
                            }
                        }
                    }
                }

                "startDownload" -> {
                    val id = call.argument<String>("id")
                    val url = call.argument<String>("url")
                    val formatId = call.argument<String>("formatId")
                    val outputKind = call.argument<String>("outputKind") ?: "original"
                    if (id.isNullOrBlank() || url.isNullOrBlank() || formatId.isNullOrBlank()) {
                        result.error(
                            "invalid_download_request",
                            "Download id, URL, and format id are required.",
                            null,
                        )
                    } else {
                        val tuning = DownloadTuning(
                            retries = call.argument<Int>("retries") ?: 10,
                            fragmentRetries = call.argument<Int>("fragmentRetries") ?: 10,
                            sleepRequestsSeconds =
                                call.argument<Number>("sleepRequestsSeconds")?.toDouble() ?: 0.0,
                            sleepIntervalSeconds =
                                call.argument<Int>("sleepIntervalSeconds") ?: 0,
                            maxSleepIntervalSeconds =
                                call.argument<Int>("maxSleepIntervalSeconds") ?: 0,
                        )
                        startDownload(id, url, formatId, outputKind, tuning)
                        result.success(null)
                    }
                }

                "renameOutput" -> {
                    val location = call.argument<String>("location")
                    val newName = call.argument<String>("newName")
                    if (location.isNullOrBlank() || newName.isNullOrBlank()) {
                        result.error(
                            "invalid_rename_request",
                            "Location and new name are required.",
                            null,
                        )
                    } else {
                        controlExecutor.execute {
                            try {
                                val renamed = renameOutputFile(location, newName)
                                mainHandler.post {
                                    result.success(
                                        mapOf(
                                            "location" to renamed.first,
                                            "displayName" to renamed.second,
                                        ),
                                    )
                                }
                            } catch (error: Throwable) {
                                mainHandler.post {
                                    result.error(
                                        "rename_failed",
                                        sanitizeNativeError(error),
                                        null,
                                    )
                                }
                            }
                        }
                    }
                }

                "getOutputThumbnail" -> {
                    val location = call.argument<String>("location")
                    val size = call.argument<Int>("size") ?: 256
                    if (location.isNullOrBlank()) {
                        result.success(null)
                    } else {
                        controlExecutor.execute {
                            val bytes = outputThumbnail(location, size)
                            mainHandler.post { result.success(bytes) }
                        }
                    }
                }

                "readOutputBytes" -> {
                    val location = call.argument<String>("location")
                    val maxBytes = call.argument<Number>("maxBytes")?.toLong()
                        ?: (80L * 1024 * 1024)
                    if (location.isNullOrBlank()) {
                        result.error("invalid_location", "Output location is required.", null)
                    } else {
                        controlExecutor.execute {
                            try {
                                val bytes = readOutputBytes(location, maxBytes)
                                mainHandler.post { result.success(bytes) }
                            } catch (error: Throwable) {
                                mainHandler.post {
                                    result.error(
                                        "read_failed",
                                        sanitizeNativeError(error),
                                        null,
                                    )
                                }
                            }
                        }
                    }
                }

                "writeOutputBytes" -> {
                    val location = call.argument<String>("location")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (location.isNullOrBlank() || bytes == null) {
                        result.error("invalid_write_request", "Location and bytes are required.", null)
                    } else {
                        controlExecutor.execute {
                            try {
                                writeOutputBytes(location, bytes)
                                mainHandler.post { result.success(null) }
                            } catch (error: Throwable) {
                                mainHandler.post {
                                    result.error(
                                        "write_failed",
                                        sanitizeNativeError(error),
                                        null,
                                    )
                                }
                            }
                        }
                    }
                }

                "cancelDownload" -> {
                    val id = call.argument<String>("id")
                    if (id.isNullOrBlank()) {
                        result.error("invalid_download_id", "Download id is required.", null)
                    } else {
                        cancelDownload(id)
                        result.success(null)
                    }
                }

                "updateEngine" -> {
                    // Runs on the media executor so an engine update never
                    // overlaps a running yt-dlp process.
                    mediaExecutor.execute {
                        try {
                            ensureYoutubeDlInitialized()
                            val status = YoutubeDL.getInstance().updateYoutubeDL(
                                applicationContext,
                                YoutubeDL.UpdateChannel.STABLE,
                            )
                            val version = runCatching {
                                YoutubeDL.getInstance().version(applicationContext)
                            }.getOrNull()
                            mainHandler.post {
                                result.success(
                                    mapOf(
                                        "updated" to (status == YoutubeDL.UpdateStatus.DONE),
                                        "version" to version,
                                    ),
                                )
                            }
                        } catch (error: Throwable) {
                            mainHandler.post {
                                result.error(
                                    "engine_update_failed",
                                    sanitizeNativeError(error),
                                    null,
                                )
                            }
                        }
                    }
                }

                "getCookieStatus" -> result.success(
                    mapOf(
                        "configured" to CookieVault.isConfigured(applicationContext),
                        "expired" to CookieVault.isExpired(applicationContext),
                        "message" to if (CookieVault.isExpired(applicationContext)) {
                            "Cookies look expired or invalid; re-import cookies.txt."
                        } else {
                            null
                        },
                    ),
                )

                "importCookies" -> {
                    val content = call.argument<String>("content")
                    if (content.isNullOrBlank()) {
                        result.error(
                            "invalid_cookie_file",
                            "Cookie file content is required.",
                            null,
                        )
                    } else {
                        controlExecutor.execute {
                            try {
                                CookieVault.store(applicationContext, content)
                                mainHandler.post { result.success(null) }
                            } catch (error: Throwable) {
                                mainHandler.post {
                                    result.error(
                                        "cookie_import_failed",
                                        sanitizeNativeError(error),
                                        null,
                                    )
                                }
                            }
                        }
                    }
                }

                "openOutput" -> {
                    val location = call.argument<String>("location")
                    if (location.isNullOrBlank()) {
                        result.error("invalid_location", "Output location is required.", null)
                    } else {
                        try {
                            startActivity(outputIntent(Intent.ACTION_VIEW, location))
                            result.success(null)
                        } catch (error: Throwable) {
                            result.error("open_failed", outputActionError(error), null)
                        }
                    }
                }

                "shareOutput" -> {
                    val location = call.argument<String>("location")
                    if (location.isNullOrBlank()) {
                        result.error("invalid_location", "Output location is required.", null)
                    } else {
                        try {
                            startActivity(
                                Intent.createChooser(
                                    outputIntent(Intent.ACTION_SEND, location),
                                    "Share media",
                                ),
                            )
                            result.success(null)
                        } catch (error: Throwable) {
                            result.error("share_failed", outputActionError(error), null)
                        }
                    }
                }

                "pickOutputFolder" -> {
                    if (pendingFolderPick != null) {
                        result.error("busy", "Folder picker already open.", null)
                    } else {
                        pendingFolderPick = result
                        startActivityForResult(
                            Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
                            ),
                            FOLDER_PICK_REQUEST_CODE,
                        )
                    }
                }

                "getOutputFolder" -> result.success(
                    outputTreeUri()?.let(::folderDisplayName),
                )

                "clearOutputFolder" -> {
                    outputTreeUri()?.let { uri ->
                        runCatching {
                            contentResolver.releasePersistableUriPermission(
                                uri,
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                            )
                        }
                    }
                    settingsPrefs().edit().remove(OUTPUT_TREE_KEY).apply()
                    result.success(null)
                }

                "clearCookies" -> {
                    controlExecutor.execute {
                        runCatching { CookieVault.clear(applicationContext) }
                        mainHandler.post { result.success(null) }
                    }
                }

                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DOWNLOADER_EVENTS_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    downloaderEvents = events
                }

                override fun onCancel(arguments: Any?) {
                    downloaderEvents = null
                }
            },
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedText" -> {
                    val sharedText = initialSharedText
                    initialSharedText = null
                    result.success(sharedText)
                }

                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARE_EVENTS_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    shareEvents = events
                }

                override fun onCancel(arguments: Any?) {
                    shareEvents = null
                }
            },
        )
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != FOLDER_PICK_REQUEST_CODE) {
            return
        }

        val pending = pendingFolderPick
        pendingFolderPick = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            pending?.success(null)
            return
        }

        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            settingsPrefs().edit().putString(OUTPUT_TREE_KEY, uri.toString()).apply()
            pending?.success(folderDisplayName(uri))
        } catch (error: Throwable) {
            pending?.error("folder_pick_failed", sanitizeNativeError(error), null)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val sharedText = sharedTextFromIntent(intent) ?: return
        val sink = shareEvents
        if (sink == null) {
            initialSharedText = sharedText
        } else {
            sink.success(sharedText)
        }
    }

    override fun onDestroy() {
        val ids = synchronized(downloadLock) {
            activeDownloadIds.toList()
        }
        for (id in ids) {
            runCatching { YoutubeDL.getInstance().destroyProcessById(id) }
        }
        DownloadForegroundService.stop(applicationContext)
        mediaExecutor.shutdownNow()
        controlExecutor.shutdownNow()
        scheduler.shutdownNow()
        super.onDestroy()
    }

    private fun sharedTextFromIntent(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND || intent.type != "text/plain") {
            return null
        }

        return intent.getStringExtra(Intent.EXTRA_TEXT)?.takeIf { it.isNotBlank() }
    }

    private fun ensureYoutubeDlInitialized() {
        if (youtubeDlInitialized) {
            return
        }

        synchronized(initLock) {
            if (youtubeDlInitialized) {
                return
            }

            cleanStaleTempFiles()
            YoutubeDL.getInstance().init(applicationContext)
            FFmpeg.getInstance().init(applicationContext)
            fixFfmpegPageSizeLibs()
            youtubeDlInitialized = true
        }
    }

    /**
     * Removes temp files left behind by a crash or process kill. Runs before
     * the first yt-dlp task of the process, so no download can be active yet.
     */
    private fun cleanStaleTempFiles() {
        runCatching { File(cacheDir, "downloads").deleteRecursively() }
        runCatching { File(cacheDir, "cookies").deleteRecursively() }
    }

    private fun outputIntent(action: String, location: String): Intent {
        val uri = Uri.parse(location)
        require(uri.scheme == "content") {
            "Only media saved through the system storage can be opened here."
        }

        // A deleted or moved file leaves a dangling entry; probing first
        // gives a clear message instead of a broken player screen.
        val exists = runCatching {
            contentResolver.openAssetFileDescriptor(uri, "r")?.use { true } ?: false
        }.getOrDefault(false)
        require(exists) {
            "This file no longer exists on the device - it was deleted or " +
                "moved. Remove this entry from history."
        }

        val mimeType = contentResolver.getType(uri) ?: "*/*"
        return Intent(action).apply {
            if (action == Intent.ACTION_SEND) {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
            } else {
                setDataAndType(uri, mimeType)
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    private fun outputActionError(error: Throwable): String {
        return when (error) {
            is android.content.ActivityNotFoundException ->
                "No app on this device can open this file type."
            is IllegalArgumentException -> error.message
                ?: "This item cannot be opened."
            else -> sanitizeNativeError(error)
        }
    }

    private fun settingsPrefs() =
        getSharedPreferences("downloader_settings", Context.MODE_PRIVATE)

    private fun outputTreeUri(): Uri? {
        val stored = settingsPrefs().getString(OUTPUT_TREE_KEY, null) ?: return null
        val uri = Uri.parse(stored)
        val stillGranted = contentResolver.persistedUriPermissions.any {
            it.uri == uri && it.isWritePermission
        }
        if (!stillGranted) {
            settingsPrefs().edit().remove(OUTPUT_TREE_KEY).apply()
            return null
        }

        return uri
    }

    private fun folderDisplayName(uri: Uri): String {
        return uri.lastPathSegment ?: uri.toString()
    }

    private fun saveToDocumentTree(file: File, outputKind: String, tree: Uri): Uri {
        val parent = DocumentsContract.buildDocumentUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        // createDocument de-duplicates names itself (appends " (1)").
        val target = DocumentsContract.createDocument(
            contentResolver,
            parent,
            mimeTypeFor(file, outputKind),
            displayNameFor(file, outputKind),
        ) ?: throw IllegalStateException("Could not create a file in the selected folder.")

        try {
            file.inputStream().use { input ->
                contentResolver.openOutputStream(target)?.use { output ->
                    input.copyTo(output)
                } ?: throw IllegalStateException("Could not write to the selected folder.")
            }
            return target
        } catch (error: Throwable) {
            runCatching { DocumentsContract.deleteDocument(contentResolver, target) }
            throw error
        }
    }

    /**
     * youtubedl-android 0.18.1 ships libwebp shared libraries built with 4 KB
     * page alignment, which the dynamic linker rejects on 16 KB page-size
     * devices ("program alignment (4096) cannot be smaller than system page
     * size (16384)"), so every FFmpeg invocation fails there. The app bundles
     * 16 KB-aligned libwebp builds in jniLibs and overwrites the extracted
     * copies after FFmpeg.init. Size comparison re-applies the fix whenever a
     * library update re-extracts the original files.
     */
    private fun fixFfmpegPageSizeLibs() {
        val nativeDir = File(applicationInfo.nativeLibraryDir)
        val ffmpegLibDir = File(
            applicationContext.noBackupFilesDir,
            "youtubedl-android/packages/ffmpeg/usr/lib",
        )
        if (!ffmpegLibDir.isDirectory) {
            return
        }

        for (name in PAGE_ALIGNED_FFMPEG_LIBS) {
            val source = File(nativeDir, name)
            val target = File(ffmpegLibDir, name)
            if (source.isFile && target.isFile && source.length() != target.length()) {
                runCatching { source.copyTo(target, overwrite = true) }
            }
        }
    }

    private fun fetchMediaInfo(url: String, useCookies: Boolean): VideoInfo {
        val processId = "info-${System.currentTimeMillis()}"
        // Warnings stay enabled: expired-cookie detection depends on the
        // "cookies are no longer valid" warning text in failure output.
        val request = YoutubeDLRequest(url)
            .addOption("--no-playlist")
            .addOption("--dump-json")

        val cookieFile = if (useCookies) {
            CookieVault.materialize(applicationContext, File(cacheDir, "cookies"))
        } else {
            null
        }
        cookieFile?.let { request.addOption("--cookies", it.absolutePath) }

        val timeout = scheduler.schedule(
            { YoutubeDL.getInstance().destroyProcessById(processId) },
            METADATA_TIMEOUT_SECONDS,
            TimeUnit.SECONDS,
        )

        return try {
            val response = YoutubeDL.getInstance().execute(request, processId, false, null)
            YoutubeDL.objectMapper.readValue(response.out, VideoInfo::class.java)
                ?: throw IllegalStateException("Unable to parse media information.")
        } catch (error: YoutubeDL.CanceledException) {
            throw IllegalStateException("Metadata extraction timed out.")
        } catch (error: Throwable) {
            if (cookieFile != null) {
                CookieVault.markExpiredIfAuthError(
                    applicationContext,
                    error.message ?: "",
                )
            }
            throw error
        } finally {
            timeout.cancel(false)
            cookieFile?.delete()
        }
    }

    private fun fetchPlaylistInfo(url: String, useCookies: Boolean): Map<String, Any?> {
        val processId = "playlist-${System.currentTimeMillis()}"
        val request = YoutubeDLRequest(url)
            .addOption("--flat-playlist")
            .addOption("--dump-single-json")

        val cookieFile = if (useCookies) {
            CookieVault.materialize(applicationContext, File(cacheDir, "cookies"))
        } else {
            null
        }
        cookieFile?.let { request.addOption("--cookies", it.absolutePath) }

        val timeout = scheduler.schedule(
            { YoutubeDL.getInstance().destroyProcessById(processId) },
            PLAYLIST_TIMEOUT_SECONDS,
            TimeUnit.SECONDS,
        )

        try {
            val response = YoutubeDL.getInstance().execute(request, processId, false, null)
            val root = YoutubeDL.objectMapper.readTree(response.out)
            val entries = root.path("entries").mapNotNull { entry ->
                val entryUrl = playlistEntryUrl(entry) ?: return@mapNotNull null
                mapOf(
                    "url" to entryUrl,
                    "title" to entry.path("title").asText(null),
                    "durationSeconds" to entry.path("duration").asLong(0)
                        .takeIf { it > 0 },
                    "uploader" to (
                        entry.path("uploader").asText(null)
                            ?: entry.path("channel").asText(null)
                        ),
                )
            }

            return mapOf(
                "url" to (root.path("webpage_url").asText(null) ?: url),
                "title" to (root.path("title").asText(null) ?: "Playlist"),
                "entries" to entries,
            )
        } catch (error: YoutubeDL.CanceledException) {
            throw IllegalStateException("Playlist extraction timed out.")
        } finally {
            timeout.cancel(false)
            cookieFile?.delete()
        }
    }

    private fun playlistEntryUrl(entry: com.fasterxml.jackson.databind.JsonNode): String? {
        val webpage = entry.path("webpage_url").asText(null)
        if (!webpage.isNullOrBlank() && webpage.startsWith("http")) {
            return webpage
        }

        val url = entry.path("url").asText(null)
        if (!url.isNullOrBlank() && url.startsWith("http")) {
            return url
        }

        val id = entry.path("id").asText(null) ?: url
        if (!id.isNullOrBlank()) {
            return when (entry.path("ie_key").asText("").lowercase()) {
                "youtube" -> "https://www.youtube.com/watch?v=$id"
                "dailymotion" -> "https://www.dailymotion.com/video/$id"
                "vimeo" -> "https://vimeo.com/$id"
                else -> null
            }
        }

        return null
    }

    private fun videoInfoToMap(info: VideoInfo, fallbackUrl: String): Map<String, Any?> {
        val formats = (info.formats ?: info.requestedFormats ?: arrayListOf())
            .mapNotNull(::videoFormatToMap)

        return mapOf(
            "url" to (info.webpageUrl ?: fallbackUrl),
            "title" to (info.fulltitle ?: info.title ?: "Untitled media"),
            "uploader" to info.uploader,
            "thumbnailUrl" to info.thumbnail,
            "durationSeconds" to info.duration.takeIf { it > 0 },
            "extractor" to (info.extractorKey ?: info.extractor),
            "formats" to formats,
        )
    }

    private fun videoFormatToMap(format: VideoFormat): Map<String, Any?>? {
        val id = format.formatId ?: return null
        val hasVideo = !format.vcodec.isNullOrBlank() && format.vcodec != "none"
        val hasAudio = !format.acodec.isNullOrBlank() && format.acodec != "none"
        val kind = when {
            hasVideo && hasAudio -> "muxed"
            hasVideo -> "video"
            hasAudio -> "audio"
            else -> "unknown"
        }
        val filesize = when {
            format.fileSize > 0 -> format.fileSize
            format.fileSizeApproximate > 0 -> format.fileSizeApproximate
            else -> null
        }
        val codec = listOfNotNull(
            format.vcodec?.takeUnless { it == "none" },
            format.acodec?.takeUnless { it == "none" },
        ).joinToString(" + ").takeIf { it.isNotBlank() }

        return mapOf(
            "id" to id,
            "extension" to (format.ext ?: "unknown"),
            "kind" to kind,
            "qualityLabel" to qualityLabelFor(format),
            "width" to format.width.takeIf { it > 0 },
            "height" to format.height.takeIf { it > 0 },
            "audioBitrateKbps" to format.abr.takeIf { it > 0 },
            "videoBitrateKbps" to format.tbr.takeIf { it > 0 && hasVideo },
            "filesizeBytes" to filesize,
            "codec" to codec,
            "note" to format.formatNote,
        )
    }

    private fun qualityLabelFor(format: VideoFormat): String {
        return when {
            !format.formatNote.isNullOrBlank() -> format.formatNote!!
            format.height > 0 -> "${format.height}p"
            format.abr > 0 -> "${format.abr} kbps"
            format.tbr > 0 -> "${format.tbr} kbps"
            !format.format.isNullOrBlank() -> format.format!!
            !format.formatId.isNullOrBlank() -> format.formatId!!
            else -> "Unknown quality"
        }
    }

    private fun startDownload(
        id: String,
        url: String,
        formatId: String,
        outputKind: String,
        tuning: DownloadTuning,
    ) {
        markDownloadStarted(id)

        mediaExecutor.execute {
            var outputDir: File? = null
            var cookieFile: File? = null
            try {
                ensureYoutubeDlInitialized()
                emitProgress(
                    id = id,
                    stage = "Starting",
                    percent = 0.0,
                    downloadedBytes = null,
                    totalBytes = null,
                    speedBytesPerSecond = null,
                    etaSeconds = null,
                    rawLine = null,
                )

                val workingDir = File(cacheDir, "downloads/$id").apply { mkdirs() }
                outputDir = workingDir
                val request = downloadRequest(url, formatId, outputKind, workingDir, tuning)

                // The plain cookie file must stay OUTSIDE the working
                // directory: output detection picks the newest file there,
                // and yt-dlp rewrites the cookie file on exit, which would
                // make it the newest and leak it as the saved output.
                cookieFile = CookieVault.materialize(
                    applicationContext,
                    File(cacheDir, "cookies"),
                )
                cookieFile?.let { request.addOption("--cookies", it.absolutePath) }

                YoutubeDL.getInstance().execute(request, id) { progress, etaSeconds, line ->
                    val percent = progress.takeIf { it >= 0 }?.let { it / 100.0 }
                    val metrics = progressMetricsFromLine(line, percent)
                    emitProgress(
                        id = id,
                        stage = stageFromOutput(line),
                        percent = percent,
                        downloadedBytes = metrics.downloadedBytes,
                        totalBytes = metrics.totalBytes,
                        speedBytesPerSecond = metrics.speedBytesPerSecond,
                        etaSeconds = etaSeconds.takeIf { it >= 0 },
                        rawLine = line,
                    )
                }

                val outputFile = outputDir
                    .walkTopDown()
                    .filter { it.isFile && !it.name.endsWith(".part") }
                    .maxByOrNull { it.lastModified() }
                    ?: throw IllegalStateException("Download finished without an output file.")

                if (!wasCanceled(id)) {
                    val (outputLocation, displayName) = saveOutputFile(outputFile, outputKind)
                    emitCompleted(id, outputLocation, displayName)
                }
            } catch (error: YoutubeDL.CanceledException) {
                markCanceled(id)
                emitCanceled(id)
            } catch (error: InterruptedException) {
                Thread.currentThread().interrupt()
                markCanceled(id)
                emitCanceled(id)
            } catch (error: Throwable) {
                if (wasCanceled(id)) {
                    emitCanceled(id)
                } else {
                    if (cookieFile != null) {
                        CookieVault.markExpiredIfAuthError(
                            applicationContext,
                            error.message ?: "",
                        )
                    }
                    emitFailed(id, sanitizeNativeError(error))
                }
            } finally {
                cookieFile?.delete()
                outputDir?.deleteRecursively()
                markDownloadFinished(id)
            }
        }
    }

    private fun downloadRequest(
        url: String,
        formatId: String,
        outputKind: String,
        outputDir: File,
        tuning: DownloadTuning,
    ): YoutubeDLRequest {
        val request = YoutubeDLRequest(url)
            .addOption("--no-playlist")
            .addOption("--newline")
            .addOption("--restrict-filenames")
            .addOption("--trim-filenames", 180)
            .addOption("--retries", tuning.retries)
            .addOption("--fragment-retries", tuning.fragmentRetries)
            .addOption("-f", formatId)
            .addOption("-o", File(outputDir, "%(title)s.%(ext)s").absolutePath)

        if (tuning.sleepRequestsSeconds > 0) {
            request.addOption("--sleep-requests", tuning.sleepRequestsSeconds)
        }
        if (tuning.sleepIntervalSeconds > 0) {
            request.addOption("--sleep-interval", tuning.sleepIntervalSeconds)
            if (tuning.maxSleepIntervalSeconds > tuning.sleepIntervalSeconds) {
                request.addOption("--max-sleep-interval", tuning.maxSleepIntervalSeconds)
            }
        }

        when (outputKind) {
            "mp3" -> request
                .addOption("-x")
                .addOption("--audio-format", "mp3")
                .addOption("--audio-quality", "0")

            "m4a" -> request
                .addOption("-x")
                .addOption("--audio-format", "m4a")

            "mp4" -> request.addOption("--merge-output-format", "mp4")
        }

        return request
    }

    private fun cancelDownload(id: String) {
        val wasActive = synchronized(downloadLock) {
            val active = activeDownloadIds.contains(id)
            canceledDownloadIds.add(id)
            active
        }
        controlExecutor.execute {
            runCatching { YoutubeDL.getInstance().destroyProcessById(id) }
            if (!wasActive) {
                emitCanceled(id)
            }
        }
    }

    private fun stageFromOutput(line: String): String {
        return when {
            line.contains("[ExtractAudio]") -> "Converting"
            line.contains("[Merger]") -> "Merging"
            line.contains("[download]") -> "Downloading"
            line.contains("[ffmpeg]") -> "Finalizing"
            else -> "Working"
        }
    }

    private fun emitProgress(
        id: String,
        stage: String,
        percent: Double?,
        downloadedBytes: Long?,
        totalBytes: Long?,
        speedBytesPerSecond: Long?,
        etaSeconds: Long?,
        rawLine: String?,
    ) {
        mainHandler.post {
            downloaderEvents?.success(
                mapOf(
                    "type" to "progress",
                    "id" to id,
                    "stage" to stage,
                    "percent" to percent,
                    "downloadedBytes" to downloadedBytes,
                    "totalBytes" to totalBytes,
                    "speedBytesPerSecond" to speedBytesPerSecond,
                    "etaSeconds" to etaSeconds,
                    "message" to rawLine?.let(::safeProgressLine),
                ),
            )
        }
    }

    private fun emitCompleted(id: String, outputLocation: String, displayName: String?) {
        mainHandler.post {
            downloaderEvents?.success(
                mapOf(
                    "type" to "completed",
                    "id" to id,
                    "outputLocation" to outputLocation,
                    "outputDisplayName" to displayName,
                ),
            )
        }
    }

    private fun emitFailed(id: String, message: String) {
        mainHandler.post {
            downloaderEvents?.success(
                mapOf(
                    "type" to "failed",
                    "id" to id,
                    "message" to message,
                ),
            )
        }
    }

    private fun emitCanceled(id: String) {
        mainHandler.post {
            downloaderEvents?.success(
                mapOf(
                    "type" to "canceled",
                    "id" to id,
                ),
            )
        }
    }

    private fun markCanceled(id: String) {
        synchronized(downloadLock) {
            canceledDownloadIds.add(id)
        }
    }

    private fun markDownloadStarted(id: String) {
        val shouldStartService = synchronized(downloadLock) {
            val firstDownload = activeDownloadIds.isEmpty()
            activeDownloadIds.add(id)
            canceledDownloadIds.remove(id)
            firstDownload
        }

        if (shouldStartService) {
            DownloadForegroundService.start(applicationContext)
        }
    }

    private fun markDownloadFinished(id: String) {
        val shouldStopService = synchronized(downloadLock) {
            activeDownloadIds.remove(id)
            canceledDownloadIds.remove(id)
            activeDownloadIds.isEmpty()
        }

        if (shouldStopService) {
            DownloadForegroundService.stop(applicationContext)
        }
    }

    private fun wasCanceled(id: String): Boolean {
        return synchronized(downloadLock) {
            canceledDownloadIds.contains(id)
        }
    }

    private fun progressMetricsFromLine(line: String, percent: Double?): ProgressMetrics {
        val match = progressMetricsRegex.find(line) ?: return ProgressMetrics()
        val totalBytes = bytesFromUnitValue(
            match.groups["totalValue"]?.value,
            match.groups["totalUnit"]?.value,
        )
        val speedBytes = bytesFromUnitValue(
            match.groups["speedValue"]?.value,
            match.groups["speedUnit"]?.value,
        )
        val downloadedBytes = if (totalBytes != null && percent != null) {
            (totalBytes * percent).toLong()
        } else {
            null
        }

        return ProgressMetrics(
            downloadedBytes = downloadedBytes,
            totalBytes = totalBytes,
            speedBytesPerSecond = speedBytes,
        )
    }

    private fun bytesFromUnitValue(value: String?, unit: String?): Long? {
        val number = value?.toDoubleOrNull() ?: return null
        val multiplier = when (unit?.lowercase()) {
            "b" -> 1.0
            "kb" -> 1000.0
            "kib" -> 1024.0
            "mb" -> 1000.0 * 1000.0
            "mib" -> 1024.0 * 1024.0
            "gb" -> 1000.0 * 1000.0 * 1000.0
            "gib" -> 1024.0 * 1024.0 * 1024.0
            "tb" -> 1000.0 * 1000.0 * 1000.0 * 1000.0
            "tib" -> 1024.0 * 1024.0 * 1024.0 * 1024.0
            else -> return null
        }

        return (number * multiplier).toLong()
    }

    private fun sanitizeNativeError(error: Throwable): String {
        // Walk the cause chain so a wrapper exception without a message still
        // produces something actionable instead of a bare class name.
        val raw = generateSequence(error) { it.cause }
            .mapNotNull { it.message?.takeIf(String::isNotBlank) }
            .firstOrNull()
            ?: error.javaClass.name
        // yt-dlp output mixes WARNING lines into the failure message; surface
        // only the ERROR lines to the user when they are present.
        val errorLines = raw.lines().filter { it.trimStart().startsWith("ERROR:") }
        val message = if (errorLines.isEmpty()) raw else errorLines.joinToString("\n")
        return message
            .replace(
                Regex("(?i)(cookie|token|auth|session)[^\\s&=]*=([^\\s&]+)"),
                "$1=<redacted>",
            )
            .replace(Regex("https?://\\S+"), "<url>")
            .take(800)
    }

    private fun safeProgressLine(line: String): String {
        return line
            .replace(Regex("https?://\\S+"), "<url>")
            .take(240)
    }

    private fun saveOutputFile(file: File, outputKind: String): Pair<String, String> {
        outputTreeUri()?.let { tree ->
            // If the chosen folder became unavailable (deleted, unmounted),
            // fall back to the default MediaStore path instead of failing.
            runCatching {
                val saved = saveToDocumentTree(file, outputKind, tree)
                return saved.toString() to
                    (queryDisplayName(saved) ?: displayNameFor(file, outputKind))
            }
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val saved = saveOutputFileToMediaStore(file, outputKind)
            saved.toString() to
                (queryDisplayName(saved) ?: displayNameFor(file, outputKind))
        } else {
            val saved = saveOutputFileToAppExternalStorage(file, outputKind)
            saved.absolutePath to saved.name
        }
    }

    /// Display name recorded by the storage backend, which may differ from
    /// the requested one when duplicates get " (1)" suffixes.
    private fun queryDisplayName(uri: Uri): String? {
        return runCatching {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }
        }.getOrNull()
    }

    private fun renameOutputFile(location: String, newName: String): Pair<String, String> {
        require(!newName.contains(Regex("[\\\\/:*?\"<>|]"))) { "Invalid file name." }

        if (!location.startsWith("content://")) {
            val source = File(location)
            if (!source.isFile) {
                throw IllegalStateException("The file no longer exists at this location.")
            }
            val target = File(source.parentFile, newName)
            if (target.exists()) {
                throw IllegalStateException("A file with that name already exists.")
            }
            if (!source.renameTo(target)) {
                throw IllegalStateException("Could not rename this file.")
            }
            return target.absolutePath to target.name
        }

        val uri = Uri.parse(location)
        return if (DocumentsContract.isDocumentUri(this, uri)) {
            val renamed = DocumentsContract.renameDocument(contentResolver, uri, newName)
                ?: throw IllegalStateException("Could not rename this file.")
            renamed.toString() to (queryDisplayName(renamed) ?: newName)
        } else {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, newName)
            }
            val updated = contentResolver.update(uri, values, null, null)
            if (updated <= 0) {
                throw IllegalStateException("Could not rename this file.")
            }
            location to (queryDisplayName(uri) ?: newName)
        }
    }

    private fun outputThumbnail(location: String, size: Int): ByteArray? {
        return runCatching {
            val bitmap = (if (location.startsWith("content://")) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    contentResolver.loadThumbnail(
                        Uri.parse(location),
                        Size(size, size),
                        null,
                    )
                } else {
                    null
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                android.media.ThumbnailUtils.createVideoThumbnail(
                    File(location),
                    Size(size, size),
                    null,
                )
            } else {
                null
            }) ?: return null

            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, 82, stream)
            bitmap.recycle()
            stream.toByteArray()
        }.getOrNull()
    }

    private fun readOutputBytes(location: String, maxBytes: Long): ByteArray {
        if (!location.startsWith("content://")) {
            val file = File(location)
            if (!file.isFile) {
                throw IllegalStateException("The file no longer exists at this location.")
            }
            if (file.length() > maxBytes) {
                throw IllegalStateException("The file is too large to edit on this device.")
            }
            return file.readBytes()
        }

        val uri = Uri.parse(location)
        contentResolver.openAssetFileDescriptor(uri, "r")?.use { descriptor ->
            if (descriptor.length != -1L && descriptor.length > maxBytes) {
                throw IllegalStateException("The file is too large to edit on this device.")
            }
        }

        val input = contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("The file no longer exists at this location.")
        input.use { stream ->
            val buffer = ByteArrayOutputStream()
            val chunk = ByteArray(64 * 1024)
            var total = 0L
            while (true) {
                val read = stream.read(chunk)
                if (read == -1) {
                    break
                }
                total += read
                if (total > maxBytes) {
                    throw IllegalStateException("The file is too large to edit on this device.")
                }
                buffer.write(chunk, 0, read)
            }
            return buffer.toByteArray()
        }
    }

    private fun writeOutputBytes(location: String, bytes: ByteArray) {
        if (!location.startsWith("content://")) {
            File(location).writeBytes(bytes)
            return
        }

        val output = contentResolver.openOutputStream(Uri.parse(location), "wt")
            ?: throw IllegalStateException("Could not write to this file.")
        output.use { it.write(bytes) }
    }

    private fun saveOutputFileToMediaStore(file: File, outputKind: String): Uri {
        val audio = isAudioOutput(file, outputKind)
        val resolver = applicationContext.contentResolver
        val displayName = displayNameFor(file, outputKind)
        val collection = if (audio) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        }
        val relativePath = if (audio) {
            "${Environment.DIRECTORY_MUSIC}/DBase Downloader"
        } else {
            "${Environment.DIRECTORY_MOVIES}/DBase Downloader"
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeTypeFor(file, outputKind))
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore insert failed.")

        try {
            file.inputStream().use { input ->
                resolver.openOutputStream(uri)?.use { output ->
                    input.copyTo(output)
                } ?: throw IllegalStateException("MediaStore output stream failed.")
            }

            val completeValues = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(uri, completeValues, null, null)
            return uri
        } catch (error: Throwable) {
            resolver.delete(uri, null, null)
            throw error
        }
    }

    private fun saveOutputFileToAppExternalStorage(file: File, outputKind: String): File {
        val directoryType = if (isAudioOutput(file, outputKind)) {
            Environment.DIRECTORY_MUSIC
        } else {
            Environment.DIRECTORY_MOVIES
        }
        val baseDir = getExternalFilesDir(directoryType) ?: filesDir
        val outputDir = File(baseDir, "DBase Downloader").apply { mkdirs() }
        val target = uniqueFile(outputDir, displayNameFor(file, outputKind))

        file.copyTo(target, overwrite = false)
        return target
    }

    private fun uniqueFile(directory: File, displayName: String): File {
        val cleanName = displayName.ifBlank { "dbase-download" }
        val extension = cleanName.substringAfterLast('.', "")
        val baseName = if (extension.isBlank()) {
            cleanName
        } else {
            cleanName.removeSuffix(".$extension")
        }
        var candidate = File(directory, cleanName)
        var index = 1

        while (candidate.exists()) {
            val nextName = if (extension.isBlank()) {
                "$baseName ($index)"
            } else {
                "$baseName ($index).$extension"
            }
            candidate = File(directory, nextName)
            index++
        }

        return candidate
    }

    private fun displayNameFor(file: File, outputKind: String): String {
        val extension = when (outputKind) {
            "mp3", "m4a", "mp4" -> outputKind
            else -> file.extension.ifBlank { "media" }
        }
        val baseName = file.nameWithoutExtension
            .ifBlank { "dbase-download" }
            .replace(Regex("[\\\\/:*?\"<>|]+"), "_")
            .take(180)

        return "$baseName.$extension"
    }

    private fun mimeTypeFor(file: File, outputKind: String): String {
        val extension = when (outputKind) {
            "mp3", "m4a", "mp4" -> outputKind
            else -> file.extension.lowercase()
        }

        return when (extension) {
            "mp3" -> "audio/mpeg"
            "m4a" -> "audio/mp4"
            "aac" -> "audio/aac"
            "opus" -> "audio/opus"
            "ogg" -> "audio/ogg"
            "wav" -> "audio/wav"
            "mp4", "m4v" -> "video/mp4"
            "webm" -> "video/webm"
            "mkv" -> "video/x-matroska"
            else -> if (isAudioOutput(file, outputKind)) {
                "audio/*"
            } else {
                "video/*"
            }
        }
    }

    private fun isAudioOutput(file: File, outputKind: String): Boolean {
        if (outputKind == "mp3" || outputKind == "m4a") {
            return true
        }
        if (outputKind == "mp4") {
            return false
        }

        return file.extension.lowercase() in setOf("mp3", "m4a", "aac", "opus", "ogg", "wav")
    }

    companion object {
        private const val DOWNLOADER_CHANNEL = "rs.in.dbase.downloader/downloader"
        private const val DOWNLOADER_EVENTS_CHANNEL = "rs.in.dbase.downloader/events"
        private const val SHARE_CHANNEL = "rs.in.dbase.downloader/share"
        private const val SHARE_EVENTS_CHANNEL = "rs.in.dbase.downloader/share_events"
        private const val METADATA_TIMEOUT_SECONDS = 60L
        private const val PLAYLIST_TIMEOUT_SECONDS = 120L
        private const val FOLDER_PICK_REQUEST_CODE = 4001
        private const val OUTPUT_TREE_KEY = "output_tree_uri"
        private val PAGE_ALIGNED_FFMPEG_LIBS = listOf(
            "libsharpyuv.so",
            "libwebp.so",
            "libwebpdecoder.so",
            "libwebpdemux.so",
            "libwebpmux.so",
        )
        private val progressMetricsRegex = Regex(
            """of\s+~?\s*(?<totalValue>[0-9.]+)\s*(?<totalUnit>[KMGT]?i?B|[KMGT]?B)\s+at\s+(?<speedValue>[0-9.]+)\s*(?<speedUnit>[KMGT]?i?B|[KMGT]?B)/s""",
        )
    }
}

private data class ProgressMetrics(
    val downloadedBytes: Long? = null,
    val totalBytes: Long? = null,
    val speedBytesPerSecond: Long? = null,
)

/** User-tunable yt-dlp politeness and retry options from the Dart side. */
private data class DownloadTuning(
    val retries: Int = 10,
    val fragmentRetries: Int = 10,
    val sleepRequestsSeconds: Double = 0.0,
    val sleepIntervalSeconds: Int = 0,
    val maxSleepIntervalSeconds: Int = 0,
)
