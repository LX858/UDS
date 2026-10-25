import { useCallback, useEffect, useState } from 'react'
import LeaderboardPanel from '@/features/Leaderboard'
import { useNuiEvent } from '@/hooks'
import '@/mocks'
import type { BoardSummary, LeaderboardBranding, VisiblePayload } from '@/types/leaderboard'
import { cn, fetchNui, isEnvBrowser } from '@/utils'
import { mockBoards, mockBranding } from '@/mocks'

const PANEL_MS = 320

const App: React.FC = () => {
	const [visible, setVisible] = useState(isEnvBrowser())
	const [panelOpen, setPanelOpen] = useState(isEnvBrowser())
	const [boards, setBoards] = useState<BoardSummary[]>(
		isEnvBrowser() ? mockBoards : []
	)
	const [branding, setBranding] = useState<LeaderboardBranding | undefined>(
		isEnvBrowser() ? mockBranding : undefined
	)
	const [activeBoardId, setActiveBoardId] = useState<string | null>(
		isEnvBrowser() ? mockBoards[0]?.id ?? null : null
	)

	const handleClose = useCallback(() => {
		setPanelOpen(false)
		setTimeout(() => {
			setVisible(false)
			if (!isEnvBrowser()) fetchNui('close')
		}, PANEL_MS)
	}, [])

	const handleOpen = useCallback(() => {
		setVisible(true)
		requestAnimationFrame(() => setPanelOpen(true))
	}, [])

	useNuiEvent<VisiblePayload>('setVisible', (payload) => {
		if (payload.visible) {
			setVisible(true)
			if (payload.boards) setBoards(payload.boards)
			if (payload.branding) setBranding(payload.branding)
			if (payload.boardId) setActiveBoardId(payload.boardId)
			else if (payload.boards?.[0]) setActiveBoardId(payload.boards[0].id)
			requestAnimationFrame(() => setPanelOpen(true))
		} else {
			setPanelOpen(false)
			setTimeout(() => setVisible(false), PANEL_MS)
		}
	})

	useEffect(() => {
		const onKey = (e: KeyboardEvent) => {
			if (e.key === 'Escape' && visible) handleClose()
		}
		window.addEventListener('keydown', onKey)
		return () => window.removeEventListener('keydown', onKey)
	}, [visible, handleClose])

	useEffect(() => {
		if (!isEnvBrowser()) {
			const t = setTimeout(() => fetchNui('AppReady'), 500)
			return () => clearTimeout(t)
		}
	}, [])

	if (!visible) {
		if (!isEnvBrowser()) return null
		return (
			<button
				onClick={handleOpen}
				className='absolute left-4 top-4 z-50 rounded-lg bg-uls px-4 py-2 text-sm font-bold text-black'>
				Mở BXH (dev)
			</button>
		)
	}

	return (
		<div
			className={cn(
				'absolute inset-0 transition-opacity duration-300',
				panelOpen ? 'bg-black/45' : 'bg-black/0 pointer-events-none'
			)}
			onClick={handleClose}>
			<div onClick={(e) => e.stopPropagation()}>
				<LeaderboardPanel
					boards={boards}
					branding={branding}
					activeBoardId={activeBoardId}
					onBoardChange={setActiveBoardId}
					onClose={handleClose}
					panelVisible={panelOpen}
				/>
			</div>
		</div>
	)
}

export default App
