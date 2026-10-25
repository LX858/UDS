import { useMemo } from 'react'
import ItemImage from './ItemImage'
import type { Locales, StreakMilestoneState } from '../types'

type StreakMilestonesBarProps = {
	current: number
	milestones: StreakMilestoneState[]
	locales: Locales
	claimingDays?: number | null
	onClaim: (days: number) => void
}

export default function StreakMilestonesBar({
	current,
	milestones,
	locales,
	claimingDays = null,
	onClaim,
}: StreakMilestonesBarProps) {
	const maxDays = useMemo(
		() => Math.max(1, ...milestones.map((item) => item.days), current),
		[current, milestones],
	)
	const percent = Math.min(100, Math.round((current / maxDays) * 100))

	if (!milestones.length) return null

	return (
		<section className='streak-shell'>
			<div className='streak-top'>
				<div className='streak-head'>
					<p className='tipi-label streak-title'>{locales.StreakTitle ?? 'CHUỖI ĐIỂM DANH'}</p>
					<p className='streak-sub'>
						{(locales.StreakCurrent ?? 'Chuỗi của bạn: %d ngày').replace('%d', String(current))}
					</p>
				</div>
				<div className='streak-progress relative'>
					<div className='streak-progress-fill' style={{ width: `${percent}%` }} />
					{milestones.map((m) => {
						const pos = Math.min(100, Math.round((m.days / maxDays) * 100))
						const reached = current >= m.days
						return (
							<div
								key={`dot-${m.days}`}
								className={`streak-progress-dot${reached ? ' streak-progress-dot-active' : ''}`}
								style={{ left: `${pos}%` }}
								title={`${m.days} ngày`}
							/>
						)
					})}
				</div>
			</div>

			<div className='streak-list' style={{ ['--streak-count' as string]: Math.max(1, milestones.length) }}>
				{milestones.map((milestone) => {
					const clickable = milestone.ready && !milestone.claimed && claimingDays == null
					return (
						<button
							key={milestone.days}
							type='button'
							className={[
								'streak-chip',
								milestone.claimed ? 'streak-chip-done' : '',
								milestone.ready && !milestone.claimed ? 'streak-chip-ready' : '',
								clickable ? 'streak-chip-clickable' : '',
							]
								.filter(Boolean)
								.join(' ')}
							disabled={!clickable}
							onClick={() => onClaim(milestone.days)}
							title={milestone.reward?.itemLabel}>
							<div className='streak-chip-gift'>
								{milestone.reward ? (
									<ItemImage
										itemName={milestone.reward.itemName}
										alt={milestone.reward.itemLabel}
										className='object-contain'
										mystery={!milestone.claimed}
										itemType={milestone.reward.itemType}
										clothComponent={milestone.reward.clothComponent}
										clothDrawable={milestone.reward.clothDrawable}
										clothSex={milestone.reward.clothSex}
									/>
								) : null}
							</div>
							<div className='streak-chip-meta'>
								<span className='streak-chip-days'>{milestone.days} ngày</span>
								<span className='streak-chip-state'>
									{milestone.claimed
										? locales.Checked ?? 'Đã nhận'
										: milestone.ready
											? locales.Collect ?? 'Nhận'
											: `${current}/${milestone.days}`}
								</span>
							</div>
						</button>
					)
				})}
			</div>
		</section>
	)
}
