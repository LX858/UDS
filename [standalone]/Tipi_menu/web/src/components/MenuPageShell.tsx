import { Box } from 'lr-components'
import { motion } from 'framer-motion'
import React from 'react'
import Category from './Category'
import { useMenuPanelLayout } from '../hooks/useMenuPanelLayout'
import { motionPageInitial } from '../utils/misc'

const variants = {
	hidden: { opacity: 0 },
	visible: { opacity: 1 },
}

type MenuPageShellProps = {
	/** Trang đang hiển thị (so với store.page) */
	active: boolean
	children: React.ReactNode
	/** false = Main (viền đặt trong children) */
	showPanelChrome?: boolean
	className?: string
}

function MenuPageShell({ active, children, showPanelChrome = true, className }: MenuPageShellProps) {
	const layout = useMenuPanelLayout()

	if (!active) {
		return null
	}

	return (
		<Box width={'100%'} height={'100%'} position='absolute'>
			<Box width={'100%'} height={'100%'} position='relative'>
				<Category />
				<motion.div
					initial={motionPageInitial()}
					animate='visible'
					variants={variants}
					transition={{ type: 'spring', stiffness: 100 }}
					className='mp-menu-panel'
					style={{
						width: layout.width,
						height: layout.height,
						position: 'absolute',
						left: '50%',
						transform: 'translateX(-50%)',
						top: layout.top,
					}}>
					{showPanelChrome ? (
						<Box
							width={'100%'}
							height={'100%'}
							position='relative'
							backgroundColor='var(--bg-card)'
							border={'1px solid var(--border-dim)'}
							rBorderRadius={4}
							className={className}>
							{children}
						</Box>
					) : (
						<Box width={'100%'} height={'100%'} position='relative' className={className}>
							{children}
						</Box>
					)}
				</motion.div>
			</Box>
		</Box>
	)
}

export default MenuPageShell
