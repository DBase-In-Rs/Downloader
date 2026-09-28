# Privacy Policy for DBase Video & Music Downloader

Last updated: September 28, 2026

This policy applies specifically to DBase Video & Music Downloader (the
"App"), package identifier `rs.in.dbase.downloader`, on Android, Windows, and
Linux. It explains what information the App keeps on your device, what it
transmits when you use network features, and how you can delete locally stored
data.

The App is open source. It has no user accounts, analytics, telemetry,
advertising SDKs, or project-operated backend. The DBase project does not
receive a copy of your submitted media URLs, imported cookies, download
history, or downloaded files through the App.

## Information stored on your device

The App stores the following information locally as needed to provide its
features:

- **Download queue and history:** source media URLs, titles, provider names,
  selected formats, status and error information, output locations, and
  timestamps. Queue and history data is stored in the App's local preferences,
  is not additionally encrypted by the App, and is limited to the 200 most
  recent history entries.
- **Settings:** output-folder choices, paths to user-provided yt-dlp and FFmpeg
  tools on desktop, download preferences, and similar App configuration.
- **Imported cookies:** optional Netscape-format `cookies.txt` content supplied
  by you for media that requires authentication. On Android, cookies are
  encrypted at rest with AES-GCM using a key held by Android Keystore. On
  Windows and Linux, cookies are stored in the App's per-user application-data
  directory and rely on operating-system user-profile permissions; the App
  does not add separate encryption on those platforms.
- **Downloaded media:** files you choose to download or create with the trim
  editor, saved in the output location you select or in the platform's normal
  media/download storage.
- **Temporary files:** download, conversion, editing-preview, artwork, and
  short-lived plaintext cookie files required by yt-dlp or FFmpeg. The App
  removes backend-owned temporary files after use or cancellation where
  applicable. Operating-system cleanup may also remove cache files.

The App does not read cookies directly from browsers or other apps. Cookie
import happens only when you explicitly select a `cookies.txt` file.

## Information transmitted over the network

The App makes network requests only when required by a feature you use:

- **Media providers and their service providers:** when you inspect or download
  a media URL, the URL is passed to yt-dlp. yt-dlp contacts the website named in
  the URL and may contact related API, authentication, image, advertising, or
  content-delivery domains selected by that provider. These services receive
  normal network information such as your IP address and request headers and
  are governed by their own privacy policies.
- **Login cookies:** if cookies are configured and used for a request, yt-dlp
  sends the applicable cookies to the relevant provider domains as part of that
  request. Cookies are not sent to the DBase project or uploaded to a
  project-operated server.
- **GitHub:** non-F-Droid builds check the public DBase GitHub Releases API for
  App updates. The App can also ask yt-dlp to check for and install an engine
  update; that process contacts the update sources used by yt-dlp, normally
  GitHub. These requests disclose normal connection information such as your IP
  address and user agent to GitHub. Submitted media URLs, download history, and
  imported cookies are not included in the App update request.
- **Links you open:** the App contains links to project documentation, support,
  browser-extension listings, and third-party policies. Opening a link uses
  your browser, and the destination's privacy policy applies.

The App does not sell personal information and does not transmit App usage data
for analytics, advertising, or profiling.

## Diagnostics and logs

Operational errors are displayed locally. The App redacts cookies, tokens,
authentication values, and URLs from backend errors exposed through its UI
where applicable. Its copyable diagnostic report intentionally excludes source
URLs, direct media URLs, cookies, tokens, headers, and file paths.

No diagnostic information is uploaded automatically. If you choose to file a
GitHub issue or otherwise send a diagnostic report, the information you submit
is processed by the service you use and may become public. Never include real
cookies, tokens, private URLs, or sensitive media in a public report.

## Retention and deletion

Local data remains until you remove it, clear the App's data, or uninstall the
App, subject to platform behavior:

- Delete one history entry from its item menu, or use **Clear history** to
  remove all queue/history records stored by the App. Removing a history record
  does not delete the downloaded media file.
- Use **Clear cookies** in Settings to delete imported cookies and their expiry
  marker.
- Delete downloaded or edited media through the App where that action is
  available, or through your operating system's file manager or media tools.
- Clear the App's storage or uninstall it to remove App-managed preferences and
  private files. Files saved to shared storage, Downloads, MediaStore, or a
  user-selected folder may remain and must be deleted separately.

The DBase project cannot retrieve or delete this local data remotely because it
does not operate an account or synchronization service for the App.

## Security and third-party services

Reasonable safeguards are used for App-managed data, including Android
Keystore encryption for imported cookies on Android and redaction of sensitive
values from user-facing errors. No storage or network transmission can be
guaranteed to be completely secure. Keep your device and cookies secure, use
cookies only when necessary, and remove them when they are no longer needed.

Media providers, GitHub, browser-extension stores, and other destinations you
choose to use are independent third parties. Their handling of information is
governed by their own terms and privacy policies.

## Children

The App is not directed to children and the DBase project does not knowingly
collect personal information from children through the App. Because the App
does not operate user accounts or a backend, it does not receive age information
from App users.

## Changes to this policy

This policy may be updated when the App's data handling changes. The revision
date at the top identifies the latest version. The version maintained in the
App's official GitHub repository is the canonical privacy policy for the App.

## Related website policy and contact

The broader [DBase.in.rs privacy notice](https://dbase.in.rs/privacy) applies to
the DBase website and other services described there. It may describe accounts,
analytics, advertising, or other processing that is not present in DBase Video
& Music Downloader. For the App, this App-specific policy controls if the two
notices differ.

For privacy questions about the App, contact
`velimir (at) majstorov (dot) info`. For non-sensitive technical questions, use the
[project issue tracker](https://github.com/DBase-In-Rs/Downloader/issues).
