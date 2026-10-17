import { GamePlayer, RoomState } from '@/types'

const basePlayers: GamePlayer[] = [
	{ source: 1, name: 'Ender', alive: true, ready: true, hasVoted: false, hasActed: false, isMe: true },
	{ source: 2, name: 'Player 2', alive: true, ready: true, hasVoted: false, hasActed: false },
	{ source: 3, name: 'Player 3', alive: true, ready: false, hasVoted: false, hasActed: false },
	{ source: 4, name: 'Player 4', alive: true, ready: true, hasVoted: false, hasActed: false },
	{ source: 5, name: 'Player 5', alive: true, ready: true, hasVoted: false, hasActed: false },
	{ source: 6, name: 'Player 6', alive: true, ready: true, hasVoted: false, hasActed: false },
	{ source: 7, name: 'Player 7', alive: false, ready: true, hasVoted: false, hasActed: false, role: 'villager' },
	{ source: 8, name: 'Player 8', alive: true, ready: true, hasVoted: false, hasActed: false }
]

const baseRoom = (): Omit<RoomState, 'state'> => ({
	id: 'ABC123',
	host: 1,
	nightPhase: null,
	round: 1,
	players: basePlayers.map((p) => ({ ...p })),
	logs: [
		{ text: 'Ender đã tạo phòng.', time: Date.now() / 1000 },
		{ text: 'Trò chơi bắt đầu!', time: Date.now() / 1000 },
		{ text: 'Đêm 1: Player 2 đã bị giết', time: Date.now() / 1000 },
	],
	winner: null,
	timer: 30,
	canAct: false,
	actionType: null,
	myRole: 'villager',
	myAlive: true,
	pendingHunter: false,
	playerCount: 8,
	minPlayers: 6,
	maxPlayers: 12
})

export type DebugPreset = {
	id: string
	label: string
	group: string
	visible?: boolean
	room: RoomState | null
}

export const DEBUG_PRESETS: DebugPreset[] = [
	{
		id: 'no-room',
		label: 'Chưa vào phòng',
		group: 'Màn hình',
		room: null
	},
	{
		id: 'lobby',
		label: 'Phòng chờ',
		group: 'Màn hình',
		room: {
			...baseRoom(),
			state: 'lobby',
			round: 0,
			myRole: null,
			timer: 0,
			players: basePlayers.slice(0, 6).map((p) => ({ ...p }))
		}
	},
	{
		id: 'day',
		label: 'Ban ngày',
		group: 'Màn hình',
		room: {
			...baseRoom(),
			state: 'day',
			timer: 90,
			canAct: false,
			actionType: null
		}
	},
	{
		id: 'voting',
		label: 'Bỏ phiếu',
		group: 'Màn hình',
		room: {
			...baseRoom(),
			state: 'voting',
			timer: 45,
			canAct: true,
			actionType: 'vote'
		}
	},
	{
		id: 'end-villager',
		label: 'Thắng - Dân Làng',
		group: 'Màn hình',
		room: {
			...baseRoom(),
			state: 'ended',
			winner: 'villager',
			timer: 0,
			players: basePlayers.map((p) => ({
				...p,
				role: p.source <= 2 ? 'werewolf' : 'villager',
				alive: p.source > 2
			}))
		}
	},
	{
		id: 'end-werewolf',
		label: 'Thắng - Ma Sói',
		group: 'Màn hình',
		room: {
			...baseRoom(),
			state: 'ended',
			winner: 'werewolf',
			timer: 0,
			players: basePlayers.map((p) => ({
				...p,
				role: p.source <= 3 ? 'werewolf' : 'villager',
				alive: p.source <= 3 || p.source === 4
			}))
		}
	},
	{
		id: 'role-werewolf',
		label: 'Ma Sói',
		group: 'Vai trò',
		room: {
			...baseRoom(),
			state: 'night',
			nightPhase: 'werewolf',
			myRole: 'werewolf',
			canAct: true,
			actionType: 'werewolf',
			werewolfPartners: [{ source: 4, name: 'Player 4' }]
		}
	},
	{
		id: 'role-seer',
		label: 'Tiên Tri',
		group: 'Vai trò',
		room: {
			...baseRoom(),
			state: 'night',
			nightPhase: 'seer',
			myRole: 'seer',
			canAct: true,
			actionType: 'seer',
			investigateResult: {
				target: 3,
				targetName: 'Player 3',
				result: 'Ma Sói',
				isWerewolf: true
			}
		}
	},
	{
		id: 'role-doctor',
		label: 'Bác Sĩ',
		group: 'Vai trò',
		room: {
			...baseRoom(),
			state: 'night',
			nightPhase: 'doctor',
			myRole: 'doctor',
			canAct: true,
			actionType: 'doctor'
		}
	},
	{
		id: 'role-witch',
		label: 'Phù Thủy',
		group: 'Vai trò',
		room: {
			...baseRoom(),
			state: 'night',
			nightPhase: 'witch',
			myRole: 'witch',
			canAct: true,
			actionType: 'witch',
			werewolfTarget: 5,
			witchPotions: { save: true, poison: true }
		}
	},
	{
		id: 'role-hunter',
		label: 'Thợ Săn',
		group: 'Vai trò',
		room: {
			...baseRoom(),
			state: 'day',
			myRole: 'hunter',
			myAlive: false,
			pendingHunter: true,
			canAct: true,
			actionType: 'hunter',
			players: basePlayers.map((p) => (p.source === 1 ? { ...p, alive: false } : { ...p }))
		}
	},
	{
		id: 'role-villager',
		label: 'Dân Làng (chờ)',
		group: 'Vai trò',
		room: {
			...baseRoom(),
			state: 'night',
			nightPhase: 'werewolf',
			myRole: 'villager',
			canAct: false,
			actionType: null
		}
	},
	{
		id: 'disconnected',
		label: 'Mất kết nối',
		group: 'Màn hình',
		room: {
			...baseRoom(),
			state: 'day',
			timer: 60,
			players: basePlayers.map((p, i) =>
				i === 2 ? { ...p, alive: false, disconnected: true } : { ...p }
			)
		}
	}
]

export const DEBUG_GROUPS = ['UI', 'Màn hình', 'Vai trò'] as const
