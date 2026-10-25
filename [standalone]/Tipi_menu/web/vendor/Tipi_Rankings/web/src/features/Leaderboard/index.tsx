import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import type {
	BoardSummary,
	LeaderboardData,
	LeaderboardEntry,
	LeaderboardBranding,
} from '@/types/leaderboard'
import { getBoardTheme } from '@/constants/boardThemes'
import { mpMenuUi } from '@/constants/mpMenuUi'
import { cn, fetchNui, isEnvBrowser } from '@/utils'
import { playUiClick } from '@/utils/uiSound'
import { getMockLeaderboard } from '@/mocks'
import BoardNav from '@/components/BoardNav'
import EntryRow, { LB_TABLE_GRID_COMPACT, LB_TABLE_GRID_EMBEDDED } from '@/components/EntryRow'
import TopThreeStrip from '@/components/TopThreeStrip'
import LeaderboardSkeleton from '@/components/LeaderboardSkeleton'
import MyRankBar from '@/components/MyRankBar'

interface LeaderboardPanelProps {
	boards: BoardSummary[]
	branding?: LeaderboardBranding
	activeBoardId: string | null
	onBoardChange: (boardId: string) => void
	onClose?: () => void
	panelVisible: boolean
	embedded?: boolean
}

export default function LeaderboardPanel({
	boards,
	branding,
	activeBoardId,
	onBoardChange,
	onClose,
	panelVisible,
	embedded = false,
}: LeaderboardPanelProps) {
	const [data, setData] = useState<LeaderboardData | null>(null)
	const [loading, setLoading] = useState(false)
	const [contentKey, setContentKey] = useState(0)
	const [search, setSearch] = useState('')
	const [searchOpen, setSearchOpen] = useState(false)
	const [animateValues, setAnimateValues] = useState(false)
	const listRef = useRef<HTMLDivElement>(null)
	const searchInputRef = useRef<HTMLInputElement>(null)
	const selfRowRef = useRef<HTMLDivElement>(null)

	const activeBoard = boards.find((b) => b.id === activeBoardId)
	const boardTheme = getBoardTheme(data?.theme ?? activeBoard?.theme)

	const loadBoard = useCallback(async (boardId: string) => {
		setLoading(true)
		setAnimateValues(false)
		setSearch('')
		setSearchOpen(false)
		try {
			const result = await fetchNui<{ success: boolean; data?: LeaderboardData }>(
				'getLeaderboard',
				{ boardId },
				isEnvBrowser() ? { success: true, data: getMockLeaderboard(boardId) } : undefined
			)
			if (result.success && result.data) {
				setData(result.data)
				setContentKey((k) => k + 1)
				setTimeout(() => setAnimateValues(true), 50)
			} else {
				setData(null)
			}
		} catch {
			if (isEnvBrowser()) {
				setData(getMockLeaderboard(boardId))
				setContentKey((k) => k + 1)
				setTimeout(() => setAnimateValues(true), 50)
			}
		} finally {
			setLoading(false)
		}
	}, [])

	useEffect(() => {
		if (activeBoardId) loadBoard(activeBoardId)
	}, [activeBoardId, loadBoard])

	const handleBoardChange = (id: string) => {
		playUiClick()
		onBoardChange(id)
	}

	const myKey = data?.player?.myEntryKey

	const restEntries: LeaderboardEntry[] = useMemo(() => {
		const base = data?.entries.filter((e: LeaderboardEntry) => e.rank > 3) ?? []
		if (!search.trim()) return base
		const q = search.trim().toLowerCase()
		return base.filter(
			(e) => e.label.toLowerCase().includes(q) || e.name.toLowerCase().includes(q)
		)
	}, [data?.entries, search])

	const topThree: LeaderboardEntry[] =
		data?.entries.filter((e: LeaderboardEntry) => e.rank <= 3) ?? []

	const title = data?.label ?? activeBoard?.label ?? 'BXH'
	const levelHeader = data?.entryType === 'player' ? 'Cấp nghề' : 'Cấp'
	const widePanel = boards.length >= 6
	const hasRankFourPlus = (data?.entries.length ?? 0) > 3

	const jumpToMyRank = () => {
		if (!myKey || !data) return
		if (data.player?.inTopList === false) return
		if (!data.entries.some((e) => e.name === myKey)) return
		playUiClick()
		const myEntry = data.entries.find((e) => e.name === myKey)
		if (myEntry && myEntry.rank <= 3) {
			listRef.current?.scrollTo({ top: 0, behavior: 'smooth' })
			return
		}
		selfRowRef.current?.scrollIntoView({ behavior: 'smooth', block: 'center' })
	}

	const showSearch = (data?.entries.length ?? 0) > 3
	const searchExpanded = searchOpen || search.trim().length > 0

	const openSearch = () => {
		playUiClick()
		setSearchOpen(true)
		requestAnimationFrame(() => searchInputRef.current?.focus())
	}

	const closeSearch = () => {
		if (search.trim()) return
		setSearchOpen(false)
	}

	const panelShown = embedded || panelVisible
	const tableGrid = embedded ? LB_TABLE_GRID_EMBEDDED : LB_TABLE_GRID_COMPACT

	const searchIconBtnClass = embedded
		? searchExpanded
			? mpMenuUi.iconBtnActive
			: mpMenuUi.iconBtn
		: cn(
				'rounded border',
				searchExpanded
					? 'border-uls/35 bg-uls/10 text-uls'
					: 'border-white/10 bg-white/[0.04] text-white/45 hover:border-uls/25 hover:text-white/70'
			)

	const searchControl = showSearch ? (
		<div className='flex shrink-0 items-center justify-end'>
			<div
				className={cn(
					'overflow-hidden transition-[max-width,opacity] duration-300 ease-out',
					searchExpanded
						? 'max-w-[min(280px,42vw)] opacity-100'
						: 'max-w-0 opacity-0 pointer-events-none'
				)}
				aria-hidden={!searchExpanded}>
				<div className='flex items-center gap-1.5 pr-1.5'>
					<input
						ref={searchInputRef}
						type='text'
						value={search}
						onChange={(e) => setSearch(e.target.value)}
						onBlur={closeSearch}
						placeholder='Tìm tên hạng 4+...'
						tabIndex={searchExpanded ? 0 : -1}
						className={cn(
							'h-9 w-[min(260px,40vw)] min-w-0 text-sm text-white',
							embedded
								? mpMenuUi.input
								: 'rounded border border-white/10 bg-black/30 px-2.5 text-xs placeholder:text-white/30 focus:border-uls/40 focus:outline-none'
						)}
					/>
					{search.trim() && (
						<button
							type='button'
							onMouseDown={(e) => e.preventDefault()}
							onClick={() => {
								playUiClick()
								setSearch('')
								searchInputRef.current?.focus()
							}}
							className='shrink-0 px-1 text-sm text-white/40 hover:text-white/70'
							aria-label='Xóa'>
							×
						</button>
					)}
				</div>
			</div>
			<button
				type='button'
				onClick={() => {
					if (searchExpanded) {
						playUiClick()
						setSearch('')
						setSearchOpen(false)
					} else {
						openSearch()
					}
				}}
				className={cn(
					'flex h-9 w-9 shrink-0 items-center justify-center text-sm transition',
					searchIconBtnClass
				)}
				aria-label='Tìm tên'
				title='Tìm tên'>
				<svg
					className='h-3.5 w-3.5'
					viewBox='0 0 24 24'
					fill='none'
					stroke='currentColor'
					strokeWidth='2.5'
					aria-hidden>
					<circle cx='11' cy='11' r='7' />
					<path d='M20 20L16.5 16.5' strokeLinecap='round' />
				</svg>
			</button>
		</div>
	) : null

	const topThreeBlock = !loading && data && data.entries.length > 0 && topThree.length > 0 && (
		<div
			key={`top-${contentKey}`}
			className={cn(
				'lb-content-fade shrink-0',
				embedded ? mpMenuUi.top3Zone : 'lb-top3-pinned relative z-20 border-b border-white/[0.06] bg-[#090810] px-3 pb-2 pt-2 shadow-[0_10px_20px_-6px_#090810]'
			)}>
			<TopThreeStrip
				entries={topThree}
				valueLabel={data.valueLabel}
				fallbackLogoUrl={branding?.logoUrl ?? data.branding?.logoUrl}
				animate={animateValues}
				embedded={embedded}
			/>
		</div>
	)

	const listContent = (
		<div
			ref={listRef}
			className={cn(
				'lb-list-scroll leaderboard-scroll min-h-0 flex-1 overflow-x-hidden overflow-y-auto overscroll-contain',
				embedded && mpMenuUi.listBody
			)}>
			{loading && (
				<div className={embedded ? 'px-4 py-3' : 'px-3 py-2'}>
					<LeaderboardSkeleton listOnly />
				</div>
			)}

			{!loading && data && data.entries.length === 0 && (
				<div
					className={cn(
						'flex h-40 items-center justify-center',
						embedded ? cn('px-4', mpMenuUi.empty) : 'px-3 text-sm text-white/35'
					)}>
					Chưa có dữ liệu
				</div>
			)}

			{!loading && data && data.entries.length > 0 && (
				<div key={contentKey} className='lb-content-fade'>
					{hasRankFourPlus && (
						<div
							className={cn(
								'lb-rank4-head sticky top-0 z-20',
								embedded
									? mpMenuUi.rank4Head
									: 'border-b border-white/[0.06] bg-[#090810] px-3 pb-1.5 pt-1.5 shadow-[0_8px_16px_-8px_#090810]'
							)}>
							<div className='mb-2 flex items-center gap-2'>
								<p
									className={
										embedded
											? mpMenuUi.rank4Label
											: 'text-[10px] font-semibold uppercase tracking-[0.14em] text-white/30'
									}>
									Hạng 4 trở đi
								</p>
								<div
									className={cn(
										'h-px flex-1',
										embedded ? 'bg-[#FFFFFF40]' : 'bg-gradient-to-r from-white/10 to-transparent'
									)}
								/>
							</div>
							<div className={cn(tableGrid, 'lb-table-head', embedded && mpMenuUi.tableHead)}>
								<span>#</span>
								<span>Tên</span>
								<span className='text-center leading-tight tracking-[0.06em]'>
									{levelHeader}
								</span>
								<span className='text-right'>{data.valueLabel}</span>
							</div>
						</div>
					)}

					<div className={embedded ? mpMenuUi.listInner : 'space-y-1.5 px-3 py-2'}>
						{restEntries.length > 0 ? (
							restEntries.map((entry) => (
								<EntryRow
									key={`${data.boardId}-${entry.rank}-${entry.name}`}
									ref={myKey && entry.name === myKey ? selfRowRef : undefined}
									entry={entry}
									entryType={data.entryType}
									isSelf={!!myKey && entry.name === myKey}
									animateValues={animateValues}
									theme={boardTheme}
									zebra
									embedded={embedded}
								/>
							))
						) : (
							search &&
							hasRankFourPlus && (
								<p className='py-6 text-center text-xs text-white/35'>Không tìm thấy kết quả</p>
							)
						)}
					</div>
				</div>
			)}
		</div>
	)

	const showMyRankFooter =
		data?.player?.myEntryKey ||
		(data?.player?.inTopList && data?.player?.myRank)

	const footerBlock =
		data && (embedded ? showMyRankFooter || data.updatedAt : showMyRankFooter) ? (
			<MyRankBar
				data={data}
				onJumpToRank={jumpToMyRank}
				theme={boardTheme}
				className='shrink-0'
				embedded={embedded}
				updatedAt={embedded ? data.updatedAt : undefined}
			/>
		) : null

	const updatedFooter =
		data?.updatedAt && !embedded ? (
			<div className='shrink-0 border-t border-white/[0.06] px-4 py-2 text-center text-[10px] text-white/25'>
				Cập nhật {new Date(data.updatedAt * 1000).toLocaleString('vi-VN')}
			</div>
		) : null

	return (
		<div
			className={cn(
				'flex h-full w-full transition-transform duration-300 ease-out',
				embedded
					? 'min-h-0 items-stretch justify-center p-0'
					: 'items-start justify-end px-6 pb-6 pt-12',
				panelShown ? 'translate-x-0' : 'translate-x-8 pointer-events-none opacity-0'
			)}>
			<div
				className={cn(
					'lb-panel lb-panel-themed flex flex-col overflow-hidden transition-all duration-300',
					embedded
						? cn(mpMenuUi.panel, 'h-full min-h-0 w-full max-w-none min-w-0')
						: cn(
								'rounded-lg',
								'h-[min(82vh,720px)]',
								widePanel ? 'w-[min(620px,48vw)] min-w-[500px]' : 'w-[min(560px,44vw)] min-w-[480px]'
							)
				)}
				data-theme={data?.theme ?? activeBoard?.theme ?? 'default'}>
				{embedded ? (
					<div className={mpMenuUi.layout}>
						<BoardNav
							boards={boards}
							activeBoardId={activeBoardId}
							onBoardChange={handleBoardChange}
							seasonTagline={branding?.seasonTagline ?? data?.branding?.seasonTagline}
							logoUrl={branding?.logoUrl ?? data?.branding?.logoUrl}
							embedded
						/>

						<div className={mpMenuUi.mainColumn}>
							<div className={mpMenuUi.titleBar}>
								<span className={cn(mpMenuUi.titleAccent, mpMenuUi.titleAccentH)} />
								<div className='min-w-0 flex-1'>
									<h1 className={mpMenuUi.titleText}>{title}</h1>
								</div>
								{searchControl}
							</div>

							<div className={mpMenuUi.contentCard}>
								{topThreeBlock}
								{listContent}
								{footerBlock}
							</div>
						</div>
					</div>
				) : (
					<div className='flex min-h-0 flex-1'>
						<BoardNav
							boards={boards}
							activeBoardId={activeBoardId}
							onBoardChange={handleBoardChange}
							seasonTagline={branding?.seasonTagline ?? data?.branding?.seasonTagline}
							logoUrl={branding?.logoUrl ?? data?.branding?.logoUrl}
						/>

						<div className='flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden'>
							<div className={cn('flex items-start justify-between gap-3 border-b px-4 py-3', boardTheme.border)}>
								<div className='min-w-0'>
									<h1 className='font-display text-xl font-bold uppercase tracking-wide text-white'>
										{title}
									</h1>
								</div>
								<div className='flex shrink-0 items-center gap-1'>
									{searchControl}
									{onClose && (
										<button
											type='button'
											onClick={() => {
												playUiClick()
												onClose()
											}}
											className='flex h-8 w-8 shrink-0 items-center justify-center rounded border border-white/10 bg-white/[0.04] text-base text-white/50 transition hover:border-red-400/30 hover:bg-red-500/10 hover:text-red-300'
											aria-label='Đóng'>
											×
										</button>
									)}
								</div>
							</div>

							{topThreeBlock}
							{listContent}
							{footerBlock}
							{updatedFooter}
						</div>
					</div>
				)}
			</div>
		</div>
	)
}
