import GiftOpenScene from './GiftOpenScene'
import type { SelectedReward } from '../types'

interface RewardRevealModalProps {
	reward: SelectedReward
	onCollect: () => void
}

export default function RewardRevealModal({ reward, onCollect }: RewardRevealModalProps) {
	return (
		<div
			className='gift-reveal-overlay'
			role='dialog'
			aria-modal='true'
			onClick={onCollect}
			onKeyDown={(event) => {
				if (event.key === 'Escape' || event.key === 'Enter' || event.key === ' ') {
					event.preventDefault()
					onCollect()
				}
			}}
			tabIndex={0}>
			<GiftOpenScene
				key={`${reward.day}-${reward.itemName}-${reward.kind ?? 'streak'}`}
				itemName={reward.itemName}
				itemLabel={reward.itemLabel}
				size='modal'
				itemType={reward.itemType}
				clothComponent={reward.clothComponent}
				clothDrawable={reward.clothDrawable}
				clothSex={reward.clothSex}
			/>

			<div className='gift-reveal-meta'>
				<h3 className='tipi-title text-2xl font-bold text-[var(--text-main)]'>{reward.itemLabel}</h3>
				{reward.itemCount && reward.itemCount > 1 ? (
					<p className='mt-1 font-accent text-sm text-[var(--cyan)]'>x{reward.itemCount}</p>
				) : null}
			</div>
		</div>
	)
}
