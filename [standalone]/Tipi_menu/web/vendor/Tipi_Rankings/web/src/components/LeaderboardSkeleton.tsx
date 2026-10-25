interface LeaderboardSkeletonProps {
	listOnly?: boolean
}

export default function LeaderboardSkeleton({ listOnly }: LeaderboardSkeletonProps) {
	return (
		<div className='animate-pulse space-y-3 px-1 py-2'>
			{!listOnly && (
				<div className='grid grid-cols-3 gap-2'>
					{[0, 1, 2].map((i) => (
						<div key={i} className='h-28 rounded-lg bg-white/[0.06]' />
					))}
				</div>
			)}
			<div className='space-y-1.5'>
				{Array.from({ length: 8 }).map((_, i) => (
					<div key={i} className='flex gap-2 rounded-md bg-white/[0.04] px-3 py-2.5'>
						<div className='h-7 w-7 rounded bg-white/[0.08]' />
						<div className='flex-1 space-y-1.5 py-0.5'>
							<div className='h-3 w-2/3 rounded bg-white/[0.08]' />
						</div>
						<div className='h-4 w-10 rounded bg-white/[0.08]' />
						<div className='h-4 w-12 rounded bg-white/[0.08]' />
					</div>
				))}
			</div>
		</div>
	)
}
