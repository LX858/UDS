import { cn } from '@/lib/utils'
import '@/mocks'
import { useAppStore } from '@/store/app'
import { Player, RoomState } from '@/types'
import { fetchNui, isEnvBrowser } from '@/utils'
import { useEffect, useState } from 'react'
import { useNuiEvent } from './hooks'
import { AnimatePresence, motion } from 'framer-motion'
import GameHeader from '@/features/Werewolf/GameHeader'
import Lobby from '@/features/Werewolf/Lobby'
import GameBoard from '@/features/Werewolf/GameBoard'
import EndScreen from '@/features/Werewolf/EndScreen'
import DebugPanel from '@/features/Werewolf/DebugPanel'

const App: React.FC = () => {
	const { visible, room, setPlayerData, setMyId, hideFrame, setVisible, setRoomState } = useAppStore()
	const [hudMode, setHudMode] = useState(false)

	useNuiEvent('setVisible', (v: boolean) => setVisible(v))
	useNuiEvent('setHudMode', (hud: boolean) => setHudMode(hud))
	useNuiEvent('resetUI', () => hideFrame())
	useNuiEvent('setMyId', (id: number) => setMyId(id))
	useNuiEvent<Player>('setPlayerData', (player) => setPlayerData(player))
	useNuiEvent<RoomState | null>('setRoomState', (state) => setRoomState(state))

	const handleClose = () => {
		fetchNui('hideFrame', {}, 1)
	}

	useEffect(() => {
		if (!visible) return

		const keyHandler = (e: KeyboardEvent) => {
			if (hudMode) return
			if (['Escape'].includes(e.code)) {
				if (!isEnvBrowser()) {
					handleClose()
				} else setVisible(false)
			}
		}

		window.addEventListener('keydown', keyHandler)
		return () => window.removeEventListener('keydown', keyHandler)
	}, [visible, hudMode])

	useEffect(() => {
		if (!isEnvBrowser()) {
			const timeout = setTimeout(async () => {
				fetchNui('AppReady')
			}, 2000)
			return () => clearTimeout(timeout)
		}
	}, [])

	const renderContent = () => {
		if (!room || room.state === 'lobby') return <Lobby />
		if (room.state === 'ended') return <EndScreen />
		return <GameBoard />
	}

	return (
		<div className={cn('absolute h-full w-full !bg-transparent')}>
			<DebugPanel />
			<AnimatePresence>
				{visible && (
					<motion.div
						initial={{ opacity: 0, scale: 0.95 }}
						animate={{ opacity: 1, scale: 1 }}
						exit={{ opacity: 0, scale: 0.95 }}
						transition={{ duration: 0.25, ease: [0.43, 0.13, 0.23, 0.96] }}
						className={cn(
							'absolute inset-0 flex items-center justify-center',
							hudMode && 'pointer-events-none'
						)}
					>
						<div
							className={cn(
								'relative w-2xl overflow-hidden rounded-[1vh] border border-white/10 bg-gradient-to-b from-[#1a1a2e] to-[#0f0f1a] p-[2vh] shadow-2xl',
								hudMode && 'pointer-events-none'
							)}
						>
							<GameHeader />
							{renderContent()}
						</div>
					</motion.div>
				)}
			</AnimatePresence>
		</div>
	)
}

export default App
