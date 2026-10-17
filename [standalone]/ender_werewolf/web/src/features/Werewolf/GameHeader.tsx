import { useAppStore } from '@/store/app'
import { NIGHT_PHASE_LABELS, PHASE_LABELS } from '@/types'
import { Moon, Sun, Users, Vote } from 'lucide-react'

export default function GameHeader() {
	const { room } = useAppStore()
	if (!room) return null

	const phaseIcon = () => {
		switch (room.state) {
			case 'night':
				return <Moon className='h-[1.8vh] w-[1.8vh] text-indigo-300' />
			case 'day':
				return <Sun className='h-[1.8vh] w-[1.8vh] text-amber-300' />
			case 'voting':
				return <Vote className='h-[1.8vh] w-[1.8vh] text-red-300' />
			default:
				return <Users className='h-[1.8vh] w-[1.8vh] text-gray-300' />
		}
	}

	return (
		<div className='mb-[1.5vh] flex items-center justify-between border-b border-white/10 pb-[1vh]'>
			<div>
				<h1 className='text-[2vh] font-bold tracking-wide text-white'>Werewolf</h1>
				{room.id && <p className='text-[1vh] text-gray-400'>Mã phòng: {room.id}</p>}
				{room.lobbyLabel && <p className='text-[1vh] text-amber-400/80'>{room.lobbyLabel}</p>}
			</div>
			<div className='flex flex-col items-end gap-[0.3vh]'>
				<div className='flex items-center gap-[0.5vh] text-[1.2vh] text-white'>
					{phaseIcon()}
					<span>{PHASE_LABELS[room.state]}</span>
					{room.round > 0 && <span className='text-gray-400'>• Vòng {room.round}</span>}
				</div>
				{room.state === 'night' && room.nightPhase && (
					<span className='text-[1vh] text-indigo-300'>{NIGHT_PHASE_LABELS[room.nightPhase]}</span>
				)}
				{room.timer > 0 && (
					<span className='rounded bg-white/10 px-[0.8vh] py-[0.2vh] text-[1vh] text-amber-300'>
						⏱ {room.timer}s
					</span>
				)}
			</div>
		</div>
	)
}
