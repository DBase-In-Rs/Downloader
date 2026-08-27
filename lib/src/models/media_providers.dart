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
    extractorNames: ['espn', 'espncricinfo', 'watchespn'],
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
    extractorNames: ['mlb', 'mlbvideo'],
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
    id: 'odnoklassniki',
    displayName: 'OK.ru',
    tier: MediaProviderTier.planned,
    domains: ['ok.ru', 'odnoklassniki.ru'],
    extractorNames: ['odnoklassniki'],
  ),
  MediaProviderInfo(
    id: 'boosty',
    displayName: 'Boosty',
    tier: MediaProviderTier.planned,
    domains: ['boosty.to'],
    extractorNames: ['boosty'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'dzen',
    displayName: 'Dzen',
    tier: MediaProviderTier.planned,
    domains: ['dzen.ru'],
    extractorNames: ['dzen.ru', 'dzen.ru:channel'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'newgrounds',
    displayName: 'Newgrounds',
    tier: MediaProviderTier.planned,
    domains: ['newgrounds.com'],
    extractorNames: ['newgrounds', 'newgrounds:playlist', 'newgrounds:user'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'nebula',
    displayName: 'Nebula',
    tier: MediaProviderTier.planned,
    domains: ['nebula.tv', 'nebula.app'],
    extractorNames: ['nebula:video', 'nebula:media', 'nebula:channel'],
    cookiesOftenNeeded: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'floatplane',
    displayName: 'Floatplane',
    tier: MediaProviderTier.planned,
    domains: ['floatplane.com'],
    extractorNames: ['floatplane', 'floatplanechannel'],
    cookiesOftenNeeded: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'vevo',
    displayName: 'Vevo',
    tier: MediaProviderTier.planned,
    domains: ['vevo.com'],
    extractorNames: ['vevo', 'vevoplaylist'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'dailywire',
    displayName: 'Daily Wire',
    tier: MediaProviderTier.planned,
    domains: ['dailywire.com'],
    extractorNames: ['dailywire', 'dailywirepodcast'],
    cookiesOftenNeeded: true,
  ),
  MediaProviderInfo(
    id: 'mave',
    displayName: 'Mave',
    tier: MediaProviderTier.planned,
    domains: ['mave.digital'],
    extractorNames: ['mave', 'mave:channel'],
    audioFirst: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'rtvslo',
    displayName: 'RTV Slovenija',
    tier: MediaProviderTier.planned,
    domains: ['rtvslo.si', '365.rtvslo.si'],
    extractorNames: ['rtvslo.si', 'rtvslo.si:show'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'hrt',
    displayName: 'HRTi',
    tier: MediaProviderTier.planned,
    domains: ['hrti.hrt.hr'],
    extractorNames: ['hrti', 'hrtiplaylist'],
    cookiesOftenNeeded: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'rai',
    displayName: 'RaiPlay',
    tier: MediaProviderTier.planned,
    domains: ['raiplay.it', 'rai.it', 'raiplaysound.it'],
    extractorNames: ['rai', 'raiplay', 'raiplaysound'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'ard',
    displayName: 'ARD Mediathek',
    tier: MediaProviderTier.planned,
    domains: ['ardmediathek.de', 'ardaudiothek.de'],
    extractorNames: ['ardmediathek', 'ardaudiothek'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'ceska_televize',
    displayName: 'Česká televize',
    tier: MediaProviderTier.planned,
    domains: ['ceskatelevize.cz'],
    extractorNames: ['ceskatelevize'],
  ),
  MediaProviderInfo(
    id: 'rtve',
    displayName: 'RTVE',
    tier: MediaProviderTier.planned,
    domains: ['rtve.es'],
    extractorNames: ['rtve.es:alacarta', 'rtve.es:television', 'rtve.es:audio'],
  ),
  MediaProviderInfo(
    id: 'svt',
    displayName: 'SVT Play',
    tier: MediaProviderTier.planned,
    domains: ['svtplay.se', 'svt.se'],
    extractorNames: ['svt:play', 'svt:page'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'nrk',
    displayName: 'NRK',
    tier: MediaProviderTier.planned,
    domains: ['nrk.no', 'tv.nrk.no', 'radio.nrk.no'],
    extractorNames: ['nrk', 'nrktv', 'nrkplaylist', 'nrkradiopodkast'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'tvp',
    displayName: 'TVP',
    tier: MediaProviderTier.planned,
    domains: ['tvp.pl', 'vod.tvp.pl'],
    extractorNames: ['tvp', 'tvp:vod', 'tvp:stream'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'mediaklikk',
    displayName: 'MédiaKlikk',
    tier: MediaProviderTier.planned,
    domains: ['mediaklikk.hu'],
    extractorNames: ['mediaklikk'],
  ),
  MediaProviderInfo(
    id: 'puhutv',
    displayName: 'Puhutv',
    tier: MediaProviderTier.planned,
    domains: ['puhutv.com'],
    extractorNames: ['puhutv', 'puhutv:serie'],
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'francetv',
    displayName: 'France TV',
    tier: MediaProviderTier.planned,
    domains: ['france.tv', 'francetvinfo.fr'],
    extractorNames: ['francetv', 'francetv:site'],
  ),
  MediaProviderInfo(
    id: 'abcnews',
    displayName: 'ABC News',
    tier: MediaProviderTier.planned,
    domains: ['abcnews.go.com'],
    extractorNames: ['abcnews', 'abcnews:video'],
  ),
  MediaProviderInfo(
    id: 'cbsnews',
    displayName: 'CBS News',
    tier: MediaProviderTier.planned,
    domains: ['cbsnews.com'],
    extractorNames: ['cbsnews', 'cbsnews:embed', 'cbsnews:live'],
  ),
  MediaProviderInfo(
    id: 'foxnews',
    displayName: 'Fox News',
    tier: MediaProviderTier.planned,
    domains: ['foxnews.com', 'video.foxnews.com'],
    extractorNames: ['foxnews', 'foxnewsvideo'],
  ),
  MediaProviderInfo(
    id: 'nbcnews',
    displayName: 'NBC News',
    tier: MediaProviderTier.planned,
    domains: ['nbcnews.com'],
    extractorNames: ['nbcnews'],
  ),
  MediaProviderInfo(
    id: 'gamespot',
    displayName: 'GameSpot',
    tier: MediaProviderTier.planned,
    domains: ['gamespot.com'],
    extractorNames: ['gamespot'],
  ),
  MediaProviderInfo(
    id: 'ign',
    displayName: 'IGN',
    tier: MediaProviderTier.planned,
    domains: ['ign.com'],
    extractorNames: ['ign.com', 'ignvideo'],
  ),
  MediaProviderInfo(
    id: 'libsyn',
    displayName: 'Libsyn',
    tier: MediaProviderTier.planned,
    domains: ['libsyn.com'],
    extractorNames: ['libsyn'],
    audioFirst: true,
  ),
  MediaProviderInfo(
    id: 'nhl',
    displayName: 'NHL',
    tier: MediaProviderTier.planned,
    domains: ['nhl.com'],
    extractorNames: ['nhl.com'],
  ),
  MediaProviderInfo(
    id: 'picarto',
    displayName: 'Picarto',
    tier: MediaProviderTier.planned,
    domains: ['picarto.tv'],
    extractorNames: ['picarto', 'picarto:vod'],
  ),
  MediaProviderInfo(
    id: 'roosterteeth',
    displayName: 'Rooster Teeth',
    tier: MediaProviderTier.planned,
    domains: ['roosterteeth.com'],
    extractorNames: ['roosterteeth', 'roosterteethseries'],
    cookiesOftenNeeded: true,
    playlists: true,
  ),
  MediaProviderInfo(
    id: 'dumpert',
    displayName: 'Dumpert',
    tier: MediaProviderTier.planned,
    domains: ['dumpert.nl'],
    extractorNames: ['dumpert'],
  ),
  MediaProviderInfo(
    id: 'steam',
    displayName: 'Steam',
    tier: MediaProviderTier.planned,
    domains: ['store.steampowered.com', 'steamcommunity.com'],
    extractorNames: ['steam', 'steamcommunity', 'steamcommunitybroadcast'],
  ),
  MediaProviderInfo(
    id: 'vidyard',
    displayName: 'Vidyard',
    tier: MediaProviderTier.planned,
    domains: ['vidyard.com', 'play.vidyard.com'],
    extractorNames: ['vidyard'],
  ),
  MediaProviderInfo(
    id: 'skynews_au',
    displayName: 'Sky News Australia',
    tier: MediaProviderTier.planned,
    domains: ['skynews.com.au'],
    extractorNames: ['skynewsau'],
  ),
  MediaProviderInfo(
    id: 'banbye',
    displayName: 'BanBye',
    tier: MediaProviderTier.planned,
    domains: ['banbye.com'],
    extractorNames: ['banbye', 'banbyechannel'],
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
];

MediaProviderInfo resolveMediaProvider({String? url, String? extractor}) {
  final byUrl = mediaProviderForUrl(url);
  if (byUrl.id != unknownMediaProvider.id) {
    return byUrl;
  }

  return mediaProviderForExtractor(extractor);
}

/// Resolves a provider identity for ANY yt-dlp-supported site. Cataloged
/// providers win; everything else gets a dynamic identity named after the
/// yt-dlp extractor (or the URL host), so all ~1750 extractors show a real
/// name and group correctly in history without a catalog entry.
MediaProviderInfo dynamicMediaProvider({String? url, String? extractor}) {
  final cataloged = resolveMediaProvider(url: url, extractor: extractor);
  if (cataloged.id != unknownMediaProvider.id) {
    return cataloged;
  }

  final extractorName = _dynamicExtractorName(extractor);
  if (extractorName != null) {
    return MediaProviderInfo(
      id: 'ext:${_normalizeExtractor(extractorName)}',
      displayName: extractorName,
      tier: MediaProviderTier.generic,
      domains: const [],
      extractorNames: const [],
    );
  }

  final host = Uri.tryParse(url ?? '')?.host.toLowerCase() ?? '';
  if (host.isNotEmpty) {
    final trimmed = host.startsWith('www.') ? host.substring(4) : host;
    return MediaProviderInfo(
      id: 'site:$trimmed',
      displayName: trimmed,
      tier: MediaProviderTier.generic,
      domains: const [],
      extractorNames: const [],
    );
  }

  return unknownMediaProvider;
}

/// Rebuilds the provider identity persisted on a queue/history item,
/// keeping dynamic (non-catalog) names intact across restarts.
MediaProviderInfo storedMediaProvider({
  String? providerId,
  String? providerName,
  String? url,
}) {
  if (providerId != null && providerId.isNotEmpty) {
    final cataloged = mediaProviderById(providerId);
    if (cataloged.id != unknownMediaProvider.id) {
      return cataloged;
    }

    return MediaProviderInfo(
      id: providerId,
      displayName: providerName?.isNotEmpty == true ? providerName! : providerId,
      tier: MediaProviderTier.generic,
      domains: const [],
      extractorNames: const [],
    );
  }

  return dynamicMediaProvider(url: url);
}

String? _dynamicExtractorName(String? extractor) {
  final raw = (extractor ?? '').trim();
  if (raw.isEmpty) {
    return null;
  }

  final base = raw.split(':').first.trim();
  if (base.isEmpty || base.toLowerCase() == 'generic') {
    return null;
  }

  // "coub" reads better as "Coub"; mixed-case and dotted names stay as-is.
  if (base == base.toLowerCase() && !base.contains('.')) {
    return base[0].toUpperCase() + base.substring(1);
  }

  return base;
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
