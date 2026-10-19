import { Box, Text } from 'lr-components'
import React, { ReactNode } from 'react'
import styled from 'styled-components'
import { motion } from 'framer-motion'
import Button from './Button'
import { css } from 'styled-components'
import { menuCardBase, menuCardHover } from '../styles/menuCardStyles'

const EventCard = styled(motion.div)<{ $disabled?: boolean; $hasBackground?: boolean }>`
	${menuCardBase}
	width: 100%;
	height: 100%;
	min-height: 0;
	cursor: ${(p) => (p.$disabled ? 'not-allowed' : 'pointer')};
	opacity: ${(p) => (p.$disabled ? 0.72 : 1)};
	filter: ${(p) => (p.$disabled ? 'brightness(0.88) saturate(0.85)' : 'none')};

	&:hover {
		${(p) => !p.$disabled && !p.$hasBackground && menuCardHover}
		${(p) =>
			!p.$disabled &&
			p.$hasBackground &&
			css`
				border-color: var(--border);
			`}
	}
`

const CardBody = styled(Box)<{ $variant?: 'hero' | 'tile' | 'banner'; $hasBackground?: boolean }>`
	position: relative;
	z-index: 1;
	height: 100%;
	display: flex;
	flex-direction: ${(p) => (p.$variant === 'banner' ? 'row' : 'column')};
	align-items: ${(p) => (p.$variant === 'banner' ? 'stretch' : 'stretch')};
	padding: ${(p) => {
		if (p.$variant === 'banner' && p.$hasBackground) return '0'
		if (p.$variant === 'banner') return '12px 14px'
		if (p.$hasBackground) return '0'
		return '16px'
	}};
	box-sizing: border-box;
	min-height: 0;
	gap: ${(p) => (p.$variant === 'banner' ? '10px' : '0')};
`

const CardContent = styled(Box)`
	flex: 1;
	min-width: 0;
	display: flex;
	flex-direction: column;
	justify-content: space-between;
	min-height: 0;
	z-index: 2;
`

const CardHeader = styled(Box)<{ $hero?: boolean; $banner?: boolean }>`
	flex-shrink: 0;
	max-width: ${(p) => (p.$banner ? '100%' : p.$hero ? '52%' : '56%')};
`

const CardSubtitle = styled(Text)`
	display: block;
	margin-top: 6px;
	line-height: 1.45;
	color: var(--text-sub);
	text-transform: uppercase;
	letter-spacing: 0.04em;
`

const CardVisual = styled(Box)<{ $banner?: boolean }>`
	flex: ${(p) => (p.$banner ? '0 0 44%' : '1')};
	min-height: 0;
	position: relative;
	margin: ${(p) => (p.$banner ? '0' : '4px 0')};
`

const CardArt = styled.img<{ $hero?: boolean; $banner?: boolean }>`
	position: absolute;
	right: 0;
	top: 50%;
	transform: translateY(-50%);
	height: ${(p) => (p.$banner ? '100%' : p.$hero ? '98%' : '94%')};
	max-width: ${(p) => (p.$banner ? '100%' : p.$hero ? '72%' : '82%')};
	object-fit: contain;
	object-position: ${(p) => (p.$banner ? 'right center' : 'right center')};
	pointer-events: none;
	user-select: none;
	filter: drop-shadow(0 12px 32px rgba(0, 0, 0, 0.5));
`

const CardFooter = styled(Box)`
	flex-shrink: 0;
	display: flex;
	align-items: center;
	gap: 8px;
	padding-top: 8px;
`

const CardBackground = styled(Box)<{
	$src: string
	$opacity?: number
	$cover?: boolean
	$contain?: boolean
	$position?: string
	$poster?: boolean
}>`
	position: absolute;
	inset: 0;
	z-index: 0;
	background-color: ${(p) => (p.$poster ? 'rgba(0, 8, 18, 0.4)' : 'rgba(0, 5, 12, 0.98)')};
	${(p) => p.$opacity != null && `opacity: ${p.$opacity};`}
	background-image: url(${(p) => p.$src});
	background-size: ${(p) => {
		if (p.$contain) return 'contain'
		if (p.$cover) return 'cover'
		return '100% 100%'
	}};
	background-position: ${(p) => p.$position || 'center center'};
	background-repeat: no-repeat;
	pointer-events: none;
	transition: transform 0.35s ease, filter 0.35s ease;
`

