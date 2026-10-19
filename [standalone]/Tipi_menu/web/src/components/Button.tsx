import { useWindowSize } from 'lr-components'
import React, { useState } from 'react'
import styled from 'styled-components'
import buttonSvg from '../assets/xn-case/button.svg?url'
import buttonActiveSvg from '../assets/xn-case/button-active.svg?url'

export type ButtonProps = {
	text: string
	rWidth?: number
	rHeight?: number
	rFontSize?: number
	active?: boolean
	disabled?: boolean
	cursor?: string
	pointerEvents?: React.CSSProperties['pointerEvents']
	className?: string
	onClick?: React.MouseEventHandler<HTMLButtonElement>
} & Omit<React.ButtonHTMLAttributes<HTMLButtonElement>, 'onClick'>

const Shell = styled.button<{ $width: number; $height: number; $disabled?: boolean }>`
	position: relative;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	width: ${(p) => p.$width}px;
	height: ${(p) => p.$height}px;
	padding: 0 14px;
	border: none;
	background-color: transparent;
	cursor: ${(p) => (p.$disabled ? 'not-allowed' : 'pointer')};
	isolation: isolate;
	opacity: ${(p) => (p.$disabled ? 0.55 : 1)};
	transition: filter 0.15s ease, transform 0.1s ease, opacity 0.15s ease;

	&:hover:not(:disabled) {
		filter: brightness(1.15);
	}

	&:active:not(:disabled) {
		transform: scale(0.96);
	}
`

const Label = styled.span<{ $fontSize: number }>`
	position: relative;
	z-index: 1;
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: ${(p) => p.$fontSize}px;
	font-weight: 500;
	text-transform: uppercase;
	letter-spacing: 0.04em;
	line-height: 1;
	white-space: nowrap;
	color: cyan;
	text-shadow: 0 0 8px rgba(0, 255, 255, 0.3);
	pointer-events: none;
`

function Button({
	text,
	rWidth = 140,
	rHeight = 40,
	rFontSize,
	active = false,
	disabled = false,
	cursor,
	pointerEvents,
	className,
	onClick,
	...rest
}: ButtonProps) {
	const windowSize = useWindowSize()
	const [hover, setHover] = useState(false)

	const width = Math.max(windowSize.ratioWidth * rWidth, rWidth * 0.85)
	const height = Math.max(windowSize.ratioWidth * rHeight, rHeight * 0.85)
	const fontSize = rFontSize
		? Math.max(windowSize.ratioWidth * rFontSize, 10)
		: Math.max(windowSize.ratioWidth * 12, 10)

	const showActiveBg = !disabled && (active || hover)
	const bgUrl = showActiveBg ? buttonActiveSvg : buttonSvg

	return (
		<Shell
			type='button'
			$width={width}
			$height={height}
			$disabled={disabled}
			disabled={disabled}
			className={className}
			style={{
				backgroundImage: `url(${bgUrl})`,
				backgroundSize: '100% 100%',
				backgroundRepeat: 'no-repeat',
				backgroundPosition: 'center',
				cursor: disabled ? 'not-allowed' : cursor,
				pointerEvents,
			}}
			onMouseEnter={() => !disabled && setHover(true)}
			onMouseLeave={() => setHover(false)}
			onClick={disabled ? undefined : onClick}
			{...rest}>
			<Label $fontSize={fontSize}>{text}</Label>
		</Shell>
	)
}

export default Button
