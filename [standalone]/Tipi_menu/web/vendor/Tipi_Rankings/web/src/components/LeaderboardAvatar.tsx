import { useState } from 'react'
import { cn } from '@/utils'

interface LeaderboardAvatarProps {
	label: string
	logoUrl?: string
	fallbackLogoUrl?: string
	className?: string
	ringClass?: string
	textClass?: string
	centered?: boolean
	embedded?: boolean
}

export default function LeaderboardAvatar({
	label,
	logoUrl,
	fallbackLogoUrl,
	className = 'h-10 w-10',
	ringClass = 'ring-1 ring-white/15',
	textClass = 'text-xs',
	centered = false,
	embedded = false,
}: LeaderboardAvatarProps) {
	const imgFit = centered ? 'object-cover object-center' : 'object-cover'
	const fallbackFit = centered ? 'object-contain object-center p-2' : 'object-contain p-1.5 opacity-90'
	const [primaryFailed, setPrimaryFailed] = useState(false)
	const [fallbackFailed, setFallbackFailed] = useState(false)
	const initials = label.slice(0, 2).toUpperCase()

	const showPrimary = Boolean(logoUrl) && !primaryFailed
	const showFallback = !showPrimary && Boolean(fallbackLogoUrl) && !fallbackFailed

	return (
		<div
			className={cn(
				'relative mx-auto shrink-0 overflow-hidden rounded-full',
				embedded ? 'bg-[#ffffff16]' : 'bg-black/40',
				className,
				ringClass
			)}>
			{showPrimary ? (
				<img
					src={logoUrl}
					alt={label}
					className={cn('block h-full w-full', imgFit)}
					onError={() => setPrimaryFailed(true)}
				/>
			) : showFallback ? (
				<img
					src={fallbackLogoUrl}
					alt=''
					className={cn('block h-full w-full opacity-95', fallbackFit)}
					onError={() => setFallbackFailed(true)}
				/>
			) : (
				<div
					className={cn(
						'flex h-full w-full items-center justify-center bg-gradient-to-br from-[#00e5ff]/35 to-[#001824] font-bold text-white',
						textClass
					)}>
					{initials}
				</div>
			)}
		</div>
	)
}
