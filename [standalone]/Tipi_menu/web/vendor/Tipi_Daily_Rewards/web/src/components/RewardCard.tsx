import ItemImage from './ItemImage'
import { getAssetRevision, getSpecialStarsEffectImage, subscribeAssetRevision } from '../utils/assets'
import type { Locales, RewardConfig, RewardStatus } from '../types'
import { memo, useEffect, useRef, useState } from 'react'

interface RewardCardProps {
	dayOfMonth: number
	todayReward: number
	reward: RewardConfig
	status: RewardStatus
	locales: Locales
	isToday: boolean
	vipTrack?: boolean
	isFreeClaim?: boolean
	missedClaimPrice?: number
	missedClaimsCount?: number
	maxMissedClaimsPerMonth?: number
	onClaimStreak: (day: number, reward: RewardConfig) => void
	onDenyFeedback?: (message: string) => void
}

function RewardCard({
	dayOfMonth,
	todayReward,
	reward,
	status,
	locales,
	isToday,
	vipTrack = false,
	isFreeClaim = false,
	missedClaimPrice = 0,
	missedClaimsCount = 0,
	maxMissedClaimsPerMonth = 0,
	onClaimStreak,
	onDenyFeedback,
}: RewardCardProps) {
	const [assetRevision, setAssetRevision] = useState(getAssetRevision)
	useEffect(() => subscribeAssetRevision(() => setAssetRevision(getAssetRevision())), [])
	const starsSrc = getSpecialStarsEffectImage()
	void assetRevision
	const [shake, setShake] = useState(false)
	const shakeTimerRef = useRef<number | null>(null)

	useEffect(() => {
		return () => {
			if (shakeTimerRef.current !== null) {
				window.clearTimeout(shakeTimerRef.current)
			}
		}
	}, [])

	const isCollected = status === 'collected'
	const isVipLocked = status === 'vip_locked'
	const isMissedLimit = status === 'missed_limit'
	const canClaimToday = !isVipLocked && !isMissedLimit && ((isToday && status === 'usual') || status === 'missed_claimable')
	const isFuture = !isCollected && dayOfMonth > todayReward
	const showStars = !isCollected && !isFuture && !isVipLocked && !isMissedLimit
	const isMissedClaimable = status === 'missed_claimable'
	const showMissedPrice = isMissedClaimable && !isFreeClaim && missedClaimPrice > 0
	const showFreeClaimBadge = isMissedClaimable && isFreeClaim
	const missedPriceLabel = (locales.MissedDayPrice ?? 'Bù %s$').replace('%s', String(missedClaimPrice))
	const missedHint = isFreeClaim
		? (locales.MissedFreeClaim ?? 'Nhận miễn phí')
		: (locales.MissedDayHint ?? 'Ngày bỏ lỡ — trả %s$ để nhận').replace(
				'%s',
				String(missedClaimPrice),
			)
	const missedLimitLabel = (locales.MissedLimitReached ?? 'Đã hết lượt nhận bù ngày trong tháng này tối đa %d lượt').replace(
		'%d',
		String(maxMissedClaimsPerMonth || missedClaimsCount || 0),
	)

	const cellClass = [
		'cal-cell',
		vipTrack ? 'cal-cell-vip' : '',
		isCollected ? 'cal-cell-done' : isFuture ? 'cal-cell-future' : 'cal-cell-bright',
		canClaimToday ? 'cal-cell-clickable' : '',
		isToday && canClaimToday ? 'cal-cell-today' : '',
		isMissedClaimable ? 'cal-cell-missed' : '',
		isMissedLimit ? 'cal-cell-missed-limit' : '',
		isVipLocked ? 'cal-cell-vip-locked' : '',
		shake ? 'cal-cell-shake' : '',
	]
		.filter(Boolean)
		.join(' ')

	const imageClass = [
		'cal-cell-img',
		isCollected ? 'cal-cell-img-revealed' : 'cal-cell-img-locked',
		isFuture || isVipLocked || isMissedLimit ? 'cal-cell-img-future' : '',
		canClaimToday || (isToday && !isCollected && !isVipLocked) || isMissedClaimable ? 'cal-cell-img-today' : '',
	]
		.filter(Boolean)
		.join(' ')

	const denyMessage = isVipLocked
		? locales.VipNeedPack ?? 'Cần mua gói VIP tháng này'
		: isMissedLimit
			? missedLimitLabel
			: showMissedPrice
				? missedHint
				: isCollected
					? locales.AlreadyClaimed ?? 'Ngày này đã nhận rồi'
					: isFuture
						? locales.NotYetAvailable ?? 'Ngày chưa đến'
						: locales.NotYetEligible ?? 'Chưa đủ điều kiện nhận'

	const handleClick = () => {
		if (canClaimToday) {
			onClaimStreak(dayOfMonth, reward)
			return
		}
		onDenyFeedback?.(denyMessage)
		if (shakeTimerRef.current !== null) {
			window.clearTimeout(shakeTimerRef.current)
		}
		setShake(true)
		shakeTimerRef.current = window.setTimeout(() => {
			setShake(false)
			shakeTimerRef.current = null
		}, 400)
	}

	return (
		<div
			className={cellClass}
			onClick={handleClick}
			onKeyDown={(event) => {
				if (canClaimToday && (event.key === 'Enter' || event.key === ' ')) {
					event.preventDefault()
					onClaimStreak(dayOfMonth, reward)
				}
			}}
			role={canClaimToday ? 'button' : undefined}
			tabIndex={canClaimToday ? 0 : undefined}
			title={denyMessage}>
			<span className='cal-cell-day'>{dayOfMonth}</span>
			{showMissedPrice ? <span className='cal-cell-missed-price'>{missedPriceLabel}</span> : null}
			{showFreeClaimBadge ? <span className='cal-cell-free-badge'>{locales.MissedFreeClaim ?? 'Miễn phí'}</span> : null}
			{isMissedLimit ? <span className='cal-cell-limit-badge'>HẾT LƯỢT</span> : null}

			<div className='cal-cell-body'>
				<div className='cal-cell-gift'>
					<ItemImage
						itemName={reward.itemName}
						alt={isCollected ? reward.itemLabel : (locales.MysteryReward ?? 'Hộp quà bí ẩn')}
						className={imageClass}
						mystery={!isCollected}
						itemType={reward.itemType}
						clothComponent={reward.clothComponent}
						clothDrawable={reward.clothDrawable}
						clothSex={reward.clothSex}
					/>
				</div>
				{isCollected ? (
					<p className='cal-cell-label'>
						{reward.itemLabel}
						{reward.itemCount > 1 ? ` x${reward.itemCount}` : ''}
					</p>
				) : null}
			</div>

			{showStars && (
				<img
					className={`cal-cell-stars${canClaimToday ? ' cal-cell-stars--active' : ''}`}
					src={starsSrc}
					alt=''
					draggable={false}
					aria-hidden
				/>
			)}

			{isVipLocked && (
				<div className='cal-cell-lock' aria-hidden>
					VIP
				</div>
			)}

			{isCollected && (
				<div className='cal-cell-check' title={locales.Checked ?? 'Đã nhận'} aria-hidden>
					<svg viewBox='0 0 24 24' width='12' height='12' fill='none' aria-hidden>
						<path
							d='M5 12.5l4.2 4.2L19 7'
							stroke='currentColor'
							strokeWidth='2.8'
							strokeLinecap='round'
							strokeLinejoin='round'
						/>
					</svg>
				</div>
			)}
		</div>
	)
}

export default memo(RewardCard)