const PosterCardRoot = styled(EventCard)`
	display: flex;
	flex-direction: column;
	overflow: hidden;

	&[data-enabled='true'] {
		border-color: var(--border);
		box-shadow: 0 0 20px rgba(0, 229, 255, 0.14), inset 0 1px 0 rgba(0, 229, 255, 0.1);

		${CardBackground} {
			filter: brightness(1.06) saturate(1.08);
		}
	}

	&[data-enabled='false'] ${CardBackground} {
		filter: brightness(0.78) saturate(0.72);
	}

	&[data-grayscale='true'] ${CardBackground} {
		filter: grayscale(1) brightness(0.88);
	}

	&[data-grayscale='true'][data-enabled='false'] ${CardBackground} {
		filter: grayscale(1) brightness(0.78);
	}

	&:hover:not([data-disabled='true']) {
		border-color: var(--border);
		box-shadow: 0 8px 28px rgba(0, 0, 0, 0.42), 0 0 0 1px rgba(0, 229, 255, 0.08);

		${CardBackground} {
			transform: scale(1.015);
			filter: brightness(1.1) saturate(1.1);
		}
	}
`

const PosterMedia = styled(Box)`
	position: relative;
	flex: 1;
	min-height: 0;
	overflow: hidden;
	display: flex;
	flex-direction: column;
`

const PosterTopScrim = styled(Box)`
	position: absolute;
	left: 0;
	right: 0;
	top: 0;
	height: 22%;
	z-index: 1;
	pointer-events: none;
	background: linear-gradient(180deg, rgba(0, 6, 14, 0.55) 0%, transparent 100%);
`

const PosterDock = styled(Box)`
	position: absolute;
	left: 0;
	right: 0;
	bottom: 0;
	z-index: 2;
	display: flex;
	flex-direction: column;
	gap: 8px;
	padding: 40px 8px 8px;
	box-sizing: border-box;
	background: linear-gradient(
		0deg,
		rgba(0, 4, 10, 0.99) 0%,
		rgba(0, 6, 14, 0.96) 28%,
		rgba(0, 8, 18, 0.78) 52%,
		rgba(0, 10, 22, 0.28) 72%,
		rgba(0, 10, 22, 0) 100%
	);

	&::before {
		content: '';
		position: absolute;
		left: 8px;
		right: 8px;
		top: 0;
		height: 1px;
		background: linear-gradient(
			90deg,
			transparent 0%,
			rgba(0, 229, 255, 0.35) 18%,
			rgba(0, 229, 255, 0.35) 82%,
			transparent 100%
		);
		opacity: 0.9;
	}
`

const PosterTitleBlock = styled(Box)`
	position: relative;
	padding: 7px 9px 7px 10px;
	border-radius: 4px;
	background: linear-gradient(135deg, rgba(0, 14, 28, 0.96) 0%, rgba(0, 8, 18, 0.9) 100%);
	border: 1px solid rgba(0, 229, 255, 0.22);
	box-shadow:
		0 4px 14px rgba(0, 0, 0, 0.45),
		inset 0 1px 0 rgba(0, 229, 255, 0.1);

	&::before {
		content: '';
		position: absolute;
		left: 0;
		top: 7px;
		bottom: 7px;
		width: 2px;
		background: linear-gradient(180deg, transparent, var(--cyan) 45%, transparent);
		opacity: 0.85;
	}
`

const PosterTitle = styled(Text)`
	flex: 1;
	min-width: 0;
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-weight: 700;
	text-transform: uppercase;
	letter-spacing: 0.06em;
	color: #fff;
	line-height: 1.15;
	text-shadow:
		0 0 18px rgba(0, 229, 255, 0.42),
		0 2px 8px rgba(0, 0, 0, 0.98),
		0 0 2px rgba(0, 0, 0, 1);
	overflow: hidden;
	text-overflow: ellipsis;
	white-space: nowrap;
`

