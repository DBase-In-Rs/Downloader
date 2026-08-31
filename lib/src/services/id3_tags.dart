/// Pure-Dart ID3v2 reader/writer for MP3 files, kept dependency-free so
/// F-Droid builds need no prebuilt native libraries.
///
/// Writing produces an ID3v2.3 tag. Frames from an existing v2.3/v2.4 tag
/// that are not being edited (embedded cover art in particular) are carried
/// over; tags with unsynchronisation or extended headers are replaced whole.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Editable metadata of an audio file. Null fields are left untouched when
/// writing; empty strings remove the frame.
class AudioTags {
  const AudioTags({this.title, this.artist, this.album, this.comment});

  final String? title;
  final String? artist;
  final String? album;
  final String? comment;
}

const _editedFrameIds = {'TIT2', 'TPE1', 'TALB', 'COMM'};

/// Reads title/artist/album/comment from an ID3v2 tag, when present.
AudioTags readId3Tags(Uint8List bytes) {
  final tag = _parseTag(bytes);
  if (tag == null) {
    return const AudioTags();
  }

  String? text(String id) {
    final frame = tag.frames.where((frame) => frame.id == id).firstOrNull;
    return frame == null ? null : _decodeTextFrame(frame.content);
  }

  String? comment() {
    final frame = tag.frames.where((frame) => frame.id == 'COMM').firstOrNull;
    return frame == null ? null : _decodeCommentFrame(frame.content);
  }

  return AudioTags(
    title: text('TIT2'),
    artist: text('TPE1'),
    album: text('TALB'),
    comment: comment(),
  );
}

/// Returns a copy of [bytes] with [tags] applied as an ID3v2.3 tag. Fields
/// that are null keep their existing value; empty strings remove the frame.
Uint8List applyId3Tags(Uint8List bytes, AudioTags tags) {
  final existing = _parseTag(bytes);
  final audioStart = existing?.totalLength ?? 0;
  final current = readId3Tags(bytes);

  String? merged(String? edited, String? present) {
    final value = edited ?? present;
    return (value == null || value.isEmpty) ? null : value;
  }

  final title = merged(tags.title, current.title);
  final artist = merged(tags.artist, current.artist);
  final album = merged(tags.album, current.album);
  final comment = merged(tags.comment, current.comment);

  final frames = BytesBuilder();
  for (final frame in existing?.frames ?? const <_Id3Frame>[]) {
    if (_editedFrameIds.contains(frame.id)) {
      continue;
    }
    frames.add(_encodeFrame(frame.id, frame.content));
  }
  if (title != null) {
    frames.add(_encodeFrame('TIT2', _encodeTextContent(title)));
  }
  if (artist != null) {
    frames.add(_encodeFrame('TPE1', _encodeTextContent(artist)));
  }
  if (album != null) {
    frames.add(_encodeFrame('TALB', _encodeTextContent(album)));
  }
  if (comment != null) {
    frames.add(_encodeFrame('COMM', _encodeCommentContent(comment)));
  }

  final frameBytes = frames.toBytes();
  const padding = 512;
  final tagSize = frameBytes.length + padding;

  final output = BytesBuilder();
  output.add(const [0x49, 0x44, 0x33, 3, 0, 0]); // "ID3", v2.3.0, no flags.
  output.add(_syncSafe(tagSize));
  output.add(frameBytes);
  output.add(Uint8List(padding));
  output.add(Uint8List.sublistView(bytes, audioStart));
  return output.toBytes();
}

/// True when [bytes] look like an MP3 stream this writer can safely edit:
/// either an existing ID3v2 tag or an MPEG audio frame sync at the start.
bool looksLikeMp3(Uint8List bytes) {
  if (bytes.length < 4) {
    return false;
  }
  if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
    return true;
  }
  return bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0;
}

class _Id3Frame {
  const _Id3Frame(this.id, this.content);

  final String id;
  final Uint8List content;
}

class _Id3Tag {
  const _Id3Tag({required this.totalLength, required this.frames});

  /// Bytes from the start of the file occupied by the tag.
  final int totalLength;
  final List<_Id3Frame> frames;
}

_Id3Tag? _parseTag(Uint8List bytes) {
  if (bytes.length < 10 ||
      bytes[0] != 0x49 ||
      bytes[1] != 0x44 ||
      bytes[2] != 0x33) {
    return null;
  }

  final major = bytes[3];
  final flags = bytes[5];
  final size = _readSyncSafe(bytes, 6);
  final hasFooter = major == 4 && (flags & 0x10) != 0;
  final totalLength = (10 + size + (hasFooter ? 10 : 0)).clamp(
    0,
    bytes.length,
  );

  // Unsynchronised/extended/compressed layouts are rare and not worth the
  // parser complexity; the whole tag is replaced instead of merged.
  if (major < 3 || major > 4 || flags != 0) {
    return _Id3Tag(totalLength: totalLength, frames: const []);
  }

  final frames = <_Id3Frame>[];
  var pos = 10;
  final end = 10 + size;
  while (pos + 10 <= end && pos + 10 <= bytes.length) {
    if (bytes[pos] == 0) {
      break; // Padding reached.
    }

    final id = String.fromCharCodes(bytes, pos, pos + 4);
    if (!RegExp(r'^[A-Z0-9]{4}$').hasMatch(id)) {
      break;
    }

    final frameSize = major == 4
        ? _readSyncSafe(bytes, pos + 4)
        : (bytes[pos + 4] << 24) |
              (bytes[pos + 5] << 16) |
              (bytes[pos + 6] << 8) |
              bytes[pos + 7];
    final frameFlags = (bytes[pos + 8] << 8) | bytes[pos + 9];
    final contentEnd = pos + 10 + frameSize;
    if (frameSize <= 0 || contentEnd > bytes.length || contentEnd > end) {
      break;
    }

    // Frames with format flags (compression, encryption...) cannot be
    // carried over verbatim; drop them rather than corrupt the tag.
    if (frameFlags == 0) {
      frames.add(
        _Id3Frame(id, Uint8List.sublistView(bytes, pos + 10, contentEnd)),
      );
    }
    pos = contentEnd;
  }

  return _Id3Tag(totalLength: totalLength, frames: frames);
}

