import { cn } from '@/utils'

function CupIcon({ className }: { className?: string }) {
	return (
		<svg viewBox='0 0 24 24' fill='none' className={className} aria-hidden>
			<path
				d='M8 4h8v3a4 4 0 01-8 0V4zM6 4H4v1a3 3 0 003 3M18 4h2v1a3 3 0 01-3 3M12 14v3M8 20h8M10 17h4'
				stroke='currentColor'
				strokeWidth='1.5'
				strokeLinecap='round'
				strokeLinejoin='round'
			/>
		</svg>
	)
}

interface BoardIconProps {
	icon?: string
	boardId?: string
	active?: boolean
	embedded?: boolean
	skewed?: boolean
	className?: string
}

export default function BoardIcon({
	active,
	embedded = false,
	skewed = false,
	className,
}: BoardIconProps) {
	const cup = <CupIcon className='h-[18px] w-[18px]' />

	return (
		<span
			className={cn(
				'flex shrink-0 items-center justify-center border transition',
				skewed ? 'lb-nav-icon-skewed rounded-md' : 'rounded',
				embedded
					? active
						? 'border-black/25 bg-[#00e5ff] text-black'
						: 'border-[#FFFFFF40] bg-[#ffffff16] text-white'
					: active
						? 'border-uls/40 bg-gradient-to-br from-uls/30 to-uls/10 text-uls'
						: 'border-white/8 bg-white/[0.04] text-white/55 group-hover:border-white/15 group-hover:text-white/80',
				!className?.includes('h-') && 'h-9 w-9',
				className
			)}>
			{skewed ? <span className='lb-nav-icon-straight inline-flex'>{cup}</span> : cup}
		</span>
	)
}
