import { Box, Text } from 'lr-components'
import { useMemo } from 'react'
import styled, { keyframes } from 'styled-components'
import { menuCardBase, menuCardHover } from '../styles/menuCardStyles'
import { isEnvBrowser } from '../utils/misc'
import type { DailyRewardsSummary } from '../Page/DailyRewardsEmbed'

/** Tipi_menu luôn có asset dưới public/images/daily-rewards — không phụ thuộc embed state shared. */
function getCompactGiftSrc() {
	return isEnvBrowser() ? '/images/daily-rewards/common.png' : './images/daily-rewards/common.png'
}

const alertGiftSway = keyframes`
	0%, 100% { transform: rotate(-10deg) translateY(0); }
	50% { transform: rotate(10deg) translateY(-1px); }
`

const Card = styled(
	({
		$expanded,
		$ready,
		$disabled,
		...rest
	}: {
		$expanded?: boolean
		$ready?: boolean
		$disabled?: boolean
		[key: string]: any
	}) => <Box {...rest} />
)<{ $expanded?: boolean; $ready?: boolean; $disabled?: boolean }>`
	${menuCardBase}
	position: relative;
	overflow: hidden;
	flex: 1;
	min-height: 0;
	height: 100%;
	width: 100%;
	display: flex;
	flex-direction: column;
	padding: 12px;
	box-sizing: border-box;
	cursor: ${(p) => (p.$disabled ? 'wait' : 'pointer')};
	background:
		radial-gradient(ellipse 80% 55% at 0% 0%, rgba(0, 229, 255, 0.1) 0%, transparent 55%),
		linear-gradient(155deg, rgba(0, 22, 38, 0.96) 0%, rgba(0, 10, 20, 0.9) 55%, rgba(0, 6, 14, 0.94) 100%);
	border-color: ${(p) => (p.$expanded || p.$ready ? 'var(--cyan)' : 'var(--border-dim)')};
	box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
	transition:
		border-color 0.2s ease,
		transform 0.15s ease,
		opacity 0.15s ease;
	opacity: ${(p) => (p.$disabled ? 0.7 : 1)};

	&:hover {
		${menuCardHover}
		transform: ${(p) => (p.$disabled ? 'none' : 'translateY(-1px)')};
	}

	&:active {
		transform: ${(p) => (p.$disabled ? 'none' : 'scale(0.99)')};
	}
`

const CardInner = styled(Box)`
	position: relative;
	z-index: 1;
	display: flex;
	flex-direction: column;
	gap: 10px;
	flex: 1;
	min-height: 0;
	height: 100%;
	pointer-events: none;
`

const TitleAccent = styled(Box)`
	display: flex;
	align-items: center;
	gap: 8px;

	&::before {
		content: '';
		width: 3px;
		height: 14px;
		border-radius: 2px;
		background: linear-gradient(180deg, var(--cyan) 0%, var(--cyan-dim) 100%);
		box-shadow: 0 0 8px var(--cyan-glow);
		flex-shrink: 0;
	}
`

const TitleText = styled(Text)`
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 13px;
	font-weight: 700;
	line-height: 1.1;
	text-transform: uppercase;
	letter-spacing: 0.04em;
	color: #fff;
`

const StatusText = styled(Text)<{ $ready?: boolean }>`
	font-size: 10px;
	font-weight: 700;
	letter-spacing: 0.04em;
	text-transform: uppercase;
	color: ${(p) => (p.$ready ? '#5dffb0' : 'var(--text-sub)')};
	line-height: 1.3;
`

const StatsRow = styled(Box)`
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 6px;
	width: 100%;
	flex-shrink: 0;
`

const StatCell = styled(Box)`
	display: flex;
	flex-direction: column;
	gap: 2px;
	padding: 7px 8px;
	border-radius: 5px;
	border: 1px solid rgba(0, 229, 255, 0.14);
	background: rgba(0, 10, 22, 0.72);
	min-width: 0;
`

const StatLabel = styled(Text)`
	font-size: 7px;
	font-weight: 700;
	letter-spacing: 0.08em;
	text-transform: uppercase;
	color: var(--text-muted);
`

const StatValue = styled(Text)`
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 13px;
	font-weight: 700;
	line-height: 1.1;
	color: #fff;
`

const StatValueAccent = styled(StatValue)`
	color: var(--cyan);
	font-size: 12px;
`

const ProgressTrack = styled(Box)`
	width: 100%;
	height: 5px;
	border-radius: 999px;
	overflow: hidden;
	border: 1px solid rgba(0, 229, 255, 0.14);
	background: rgba(0, 8, 16, 0.9);
	flex-shrink: 0;
`

const ProgressFill = styled(Box)<{ $pct: number }>`
	height: 100%;
	width: ${(p) => `${Math.max(0, Math.min(100, p.$pct))}%`};
	border-radius: 999px;
	background: linear-gradient(90deg, #006272 0%, #00e5ff 100%);
	box-shadow: 0 0 8px rgba(0, 229, 255, 0.3);
	transition: width 0.35s ease;
`

