import { Box, Text } from 'lr-components'
import React from 'react'
import styled, { css } from 'styled-components'
import { EVENT_CARD_CDN } from '../constants/eventCards'
import { menuCardBase } from '../styles/menuCardStyles'

export const developingCardStyles = css`
	position: relative;
	overflow: hidden;
	border-color: rgba(255, 255, 255, 0.16);
	filter: grayscale(1);
`

const DevelopingBg = styled(Box)`
	position: absolute;
	inset: 0;
	z-index: 0;
	background-image: url(${EVENT_CARD_CDN.comingSoon});
	background-size: cover;
	background-position: center center;
	background-repeat: no-repeat;
	filter: grayscale(1);
	pointer-events: none;
`

const DevelopingScrim = styled(Box)`
	position: absolute;
	inset: 0;
	z-index: 1;
	background: rgba(0, 8, 16, 0.42);
	pointer-events: none;
`

const DevelopingShell = styled(Box)<{ $fill?: boolean }>`
	${menuCardBase}
	${developingCardStyles}
	width: 100%;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	text-align: center;
	padding: 16px 12px;
	box-sizing: border-box;
	gap: 8px;
	${(p) =>
		p.$fill &&
		css`
			flex: 1;
			min-height: 0;
		`}
`

const DevelopingInner = styled(Box)`
	position: relative;
	z-index: 2;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	text-align: center;
	gap: 8px;
	width: 100%;
	height: 100%;
	min-height: 0;
`

export const DevelopingBody = styled(Box)`
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	text-align: center;
	gap: 8px;
	width: 100%;
	height: 100%;
	min-height: 0;
`

const DevelopingBadge = styled(Box)`
	padding: 5px 12px;
	border-radius: 999px;
	border: 1px solid rgba(255, 255, 255, 0.28);
	background: rgba(0, 0, 0, 0.45);
	backdrop-filter: blur(4px);
`

type DevelopingCardBlockProps = {
	title: string
	description?: string
	fill?: boolean
	compact?: boolean
	className?: string
}

export function DevelopingCardBlock({
	title,
	description,
	fill = false,
	compact = false,
	className,
}: DevelopingCardBlockProps) {
	return (
		<DevelopingShell $fill={fill} className={className}>
			<DevelopingBg />
			<DevelopingScrim />
			<DevelopingInner>
				<DevelopingBadge>
					<Text
						rFontSize={compact ? 8 : 9}
						fontWeight='bold'
						textTransform='uppercase'
						color='rgba(255,255,255,0.92)'>
						{title}
					</Text>
				</DevelopingBadge>
				{description && (
					<Text
						rFontSize={compact ? 10 : 11}
						color='rgba(255,255,255,0.72)'
						textTransform='uppercase'
						lineHeight={1.45}>
						{description}
					</Text>
				)}
			</DevelopingInner>
		</DevelopingShell>
	)
}

export function DevelopingCardContent({
	title,
	description,
	compact = false,
}: Omit<DevelopingCardBlockProps, 'fill' | 'className'>) {
	return (
		<DevelopingBody>
			<DevelopingBadge>
				<Text
					rFontSize={compact ? 8 : 9}
					fontWeight='bold'
					textTransform='uppercase'
					color='rgba(255,255,255,0.92)'>
					{title}
				</Text>
			</DevelopingBadge>
			{description && (
				<Text
					rFontSize={compact ? 10 : 11}
					color='rgba(255,255,255,0.72)'
					textTransform='uppercase'
					lineHeight={1.45}>
					{description}
				</Text>
			)}
		</DevelopingBody>
	)
}

export default DevelopingCardBlock
