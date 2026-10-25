import type { BoardSummary } from '@/types/leaderboard'
import { mpMenuUi } from '@/constants/mpMenuUi'
import { cn } from '@/utils'
import { playUiClick } from '@/utils/uiSound'
import BoardIcon from '@/components/BoardIcon'

interface BoardNavProps {
	boards: BoardSummary[]
	activeBoardId: string | null
	onBoardChange: (boardId: string) => void
	seasonTagline?: string
	logoUrl?: string
	embedded?: boolean
}

export default function BoardNav({
	boards,
	activeBoardId,
	onBoardChange,
	seasonTagline,
	logoUrl,
	embedded = false,
}: BoardNavProps) {
	if (embedded) {
		return (
			<aside className={mpMenuUi.navColumn}>
				<div className={cn(mpMenuUi.navHeader, 'lb-nav-header')}>
					{logoUrl ? (
						<img
							src={logoUrl}
							alt='UnderStars'
							className='mx-auto mb-2 h-9 w-full max-w-[140px] object-contain drop-shadow-[0_0_12px_rgba(0,229,255,0.35)]'
						/>
					) : (
						<p className='text-center font-display text-[10px] font-bold uppercase tracking-[0.2em] text-[#00e5ff]'>
							UnderStars
						</p>
					)}
					<p className='text-center text-xs font-bold uppercase tracking-wide text-white drop-shadow-sm'>
						Bảng xếp hạng
					</p>
					{seasonTagline && (
						<p className='lb-nav-season mt-1 text-center text-[9px] font-semibold uppercase tracking-[0.14em] text-[#7fafc0] drop-shadow-[0_1px_4px_rgba(0,0,0,0.9)]'>
							{seasonTagline}
						</p>
					)}
				</div>

				<nav className='lb-nav-scroll lb-nav-skew-list leaderboard-scroll flex min-h-0 flex-1 flex-col overflow-y-auto'>
					{boards.map((board) => {
						const active = activeBoardId === board.id
						return (
							<button
								key={board.id}
								type='button'
								onClick={() => {
									playUiClick()
									onBoardChange(board.id)
								}}
								title={board.description}
								className={mpMenuUi.navSkewBtn}>
								<span
									className={
										active ? mpMenuUi.navSkewCardActive : mpMenuUi.navSkewCard
									}>
									<span className={mpMenuUi.navSkewInner}>
										<BoardIcon
											icon={board.icon}
											boardId={board.id}
											active={active}
											embedded
											skewed
											className='!h-8 !w-8'
										/>
										<span
											className={cn(
												mpMenuUi.navSkewLabel,
												active ? mpMenuUi.navTitleActive : mpMenuUi.navTitleIdle
											)}>
											{board.label}
										</span>
									</span>
								</span>
							</button>
						)
					})}
				</nav>
			</aside>
		)
	}

	return (
		<aside className='lb-nav flex w-[172px] shrink-0 flex-col border-r border-white/[0.06] bg-black/25'>
			<div className='border-b border-white/[0.06] px-3 py-3'>
				{logoUrl ? (
					<img
						src={logoUrl}
						alt='UnderStars'
						className='mx-auto mb-2 h-10 w-full max-w-[140px] object-contain opacity-95 drop-shadow-[0_0_12px_rgba(0,229,255,0.35)]'
					/>
				) : (
					<p className='font-display text-[10px] font-bold uppercase tracking-[0.22em] text-uls/70'>
						UnderStars
					</p>
				)}
				<p className='font-heading text-xs font-extrabold uppercase tracking-wide text-white/90'>
					Bảng xếp hạng
				</p>
				{seasonTagline && (
					<p className='lb-nav-season mt-1 text-[9px] font-semibold uppercase leading-tight tracking-wide text-[#7fafc0] drop-shadow-[0_1px_3px_rgba(0,0,0,0.85)]'>
						{seasonTagline}
					</p>
				)}
			</div>

			<nav className='leaderboard-scroll flex-1 space-y-0.5 overflow-y-auto p-2'>
				{boards.map((board) => {
					const active = activeBoardId === board.id
					return (
						<button
							key={board.id}
							type='button'
							onClick={() => {
								playUiClick()
								onBoardChange(board.id)
							}}
							title={board.description}
							className={cn(
								'relative flex w-full items-center gap-2 rounded-md border px-2 py-2 text-left transition',
								active
									? 'border-uls/35 bg-uls/12'
									: 'border-transparent hover:border-white/8 hover:bg-white/[0.04]'
							)}>
							{active && (
								<span className='absolute bottom-1.5 left-0 top-1.5 w-[2px] rounded-full bg-uls' />
							)}
							<BoardIcon
								icon={board.icon}
								boardId={board.id}
								active={active}
								className='!h-8 !w-8 shrink-0'
							/>
							<span className='min-w-0 flex-1'>
								<span
									className={cn(
										'block text-xs font-semibold leading-tight',
										active ? 'text-uls' : 'text-white/75'
									)}>
									{board.label}
								</span>
								{board.description && (
									<span className='mt-0.5 line-clamp-2 text-[9px] leading-tight text-white/30'>
										{board.description}
									</span>
								)}
							</span>
						</button>
					)
				})}
			</nav>

			<div className='h-px shrink-0 bg-gradient-to-r from-transparent via-uls/40 to-transparent' />
		</aside>
	)
}
