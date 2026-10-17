import { useAppStore } from '@/store/app'
import { fetchNui } from '@/utils'
import { Button } from '@/components/ui/button'
import { ScrollArea } from '@/components/ui/scroll-area'
import PlayerCard from './PlayerCard'

export default function EndScreen() {
	const { room } = useAppStore()
	if (!room) return null

	const winnerLabel = room.winner === 'werewolf' ? 'Ma Sói' : 'Dân Làng'
	const winnerColor = room.winner === 'werewolf' ? '#ef4444' : '#22c55e'

	return (
		<div className='flex flex-col gap-[1.5vh] text-center'>
			<div
				className='rounded-[0.6vh] p-[2vh]'
				style={{ background: `linear-gradient(135deg, ${winnerColor}33, transparent)` }}
			>
				<p className='text-[1.2vh] text-gray-300'>Chiến thắng thuộc về</p>
				<p className='text-[2.5vh] font-bold' style={{ color: winnerColor }}>
					Phe {winnerLabel}
				</p>
			</div>

			<div className='grid grid-cols-3 gap-[0.6vh]'>
				{room.players.map((player) => (
					<PlayerCard key={player.source} player={player} showRole disabled />
				))}
			</div>

			<Button onClick={() => fetchNui('leaveRoom', {}, 1)}>Quay về lobby</Button>
		</div>
	)
}
