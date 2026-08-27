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
      'https://wallhaven.cc/w/abc123': 'wallpaper',
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
      'ESPNArticle': 'espn',
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
