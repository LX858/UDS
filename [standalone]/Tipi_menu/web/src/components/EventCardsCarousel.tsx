import { Box } from 'lr-components'
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import styled from 'styled-components'
import { AnimatePresence, motion } from 'framer-motion'
import { VISIBLE_EVENT_CARD_COUNT } from '../constants/eventCards'
import { EventCardConfig } from '../types/eventCard'

const CarouselRoot = styled(Box)`
	position: relative;
	width: 100%;
	height: 100%;
	min-height: 0;
	display: flex;
	flex-direction: column;
	align-items: stretch;
`

const CarouselGrid = styled(Box)<{ $carousel?: boolean }>`
	flex: 1;
	min-width: 0;
	min-height: 0;
	display: flex;
	flex-direction: row;
	align-items: stretch;
	gap: 12px;
	padding: 0 36px;
	box-sizing: border-box;
`

const CarouselSlot = styled(Box)<{ $carousel?: boolean }>`
	flex: ${(p) => (p.$carousel ? `0 0 calc((100% - ${(VISIBLE_EVENT_CARD_COUNT - 1) * 12}px) / ${VISIBLE_EVENT_CARD_COUNT})` : '1')};
	min-width: 0;
	min-height: 0;
`

const CardFrame = styled(Box)`
	width: 100%;
	height: 100%;
	min-width: 0;
	min-height: 0;
`

const Pagination = styled(Box)`
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 8px;
	padding: 12px 36px 0;
	box-sizing: border-box;
	flex-shrink: 0;
`

const NavButton = styled.button`
	min-width: 30px;
	height: 30px;
	padding: 0 8px;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 12, 24, 0.88);
	color: var(--cyan);
	cursor: pointer;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 16px;
	line-height: 1;
	transition:
		background-color 0.15s ease,
		border-color 0.15s ease,
		box-shadow 0.15s ease;

	&:hover:not(:disabled) {
		border-color: var(--border);
		background: rgba(0, 229, 255, 0.12);
		box-shadow: 0 0 12px var(--cyan-glow);
	}

	&:disabled {
		opacity: 0.35;
		cursor: default;
	}
`

const PageButton = styled.button<{ $active?: boolean }>`
	min-width: 30px;
	height: 30px;
	padding: 0 8px;
	border-radius: 4px;
	border: 1px solid ${(p) => (p.$active ? 'var(--border)' : 'var(--border-dim)')};
	background: ${(p) => (p.$active ? 'rgba(0, 229, 255, 0.18)' : 'rgba(0, 12, 24, 0.88)')};
	color: ${(p) => (p.$active ? '#fff' : 'var(--cyan)')};
	cursor: pointer;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 13px;
	font-weight: ${(p) => (p.$active ? 700 : 500)};
	line-height: 1;
	box-shadow: ${(p) => (p.$active ? '0 0 12px var(--cyan-glow)' : 'none')};
	transition:
		background-color 0.15s ease,
		border-color 0.15s ease,
		box-shadow 0.15s ease;

	&:hover {
		border-color: var(--border);
		background: rgba(0, 229, 255, 0.12);
	}
`

const SlideWrap = styled(motion.div)`
	width: 100%;
	height: 100%;
	min-height: 0;
`

export function sortEventCards(cards: EventCardConfig[]) {
	return [...cards].sort(
		(a, b) => a.sortOrder - b.sortOrder || a.cardKey.localeCompare(b.cardKey),
	)
}

type EventCardsCarouselProps = {
	cards: EventCardConfig[]
	renderCard: (card: EventCardConfig) => React.ReactNode
}

export default function EventCardsCarousel({
	cards,
	renderCard,
}: EventCardsCarouselProps) {
	const sortedCards = useMemo(() => sortEventCards(cards), [cards])
	const pageCount = Math.max(1, Math.ceil(sortedCards.length / VISIBLE_EVENT_CARD_COUNT))
	const usePaging = pageCount > 1
	const [pageIndex, setPageIndex] = useState(0)
	const rootRef = useRef<HTMLDivElement | null>(null)
	const wheelLockRef = useRef(false)

	useEffect(() => {
		setPageIndex((prev) => Math.min(prev, pageCount - 1))
	}, [pageCount])

	const goPrev = useCallback(() => {
		setPageIndex((prev) => Math.max(0, prev - 1))
	}, [])

	const goNext = useCallback(() => {
		setPageIndex((prev) => Math.min(pageCount - 1, prev + 1))
	}, [pageCount])

	useEffect(() => {
		const root = rootRef.current
		if (!root || !usePaging) return

		const onWheel = (event: WheelEvent) => {
			const delta =
				Math.abs(event.deltaY) >= Math.abs(event.deltaX) ? event.deltaY : event.deltaX
			if (Math.abs(delta) < 6) return

			event.preventDefault()

			if (wheelLockRef.current) return
			wheelLockRef.current = true

			if (delta > 0) {
				goNext()
			} else {
				goPrev()
			}

			window.setTimeout(() => {
				wheelLockRef.current = false
			}, 260)
		}

		root.addEventListener('wheel', onWheel, { passive: false })
		return () => root.removeEventListener('wheel', onWheel)
	}, [usePaging, goNext, goPrev])

	const visibleCards = useMemo(() => {
		const start = pageIndex * VISIBLE_EVENT_CARD_COUNT
		return sortedCards.slice(start, start + VISIBLE_EVENT_CARD_COUNT)
	}, [sortedCards, pageIndex])

	return (
		<CarouselRoot ref={rootRef}>
			<CarouselGrid $carousel={usePaging}>
				<AnimatePresence mode='popLayout' initial={false}>
					{visibleCards.map((card) => (
						<CarouselSlot key={`${pageIndex}-${card.cardKey}`} $carousel={usePaging}>
							<CardFrame>
								<SlideWrap
									initial={{ opacity: 0.55, x: 12 }}
									animate={{ opacity: 1, x: 0 }}
									exit={{ opacity: 0.55, x: -12 }}
									transition={{ type: 'spring', stiffness: 320, damping: 32 }}>
									{renderCard(card)}
								</SlideWrap>
							</CardFrame>
						</CarouselSlot>
					))}
				</AnimatePresence>
			</CarouselGrid>

			{usePaging && (
				<Pagination>
					<NavButton
						type='button'
						aria-label='Previous'
						onClick={goPrev}
						disabled={pageIndex === 0}>
						‹
					</NavButton>

					{Array.from({ length: pageCount }, (_, index) => (
						<PageButton
							key={index}
							type='button'
							aria-label={`Page ${index + 1}`}
							aria-current={index === pageIndex}
							$active={index === pageIndex}
							onClick={() => setPageIndex(index)}>
							{index + 1}
						</PageButton>
					))}

					<NavButton
						type='button'
						aria-label='Next'
						onClick={goNext}
						disabled={pageIndex === pageCount - 1}>
						›
					</NavButton>
				</Pagination>
			)}
		</CarouselRoot>
	)
}
