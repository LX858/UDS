import { useAppStore } from '@/store/app'
import { ROLE_INFO } from '@/types'
import { Eye, FlaskConical, Heart, Crosshair, Moon } from 'lucide-react'

const roleIcons: Record<string, React.ReactNode> = {
	seer: <Eye className='h-[3vh] w-[3vh]' />,
	doctor: <Heart className='h-[3vh] w-[3vh]' />,
	witch: <FlaskConical className='h-[3vh] w-[3vh]' />,
	hunter: <Crosshair className='h-[3vh] w-[3vh]' />,
	werewolf: <Moon className='h-[3vh] w-[3vh]' />
}

export default function RoleCard() {
	const { room } = useAppStore()
	if (!room?.myRole) return null

	const info = ROLE_INFO[room.myRole]
	if (!info) return null

	return (
		<div
			className='mb-[1.5vh] rounded-[0.6vh] border p-[1.2vh]'
			style={{ borderColor: `${info.color}66`, background: `linear-gradient(135deg, ${info.color}22, transparent)` }}
		>
			<div className='flex items-center gap-[1vh]'>
				<div
					className='flex h-[5vh] w-[5vh] items-center justify-center rounded-full'
					style={{ backgroundColor: `${info.color}44`, color: info.color }}
				>
					{roleIcons[room.myRole] || roleIcons.werewolf}
				</div>
				<div>
					<p className='text-[1.6vh] font-bold' style={{ color: info.color }}>
						{info.label}
					</p>
					<p className='text-[1vh] text-gray-300'>{info.description}</p>
				</div>
			</div>

			{room.werewolfPartners && room.werewolfPartners.length > 0 && (
				<div className='mt-[0.8vh] rounded bg-red-950/30 p-[0.8vh] text-[1vh] text-red-300'>
					Đồng đội Ma Sói: {room.werewolfPartners.map((p) => p.name).join(', ')}
				</div>
			)}

			{room.investigateResult && (
				<div className='mt-[0.8vh] rounded bg-purple-950/30 p-[0.8vh] text-[1vh] text-purple-200'>
					Kết quả điều tra: <strong>{room.investigateResult.targetName}</strong> là{' '}
					<strong>{room.investigateResult.result}</strong>
				</div>
			)}

			{room.witchPotions && (
				<div className='mt-[0.8vh] flex gap-[1vh] text-[1vh]'>
					<span className={room.witchPotions.save ? 'text-green-400' : 'text-gray-600'}>
						💊 Cứu: {room.witchPotions.save ? 'Còn' : 'Hết'}
					</span>
					<span className={room.witchPotions.poison ? 'text-red-400' : 'text-gray-600'}>
						☠️ Độc: {room.witchPotions.poison ? 'Còn' : 'Hết'}
					</span>
				</div>
			)}
		</div>
	)
}
