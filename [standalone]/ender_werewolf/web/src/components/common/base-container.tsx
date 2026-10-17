import { ReactNode } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { cn } from '@/lib/utils'
import { Icon } from '@iconify/react'

export interface BaseTab {
	id: string
	label: string
	icon: string
	description?: string
}

export interface BaseContainerProps {
	visible: boolean
	title: string
	subtitle: string
	headerComponent?: ReactNode
	tabs: readonly BaseTab[]
	activeTab: string
	sidebarTitle?: string
	children: ReactNode
	closeButtonText?: string
	className?: string
	onTabChange: (tabId: string) => void
	onClose: () => void
}

export default function BaseContainer(props: BaseContainerProps) {
	const {
		visible,
		title,
		subtitle,
		headerComponent,
		tabs,
		activeTab,
		sidebarTitle = 'tổng quan',
		children,
		closeButtonText = 'thoát',
		className = '',
		onTabChange,
		onClose
	} = props

	return (
		<AnimatePresence>
			{visible && (
				<motion.div
					initial={{ opacity: 0, scale: 0.95 }}
					animate={{ opacity: 1, scale: 1 }}
					exit={{ opacity: 0, scale: 0.95 }}
					transition={{
						duration: 0.25,
						ease: [0.43, 0.13, 0.23, 0.96]
					}}
					className={cn('absolute inset-0 flex items-center justify-center', className)}
				>
					<div className='relative h-[78vh] w-[72vw] overflow-hidden rounded-[1.25vh] border border-[#4d4d4d] bg-[url("https://cdn.jsdelivr.net/gh/enderit171/cdn_underlord@main/gta5nrp_core/assets/inv_bg.png")] bg-[length:100%_100%] bg-center bg-no-repeat px-[2vh]'>
						<div className='flex h-full w-full items-center'>
							<div className='pointer-events-none absolute -left-[14vh] -top-[21vh] z-0 size-[50vh] bg-[url("https://cdn.jsdelivr.net/gh/enderit171/cdn_underlord@main/images/element_1.webp")] bg-full-size bg-full-center bg-no-repeat' />
							<div className='pointer-events-none absolute -bottom-[23vh] -right-[25vh] z-0 size-[50vh] bg-[url("https://cdn.jsdelivr.net/gh/enderit171/cdn_underlord@main/images/element_1.webp")] bg-full-size bg-full-center bg-no-repeat' />
							<div className='pointer-events-none absolute -right-[16vh] -top-[18vh] z-0 size-[50vh] bg-[url("https://cdn.jsdelivr.net/gh/enderit171/cdn_underlord@main/images/element_1.webp")] bg-full-size bg-full-center bg-no-repeat' />

							<div className='relative z-[1] flex h-full w-[20%] flex-col gap-[3vh] border-r-[.1vh] border-r-[#4d4d4d] py-[2.4vh]'>
								<div className='flex h-[10%] w-full items-center gap-[1vh]'>
									<img
										src='https://cdn.jsdelivr.net/gh/enderit171/cdn_underlord@main/images/hud/logo.webp'
										alt=''
										className='h-[6vh] w-[6.45vh] object-cover'
									/>
									<div className='flex flex-col gap-[.55vh]'>
										<h1 className='text-[2.25vh] font-semibold uppercase text-[#b292f7] drop-shadow-[0_0_1vh_#b292f7]'>
											{title}
										</h1>
										<h2 className='text-[1.65vh] font-normal'>{subtitle}</h2>
									</div>
								</div>

								<div className='h-[90%] w-full'>
									<h1 className='mb-[1.5vh] text-[1.55vh] font-normal capitalize'>{sidebarTitle}</h1>
									<div className='max-h-[54vh] w-full overflow-y-auto overflow-x-hidden pr-[1.75vh]'>
										{tabs.map(({ id, label, icon }) => (
											<button
												key={id}
												className={`group mb-[.85vh] flex h-[5vh] w-full items-center gap-[.75vh] rounded-[.5vh] border-none px-[1.35vh] outline-none transition-all duration-250 last:mb-0 hover:bg-[#b292f7] ${activeTab === id ? 'bg-[#b292f7]' : ''}`}
												onClick={(e) => {
													e.preventDefault()
													onTabChange(id)
												}}
											>
												<Icon
													icon={icon}
													className={`size-[2.25vh] transition-all duration-250 group-hover:text-white ${activeTab === id ? 'text-white' : 'text-[#9b9b9b]'}`}
												/>
												<span
													className={`text-[1.55vh] font-medium capitalize transition-all duration-250 group-hover:text-white ${activeTab === id ? 'text-white' : 'text-[#9b9b9b]'}`}
												>
													{label}
												</span>
											</button>
										))}
									</div>

									<div className='absolute bottom-[2vh] left-0 w-full pr-[2vh]'>
										<button
											className='flex h-[4.5vh] w-full items-center justify-center gap-[.55vh] rounded-[.5vh] border-none bg-[#ff4747] outline-none transition-all duration-250 hover:opacity-75'
											onClick={(e) => {
												e.preventDefault()
												onClose()
											}}
										>
											<Icon icon='ic:round-logout' className='size-[2vh]' />
											<span className='text-[1.45vh] font-medium capitalize text-white'>
												{closeButtonText}
											</span>
										</button>
									</div>
								</div>
							</div>

							<div className='z-[1] flex h-full w-[80%] flex-col p-[3vh_0_3vh_2vh]'>
								{headerComponent}

								<AnimatePresence mode='wait'>
									<motion.div
										key={activeTab}
										initial={{ opacity: 0, x: 8 }}
										animate={{ opacity: 1, x: 0 }}
										exit={{ opacity: 0, x: -8 }}
										transition={{
											duration: 0.25,
											ease: [0.43, 0.13, 0.23, 0.96]
										}}
										className={`w-full ${headerComponent ? 'h-[90%]' : 'h-full'}`}
									>
										{children}
									</motion.div>
								</AnimatePresence>
							</div>
						</div>
					</div>
				</motion.div>
			)}
		</AnimatePresence>
	)
}
