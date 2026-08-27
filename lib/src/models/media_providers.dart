enum MediaProviderTier { supported, priority, planned, research, generic }

class MediaProviderInfo {
  const MediaProviderInfo({
    required this.id,
    required this.displayName,
    required this.tier,
    required this.domains,
    required this.extractorNames,
    this.pathPrefixes = const [],
    this.audioFirst = false,
    this.playlists = false,
    this.cookiesOftenNeeded = false,
  });

  final String id;
  final String displayName;
  final MediaProviderTier tier;
  final List<String> domains;
  final List<String> extractorNames;
  final List<String> pathPrefixes;
  final bool audioFirst;
  final bool playlists;
  final bool cookiesOftenNeeded;
}

const unknownMediaProvider = MediaProviderInfo(
  id: 'generic',
  displayName: 'Generic URL',
  tier: MediaProviderTier.generic,
  domains: [],
  extractorNames: [],
);

const mediaProviderCatalog = [
  MediaProviderInfo(
    id: 'youtube_shorts',
    displayName: 'YouTube Shorts',
    tier: MediaProviderTier.priority,
    domains: ['youtube.com'],
    extractorNames: ['youtube:shorts:pivot:audio'],
    pathPrefixes: ['/shorts/'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'youtube',
    displayName: 'YouTube',
    tier: MediaProviderTier.supported,
    domains: ['youtube.com', 'youtu.be', 'youtube-nocookie.com'],
    extractorNames: [
      'youtube',
      'youtubetab',
      'youtubeplaylist',
      'youtubechannel',
      'youtubehandle',
      'youtubeytbe',
      'youtubelivestreamembed',
    ],
    playlists: true,
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'dailymotion',
    displayName: 'Dailymotion',
    tier: MediaProviderTier.priority,
    domains: ['dailymotion.com', 'dai.ly'],
    extractorNames: ['dailymotion', 'dailymotionplaylist'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'vimeo',
    displayName: 'Vimeo',
    tier: MediaProviderTier.priority,
    domains: ['vimeo.com', 'player.vimeo.com'],
    extractorNames: ['vimeo', 'vimeoreview'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'soundcloud',
    displayName: 'SoundCloud',
    tier: MediaProviderTier.priority,
    domains: ['soundcloud.com', 'snd.sc'],
    extractorNames: ['soundcloud', 'soundcloudembed'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'tiktok',
    displayName: 'TikTok',
    tier: MediaProviderTier.priority,
    domains: ['tiktok.com', 'vm.tiktok.com', 'vt.tiktok.com'],
    extractorNames: ['tiktok'],
  ),
  MediaProviderInfo(
    id: 'instagram',
    displayName: 'Instagram',
    tier: MediaProviderTier.priority,
    domains: ['instagram.com'],
    extractorNames: ['instagram', 'instagramios'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'facebook',
    displayName: 'Facebook',
    tier: MediaProviderTier.priority,
    domains: ['facebook.com', 'fb.watch'],
    extractorNames: ['facebook', 'facebookpluginsvideo'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'twitter',
    displayName: 'Twitter/X',
    tier: MediaProviderTier.priority,
    domains: ['x.com', 'twitter.com'],
    extractorNames: ['twitter', 'twitteramplify', 'x'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'pinterest',
    displayName: 'Pinterest',
    tier: MediaProviderTier.planned,
    domains: ['pinterest.com', 'pin.it'],
    extractorNames: ['pinterest', 'pinterestcollection'],
  ),
  MediaProviderInfo(
    id: 'reddit',
    displayName: 'Reddit',
    tier: MediaProviderTier.planned,
    domains: ['reddit.com', 'redd.it'],
    extractorNames: ['reddit'],
  ),
  MediaProviderInfo(
    id: 'twitch',
    displayName: 'Twitch',
    tier: MediaProviderTier.planned,
    domains: ['twitch.tv'],
    extractorNames: ['twitch', 'twitchclips', 'twitchvod', 'twitchstream'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'rumble',
    displayName: 'Rumble',
    tier: MediaProviderTier.planned,
    domains: ['rumble.com'],
    extractorNames: ['rumble', 'rumblechannel', 'rumbleembed'],
  ),
  MediaProviderInfo(
    id: 'bandcamp',
    displayName: 'Bandcamp',
    tier: MediaProviderTier.planned,
    domains: ['bandcamp.com'],
    extractorNames: ['bandcamp'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'audiomack',
    displayName: 'Audiomack',
    tier: MediaProviderTier.planned,
    domains: ['audiomack.com'],
    extractorNames: ['audiomack'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'mixcloud',
    displayName: 'Mixcloud',
    tier: MediaProviderTier.planned,
    domains: ['mixcloud.com'],
    extractorNames: ['mixcloud'],
    audioFirst: true,
  ),
  MediaProviderInfo(
    id: 'audius',
    displayName: 'Audius',
    tier: MediaProviderTier.planned,
    domains: ['audius.co'],
    extractorNames: ['audius', 'audiusartist', 'audiusplaylist', 'audiustrack'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'internet_archive',
    displayName: 'Internet Archive',
    tier: MediaProviderTier.planned,
    domains: ['archive.org'],
    extractorNames: ['archiveorg', 'internetarchive'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'linkedin',
    displayName: 'LinkedIn',
    tier: MediaProviderTier.planned,
    domains: ['linkedin.com'],
    extractorNames: ['linkedin'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'tumblr',
    displayName: 'Tumblr',
    tier: MediaProviderTier.planned,
    domains: ['tumblr.com'],
    extractorNames: ['tumblr'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'vk',
    displayName: 'VK',
    tier: MediaProviderTier.planned,
    domains: ['vk.com', 'vkvideo.ru'],
    extractorNames: ['vk'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'vk_play',
    displayName: 'VK Play',
    tier: MediaProviderTier.planned,
    domains: ['vkplay.ru', 'live.vkplay.ru'],
    extractorNames: ['vkplay', 'vkplaylive'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'odysee',
    displayName: 'Odysee/LBRY',
    tier: MediaProviderTier.planned,
    domains: ['odysee.com', 'lbry.tv'],
    extractorNames: ['odysee', 'lbry'],
  ),
  MediaProviderInfo(
    id: 'streamable',
    displayName: 'Streamable',
    tier: MediaProviderTier.planned,
    domains: ['streamable.com'],
    extractorNames: ['streamable'],
  ),
  MediaProviderInfo(
    id: 'imgur',
    displayName: 'Imgur',
    tier: MediaProviderTier.planned,
    domains: ['imgur.com', 'i.imgur.com'],
    extractorNames: ['imgur'],
  ),
  MediaProviderInfo(
    id: 'flickr',
    displayName: 'Flickr',
    tier: MediaProviderTier.planned,
    domains: ['flickr.com', 'flic.kr'],
    extractorNames: ['flickr'],
  ),
  MediaProviderInfo(
    id: 'bitchute',
    displayName: 'BitChute',
    tier: MediaProviderTier.planned,
    domains: ['bitchute.com'],
    extractorNames: ['bitchute', 'bitchutechannel'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'peertube',
    displayName: 'PeerTube',
    tier: MediaProviderTier.planned,
    domains: ['joinpeertube.org', 'peertube.tv'],
    extractorNames: ['peertube'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'ted',
    displayName: 'TED',
    tier: MediaProviderTier.planned,
    domains: ['ted.com'],
    extractorNames: ['ted'],
  ),
  MediaProviderInfo(
    id: 'bilibili',
    displayName: 'Bilibili',
    tier: MediaProviderTier.planned,
    domains: ['bilibili.com', 'b23.tv'],
    extractorNames: [
      'bilibili',
      'bilibiliwatchlater',
      'bilibiliplaylist',
      'bilibiliaudio',
      'bilibiliaudioalbum',
      'bilibilispacevideo',
      'bilibilispaceaudio',
    ],
    playlists: true,
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'niconico',
    displayName: 'Niconico',
    tier: MediaProviderTier.planned,
    domains: ['nicovideo.jp', 'nico.ms', 'nicochannel.jp'],
    extractorNames: ['niconico', 'niconicouser', 'niconicochannelplus'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'coub',
    displayName: 'Coub',
    tier: MediaProviderTier.planned,
    domains: ['coub.com'],
    extractorNames: ['coub'],
  ),
  MediaProviderInfo(
    id: 'vocaroo',
    displayName: 'Vocaroo',
    tier: MediaProviderTier.planned,
    domains: ['vocaroo.com', 'voca.ro'],
    extractorNames: ['vocaroo'],
    audioFirst: true,
  ),
  MediaProviderInfo(
    id: 'hearthisat',
    displayName: 'HearThis.at',
    tier: MediaProviderTier.planned,
    domains: ['hearthis.at'],
    extractorNames: ['hearthisat'],
    audioFirst: true,
  ),
  MediaProviderInfo(
    id: 'apple_podcasts',
    displayName: 'Apple Podcasts',
    tier: MediaProviderTier.planned,
    domains: ['podcasts.apple.com'],
    extractorNames: ['apple:podcasts'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'podbay',
    displayName: 'Podbay',
    tier: MediaProviderTier.planned,
    domains: ['podbay.fm'],
    extractorNames: ['podbayfm', 'podbayfmchannel'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'podchaser',
    displayName: 'Podchaser',
    tier: MediaProviderTier.planned,
    domains: ['podchaser.com'],
    extractorNames: ['podchaser'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'acast',
    displayName: 'Acast',
    tier: MediaProviderTier.planned,
    domains: ['acast.com', 'play.acast.com'],
    extractorNames: ['acast', 'acastchannel'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'bbc',
    displayName: 'BBC',
    tier: MediaProviderTier.planned,
    domains: ['bbc.com', 'bbc.co.uk'],
    extractorNames: ['bbc'],
  ),
  MediaProviderInfo(
    id: 'cnn',
    displayName: 'CNN',
    tier: MediaProviderTier.planned,
    domains: ['cnn.com'],
    extractorNames: ['cnn', 'cnnindonesia'],
  ),
  MediaProviderInfo(
    id: 'pbs',
    displayName: 'PBS',
    tier: MediaProviderTier.planned,
    domains: ['pbs.org', 'video.pbs.org'],
    extractorNames: ['pbs', 'pbskids'],
  ),
  MediaProviderInfo(
    id: 'espn',
    displayName: 'ESPN',
    tier: MediaProviderTier.planned,
    domains: ['espn.com', 'espncricinfo.com'],
    extractorNames: ['espn', 'espnarticle', 'espncricinfo', 'watchespn'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'substack',
    displayName: 'Substack',
    tier: MediaProviderTier.planned,
    domains: ['substack.com'],
    extractorNames: ['substack'],
  ),
  MediaProviderInfo(
    id: 'bluesky',
    displayName: 'Bluesky',
    tier: MediaProviderTier.planned,
    domains: ['bsky.app', 'bsky.social'],
    extractorNames: ['bluesky'],
  ),
  MediaProviderInfo(
    id: 'truth_social',
    displayName: 'Truth Social',
    tier: MediaProviderTier.planned,
    domains: ['truthsocial.com'],
    extractorNames: ['truth'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'rutube',
    displayName: 'Rutube',
    tier: MediaProviderTier.planned,
    domains: ['rutube.ru'],
    extractorNames: ['rutube'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'youku',
    displayName: 'Youku',
    tier: MediaProviderTier.planned,
    domains: ['youku.com'],
    extractorNames: ['youku'],
  ),
  MediaProviderInfo(
    id: 'cloudflare_stream',
    displayName: 'Cloudflare Stream',
    tier: MediaProviderTier.planned,
    domains: ['watch.cloudflarestream.com', 'cloudflarestream.com'],
    extractorNames: ['cloudflarestream'],
  ),
  MediaProviderInfo(
    id: 'jwplatform',
    displayName: 'JW Platform',
    tier: MediaProviderTier.planned,
    domains: ['jwplatform.com', 'content.jwplatform.com'],
    extractorNames: ['jwplatform'],
  ),
  MediaProviderInfo(
    id: 'kaltura',
    displayName: 'Kaltura',
    tier: MediaProviderTier.planned,
    domains: ['kaltura.com', 'kaltura.tv'],
    extractorNames: ['kaltura', 'rtvckaltura'],
  ),
  MediaProviderInfo(
    id: 'wistia',
    displayName: 'Wistia',
    tier: MediaProviderTier.planned,
    domains: ['wistia.com', 'wistia.net'],
    extractorNames: ['wistia', 'wistiachannel', 'wistiaplaylist'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'brightcove',
    displayName: 'Brightcove',
    tier: MediaProviderTier.planned,
    domains: ['brightcove.com', 'players.brightcove.net'],
    extractorNames: ['brightcovenew', 'brightcove'],
  ),
  MediaProviderInfo(
    id: 'kick',
    displayName: 'Kick',
    tier: MediaProviderTier.planned,
    domains: ['kick.com'],
    extractorNames: ['kickvod', 'kickclips', 'kicklive'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'n1info',
    displayName: 'N1 Info',
    tier: MediaProviderTier.planned,
    domains: ['n1info.rs', 'n1info.com', 'n1info.ba', 'n1info.hr', 'n1info.me'],
    extractorNames: ['n1info:article', 'n1infoasset'],
  ),
  MediaProviderInfo(
    id: 'google_drive',
    displayName: 'Google Drive',
    tier: MediaProviderTier.planned,
    domains: ['drive.google.com'],
    extractorNames: ['googledrive', 'googledrive:folder'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'dropbox',
    displayName: 'Dropbox',
    tier: MediaProviderTier.planned,
    domains: ['dropbox.com'],
    extractorNames: ['dropbox'],
  ),
  MediaProviderInfo(
    id: 'telegram',
    displayName: 'Telegram',
    tier: MediaProviderTier.planned,
    domains: ['t.me', 'telegram.me'],
    extractorNames: ['telegram:embed'],
  ),
  MediaProviderInfo(
    id: 'patreon',
    displayName: 'Patreon',
    tier: MediaProviderTier.planned,
    domains: ['patreon.com'],
    extractorNames: ['patreon', 'patreon:campaign'],
    cookiesOftenNeeded: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'ninegag',
    displayName: '9GAG',
    tier: MediaProviderTier.planned,
    domains: ['9gag.com'],
    extractorNames: ['9gag'],
  ),
  MediaProviderInfo(
    id: 'loom',
    displayName: 'Loom',
    tier: MediaProviderTier.planned,
    domains: ['loom.com'],
    extractorNames: ['loom'],
  ),
  MediaProviderInfo(
    id: 'zoom',
    displayName: 'Zoom Recordings',
    tier: MediaProviderTier.planned,
    domains: ['zoom.us'],
    extractorNames: ['zoom'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'douyin',
    displayName: 'Douyin',
    tier: MediaProviderTier.planned,
    domains: ['douyin.com'],
    extractorNames: ['douyin'],
  ),
  MediaProviderInfo(
    id: 'weibo',
    displayName: 'Weibo',
    tier: MediaProviderTier.planned,
    domains: ['weibo.com', 'weibo.cn'],
    extractorNames: ['weibo', 'weibovideo', 'weibouser'],
  ),
  MediaProviderInfo(
    id: 'redgifs',
    displayName: 'RedGifs',
    tier: MediaProviderTier.planned,
    domains: ['redgifs.com'],
    extractorNames: ['redgifs'],
  ),
  MediaProviderInfo(
    id: 'jamendo',
    displayName: 'Jamendo',
    tier: MediaProviderTier.planned,
    domains: ['jamendo.com'],
    extractorNames: ['jamendo', 'jamendoalbum'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'iheart',
    displayName: 'iHeartRadio',
    tier: MediaProviderTier.planned,
    domains: ['iheart.com'],
    extractorNames: ['iheartradio', 'iheartradio:podcast'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'spreaker',
    displayName: 'Spreaker',
    tier: MediaProviderTier.planned,
    domains: ['spreaker.com'],
    extractorNames: ['spreaker', 'spreakershow'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'mlb',
    displayName: 'MLB',
    tier: MediaProviderTier.planned,
    domains: ['mlb.com'],
    extractorNames: ['mlb', 'mlbvideo', 'mlbarticle'],
  ),
  MediaProviderInfo(
    id: 'aljazeera',
    displayName: 'Al Jazeera',
    tier: MediaProviderTier.planned,
    domains: ['aljazeera.com'],
    extractorNames: ['aljazeera'],
  ),
  MediaProviderInfo(
    id: 'arte',
    displayName: 'ARTE',
    tier: MediaProviderTier.planned,
    domains: ['arte.tv'],
    extractorNames: ['artetv', 'artetvplaylist', 'artetvembed'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'snapchat',
    displayName: 'Snapchat Spotlight',
    tier: MediaProviderTier.research,
    domains: ['snapchat.com'],
    extractorNames: ['snapchatspotlight'],
    pathPrefixes: ['/spotlight/'],
  ),
  MediaProviderInfo(
    id: 'threads',
    displayName: 'Threads',
    tier: MediaProviderTier.research,
    domains: ['threads.net'],
    extractorNames: [],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'buzzvideo',
    displayName: 'BuzzVideo',
    tier: MediaProviderTier.research,
    domains: ['buzzvideo.com', 'topbuzz.com'],
    extractorNames: [],
  ),
  MediaProviderInfo(
    id: 'tubidy',
    displayName: 'Tubidy',
    tier: MediaProviderTier.research,
    domains: ['tubidy.com', 'tubidy.mobi'],
    extractorNames: [],
    audioFirst: true,
  ),
  MediaProviderInfo(
    id: 'wallpaper',
    displayName: 'Wallpaper/Image Site',
    tier: MediaProviderTier.research,
    domains: ['wallhaven.cc', 'wallpapers.com', 'wallpaperflare.com'],
    extractorNames: [],
  ),
];

MediaProviderInfo resolveMediaProvider({String? url, String? extractor}) {
  final byUrl = mediaProviderForUrl(url);
  if (byUrl.id != unknownMediaProvider.id) {
    return byUrl;
  }

  return mediaProviderForExtractor(extractor);
}

MediaProviderInfo mediaProviderForUrl(String? url) {
  final uri = Uri.tryParse(url ?? '');
  final host = uri?.host.toLowerCase();
  if (host == null || host.isEmpty) {
    return unknownMediaProvider;
  }

  final path = uri?.path.toLowerCase() ?? '';
  for (final provider in mediaProviderCatalog) {
    final domainMatches = provider.domains.any(
      (domain) => _hostMatches(host, domain),
    );
    if (!domainMatches) {
      continue;
    }

    if (provider.pathPrefixes.isNotEmpty &&
        !provider.pathPrefixes.any((prefix) => path.startsWith(prefix))) {
      continue;
    }

    return provider;
  }

  return unknownMediaProvider;
}

String normalizeMediaUrl(String value) {
  final trimmed = value.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.isEmpty) {
    return trimmed;
  }

  final provider = mediaProviderForUrl(trimmed);
  if (provider.id == unknownMediaProvider.id) {
    return trimmed;
  }

  final filteredQuery = <String, List<String>>{};
  uri.queryParametersAll.forEach((key, values) {
    final normalized = key.toLowerCase();
    if (normalized.startsWith('utm_') ||
        _trackingQueryParameters.contains(normalized)) {
      return;
    }

    filteredQuery[key] = values;
  });

  if (filteredQuery.length == uri.queryParametersAll.length) {
    return trimmed;
  }

  final normalized = uri.replace(queryParameters: filteredQuery).toString();
  if (filteredQuery.isEmpty) {
    return normalized.replaceFirst('?#', '#').replaceFirst(RegExp(r'\?$'), '');
  }

  return normalized;
}

List<MediaProviderInfo> mediaProvidersByTier(MediaProviderTier tier) {
  return mediaProviderCatalog
      .where((provider) => provider.tier == tier)
      .toList(growable: false);
}

List<MediaProviderInfo> mediaProvidersForPublicList() {
  return mediaProviderCatalog
      .where((provider) => provider.tier != MediaProviderTier.generic)
      .toList(growable: false);
}

MediaProviderInfo mediaProviderForExtractor(String? extractor) {
  final normalized = _normalizeExtractor(extractor);
  if (normalized.isEmpty) {
    return unknownMediaProvider;
  }

  for (final provider in mediaProviderCatalog) {
    for (final alias in provider.extractorNames) {
      final normalizedAlias = _normalizeExtractor(alias);
      if (normalized == normalizedAlias ||
          normalized.startsWith('$normalizedAlias:')) {
        return provider;
      }
    }
  }

  return unknownMediaProvider;
}

MediaProviderInfo mediaProviderById(String? id) {
  if (id == null || id.isEmpty) {
    return unknownMediaProvider;
  }

  return mediaProviderCatalog.firstWhere(
    (provider) => provider.id == id,
    orElse: () => unknownMediaProvider,
  );
}

String providerDisplayName({String? providerId, String? providerName}) {
  if (providerName != null && providerName.isNotEmpty) {
    return providerName;
  }

  return mediaProviderById(providerId).displayName;
}

bool _hostMatches(String host, String domain) {
  final normalized = domain.toLowerCase();
  return host == normalized || host.endsWith('.$normalized');
}

String _normalizeExtractor(String? extractor) {
  return (extractor ?? '').trim().toLowerCase().replaceAll(
    RegExp(r'[\s_-]+'),
    '',
  );
}

const _trackingQueryParameters = {
  '_r',
  'fbclid',
  'gclid',
  'dclid',
  'msclkid',
  'igsh',
  'igshid',
  'is_from_webapp',
  'mibextid',
  'pp',
  'refer',
  'referer_url',
  'sender_device',
  'share_app_id',
  'share_id',
  'si',
  'source',
  'spm_id_from',
  'timestamp',
  'tt_from',
  'u_code',
  'vd_source',
};
