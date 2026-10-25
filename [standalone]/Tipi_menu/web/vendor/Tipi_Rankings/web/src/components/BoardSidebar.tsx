import type { BoardSummary } from '@/types/leaderboard'
import { cn } from '@/utils'
import BoardIcon from '@/components/BoardIcon'

interface BoardSidebarProps {
	boards: BoardSummary[]
	activeBoardId: string | null
	onBoardChange: (boardId: string) => void
}

export default function BoardSidebar({ boards, activeBoardId, onBoardChange }: BoardSidebarProps) {
	return (
		<aside className='flex w-[220px] shrink-0 flex-col border-r border-surface-border bg-black/20'>
			<div className='border-b border-surface-border px-4 py-4'>
				<p className='text-[10px] font-semibold uppercase tracking-[0.18em] text-uls/60'>
					Bảng xếp hạng
				</p>
			</div>

			<nav className='leaderboard-scroll flex-1 space-y-1.5 overflow-y-auto p-3'>
				{boards.map((board) => {
					const active = activeBoardId === board.id
					return (
						<button
							key={board.id}
							onClick={() => onBoardChange(board.id)}
							className={cn(
								'group relative flex w-full items-center gap-3 rounded-xl border px-3 py-3 text-left transition',
								active
									? 'border-uls/35 bg-uls/10 shadow-glow'
									: 'border-transparent hover:border-white/10 hover:bg-white/[0.04]'
							)}>
							{active && (
								<span className='absolute bottom-2 left-0 top-2 w-[3px] rounded-r-full bg-uls' />
							)}
							<BoardIcon icon={board.icon} boardId={board.id} active={active} />
							<span className='min-w-0 flex-1'>
								<span
									className={cn(
										'block truncate text-sm font-semibold',
										active ? 'text-uls' : 'text-white/75 group-hover:text-white'
									)}>
									{board.label}
								</span>
								{board.description && (
									<span className='mt-0.5 block truncate text-[10px] text-white/35'>
										{board.description}
									</span>
								)}
							</span>
						</button>
					)
				})}
			</nav>
		</aside>
	)
}
