import React, { useState } from 'react'
import styled from 'styled-components'
import { getPrimeItemImageUrl } from '../constants/eventItemImages'

const Img = styled.img`
	width: 100%;
	height: 100%;
	object-fit: contain;
`

const Placeholder = styled.div`
	width: 100%;
	height: 100%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-family: 'Montserrat', sans-serif;
	font-size: 10px;
	color: var(--text-sub);
	text-align: center;
	padding: 4px;
	box-sizing: border-box;
`

type Props = {
	itemName: string
	alt?: string
	className?: string
}

export default function EventItemImage({ itemName, alt, className }: Props) {
	const [failed, setFailed] = useState(false)
	const src = getPrimeItemImageUrl(itemName)

	if (!src || failed) {
		return (
			<Placeholder className={className} title={itemName}>
				{itemName ? itemName.slice(0, 8) : '?'}
			</Placeholder>
		)
	}

	return (
		<Img
			className={className}
			src={src}
			alt={alt ?? itemName}
			loading='lazy'
			decoding='async'
			onError={() => setFailed(true)}
		/>
	)
}
