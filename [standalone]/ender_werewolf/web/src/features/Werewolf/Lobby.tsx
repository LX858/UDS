import { useAppStore } from '@/store/app'
import { fetchNui } from '@/utils'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { ScrollArea } from '@/components/ui/scroll-area'
import PlayerCard from './PlayerCard'

export default function Lobby() {
	const { room, joinCode, setJoinCode, isHost, myId } = useAppStore()
	const [loading, setLoading] = useState('')

	if (!room) {
		return (
			<div className='flex flex-col gap-[1.5vh]'>
				<p className='text-center text-[1.2vh] text-gray-300'>
					Tạo hoặc tham gia phòng (tối đa 4 phòng cùng lúc). Vào phòng sẽ được tele tới khu lobby riêng.
				</p>
				<Button
					className='w-full bg-red-700 hover:bg-red-600'
					disabled={loading === 'create'}
					onClick={async () => {
						setLoading('create')
						await fetchNui('createRoom')
						setLoading('')
					}}
				>
					{loading === 'create' ? 'Đang tạo...' : 'Tạo phòng mới'}
				</Button>
				<div className='flex gap-[0.8vh]'>
					<Input
						placeholder='Mã phòng (VD: ABC123)'
						value={joinCode}
						onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
						className='border-white/20 bg-black/30 text-[1.2vh] uppercase text-white'
					/>
					<Button
						variant='outline'
						disabled={!joinCode || loading === 'join'}
						onClick={async () => {
							setLoading('join')
							await fetchNui('joinRoom', { code: joinCode })
							setLoading('')
						}}
					>
						Vào
					</Button>
				</div>
			</div>
		)
	}

	const me = room.players.find((p) => p.source === myId)
	const allReady = room.players.every((p) => p.ready)
	const canStart = isHost() && room.playerCount >= room.minPlayers && allReady

	return (
		<div className='flex flex-col gap-[1.5vh]'>
			<div className='rounded-[0.5vh] bg-black/30 p-[1vh] text-center'>
				<p className='text-[1.8vh] font-bold tracking-widest text-amber-300'>{room.id}</p>
				{room.lobbyLabel && <p className='text-[1vh] text-amber-400/90'>{room.lobbyLabel}</p>}
				<p className='text-[1vh] text-white'>
					{room.playerCount}/{room.maxPlayers}
				</p>
				<p className='mt-[0.3vh] text-[0.9vh] text-gray-500'>Cần tối thiểu {room.minPlayers} người để bắt đầu trò chơi</p>
			</div>

			<div className='grid grid-cols-4 gap-[0.8vh]'>
				{room.players.map((player) => (
					<PlayerCard key={player.source} player={player} showReady />
				))}
			</div>

			<div className='flex flex-col gap-[0.8vh]'>
				<Button
					variant={me?.ready ? 'outline' : 'default'}
					onClick={() => fetchNui('setReady', { ready: !me?.ready }, 1)}
				>
					{me?.ready ? 'Hủy sẵn sàng' : 'Sẵn sàng'}
				</Button>

				{isHost() && (
					<Button
						className='bg-green-700 hover:bg-green-600'
						disabled={!canStart}
						onClick={() => fetchNui('startGame', {}, 1)}
					>
						Bắt đầu trò chơi
					</Button>
				)}

				<Button variant='destructive' onClick={() => fetchNui('leaveRoom', {}, 1)}>
					Rời phòng
				</Button>
			</div>
		</div>
	)
}
