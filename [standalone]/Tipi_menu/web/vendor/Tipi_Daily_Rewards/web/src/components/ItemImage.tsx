import { useEffect, useMemo, useState } from 'react'
import {
	getAssetRevision,
	getRewardImageCandidates,
	subscribeAssetRevision,
} from '../utils/assets'

interface ItemImageProps {
	itemName: string
	alt: string
	className?: string
	mystery?: boolean
	itemType?: string
	clothComponent?: string
	clothDrawable?: number
	clothSex?: string
}


const resolvedSourceIndex = new Map<string, number>()

function candidatesKey(
	sources: string[],
	opts: { itemName: string; mystery: boolean; itemType?: string },
) {
	return `${opts.mystery ? 'm' : 'i'}|${opts.itemType || ''}|${opts.itemName}|${sources.join('|')}`
}

export default function ItemImage({
	itemName,
	alt,
	className,
	mystery = false,
	itemType,
	clothComponent,
	clothDrawable,
	clothSex,
}: ItemImageProps) {
	const [assetRevision, setAssetRevision] = useState(getAssetRevision)

	useEffect(() => subscribeAssetRevision(() => setAssetRevision(getAssetRevision())), [])

	const sources = useMemo(
		() =>
			getRewardImageCandidates({
				mystery,
				itemType,
				itemName,
				clothComponent,
				clothDrawable,
				clothSex,
			}),
		[itemName, mystery, itemType, clothComponent, clothDrawable, clothSex, assetRevision],
	)

	const cacheKey = useMemo(
		() => candidatesKey(sources, { itemName, mystery, itemType }),
		[sources, itemName, mystery, itemType],
	)

	const [sourceIndex, setSourceIndex] = useState(() => resolvedSourceIndex.get(cacheKey) ?? 0)

	useEffect(() => {
		setSourceIndex(resolvedSourceIndex.get(cacheKey) ?? 0)
	}, [cacheKey])

	const src = sources[sourceIndex] ?? sources[0]

	return (
		<img
			src={src}
			alt={alt}
			className={className}
			draggable={false}
			decoding='async'
			loading='lazy'
			onError={() => {
				setSourceIndex((current) => {
					if (current + 1 >= sources.length) return current
					const next = current + 1
					resolvedSourceIndex.set(cacheKey, next)
					return next
				})
			}}
		/>
	)
}
