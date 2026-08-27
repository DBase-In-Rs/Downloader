#!/usr/bin/env bash
# Builds the Debian package from a finished Linux release bundle.
#
#   tool/build_deb.sh <version> [bundle-dir] [output-dir]
#
# Example: tool/build_deb.sh 1.0.0-rc.2
set -euo pipefail

VERSION="${1:?usage: build_deb.sh <version> [bundle-dir] [out-dir]}"
BUNDLE="${2:-build/linux/x64/release/bundle}"
OUT="${3:-build}"
# Debian versions use ~ for pre-releases so 1.0.0~rc.2 < 1.0.0.
DEB_VERSION="${VERSION/-/\~}"
STAGE="$(mktemp -d)"
PKG="$STAGE/dbase-downloader"

mkdir -p \
  "$PKG/DEBIAN" \
  "$PKG/usr/lib/dbase-downloader" \
  "$PKG/usr/bin" \
  "$PKG/usr/share/applications" \
  "$PKG/usr/share/pixmaps" \
  "$PKG/usr/share/doc/dbase-downloader"

cp -r "$BUNDLE"/. "$PKG/usr/lib/dbase-downloader/"
ln -s ../lib/dbase-downloader/dbase_downloader "$PKG/usr/bin/dbase-downloader"
cp assets/branding/icon_tile.png "$PKG/usr/share/pixmaps/dbase-downloader.png"
cp LICENSE "$PKG/usr/share/doc/dbase-downloader/copyright"

cat > "$PKG/usr/share/applications/dbase-downloader.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DBase Video & Music Downloader
Comment=Download video and audio from yt-dlp-supported sites
Exec=dbase-downloader
Icon=dbase-downloader
Terminal=false
Categories=AudioVideo;Network;
EOF

INSTALLED_SIZE=$(du -sk "$PKG/usr" | cut -f1)
cat > "$PKG/DEBIAN/control" <<EOF
Package: dbase-downloader
Version: $DEB_VERSION
Architecture: amd64
Maintainer: DBase <velimir.majstorov@dbase.in.rs>
Installed-Size: $INSTALLED_SIZE
Depends: libgtk-3-0, libc6 (>= 2.35)
Recommends: ffmpeg, yt-dlp
Section: net
Priority: optional
Homepage: https://github.com/DBase-In-Rs/Downloader
Description: Video and music downloader for yt-dlp-supported sites
 Downloads video or audio from any site supported by yt-dlp, converts
 audio to MP3 with FFmpeg, and manages a persistent download queue.
 .
 Licensed under GPL-3.0-only; source at the homepage.
EOF

dpkg-deb --build --root-owner-group "$PKG" \
  "$OUT/dbase-downloader-v$VERSION-linux-amd64.deb"
rm -rf "$STAGE"
echo "Built $OUT/dbase-downloader-v$VERSION-linux-amd64.deb"
