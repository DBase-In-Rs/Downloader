# Privacy

DBase Video & Music Downloader is planned as a local app. It should not require
a project-operated backend service for normal downloading.

## Data The App May Store

The app may store:

- download history;
- media title, thumbnail, source URL, selected format, output location, and
  status;
- temporary download and conversion files;
- user-imported cookies when the user explicitly enables cookie support;
- app settings.

## Cookies

YouTube cookies are sensitive account credentials.

Planned rules:

- cookies are optional;
- cookies are imported or captured only after explicit user action;
- cookies are stored encrypted where the platform supports secure local storage;
- cookies are passed only to yt-dlp for requested downloads;
- cookies are never uploaded to a project server;
- cookies are never printed in logs;
- users can clear cookies from Settings.

The supported baseline is `cookies.txt` import through the system file picker.
Assisted in-app login is an investigation item and may be removed if it is
unreliable or not compliant.

## Network Requests

The app, yt-dlp, FFmpeg, and target media providers may make network requests
needed to retrieve metadata and media. Provider behavior is outside this
project's control.

## Analytics

No analytics, tracking SDK, or advertising SDK is planned by default.

## User Control

Planned controls:

- delete download history;
- delete imported cookies;
- cancel active downloads;
- remove temporary files after failed jobs.
