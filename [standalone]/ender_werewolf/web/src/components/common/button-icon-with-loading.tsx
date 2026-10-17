import React, { useState } from 'react'
import { Button } from '@/components/ui/button'
import { useAppStore } from '@/store/app'
import { cn } from '@/lib/utils'
import { Spinner } from '@/components/ui/spinner'
import { Icon } from '@iconify/react'

interface ButtonIconWithLoadingProps {
	title?: string | React.ReactNode
	loadingTitle?: string | React.ReactNode
	loadingTextColor?: string
	loadingTextSize?: string
	className?: string
	buttonId?: string
	icon: string
	iconClassName?: string
	disabled?: boolean
	style?: React.CSSProperties
	onClick?: (ev: React.MouseEvent<HTMLButtonElement, MouseEvent>) => void
	onLoadingChange?: (isLoading: boolean, buttonId?: string) => void
}

const ButtonIconWithLoading = ({
	title,
	loadingTitle,
	loadingTextColor,
	loadingTextSize,
	className,
	buttonId,
	icon,
	iconClassName,
	disabled = false,
	style,
	onClick,
	onLoadingChange
}: ButtonIconWithLoadingProps) => {
	const [localLoading, setLocalLoading] = useState<boolean>(false)
	const { loadingState, setLoadingState } = useAppStore()

	const isLoading = buttonId ? loadingState[buttonId] : localLoading

	const handleClick = async (ev: React.MouseEvent<HTMLButtonElement, MouseEvent>) => {
		if (disabled || isLoading) return

		try {
			// Set loading state for this specific button
			if (buttonId) {
				setLoadingState?.(buttonId, true)
			} else {
				setLocalLoading(true)
			}
			onLoadingChange?.(true, buttonId)

			await new Promise((resolve) => setTimeout(resolve, 1000))
			onClick?.(ev)
		} catch (error: any) {
			console.log('handleClick thất bại', error)
			/* hudService.addNotification({
				title: 'Thất Bại',
				description: error.message,
				type: 'error',
				time: 5000,
				hidden: false
			}) */
		} finally {
			if (buttonId) {
				setLoadingState?.(buttonId, false)
			} else {
				setLocalLoading(false)
			}
			onLoadingChange?.(false, buttonId)
		}
	}

	const isDisabled = disabled || isLoading

	return (
		<Button
			className={cn(
				'overflow-hidden',
				className,
				isDisabled && 'pointer-events-none opacity-75 transition-all duration-250'
			)}
			onClick={handleClick}
			data-button-id={buttonId}
			style={style}
			disabled={isDisabled}
			type='button'
		>
			{!isLoading ? (
				<>
					<Icon icon={icon} className={iconClassName} />
					<span>{title}</span>
				</>
			) : (
				<>
					<Icon
						icon={icon}
						className={iconClassName}
						style={{
							color: loadingTextColor ? loadingTextColor : 'initial'
						}}
					/>
					<div className='flex items-center gap-1'>
						<span
							className={`${loadingTextColor ? '' : 'text-white'} `}
							style={loadingTextColor ? { color: loadingTextColor } : {}}
						>
							{loadingTitle || 'Đang xử lý'}
						</span>
						<Spinner style={loadingTextColor ? { color: loadingTextColor } : {}} />
					</div>
				</>
			)}
		</Button>
	)
}

export default ButtonIconWithLoading
