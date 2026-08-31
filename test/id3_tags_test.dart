import 'dart:typed_data';

import 'package:dbase_downloader/src/services/id3_tags.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake MPEG audio payload (frame sync + arbitrary data).
Uint8List fakeAudio() {
  return Uint8List.fromList([0xFF, 0xFB, 0x90, 0x00, 1, 2, 3, 4, 5, 6, 7, 8]);
}

bool containsAscii(Uint8List bytes, String needle) {
  final pattern = needle.codeUnits;
  outer:
  for (var i = 0; i <= bytes.length - pattern.length; i++) {
    for (var j = 0; j < pattern.length; j++) {
      if (bytes[i + j] != pattern[j]) {
        continue outer;
      }
    }
    return true;
  }
  return false;
}

void main() {
  test('detects MP3 streams with and without an existing tag', () {
    expect(looksLikeMp3(fakeAudio()), isTrue);
    expect(looksLikeMp3(Uint8List.fromList('ID3x'.codeUnits)), isTrue);
    expect(looksLikeMp3(Uint8List.fromList([0, 0, 0, 0])), isFalse);
    expect(looksLikeMp3(Uint8List(2)), isFalse);
  });

  test('writes tags to a file without an existing tag', () {
    final audio = fakeAudio();
    final tagged = applyId3Tags(
      audio,
      const AudioTags(title: 'Naslov Č', artist: 'Izvođač', album: 'Album'),
    );

    final read = readId3Tags(tagged);
    expect(read.title, 'Naslov Č');
    expect(read.artist, 'Izvođač');
    expect(read.album, 'Album');
    expect(read.comment, isNull);

    // The audio payload survives at the end of the file.
    final tail = Uint8List.sublistView(
      tagged,
      tagged.length - audio.length,
    );
    expect(tail, audio);
  });

  test('edits merge with existing values and empty strings remove', () {
    var tagged = applyId3Tags(
      fakeAudio(),
      const AudioTags(title: 'Old title', artist: 'Old artist'),
    );

    tagged = applyId3Tags(
      tagged,
      const AudioTags(title: 'New title', comment: 'Note'),
    );
    var read = readId3Tags(tagged);
    expect(read.title, 'New title');
    expect(read.artist, 'Old artist');
    expect(read.comment, 'Note');

    tagged = applyId3Tags(tagged, const AudioTags(artist: ''));
    read = readId3Tags(tagged);
    expect(read.title, 'New title');
    expect(read.artist, isNull);
  });

  test('unrelated frames survive a tag edit', () {
    // Hand-built ID3v2.3 tag holding one TCON (genre) frame.
    final content = <int>[0, ...'Rock'.codeUnits];
    final frame = <int>[
      ...'TCON'.codeUnits,
      0, 0, 0, content.length,
      0, 0,
      ...content,
    ];
    final tag = <int>[
      ...'ID3'.codeUnits,
      3, 0, 0,
      0, 0, (frame.length >> 7) & 0x7F, frame.length & 0x7F,
      ...frame,
    ];
    final file = Uint8List.fromList([...tag, ...fakeAudio()]);

    final tagged = applyId3Tags(file, const AudioTags(title: 'Titled'));

    expect(containsAscii(tagged, 'TCON'), isTrue);
    expect(containsAscii(tagged, 'Rock'), isTrue);
    expect(readId3Tags(tagged).title, 'Titled');
  });
}
