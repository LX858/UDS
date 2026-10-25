import { useEffect, useState } from 'react'
import ItemImage from './ItemImage'
import {
	getAssetRevision,
	getSlicedCommonBottomImage,
	getSlicedCommonUpperImage,
	subscribeAssetRevision,
} from '../utils/assets'

export const OPEN_BOX_MS = 2100

type GiftOpenSceneProps = {
	itemName: string
	itemLabel: string
	className?: string
	size?: 'compact' | 'modal'
	itemType?: string
	clothComponent?: string
	clothDrawable?: number
	clothSex?: string
}

export default function GiftOpenScene({
	itemName,
	itemLabel,
	className = '',
	size = 'compact',
	itemType,
	clothComponent,
	clothDrawable,
	clothSex,
}: GiftOpenSceneProps) {
	const [assetRevision, setAssetRevision] = useState(getAssetRevision)
	useEffect(() => subscribeAssetRevision(() => setAssetRevision(getAssetRevision())), [])
	void assetRevision

	return (
		<div className={`gift-open-scene gift-open-scene--${size} ${className}`.trim()} aria-hidden>
			<div className='gift-open-parts'>
				<img
					className='gift-open-bottom'
					src={getSlicedCommonBottomImage()}
					alt=''
					draggable={false}
				/>
				<div className='gift-open-item'>
					<ItemImage
						itemName={itemName}
						alt={itemLabel}
						className='object-contain'
						mystery={false}
						itemType={itemType}
						clothComponent={clothComponent}
						clothDrawable={clothDrawable}
						clothSex={clothSex}
					/>
				</div>
				<img
					className='gift-open-lid'
					src={getSlicedCommonUpperImage()}
					alt=''
					draggable={false}
				/>
			</div>
		</div>
	)
}
