import { create } from 'zustand'
import { Player, RoomState } from '@/types'

export type AppState = {
	visible: boolean
	player: Player
	myId: number
	room: RoomState | null
	joinCode: string
	loadingState: Record<string, boolean>

	setVisible: (visible: boolean) => void
	setPlayerData: (player: Player) => void
	setMyId: (id: number) => void
	setRoomState: (room: RoomState | null) => void
	setJoinCode: (code: string) => void
	setLoadingState: (key: string, value: boolean) => void
	isAnyLoading: () => boolean
	hideFrame: () => void
	isHost: () => boolean
}

const initialState = {
	visible: false,
	player: {} as Player,
	myId: 0,
	room: null as RoomState | null,
	joinCode: '',
	loadingState: {} as Record<string, boolean>
}

export const useAppStore = create<AppState>((set, get) => ({
	...initialState,
	setVisible: (visible) => set({ visible }),
	setPlayerData: (player) => set({ player }),
	setMyId: (id) => set({ myId: id }),
	setRoomState: (room) => set({ room }),
	setJoinCode: (joinCode) => set({ joinCode }),
	setLoadingState: (key, value) => set((state) => ({ loadingState: { ...state.loadingState, [key]: value } })),
	isAnyLoading: () => {
		const state = get()
		return Object.values(state.loadingState).some(Boolean)
	},
	hideFrame: () => {
		const { myId } = get()
		set({ ...initialState, myId })
	},
	isHost: () => {
		const { room, myId } = get()
		return room?.host === myId
	}
}))