const PreviewZone = styled(
	({ $ready, ...rest }: { $ready?: boolean; [key: string]: any }) => <Box {...rest} />
)<{ $ready?: boolean }>`
	position: relative;
	flex: 1;
	min-height: 120px;
	display: flex;
	align-items: center;
	justify-content: center;
	border-radius: 6px;
	border: 1px solid
		${(p) => (p.$ready ? 'rgba(255, 171, 0, 0.35)' : 'rgba(0, 229, 255, 0.12)')};
	background: rgba(0, 8, 16, 0.55);
	overflow: hidden;
	padding: 8px;

	img.gift-main {
		width: min(220px, 94%) !important;
		height: min(220px, 94%) !important;
		max-width: 100%;
		max-height: 100%;
		object-fit: contain;
		opacity: 0.98;
		filter: drop-shadow(0 0 16px rgba(0, 229, 255, 0.35));
	}
`

const ReadyBadge = styled(Box)`
	position: absolute;
	top: 8px;
	right: 8px;
	width: 40px;
	height: 40px;
	display: flex;
	align-items: center;
	justify-content: center;
	pointer-events: none;

	img {
		width: 36px !important;
		height: 36px !important;
		object-fit: contain;
		animation: ${alertGiftSway} 0.9s ease-in-out infinite;
		filter: drop-shadow(0 0 6px rgba(255, 171, 0, 0.55));
		transform-origin: center bottom;
	}
`

const HintText = styled(Text)`
	flex-shrink: 0;
	text-align: center;
	font-size: 9px;
	font-weight: 700;
	letter-spacing: 0.06em;
	text-transform: uppercase;
	color: var(--text-muted);
`

type DailyRewardsCompactCardProps = {
	title: string
	highlight: string
	subtitle: string
	monthProgressLabel: string
	todayStatLabel: string
	todayLabel: string
	loadingLabel: string
	unavailableLabel: string
	summary: DailyRewardsSummary | null
	loading?: boolean
	monthBoardLoading?: boolean
	expanded?: boolean
	onToggle?: () => void
}

function DailyRewardsCompactCard({
	title,
	highlight,
	subtitle,
	monthProgressLabel,
	todayStatLabel,
	todayLabel,
	loadingLabel,
	unavailableLabel,
	summary,
	loading = false,
	monthBoardLoading = false,
	expanded = false,
	onToggle,
}: DailyRewardsCompactCardProps) {
	const hasUnopenedMonthGift = Boolean(summary?.canClaimToday) && !expanded
	const hasPending = summary?.canClaimToday ?? false
	const monthGiftSrc = useMemo(() => getCompactGiftSrc(), [])
	const disabled = monthBoardLoading

	const todayText =
		summary && summary.todayReward > 0
			? todayLabel.replace('{day}', String(summary.todayReward))
			: '—'

	const progressPct =
		summary && summary.daysInMonth > 0
			? Math.round((summary.checkedCount / summary.daysInMonth) * 100)
			: 0

	const statusLine = loading
		? loadingLabel
		: hasPending
			? 'Sẵn sàng nhận hôm nay'
			: summary?.presentToday === false
				? 'Cần online thêm'
				: summary
					? 'Đã nhận hôm nay'
					: subtitle


	return (
		<Card
			$expanded={expanded}
			$ready={hasPending}
			$disabled={disabled}
			role='button'
			tabIndex={disabled ? -1 : 0}
			aria-pressed={expanded}
			aria-busy={disabled}
			className={`mp-daily-compact-card${expanded ? ' mp-daily-compact-card--active' : ''}`}
			onClick={() => {
				if (disabled) return
				onToggle?.()
			}}
			onKeyDown={(event: React.KeyboardEvent) => {
				if (disabled) return
				if (event.key === 'Enter' || event.key === ' ') {
					event.preventDefault()
					onToggle?.()
				}
			}}>
			<CardInner>
				<Box>
					<TitleAccent>
						<TitleText>
							{title} <span style={{ color: 'var(--cyan)' }}>{highlight}</span>
						</TitleText>
					</TitleAccent>
					<Box marginTop='6px'>
						<StatusText $ready={hasPending}>{statusLine}</StatusText>
					</Box>
				</Box>

				{!loading && summary?.error === 'resource_not_started' && (
					<StatusText>{unavailableLabel}</StatusText>
				)}

				{!loading && summary && summary.error !== 'resource_not_started' && (
					<>
						<StatsRow>
							<StatCell>
								<StatLabel>{monthProgressLabel}</StatLabel>
								<StatValue>
									{summary.checkedCount}/{summary.daysInMonth}
								</StatValue>
							</StatCell>
							<StatCell>
								<StatLabel>{todayStatLabel}</StatLabel>
								<StatValueAccent>{todayText}</StatValueAccent>
							</StatCell>
						</StatsRow>

						<ProgressTrack>
							<ProgressFill $pct={progressPct} />
						</ProgressTrack>

						<PreviewZone $ready={hasUnopenedMonthGift}>
							<img className='gift-main' src={monthGiftSrc} alt='' draggable={false} />
							{hasUnopenedMonthGift ? (
								<ReadyBadge>
									<img src={monthGiftSrc} alt='' draggable={false} />
								</ReadyBadge>
							) : null}
						</PreviewZone>
					</>
				)}
			</CardInner>
		</Card>
	)
}

export default DailyRewardsCompactCard
