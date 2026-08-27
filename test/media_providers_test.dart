import 'package:dbase_downloader/src/models/media_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects priority providers from URLs', () {
    final cases = {
      'https://www.youtube.com/shorts/abc123?si=shared': 'youtube_shorts',
      'https://www.youtube.com/watch?v=abc123': 'youtube',
      'https://youtu.be/abc123': 'youtube',
      'https://www.dailymotion.com/video/x123': 'dailymotion',
      'https://dai.ly/x123': 'dailymotion',
      'https://vimeo.com/123456': 'vimeo',
      'https://player.vimeo.com/video/123456': 'vimeo',
      'https://soundcloud.com/artist/track': 'soundcloud',
      'https://snd.sc/example': 'soundcloud',
      'https://www.tiktok.com/@artist/video/123': 'tiktok',
      'https://vm.tiktok.com/abc123': 'tiktok',
      'https://www.instagram.com/reel/abc123/': 'instagram',
      'https://m.facebook.com/watch/?v=123': 'facebook',
      'https://fb.watch/abc123/': 'facebook',
      'https://x.com/user/status/123': 'twitter',
      'https://mobile.twitter.com/user/status/123': 'twitter',
    };

    for (final entry in cases.entries) {
      expect(mediaProviderForUrl(entry.key).id, entry.value, reason: entry.key);
    }
  });

  test('detects planned and research providers from URLs', () {
    final cases = {
      'https://www.pinterest.com/pin/123/': 'pinterest',
      'https://pin.it/abc123': 'pinterest',
      'https://www.reddit.com/r/videos/comments/abc/title/': 'reddit',
      'https://redd.it/abc123': 'reddit',
      'https://www.twitch.tv/videos/123': 'twitch',
      'https://rumble.com/v123-title.html': 'rumble',
      'https://artist.bandcamp.com/track/song': 'bandcamp',
      'https://audiomack.com/artist/song/title': 'audiomack',
      'https://www.mixcloud.com/user/show/': 'mixcloud',
      'https://audius.co/artist/track': 'audius',
      'https://archive.org/details/example': 'internet_archive',
      'https://www.linkedin.com/posts/example': 'linkedin',
      'https://example.tumblr.com/post/123/title': 'tumblr',
      'https://vk.com/video-1_2': 'vk',
      'https://live.vkplay.ru/example': 'vk_play',
      'https://odysee.com/@channel/video:1': 'odysee',
      'https://streamable.com/abc123': 'streamable',
      'https://imgur.com/a/abc123': 'imgur',
      'https://flic.kr/p/abc123': 'flickr',
      'https://www.bitchute.com/video/abc123/': 'bitchute',
      'https://joinpeertube.org/videos/watch/abc123': 'peertube',
      'https://www.ted.com/talks/example': 'ted',
      'https://www.bilibili.com/video/BV123': 'bilibili',
      'https://nico.ms/sm123': 'niconico',
      'https://coub.com/view/abc123': 'coub',
      'https://voca.ro/abc123': 'vocaroo',
      'https://hearthis.at/user/track/': 'hearthisat',
      'https://podcasts.apple.com/us/podcast/example/id123': 'apple_podcasts',
      'https://podbay.fm/p/example/e/123': 'podbay',
      'https://www.podchaser.com/podcasts/example': 'podchaser',
      'https://play.acast.com/s/example': 'acast',
      'https://www.bbc.co.uk/programmes/example': 'bbc',
      'https://www.cnn.com/videos/example': 'cnn',
      'https://video.pbs.org/video/example/': 'pbs',
      'https://www.espn.com/video/clip/_/id/123': 'espn',
      'https://example.substack.com/p/post': 'substack',
      'https://bsky.app/profile/user/post/123': 'bluesky',
      'https://truthsocial.com/@user/posts/123': 'truth_social',
      'https://rutube.ru/video/abc123/': 'rutube',
      'https://kick.com/channel/videos/abc': 'kick',
      'https://n1info.rs/vesti/example/': 'n1info',
      'https://drive.google.com/file/d/abc123/view': 'google_drive',
      'https://www.dropbox.com/s/abc/video.mp4': 'dropbox',
      'https://t.me/channel/123': 'telegram',
      'https://www.patreon.com/posts/example-123': 'patreon',
      'https://9gag.com/gag/abc123': 'ninegag',
      'https://www.loom.com/share/abc123': 'loom',
      'https://us02web.zoom.us/rec/share/abc': 'zoom',
      'https://www.douyin.com/video/123': 'douyin',
      'https://weibo.com/tv/show/123': 'weibo',
      'https://www.redgifs.com/watch/abc': 'redgifs',
      'https://www.jamendo.com/track/123/title': 'jamendo',
      'https://www.iheart.com/podcast/example-123/': 'iheart',
      'https://www.spreaker.com/episode/123': 'spreaker',
      'https://www.mlb.com/video/example': 'mlb',
      'https://www.aljazeera.com/program/example': 'aljazeera',
      'https://www.arte.tv/en/videos/12345/example/': 'arte',
      'https://ok.ru/video/123456': 'odnoklassniki',
      'https://boosty.to/creator/posts/abc': 'boosty',
      'https://dzen.ru/video/watch/abc123': 'dzen',
      'https://www.newgrounds.com/portal/view/123': 'newgrounds',
      'https://nebula.tv/videos/example': 'nebula',
      'https://www.floatplane.com/post/abc': 'floatplane',
      'https://www.vevo.com/watch/artist/song/US123': 'vevo',
      'https://www.dailywire.com/episode/example': 'dailywire',
      'https://example.mave.digital/ep-1': 'mave',
      'https://365.rtvslo.si/arhiv/example/123': 'rtvslo',
      'https://hrti.hrt.hr/video/show/123': 'hrt',
      'https://www.raiplay.it/video/2024/example.html': 'rai',
      'https://www.ardmediathek.de/video/example': 'ard',
      'https://www.ceskatelevize.cz/porady/example/': 'ceska_televize',
      'https://www.rtve.es/play/videos/example/': 'rtve',
      'https://www.svtplay.se/video/example': 'svt',
      'https://tv.nrk.no/serie/example': 'nrk',
      'https://vod.tvp.pl/video/example,123': 'tvp',
      'https://mediaklikk.hu/video/example/': 'mediaklikk',
      'https://puhutv.com/example-izle': 'puhutv',
      'https://www.france.tv/example/video.html': 'francetv',
      'https://abcnews.go.com/Video/example-123': 'abcnews',
      'https://www.cbsnews.com/video/example/': 'cbsnews',
      'https://video.foxnews.com/v/123': 'foxnews',
      'https://www.nbcnews.com/video/example-123': 'nbcnews',
      'https://www.gamespot.com/videos/example/': 'gamespot',
      'https://www.ign.com/videos/example': 'ign',
      'https://example.libsyn.com/episode': 'libsyn',
      'https://www.nhl.com/video/example-123': 'nhl',
      'https://picarto.tv/streamer': 'picarto',
      'https://roosterteeth.com/watch/example': 'roosterteeth',
      'https://www.dumpert.nl/item/123_abc': 'dumpert',
      'https://store.steampowered.com/app/123/Example/': 'steam',
      'https://play.vidyard.com/abc123': 'vidyard',
      'https://www.skynews.com.au/video/example': 'skynews_au',
      'https://banbye.com/watch/v_abc123': 'banbye',
      'https://v.youku.com/v_show/id_abc.html': 'youku',
      'https://watch.cloudflarestream.com/abc123': 'cloudflare_stream',
      'https://content.jwplatform.com/players/abc-def.html': 'jwplatform',
      'https://cdnapisec.kaltura.com/p/123/sp/123/embedIframeJs/uiconf_id/1':
          'kaltura',
      'https://fast.wistia.net/embed/iframe/abc123': 'wistia',
      'https://players.brightcove.net/123/default_default/index.html':
          'brightcove',
      'https://www.snapchat.com/spotlight/abc123': 'snapchat',
      'https://www.threads.net/@user/post/123': 'threads',
      'https://www.buzzvideo.com/a123': 'buzzvideo',
      'https://tubidy.mobi/watch/example': 'tubidy',
    };

    for (final entry in cases.entries) {
      expect(mediaProviderForUrl(entry.key).id, entry.value, reason: entry.key);
    }
  });

  test('detects providers from extractor aliases', () {
    final cases = {
      'YoutubeTab': 'youtube',
      'youtube:playlist': 'youtube',
      'DailymotionPlaylist': 'dailymotion',
      'vimeo:review': 'vimeo',
      'SoundcloudEmbed': 'soundcloud',
      'InstagramIOS': 'instagram',
      'facebook:reel': 'facebook',
      'FacebookPluginsVideo': 'facebook',
      'TwitterAmplify': 'twitter',
      'PinterestCollection': 'pinterest',
      'TwitchVod': 'twitch',
      'RumbleEmbed': 'rumble',
      'AudiusPlaylist': 'audius',
      'VKPlayLive': 'vk_play',
      'BitChuteChannel': 'bitchute',
      'BilibiliSpaceVideo': 'bilibili',
      'NiconicoUser': 'niconico',
      'apple:podcasts': 'apple_podcasts',
      'PodbayFMChannel': 'podbay',
      'WatchESPN': 'espn',
      'CloudflareStream': 'cloudflare_stream',
      'JWPlatform': 'jwplatform',
      'RTVCKaltura': 'kaltura',
      'WistiaPlaylist': 'wistia',
      'BrightcoveNew': 'brightcove',
      'SnapchatSpotlight': 'snapchat',
    };

    for (final entry in cases.entries) {
      expect(
        mediaProviderForExtractor(entry.key).id,
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('URL provider detection wins for more specific providers', () {
    final provider = resolveMediaProvider(
      url: 'https://www.youtube.com/shorts/abc123',
      extractor: 'Youtube',
    );

    expect(provider.id, 'youtube_shorts');
  });

  test('normalizes tracking parameters only for known providers', () {
    expect(
      normalizeMediaUrl(
        'https://www.tiktok.com/@artist/video/123?is_from_webapp=1&sender_device=pc&utm_source=copy',
      ),
      'https://www.tiktok.com/@artist/video/123',
    );
    expect(
      normalizeMediaUrl(
        'https://www.youtube.com/watch?v=abc123&si=share&utm_campaign=x&t=42',
      ),
      'https://www.youtube.com/watch?v=abc123&t=42',
    );
    expect(
      normalizeMediaUrl('https://example.com/watch?token=abc&utm_source=x'),
      'https://example.com/watch?token=abc&utm_source=x',
    );
  });

  test('dynamic provider naming covers every yt-dlp site', () {
    // Uncataloged extractor: named after the extractor.
    final byExtractor = dynamicMediaProvider(
      url: 'https://example-niche-site.com/watch/1',
      extractor: 'veoh',
    );
    expect(byExtractor.id, 'ext:veoh');
    expect(byExtractor.displayName, 'Veoh');

    // Extractor variants collapse to the base name; casing is kept.
    expect(
      dynamicMediaProvider(extractor: 'NicheSite:playlist').displayName,
      'NicheSite',
    );

    // No extractor: named after the host.
    final byHost = dynamicMediaProvider(url: 'https://www.example.com/v/1');
    expect(byHost.id, 'site:example.com');
    expect(byHost.displayName, 'example.com');

    // The generic extractor never masks the host name.
    expect(
      dynamicMediaProvider(
        url: 'https://www.example.com/v/1',
        extractor: 'generic',
      ).id,
      'site:example.com',
    );

    // Cataloged providers always win.
    expect(
      dynamicMediaProvider(
        url: 'https://youtu.be/abc',
        extractor: 'youtube',
      ).id,
      'youtube',
    );
  });

  test('stored dynamic identities survive restore', () {
    final restored = storedMediaProvider(
      providerId: 'ext:nichesite',
      providerName: 'NicheSite',
      url: 'https://niche.example/v/1',
    );
    expect(restored.displayName, 'NicheSite');
    expect(restored.id, 'ext:nichesite');

    // Catalog ids resolve back to the full catalog entry.
    expect(storedMediaProvider(providerId: 'tiktok').displayName, 'TikTok');
  });

  test(
    'catalog separates supported, priority, planned, and research tiers',
    () {
      expect(mediaProvidersByTier(MediaProviderTier.supported), isNotEmpty);
      expect(mediaProvidersByTier(MediaProviderTier.priority), isNotEmpty);
      expect(mediaProvidersByTier(MediaProviderTier.planned), isNotEmpty);
      expect(mediaProvidersByTier(MediaProviderTier.research), isNotEmpty);
      expect(
        mediaProvidersForPublicList().map((provider) => provider.id),
        isNot(contains(unknownMediaProvider.id)),
      );
    },
  );
}
