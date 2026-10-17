import { useAppStore } from '@/store/app'
import { fetchNui } from '@/utils'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { ScrollArea } from '@/components/ui/scroll-area'
import PlayerCard from './PlayerCard'
import RoleCard from './RoleCard'

export default function GameBoard() {
	const { room } = useAppStore()
	const [selected, setSelected] = useState<number | null>(null)

	if (!room) return null

	const displayPlayers = room.players.filter((p) => p.alive || p.disconnected)
	const selectable = room.canAct

	const handleAction = async (action: string) => {
		if (room.actionType === 'vote') {
			await fetchNui('vote', { target: selected })
		} else if (room.actionType === 'hunter') {
			await fetchNui('hunterShot', { target: selected })
		} else {
			await fetchNui('nightAction', { action, target: selected })
		}
		setSelected(null)
	}

	const actionLabel = () => {
		switch (room.actionType) {
			case 'werewolf':
				return 'Chọn nạn nhân'
			case 'doctor':
				return 'Chọn người bảo vệ'
			case 'seer':
				return 'Chọn người điều tra'
			case 'vote':
				return 'Bỏ phiếu loại'
			case 'hunter':
				return 'Chọn người bắn'
			case 'witch':
				return 'Chọn lọ cứu hoặc độc'
			default:
				return null
		}
	}

	return (
		<div className='flex flex-col gap-[1.2vh]'>
			<RoleCard />

			{room.state === 'day' && !room.pendingHunter && !room.canAct && (
				<div className='rounded-[0.5vh] bg-amber-950/30 p-[1vh] text-center text-[1.1vh] text-amber-200'>
					{room.myAlive
						? 'Ban ngày - thảo luận người còn sống trong sảnh.'
						: 'Bạn đã chết, chỉ quan sát, không thể nói.'}
				</div>
			)}

			{room.state === 'night' && !room.canAct && (
				<div className='rounded-[0.5vh] bg-indigo-950/30 p-[1vh] text-center text-[1.1vh] text-indigo-200'>
					{room.myAlive
						? 'Ban đêm — im lặng. Chờ lượt hành động của bạn.'
						: 'Bạn đã chết, đang ở khu quan sát.'}
				</div>
			)}

			{room.state === 'night' && room.canAct && room.actionType === 'werewolf' && (
				<div className='rounded-[0.5vh] bg-red-950/30 p-[1vh] text-center text-[1.1vh] text-red-200'>
					Ma Sói: giữ phím radio (LMENU) để nói — chỉ đồng đội trên kênh nghe được.
				</div>
			)}

			<div className='grid grid-cols-4 gap-[0.6vh]'>
				{displayPlayers.map((player) => (
					<PlayerCard
						key={player.source}
						player={player}
						selected={selected === player.source}
						disabled={!selectable || player.isMe || player.disconnected}
						onClick={() => setSelected(player.source)}
					/>
				))}
			</div>

			{selectable && actionLabel() && (
				<div className='flex flex-col gap-[0.6vh]'>
					<p className='text-center text-[1.1vh] text-white'>{actionLabel()}</p>

					{room.actionType === 'witch' && (
						<div className='flex gap-[0.6vh]'>
							{room.witchPotions?.save && room.werewolfTarget && (
								<Button
									className='flex-1 bg-green-700'
									onClick={() =>
										fetchNui('nightAction', { action: 'save', target: room.werewolfTarget })
									}
								>
									Dùng lọ cứu
								</Button>
							)}
							{room.witchPotions?.poison && (
								<Button
									className='flex-1 bg-red-800'
									disabled={!selected}
									onClick={() => handleAction('poison')}
								>
									Dùng lọ độc
								</Button>
							)}
							<Button
								variant='outline'
								className='flex-1'
								onClick={() => fetchNui('nightAction', { action: 'skip', target: null })}
							>
								Bỏ qua
							</Button>
						</div>
					)}

					{room.actionType !== 'witch' && (
						<div className='flex gap-[0.6vh]'>
							<Button className='flex-1' disabled={!selected} onClick={() => handleAction('select')}>
								Xác nhận
							</Button>
							{(room.actionType === 'vote' || room.actionType === 'werewolf') && (
								<Button
									variant='outline'
									className='flex-1'
									onClick={() =>
										room.actionType === 'vote'
											? fetchNui('vote', { target: null })
											: fetchNui('nightAction', { action: 'skip', target: null })
									}
								>
									Bỏ phiếu trắng
								</Button>
							)}
						</div>
					)}
				</div>
			)}

			{room.logs.length > 0 && (
				<ScrollArea className='h-[10vh] w-full rounded-[0.5vh] bg-black/40'>
					<div className='space-y-[0.3vh] p-[0.8vh]'>
						{room.logs
							.slice()
							.reverse()
							.slice(0, 8)
							.map((log, i) => (
								<p key={i} className='text-[0.95vh] text-gray-400'>
									• {log.text}
								</p>
							))}
					</div>
				</ScrollArea>
			)}

			{/* <p className='text-center text-[0.9vh] text-gray-500'>Không thể rời phòng khi trận đang diễn ra</p> */}
		</div>
	)
}