const TitleRow = styled(Box)`
	display: flex;
	align-items: center;
	gap: 7px;
	min-width: 0;
`

const EventTimeBadge = styled.span`
	flex-shrink: 0;
	display: inline-flex;
	align-items: center;
	padding: 4px 10px;
	border-radius: 4px;
	background: linear-gradient(135deg, rgba(0, 229, 255, 0.28) 0%, rgba(0, 160, 220, 0.2) 100%);
	border: 1px solid rgba(0, 229, 255, 0.85);
	color: #eafdff;
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 12px;
	font-weight: 700;
	letter-spacing: 0.04em;
	line-height: 1.3;
	white-space: nowrap;
	text-shadow: 0 0 6px rgba(0, 229, 255, 0.7), 0 1px 3px rgba(0, 0, 0, 0.95);
	box-shadow:
		0 2px 10px rgba(0, 0, 0, 0.5),
		0 0 12px rgba(0, 229, 255, 0.35),
		inset 0 0 10px rgba(0, 229, 255, 0.18);
`

const PosterSubtitle = styled(Text)`
	margin-top: 2px;
	font-size: 8px;
	line-height: 1.35;
	text-transform: uppercase;
	letter-spacing: 0.05em;
	color: rgba(190, 230, 255, 0.82);
	text-shadow: 0 1px 6px rgba(0, 0, 0, 0.85);
	display: -webkit-box;
	-webkit-line-clamp: 1;
	-webkit-box-orient: vertical;
	overflow: hidden;
`

const PosterActions = styled(Box)`
	display: flex;
	align-items: center;
	justify-content: flex-start;
	gap: 6px;
	flex-wrap: wrap;
`

const PosterDisabledVeil = styled(Box)`
	position: absolute;
	inset: 0;
	z-index: 4;
	pointer-events: none;
	background: rgba(0, 4, 10, 0.52);
`

const PosterEnabledGlow = styled(Box)`
	position: absolute;
	inset: 0;
	z-index: 1;
	pointer-events: none;
	box-shadow: inset 0 0 24px rgba(0, 229, 255, 0.12);
`

const CardPosterScrim = styled(Box)`
	position: absolute;
	inset: 0;
	z-index: 1;
	pointer-events: none;
	background:
		linear-gradient(180deg, rgba(0, 4, 12, 0.72) 0%, rgba(0, 4, 12, 0.08) 18%, transparent 32%),
		linear-gradient(0deg, rgba(0, 4, 12, 0.92) 0%, rgba(0, 4, 12, 0.55) 22%, transparent 42%);
`

const CardTitleBar = styled(Box)`
	flex: 1;
	min-width: 0;
	display: flex;
	flex-direction: column;
	justify-content: flex-end;
	gap: 2px;
	pointer-events: none;
`

const CardTitleText = styled(Text)`
	display: block;
	flex: 1;
	min-width: 0;
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-weight: 700;
	text-transform: uppercase;
	letter-spacing: 0.06em;
	color: #fff;
	text-shadow:
		0 0 18px rgba(0, 229, 255, 0.45),
		0 2px 8px rgba(0, 0, 0, 0.95),
		0 0 2px rgba(0, 0, 0, 1);
`

const CardTitleSubtitle = styled(Text)`
	display: block;
	margin-top: 4px;
	font-size: 9px;
	line-height: 1.35;
	text-transform: uppercase;
	letter-spacing: 0.05em;
	color: rgba(190, 230, 255, 0.92);
	text-shadow: 0 1px 6px rgba(0, 0, 0, 0.9);
`

const CardOverlay = styled(Box)`
	position: absolute;
	left: 12px;
	bottom: 10px;
	z-index: 3;
	pointer-events: none;
`

