import { RoomState, Player } from '@/types'
import { debugData } from '@/utils'

debugData<Player>([
	{
		action: 'setPlayerData',
		data: {
			id: 'ABC12345',
			identifier: 'ABC12345',
			source: 1,
			name: 'E N D E R',
			job: {
				name: 'unemployed',
				label: 'Thất nghiệp',
				grade: 0,
				grade_label: 'Thất nghiệp'
			}
		}
	}
])

debugData<number>([{ action: 'setMyId', data: 1 }])

debugData<RoomState>([
	{
		action: 'setRoomState',
		data: {
			id: 'ABC123',
			host: 1,
			state: 'lobby',
			nightPhase: null,
			round: 0,
			players: [
				{ source: 1, name: 'Ender', alive: true, ready: true, hasVoted: false, hasActed: false, isMe: true },
				{ source: 2, name: 'Player 2', alive: true, ready: false, hasVoted: false, hasActed: false },
				{ source: 3, name: 'Player 3', alive: true, ready: true, hasVoted: false, hasActed: false }
			],
			logs: [{ text: 'Ender đã tạo phòng.', time: Date.now() / 1000 }],
			winner: null,
			timer: 0,
			canAct: false,
			actionType: null,
			myRole: null,
			myAlive: true,
			pendingHunter: false,
			playerCount: 3,
			minPlayers: 6,
			maxPlayers: 12
		}
	}
])

debugData([{ action: 'setVisible', data: true }])
