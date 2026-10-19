import { useCallback, useEffect, useState } from 'react'
import { Box } from 'lr-components'
import LeaderboardPanel from '@tipi-rankings/features/Leaderboard'
import type { BoardSummary, LeaderboardBranding } from '@tipi-rankings/types/leaderboard'
import { fetchNui } from '../utils/fetchNui'
import { isEnvBrowser } from '../utils/misc'

type BoardsPayload = {
	boards?: BoardSummary[]
	branding?: LeaderboardBranding
	error?: string
}

async function loadBoardsPayload(): Promise<{
	boards: BoardSummary[]
	branding?: LeaderboardBranding
	error?: string
}> {
	if (isEnvBrowser()) {
		const mocks = await import('@tipi-rankings/mocks')
		return {
			boards: mocks.mockBoards,
			branding: mocks.mockBranding,
		}
	}

	const payload = await fetchNui<BoardsPayload>('getBoards')
	if (payload.error === 'resource_not_started') {
		return { boards: [], branding: payload.branding, error: payload.error }
	}
	const boards = payload.boards ?? (payload as unknown as BoardSummary[])
	return {
		boards: Array.isArray(boards) ? boards : [],
		branding: payload.branding,
	}
}

export default function LeaderboardEmbed() {
	const [boards, setBoards] = useState<BoardSummary[]>([])
	const [branding, setBranding] = useState<LeaderboardBranding | undefined>()
	const [activeBoardId, setActiveBoardId] = useState<string | null>(null)
	const [loading, setLoading] = useState(true)
	const [error, setError] = useState<string | null>(null)

	const init = useCallback(async () => {
		setLoading(true)
		setError(null)
		try {
			const { boards: list, branding: brand, error: loadError } = await loadBoardsPayload()
			if (loadError === 'resource_not_started') {
				setError('Chưa chạy resource Tipi_Rankings (ensure Tipi_Rankings trước Tipi_menu)')
				setBoards([])
				setBranding(brand)
				return
			}
			setBoards(list)
			setBranding(brand)
			setActiveBoardId((prev) => {
				if (prev && list.some((b) => b.id === prev)) return prev
				return list[0]?.id ?? null
			})
		} catch {
			setError('Không tải được bảng xếp hạng')
			setBoards([])
		} finally {
			setLoading(false)
		}
	}, [])

	useEffect(() => {
		init()
	}, [init])

	if (loading) {
		return (
			<Box
				width='100%'
				height='100%'
				display='flex'
				alignItems='center'
				justifyContent='center'
				backgroundColor='transparent'
				className='mp-lb-embed'>
				<span className='text-sm text-white/40'>Đang tải bảng xếp hạng...</span>
			</Box>
		)
	}

	if (error || boards.length === 0) {
		return (
			<Box
				width='100%'
				height='100%'
				display='flex'
				alignItems='center'
				justifyContent='center'
				backgroundColor='transparent'
				className='mp-lb-embed'>
				<span className='text-sm text-white/45'>
					{error ?? 'Chưa có bảng xếp hạng'}
				</span>
			</Box>
		)
	}

	return (
		<Box
			width='100%'
			height='100%'
			minHeight={0}
			position='relative'
			backgroundColor='transparent'
			className='mp-lb-embed'>
			<LeaderboardPanel
				embedded
				boards={boards}
				branding={branding}
				activeBoardId={activeBoardId}
				onBoardChange={setActiveBoardId}
				panelVisible
			/>
		</Box>
	)
}