const CardActionBar = styled(Box)`
	position: absolute;
	left: 0;
	right: 0;
	bottom: 0;
	z-index: 4;
	display: flex;
	align-items: flex-end;
	justify-content: space-between;
	gap: 10px;
	padding: 32px 12px 12px;
	background: linear-gradient(
		0deg,
		rgba(0, 4, 12, 0.96) 0%,
		rgba(0, 6, 16, 0.82) 45%,
		rgba(0, 6, 16, 0) 100%
	);
	pointer-events: none;

	& > * {
		pointer-events: auto;
	}
`

const RulesButtonWrap = styled(Box)`
	flex-shrink: 0;
	padding: 2px;
	border-radius: 4px;
	border: 1px solid rgba(0, 229, 255, 0.55);
	background: linear-gradient(180deg, rgba(0, 18, 36, 0.92) 0%, rgba(0, 8, 18, 0.88) 100%);
	box-shadow:
		0 4px 16px rgba(0, 0, 0, 0.55),
		0 0 14px rgba(0, 229, 255, 0.18),
		inset 0 1px 0 rgba(0, 229, 255, 0.12);
`

export type EventCardProps = {
	title: ReactNode
	subtitle?: string
	eventTime?: string
	image?: string
	backgroundImage?: string
	backgroundOpacity?: number
	backgroundCover?: boolean
	backgroundContain?: boolean
	backgroundPosition?: string
	variant?: 'hero' | 'tile' | 'banner'
	layout?: 'default' | 'posterDock'
	enabled?: boolean
	backgroundGrayscale?: boolean
	onClick: () => void
	onJoinClick?: () => void
	children?: ReactNode
	showOpen?: boolean
	showJoinButton?: boolean
	openLabel?: string
	showRules?: boolean
	rulesLabel?: string
	onRulesClick?: () => void
}

