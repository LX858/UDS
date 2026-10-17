import { useAppStore } from '@/store/app'
import { DEBUG_GROUPS, DEBUG_PRESETS } from '@/mocks/roomStates'
import { isEnvBrowser } from '@/utils'
import { Button } from '@/components/ui/button'
import { ScrollArea } from '@/components/ui/scroll-area'
import { cn } from '@/lib/utils'
import { useState } from 'react'
import { Bug, ChevronDown, ChevronUp, Eye, EyeOff } from 'lucide-react'

export default function DebugPanel() {
	const { visible, room, setVisible, setRoomState } = useAppStore()
	const [collapsed, setCollapsed] = useState(false)
	const [activePreset, setActivePreset] = useState<string | null>('lobby')

	if (!isEnvBrowser()) return null

	const applyPreset = (presetId: string) => {
		const preset = DEBUG_PRESETS.find((p) => p.id === presetId)
		if (!preset) return
		setActivePreset(presetId)
		setRoomState(preset.room)
		setVisible(true)
	}

	return (
		<div className='pointer-events-auto fixed bottom-[2vh] left-[2vh] z-[9999] w-[28vh]'>
			<div className='overflow-hidden rounded-[0.8vh] border border-amber-500/40 bg-[#0d0d14]/95 shadow-2xl backdrop-blur-sm'>
				<button
					type='button'
					onClick={() => setCollapsed((v) => !v)}
					className='flex w-full items-center justify-between bg-amber-500/15 px-[1.2vh] py-[0.8vh] text-left'
				>
					<span className='flex items-center gap-[0.6vh] text-[1.1vh] font-semibold text-amber-300'>
						<Bug className='h-[1.6vh] w-[1.6vh]' />
						Debug Panel
					</span>
					{collapsed ? (
						<ChevronUp className='h-[1.6vh] w-[1.6vh] text-amber-300' />
					) : (
						<ChevronDown className='h-[1.6vh] w-[1.6vh] text-amber-300' />
					)}
				</button>

				{!collapsed && (
					<div className='flex max-h-[50vh] flex-col gap-[1vh] overflow-y-auto p-[1vh]'>
						<div className='flex flex-col gap-[1vh] p-[1vh]'>
						<div>
							<p className='mb-[0.5vh] text-[0.9vh] font-medium uppercase tracking-wide text-gray-500'>UI</p>
							<div className='flex flex-wrap gap-[0.5vh]'>
								<Button
									size='sm'
									variant={visible ? 'default' : 'outline'}
									className='h-auto px-[0.8vh] py-[0.4vh] text-[0.95vh]'
									onClick={() => setVisible(true)}
								>
									<Eye className='mr-[0.3vh] h-[1.2vh] w-[1.2vh]' />
									Hiện UI
								</Button>
								<Button
									size='sm'
									variant={!visible ? 'default' : 'outline'}
									className='h-auto px-[0.8vh] py-[0.4vh] text-[0.95vh]'
									onClick={() => setVisible(false)}
								>
									<EyeOff className='mr-[0.3vh] h-[1.2vh] w-[1.2vh]' />
									Ẩn UI
								</Button>
								<Button
									size='sm'
									variant='outline'
									className='h-auto px-[0.8vh] py-[0.4vh] text-[0.95vh]'
									onClick={() => {
										setRoomState(null)
										setActivePreset('no-room')
										setVisible(true)
									}}
								>
									Reset
								</Button>
							</div>
						</div>

						{DEBUG_GROUPS.filter((g) => g !== 'UI').map((group) => (
							<div key={group}>
								<p className='mb-[0.5vh] text-[0.9vh] font-medium uppercase tracking-wide text-gray-500'>{group}</p>
								<div className='flex flex-wrap gap-[0.5vh]'>
									{DEBUG_PRESETS.filter((p) => p.group === group).map((preset) => (
										<Button
											key={preset.id}
											size='sm'
											variant={activePreset === preset.id ? 'default' : 'outline'}
											className={cn(
												'h-auto px-[0.8vh] py-[0.4vh] text-[0.95vh]',
												activePreset === preset.id && 'bg-amber-600 hover:bg-amber-500'
											)}
											onClick={() => applyPreset(preset.id)}
										>
											{preset.label}
										</Button>
									))}
								</div>
							</div>
						))}

						{room && (
							<div className='rounded-[0.5vh] bg-white/5 p-[0.8vh] text-[0.85vh] text-gray-400'>
								<p>
									State: <span className='text-white'>{room.state}</span>
									{room.nightPhase && (
										<>
											{' '}
											/ <span className='text-indigo-300'>{room.nightPhase}</span>
										</>
									)}
								</p>
								<p>
									Role: <span className='text-amber-300'>{room.myRole ?? '—'}</span>
								</p>
								<p>
									canAct: <span className='text-white'>{String(room.canAct)}</span>
								</p>
							</div>
						)}
						</div>
					</div>
				)}
			</div>
		</div>
	)
}
