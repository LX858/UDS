import { cn } from '@/lib/utils'
import { GamePlayer, ROLE_INFO } from '@/types'
import { Skull, User, WifiOff } from 'lucide-react'

interface PlayerCardProps {
	player: GamePlayer
	selected?: boolean
	onClick?: () => void
	disabled?: boolean
	showRole?: boolean
	showReady?: boolean
}

export default function PlayerCard({
	player,
	selected,
	onClick,
	disabled,
	showRole,
	showReady = false
}: PlayerCardProps) {
	const roleInfo = player.role ? ROLE_INFO[player.role] : null

	return (
		<button
			type='button'
			disabled={disabled || !player.alive}
			onClick={onClick}
			className={cn(
				'flex flex-col items-center gap-[0.6vh] rounded-[0.6vh] border p-[1vh] transition-all',
				player.disconnected
					? 'border-orange-900/40 bg-orange-950/20 opacity-70'
					: player.alive
						? 'border-white/10 bg-white/5 hover:bg-white/10'
						: 'border-red-900/30 bg-red-950/20 opacity-60',
				selected && 'border-amber-400 bg-amber-500/20 ring-1 ring-amber-400',
				disabled && 'cursor-default opacity-40',
				player.isMe && 'ring-1 ring-blue-400/50'
			)}
		>
			<div
				className={cn(
					'flex h-[5vh] w-[5vh] items-center justify-center rounded-full text-[2vh] font-bold',
					player.disconnected
						? 'bg-orange-900/50'
						: player.alive
							? 'bg-gradient-to-br from-slate-600 to-slate-800'
							: 'bg-red-900/50'
				)}
				style={roleInfo && showRole ? { background: `linear-gradient(135deg, ${roleInfo.color}88, ${roleInfo.color}44)` } : undefined}
			>
				{player.disconnected ? (
					<WifiOff className='h-[2.5vh] w-[2.5vh] text-orange-400' />
				) : player.alive ? (
					<User className='h-[2.5vh] w-[2.5vh]' />
				) : (
					<Skull className='h-[2.5vh] w-[2.5vh] text-red-400' />
				)}
			</div>
			<span className='max-w-[8vh] truncate text-[1.1vh] font-medium text-white'>
				{player.name}
				{player.isMe && ' (Bạn)'}
			</span>
			{showRole && roleInfo && (
				<span className='text-[0.9vh]' style={{ color: roleInfo.color }}>
					{roleInfo.label}
				</span>
			)}
			{showReady && !player.disconnected && (
				<span className={cn('text-[0.85vh]', player.ready ? 'text-green-400' : 'text-gray-500')}>
					{player.ready ? 'Sẵn sàng' : 'Chờ...'}
				</span>
			)}
			{player.disconnected && (
				<span className='text-[0.85vh] text-orange-400'>Mất kết nối</span>
			)}
		</button>
	)
}
