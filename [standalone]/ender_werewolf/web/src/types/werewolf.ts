export interface Player {
	id: number | string
	identifier: string
	source: number
	name: string
	job: {
		name: string
		label: string
		grade: number
		grade_label: string
	}
}

export type GamePhase = 'lobby' | 'night' | 'day' | 'voting' | 'ended'
export type NightPhase = 'werewolf' | 'witch' | 'doctor' | 'seer' | null
export type ActionType = 'werewolf' | 'witch' | 'doctor' | 'seer' | 'vote' | 'hunter' | null

export interface GamePlayer {
	source: number
	name: string
	alive: boolean
	ready: boolean
	disconnected?: boolean
	hasVoted: boolean
	hasActed: boolean
	role?: string
	isMe?: boolean
}

export interface GameLog {
	text: string
	time: number
}

export interface InvestigateResult {
	target: number
	targetName: string
	result: string
	isWerewolf: boolean
}

export interface WitchPotions {
	save: boolean
	poison: boolean
}

export interface RoomState {
	id: string
	host: number
	lobbySlot?: number
	lobbyLabel?: string
	state: GamePhase
	nightPhase: NightPhase
	round: number
	players: GamePlayer[]
	logs: GameLog[]
	winner: 'werewolf' | 'villager' | null
	timer: number
	canAct: boolean
	actionType: ActionType
	myRole: string | null
	myAlive: boolean
	werewolfPartners?: { source: number; name: string }[]
	investigateResult?: InvestigateResult
	witchPotions?: WitchPotions
	werewolfTarget?: number | null
	pendingHunter: boolean
	playerCount: number
	minPlayers: number
	maxPlayers: number
	maxLobbies?: number
}

export interface RoleInfo {
	label: string
	team: string
	description: string
	color: string
	icon: string
}

export const ROLE_INFO: Record<string, RoleInfo> = {
	werewolf: {
		label: 'Ma Sói',
		team: 'werewolf',
		description: 'Ban đêm chọn một người để giết.',
		color: '#ef4444',
		icon: 'wolf'
	},
	villager: {
		label: 'Dân Làng',
		team: 'villager',
		description: 'Ban ngày thảo luận và bỏ phiếu.',
		color: '#22c55e',
		icon: 'user'
	},
	seer: {
		label: 'Tiên Tri',
		team: 'villager',
		description: 'Ban đêm kiểm tra một người.',
		color: '#a855f7',
		icon: 'eye'
	},
	doctor: {
		label: 'Bác Sĩ',
		team: 'villager',
		description: 'Ban đêm bảo vệ một người.',
		color: '#3b82f6',
		icon: 'heart'
	},
	witch: {
		label: 'Phù Thủy',
		team: 'villager',
		description: 'Có lọ cứu và lọ độc.',
		color: '#ec4899',
		icon: 'flask'
	},
	hunter: {
		label: 'Thợ Săn',
		team: 'villager',
		description: 'Bị loại có thể bắn một người.',
		color: '#f97316',
		icon: 'crosshair'
	}
}

export const PHASE_LABELS: Record<GamePhase, string> = {
	lobby: 'Phòng chờ',
	night: 'Ban đêm',
	day: 'Ban ngày',
	voting: 'Bỏ phiếu',
	ended: 'Kết thúc'
}

export const NIGHT_PHASE_LABELS: Record<string, string> = {
	werewolf: 'Ma Sói',
	witch: 'Phù Thủy',
	doctor: 'Bác Sĩ',
	seer: 'Tiên Tri'
}