export function EventCardBlock({
	title,
	subtitle,
	eventTime,
	image,
	backgroundImage,
	backgroundOpacity,
	backgroundCover = false,
	backgroundContain = false,
	backgroundPosition = 'center center',
	backgroundGrayscale = false,
	variant = 'tile',
	layout = 'default',
	enabled = true,
	onClick,
	onJoinClick,
	children,
	showOpen = true,
	showJoinButton = false,
	openLabel = 'Mở',
	showRules = false,
	rulesLabel = 'Thể lệ',
	onRulesClick,
}: EventCardProps) {
	const isHero = variant === 'hero'
	const isBanner = variant === 'banner'
	const isPosterDock = layout === 'posterDock'
	const hasBackground = Boolean(backgroundImage)
	const canJoin = enabled && showJoinButton && Boolean(onJoinClick || showOpen)

	const handleJoinClick = (e: React.MouseEvent) => {
		e.stopPropagation()
		if (!enabled || !showJoinButton) return
		if (onJoinClick) {
			onJoinClick()
			return
		}
		onClick()
	}

	if (isPosterDock && hasBackground) {
		const CardRoot = PosterCardRoot
		return (
			<CardRoot
				$disabled={!enabled}
				$hasBackground={hasBackground}
				data-enabled={enabled ? 'true' : 'false'}
				data-disabled={!enabled ? 'true' : undefined}
				data-grayscale={backgroundGrayscale ? 'true' : undefined}
				whileHover={enabled ? { y: -2 } : undefined}
				whileTap={enabled ? { scale: 0.985 } : undefined}
				transition={{ type: 'spring', stiffness: 380, damping: 28 }}
				onClick={enabled ? onClick : undefined}>
				<PosterMedia>
					<CardBackground
						$src={backgroundImage!}
						$opacity={backgroundOpacity}
						$cover={backgroundCover}
						$contain={backgroundContain}
						$position={backgroundPosition}
						$poster
					/>
					<PosterTopScrim />
					{enabled && <PosterEnabledGlow />}
					<PosterDock>
						<PosterTitleBlock minWidth={0}>
							<TitleRow>
								<PosterTitle rFontSize={13} rLineHeight={16}>
									{title}
								</PosterTitle>
								{eventTime && <EventTimeBadge>{eventTime}</EventTimeBadge>}
							</TitleRow>
							{subtitle && (
								<PosterSubtitle rFontSize={8}>{subtitle}</PosterSubtitle>
							)}
						</PosterTitleBlock>
						{(canJoin || (showRules && onRulesClick)) && (
							<PosterActions>
								{showRules && onRulesClick && (
									<Button
										rWidth={96}
										rHeight={30}
										rFontSize={10}
										text={rulesLabel}
										onClick={(e) => {
											e.stopPropagation()
											onRulesClick()
										}}
									/>
								)}
								{canJoin && (
									<Button
										rWidth={96}
										rHeight={30}
										rFontSize={10}
										text={openLabel}
										onClick={handleJoinClick}
									/>
								)}
							</PosterActions>
						)}
					</PosterDock>
					{!enabled && <PosterDisabledVeil />}
				</PosterMedia>
			</CardRoot>
		)
	}

	return (
		<EventCard
			$disabled={!enabled}
			$hasBackground={hasBackground}
			whileHover={enabled ? { y: -2 } : undefined}
			whileTap={enabled ? { scale: 0.985 } : undefined}
			transition={{ type: 'spring', stiffness: 380, damping: 28 }}
			onClick={enabled ? onClick : undefined}>
			{hasBackground && (
				<>
					<CardBackground
						$src={backgroundImage!}
						$opacity={backgroundOpacity}
						$cover={backgroundCover}
						$contain={backgroundContain}
						$position={backgroundPosition}
					/>
					{!isBanner && <CardPosterScrim />}
				</>
			)}
			<CardBody $variant={variant} $hasBackground={hasBackground}>
				{isBanner ? (
					<>
						<CardContent>
							<CardHeader $banner>
								{!hasBackground && title}
								{!hasBackground && subtitle && <CardSubtitle rFontSize={9}>{subtitle}</CardSubtitle>}
								{!(isBanner && hasBackground) && children}
							</CardHeader>

							{canJoin && (
								<CardFooter>
									<Button
										rWidth={132}
										rHeight={34}
										rFontSize={12}
										text={openLabel}
										onClick={handleJoinClick}
									/>
								</CardFooter>
							)}
						</CardContent>

						{isBanner && hasBackground && children && <CardOverlay>{children}</CardOverlay>}

						{!hasBackground && image && (
							<CardVisual $banner>
								<CardArt src={image} alt='' $banner draggable={false} />
							</CardVisual>
						)}
					</>
				) : (
					<>
						{!hasBackground && (
							<CardHeader $hero={isHero}>
								<Text
									rFontSize={isHero ? 26 : 16}
									fontWeight='bold'
									textTransform='uppercase'
									rLineHeight={isHero ? 32 : 22}
									textShadow='0 2px 14px rgba(0,0,0,0.6)'>
									{title}
								</Text>
								{subtitle && (
									<CardSubtitle rFontSize={isHero ? 11 : 10}>{subtitle}</CardSubtitle>
								)}
								{children}
							</CardHeader>
						)}

						{!hasBackground && image && (
							<CardVisual>
								<CardArt src={image} alt='' $hero={isHero} draggable={false} />
							</CardVisual>
						)}

						{!hasBackground &&
						((showRules && onRulesClick) || canJoin) ? (
							<CardFooter>
								{showRules && onRulesClick && (
									<Button
										rWidth={96}
										rHeight={30}
										rFontSize={11}
										text={rulesLabel}
										onClick={(e) => {
											e.stopPropagation()
											onRulesClick()
										}}
									/>
								)}
								{canJoin && (
									<Button
										rWidth={isHero ? 148 : 120}
										rHeight={isHero ? 40 : 34}
										rFontSize={isHero ? 13 : 12}
										text={openLabel}
										onClick={handleJoinClick}
									/>
								)}
							</CardFooter>
						) : null}
					</>
				)}
			</CardBody>

			{!isBanner && hasBackground && (
				<CardActionBar>
					<CardTitleBar>
						<TitleRow>
							<CardTitleText rFontSize={13} rLineHeight={17}>
								{title}
							</CardTitleText>
							{eventTime && <EventTimeBadge>{eventTime}</EventTimeBadge>}
						</TitleRow>
						{subtitle && (
							<CardTitleSubtitle rFontSize={8}>{subtitle}</CardTitleSubtitle>
						)}
					</CardTitleBar>
					{showRules && onRulesClick && (
						<RulesButtonWrap>
							<Button
								rWidth={112}
								rHeight={36}
								rFontSize={12}
								text={rulesLabel}
								onClick={(e) => {
									e.stopPropagation()
									onRulesClick()
								}}
							/>
						</RulesButtonWrap>
					)}
					{canJoin && (
						<RulesButtonWrap>
							<Button
								rWidth={isHero ? 148 : 120}
								rHeight={isHero ? 40 : 36}
								rFontSize={isHero ? 13 : 12}
								text={openLabel}
								onClick={handleJoinClick}
							/>
						</RulesButtonWrap>
					)}
				</CardActionBar>
			)}

		</EventCard>
	)
}