Uint8List _encodeFrame(String id, Uint8List content) {
  final builder = BytesBuilder();
  builder.add(id.codeUnits);
  builder.add([
    (content.length >> 24) & 0xFF,
    (content.length >> 16) & 0xFF,
    (content.length >> 8) & 0xFF,
    content.length & 0xFF,
  ]);
  builder.add(const [0, 0]);
  builder.add(content);
  return builder.toBytes();
}

/// Text frame content: UTF-16 with BOM (encoding byte 1) handles any script.
Uint8List _encodeTextContent(String text) {
  final builder = BytesBuilder();
  builder.addByte(1);
  builder.add(_utf16LeWithBom(text));
  return builder.toBytes();
}

/// COMM content: encoding, language, empty terminated descriptor, text.
Uint8List _encodeCommentContent(String text) {
  final builder = BytesBuilder();
  builder.addByte(1);
  builder.add('eng'.codeUnits);
  builder.add(const [0xFF, 0xFE, 0, 0]); // Empty UTF-16 descriptor.
  builder.add(_utf16LeWithBom(text));
  return builder.toBytes();
}

Uint8List _utf16LeWithBom(String text) {
  final units = text.codeUnits;
  final bytes = Uint8List(2 + units.length * 2);
  bytes[0] = 0xFF;
  bytes[1] = 0xFE;
  for (var i = 0; i < units.length; i++) {
    bytes[2 + i * 2] = units[i] & 0xFF;
    bytes[3 + i * 2] = (units[i] >> 8) & 0xFF;
  }
  return bytes;
}

String? _decodeTextFrame(Uint8List content) {
  if (content.isEmpty) {
    return null;
  }

  final text = _decodeTagString(content[0], content, 1, content.length);
  return text.isEmpty ? null : text;
}

String? _decodeCommentFrame(Uint8List content) {
  if (content.length < 4) {
    return null;
  }

  final encoding = content[0];
  var pos = 4; // Skip encoding + 3-byte language.
  if (encoding == 1 || encoding == 2) {
    while (pos + 1 < content.length &&
        !(content[pos] == 0 && content[pos + 1] == 0)) {
      pos += 2;
    }
    pos += 2;
  } else {
    while (pos < content.length && content[pos] != 0) {
      pos++;
    }
    pos += 1;
  }

  if (pos >= content.length) {
    return null;
  }

  final text = _decodeTagString(encoding, content, pos, content.length);
  return text.isEmpty ? null : text;
}

String _decodeTagString(int encoding, Uint8List bytes, int start, int end) {
  var from = start;
  var to = end;

  String decoded;
  switch (encoding) {
    case 1: // UTF-16 with BOM.
    case 2: // UTF-16 big-endian.
      var littleEndian = encoding == 1;
      if (to - from >= 2 && bytes[from] == 0xFF && bytes[from + 1] == 0xFE) {
        littleEndian = true;
        from += 2;
      } else if (to - from >= 2 &&
          bytes[from] == 0xFE &&
          bytes[from + 1] == 0xFF) {
        littleEndian = false;
        from += 2;
      }
      final units = <int>[];
      for (var i = from; i + 1 < to; i += 2) {
        final unit = littleEndian
            ? bytes[i] | (bytes[i + 1] << 8)
            : (bytes[i] << 8) | bytes[i + 1];
        if (unit == 0) {
          break;
        }
        units.add(unit);
      }
      decoded = String.fromCharCodes(units);
    case 3: // UTF-8.
      while (to > from && bytes[to - 1] == 0) {
        to--;
      }
      decoded = String.fromCharCodes(
        Uint8List.sublistView(bytes, from, to),
      );
      try {
        decoded = const Utf8Decoder(
          allowMalformed: true,
        ).convert(bytes, from, to);
      } catch (_) {
        // Keep the latin-1 interpretation.
      }
    default: // ISO-8859-1.
      while (to > from && bytes[to - 1] == 0) {
        to--;
      }
      decoded = String.fromCharCodes(Uint8List.sublistView(bytes, from, to));
  }

  return decoded.trim();
}

Uint8List _syncSafe(int value) {
  return Uint8List.fromList([
    (value >> 21) & 0x7F,
    (value >> 14) & 0x7F,
    (value >> 7) & 0x7F,
    value & 0x7F,
  ]);
}

int _readSyncSafe(Uint8List bytes, int offset) {
  return ((bytes[offset] & 0x7F) << 21) |
      ((bytes[offset + 1] & 0x7F) << 14) |
      ((bytes[offset + 2] & 0x7F) << 7) |
      (bytes[offset + 3] & 0x7F);
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
