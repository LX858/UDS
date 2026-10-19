export type EventCardConfig = {
	cardKey: string
	label: string
	description: string
	eventTime: string
	imageUrl: string
	backgroundUrl: string
	rulesContent: string
	action: string
	enabled: boolean
	showJoinButton: boolean
	joinExport: string
	sortOrder: number
}

export const EMPTY_EVENT_CARD = (): EventCardConfig => ({
	cardKey: '',
	label: '',
	description: '',
	eventTime: '',
	imageUrl: '',
	backgroundUrl: '',
	rulesContent: '',
	action: '',
	enabled: true,
	showJoinButton: false,
	joinExport: '',
	sortOrder: 0,
})
