import { EventCardConfig } from '../types/eventCard'

const CDN_BASE = 'https://raw.githubusercontent.com/ghtipi/cdn_bacsigaming/main/assets_UDS'

export const EVENT_CARD_CDN = {
	fallbackBackground: `${CDN_BASE}/logo.webp`,
	comingSoon: `${CDN_BASE}/bg-comming.webp`,
	backgrounds: {
		racing: `${CDN_BASE}/bg-duaxe-doc.webp`,
		thinh: `${CDN_BASE}/bg-cuopthinh-doc.webp`,
		audition: `${CDN_BASE}/bg-auditon-doc.webp`,
		warrior: `${CDN_BASE}/bg-warrior-doc.webp`,
	},
	donateBanner: `${CDN_BASE}/bg-donate-ngang.webp`,
	giftcodeBanner: `${CDN_BASE}/bg-giftcode-ngang.webp`,
} as const

export const DONATE_BANNER_ASPECT_RATIO = 2048 / 768
export const GIFTCODE_BANNER_ASPECT_RATIO = 2048 / 768
export const EVENT_CARD_ASPECT_RATIO = 485 / 1024
export const VISIBLE_EVENT_CARD_COUNT = 5

export function resolveEventCardBackground(
	card: Pick<EventCardConfig, 'cardKey' | 'backgroundUrl'>,
): string {
	const custom = card.backgroundUrl?.trim()
	if (custom) return custom

	const known =
		EVENT_CARD_CDN.backgrounds[card.cardKey as keyof typeof EVENT_CARD_CDN.backgrounds]
	return known || EVENT_CARD_CDN.fallbackBackground
}

export const FALLBACK_EVENT_CARDS: EventCardConfig[] = [
	{
		cardKey: 'racing',
		label: 'Đua xe',
		description: '',
		eventTime: '',
		imageUrl: '',
		backgroundUrl: EVENT_CARD_CDN.backgrounds.racing,
		rulesContent: 'Thể lệ sự kiện Đua xe sẽ được cập nhật tại đây.',
		action: 'openRacing',
		enabled: true,
		showJoinButton: false,
		joinExport: '',
		sortOrder: 1,
	},
	{
		cardKey: 'thinh',
		label: 'Thính',
		description: '',
		eventTime: '',
		imageUrl: '',
		backgroundUrl: EVENT_CARD_CDN.backgrounds.thinh,
		rulesContent: 'Thể lệ sự kiện Thính sẽ được cập nhật tại đây.',
		action: 'openThinh',
		enabled: true,
		showJoinButton: false,
		joinExport: '',
		sortOrder: 2,
	},
	{
		cardKey: 'audition',
		label: 'Audition',
		description: '',
		eventTime: '',
		imageUrl: '',
		backgroundUrl: EVENT_CARD_CDN.backgrounds.audition,
		rulesContent: 'Thể lệ sự kiện Audition sẽ được cập nhật tại đây.',
		action: 'openAudition',
		enabled: true,
		showJoinButton: false,
		joinExport: '',
		sortOrder: 3,
	},
	{
		cardKey: 'warrior',
		label: 'Warrior',
		description: '',
		eventTime: '',
		imageUrl: '',
		backgroundUrl: EVENT_CARD_CDN.backgrounds.warrior,
		rulesContent: 'Thể lệ sự kiện Warrior sẽ được cập nhật tại đây.',
		action: 'openWarrior',
		enabled: true,
		showJoinButton: false,
		joinExport: '',
		sortOrder: 4,
	},
	{
		cardKey: 'battlepass',
		label: 'Battle pass',
		description: '',
		eventTime: '',
		imageUrl: '',
		backgroundUrl: EVENT_CARD_CDN.fallbackBackground,
		rulesContent: 'Thể lệ Battle pass sẽ được cập nhật tại đây.',
		action: 'BattlePass',
		enabled: true,
		showJoinButton: false,
		joinExport: '',
		sortOrder: 5,
	},
]