export const PointBalance = styled(Box)<{ $compact?: boolean }>`
	display: inline-flex;
	flex-direction: ${(p) => (p.$compact ? 'row' : 'column')};
	align-items: ${(p) => (p.$compact ? 'center' : 'flex-start')};
	align-self: flex-start;
	gap: ${(p) => (p.$compact ? '8px' : '7px')};
	margin-top: ${(p) => (p.$compact ? '0' : '10px')};
	padding: ${(p) => (p.$compact ? '5px 10px 5px 9px' : '10px 14px 10px 16px')};
	border-radius: 4px;
	background: linear-gradient(135deg, rgba(0, 16, 32, 0.88) 0%, rgba(0, 8, 18, 0.74) 100%);
	border: 1px solid rgba(0, 229, 255, 0.28);
	box-shadow:
		0 4px 14px rgba(0, 0, 0, 0.38),
		inset 0 1px 0 rgba(0, 229, 255, 0.08);
	position: relative;
	overflow: hidden;

	&::before {
		content: '';
		position: absolute;
		left: 0;
		top: ${(p) => (p.$compact ? '4px' : '10px')};
		bottom: ${(p) => (p.$compact ? '4px' : '10px')};
		width: 2px;
		background: linear-gradient(180deg, transparent, var(--cyan) 45%, transparent);
		opacity: 0.75;
	}
`

export const PointBalanceLabel = styled.span<{ $compact?: boolean }>`
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: ${(p) => (p.$compact ? '8px' : '9px')};
	font-weight: 500;
	letter-spacing: ${(p) => (p.$compact ? '0.08em' : '0.12em')};
	text-transform: uppercase;
	color: var(--text-sub);
	line-height: 1;
	white-space: nowrap;
`

export const PointBalanceDivider = styled.span`
	width: 1px;
	height: 14px;
	background: rgba(0, 229, 255, 0.22);
	flex-shrink: 0;
`

export const PointBalanceAmount = styled(Box)`
	display: flex;
	align-items: center;
	gap: 5px;
`

export const PointBalanceValue = styled.span<{ $compact?: boolean }>`
	font-family: 'Goldman', 'Oswald', sans-serif;
	font-size: ${(p) => (p.$compact ? '15px' : '22px')};
	font-weight: 700;
	line-height: 1;
	color: var(--cyan);
	letter-spacing: 0.02em;
	font-variant-numeric: tabular-nums;
	text-shadow: ${(p) =>
		p.$compact ? 'none' : '0 0 14px rgba(0, 229, 255, 0.32)'};
`

export const PointBalanceCoin = styled(Box)<{ $compact?: boolean }>`
	flex-shrink: 0;
	width: ${(p) => (p.$compact ? '13px' : '18px')};
	height: ${(p) => (p.$compact ? '10px' : '14px')};
	background-image: url(./assets/svg/coin.svg);
	background-position: center;
	background-repeat: no-repeat;
	background-size: contain;
	filter: ${(p) =>
		p.$compact ? 'none' : 'drop-shadow(0 0 6px rgba(0, 229, 255, 0.45))'};
`
