enum MediaProviderTier { supported, priority, planned, research, generic }

class MediaProviderInfo {
  const MediaProviderInfo({
    required this.id,
    required this.displayName,
    required this.tier,
    required this.domains,
    required this.extractorNames,
    this.audioFirst = false,
    this.playlists = false,
    this.cookiesOftenNeeded = false,
  });

  final String id;
  final String displayName;
  final MediaProviderTier tier;
  final List<String> domains;
  final List<String> extractorNames;
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
    id: 'youtube',
    displayName: 'YouTube',
    tier: MediaProviderTier.supported,
    domains: ['youtube.com', 'youtu.be', 'youtube-nocookie.com'],
    extractorNames: ['youtube'],
    playlists: true,
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'dailymotion',
    displayName: 'Dailymotion',
    tier: MediaProviderTier.priority,
    domains: ['dailymotion.com', 'dai.ly'],
    extractorNames: ['dailymotion'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'vimeo',
    displayName: 'Vimeo',
    tier: MediaProviderTier.priority,
    domains: ['vimeo.com', 'player.vimeo.com'],
    extractorNames: ['vimeo'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'soundcloud',
    displayName: 'SoundCloud',
    tier: MediaProviderTier.priority,
    domains: ['soundcloud.com', 'snd.sc'],
    extractorNames: ['soundcloud'],
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
    extractorNames: ['instagram'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'facebook',
    displayName: 'Facebook',
    tier: MediaProviderTier.priority,
    domains: ['facebook.com', 'fb.watch'],
    extractorNames: ['facebook'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'twitter',
    displayName: 'Twitter/X',
    tier: MediaProviderTier.priority,
    domains: ['x.com', 'twitter.com'],
    extractorNames: ['twitter', 'x'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'pinterest',
    displayName: 'Pinterest',
    tier: MediaProviderTier.planned,
    domains: ['pinterest.com', 'pin.it'],
    extractorNames: ['pinterest'],
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
    extractorNames: ['twitch'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'rumble',
    displayName: 'Rumble',
    tier: MediaProviderTier.planned,
    domains: ['rumble.com'],
    extractorNames: ['rumble'],
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
    extractorNames: ['audius'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'internet_archive',
    displayName: 'Internet Archive',
    tier: MediaProviderTier.planned,
    domains: ['archive.org'],
    extractorNames: ['archiveorg'],
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
    id: 'odysee',
    displayName: 'Odysee/LBRY',
    tier: MediaProviderTier.planned,
    domains: ['odysee.com', 'lbry.tv'],
    extractorNames: ['odysee', 'lbry'],
  ),
];

MediaProviderInfo resolveMediaProvider({String? url, String? extractor}) {
  final byExtractor = mediaProviderForExtractor(extractor);
  if (byExtractor.id != unknownMediaProvider.id) {
    return byExtractor;
  }

  return mediaProviderForUrl(url);
}

MediaProviderInfo mediaProviderForUrl(String? url) {
  final uri = Uri.tryParse(url ?? '');
  final host = uri?.host.toLowerCase();
  if (host == null || host.isEmpty) {
    return unknownMediaProvider;
  }

  for (final provider in mediaProviderCatalog) {
    if (provider.domains.any((domain) => _hostMatches(host, domain))) {
      return provider;
    }
  }

  return unknownMediaProvider;
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
  return (extractor ?? '').trim().toLowerCase();
}
