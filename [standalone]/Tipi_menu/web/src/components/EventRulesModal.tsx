import { Box, Text } from 'lr-components'
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import styled, { keyframes } from 'styled-components'
import { motion, AnimatePresence } from 'framer-motion'
import Button from './Button'
import { menuCardBase } from '../styles/menuCardStyles'
import { getVisibleRuleSections, getVisibleRewards, formatRuleItemText, parseRulesContent } from '../utils/eventRulesContent'
import EventItemImage from './EventItemImage'
import { useLocale } from '../hooks/useLocale'

const Overlay = styled(motion.div)`
	position: fixed;
	inset: 0;
	z-index: 12000;
	display: flex;
	align-items: center;
	justify-content: center;
	background: rgba(0, 6, 14, 0.72);
	padding: 24px;
	box-sizing: border-box;
`

const Panel = styled(Box)`
	${menuCardBase}
	width: min(560px, 92vw);
	height: min(70vh, 640px);
	max-height: min(70vh, 640px);
	display: flex;
	flex-direction: column;
	overflow: hidden;
	border-color: var(--border);
`

const Header = styled(Box)`
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 12px;
	padding: 14px 16px;
	border-bottom: 1px solid var(--border-dim);
	flex-shrink: 0;
`

const BodyShell = styled(Box)`
	position: relative;
	flex: 1;
	min-height: 0;
	overflow: hidden;
`

const BodyScroll = styled.div`
	height: 100%;
	padding: 16px;
	box-sizing: border-box;
	overflow-y: auto;
	overflow-x: hidden;
	display: flex;
	flex-direction: column;
	gap: 14px;
	scrollbar-width: none;
	-ms-overflow-style: none;

	&::-webkit-scrollbar {
		display: none;
	}
`

const ScrollHint = styled(Box)`
	position: absolute;
	left: 0;
	right: 0;
	bottom: 0;
	z-index: 2;
	display: flex;
	justify-content: center;
	align-items: flex-end;
	padding: 28px 16px 10px;
	pointer-events: none;
	background: linear-gradient(
		0deg,
		rgba(0, 14, 28, 0.98) 0%,
		rgba(0, 14, 28, 0.82) 42%,
		rgba(0, 14, 28, 0) 100%
	);
`

const ScrollHintContent = styled(Box)`
	display: flex;
	flex-direction: column;
	align-items: center;
	gap: 4px;
`

const scrollHintBounce = keyframes`
	0%,
	100% {
		transform: translateY(0);
		opacity: 0.7;
	}
	50% {
		transform: translateY(4px);
		opacity: 1;
	}
`

const ScrollHintArrow = styled.span`
	display: block;
	font-size: 13px;
	line-height: 1;
	color: var(--cyan);
	text-shadow: 0 0 10px rgba(0, 229, 255, 0.45);
	animation: ${scrollHintBounce} 1.4s ease-in-out infinite;
`

const ScrollHintText = styled(Text)`
	text-transform: uppercase;
	letter-spacing: 0.08em;
	color: var(--text-sub);
	text-shadow: 0 1px 8px rgba(0, 0, 0, 0.8);
`

const SectionBlock = styled(Box)`
	display: flex;
	flex-direction: column;
	gap: 8px;
`

const SectionTitle = styled(Text)`
	text-transform: uppercase;
	font-weight: 700;
	color: var(--cyan);
	letter-spacing: 0.04em;
`

const ItemList = styled.ul`
	margin: 0;
	padding-left: 18px;
	display: flex;
	flex-direction: column;
	gap: 6px;
`

const Item = styled.li`
	font-family: 'Montserrat', sans-serif;
	font-size: 13px;
	line-height: 1.6;
	color: #e8f4ff;
	white-space: pre-wrap;
	word-break: break-word;
	overflow-wrap: anywhere;
`

const PlainText = styled.p`
	margin: 0;
	font-family: 'Montserrat', sans-serif;
	font-size: 13px;
	line-height: 1.65;
	color: #e8f4ff;
`

const RewardsPanel = styled(Box)`
	padding: 12px;
	border-radius: 6px;
	border: 1px solid rgba(0, 229, 255, 0.14);
	background: linear-gradient(180deg, rgba(0, 22, 38, 0.55) 0%, rgba(0, 10, 20, 0.35) 100%);
`

const RewardsGrid = styled(Box)`
	display: flex;
	flex-wrap: wrap;
	gap: 12px;
`

const RewardCard = styled(Box)`
	position: relative;
	width: 112px;
	flex-shrink: 0;
	display: flex;
	flex-direction: column;
	align-items: stretch;
	padding: 8px 8px 10px;
	border-radius: 6px;
	border: 1px solid rgba(0, 229, 255, 0.3);
	background: linear-gradient(
		165deg,
		rgba(0, 52, 78, 0.62) 0%,
		rgba(0, 16, 30, 0.94) 52%,
		rgba(0, 8, 18, 0.98) 100%
	);
	box-shadow:
		inset 0 1px 0 rgba(0, 229, 255, 0.2),
		0 4px 16px rgba(0, 0, 0, 0.32);
	overflow: hidden;
	transition:
		border-color 0.2s ease,
		transform 0.15s ease,
		box-shadow 0.2s ease;

	&::before {
		content: '';
		position: absolute;
		top: 0;
		left: 10%;
		right: 10%;
		height: 1px;
		background: linear-gradient(90deg, transparent, rgba(0, 229, 255, 0.75), transparent);
		pointer-events: none;
	}

	&:hover {
		border-color: rgba(0, 229, 255, 0.52);
		transform: translateY(-2px);
		box-shadow:
			inset 0 1px 0 rgba(0, 229, 255, 0.28),
			0 8px 22px rgba(0, 229, 255, 0.14);
	}
`

const CountBadge = styled(Box)`
	position: absolute;
	top: 6px;
	right: 6px;
	z-index: 2;
	padding: 2px 7px;
	border-radius: 3px;
	border: 1px solid rgba(0, 229, 255, 0.45);
	background: rgba(0, 18, 32, 0.88);
	box-shadow: 0 0 10px rgba(0, 229, 255, 0.2);
`

const CountBadgeText = styled(Text)`
	color: var(--cyan);
	font-weight: 700;
	line-height: 1;
	font-family: 'Oswald', 'Montserrat', sans-serif;
`

const RewardImageArea = styled(Box)`
	position: relative;
	width: 100%;
	aspect-ratio: 1;
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 10px;
	box-sizing: border-box;

	&::after {
		content: '';
		position: absolute;
		inset: 18%;
		border-radius: 50%;
		background: radial-gradient(circle, rgba(0, 229, 255, 0.16) 0%, transparent 72%);
		pointer-events: none;
	}
`

const RewardImageSlot = styled(Box)`
	position: relative;
	z-index: 1;
	width: 78%;
	height: 78%;
	display: flex;
	align-items: center;
	justify-content: center;
	filter: drop-shadow(0 3px 10px rgba(0, 229, 255, 0.28));
`

const RewardLabel = styled(Text)`
	margin-top: 6px;
	padding: 0 2px;
	text-align: center;
	line-height: 1.35;
	color: #eef8ff;
	word-break: break-word;
	display: -webkit-box;
	-webkit-line-clamp: 2;
	-webkit-box-orient: vertical;
	overflow: hidden;
	min-height: 2.7em;
`

const Footer = styled(Box)`
	display: flex;
	justify-content: flex-end;
	padding: 12px 16px 16px;
	flex-shrink: 0;
	border-top: 1px solid var(--border-dim);
`

type EventRulesModalProps = {
	open: boolean
	title: string
	content: string
	closeLabel: string
	onClose: () => void
}

export default function EventRulesModal({
	open,
	title,
	content,
	closeLabel,
	onClose,
}: EventRulesModalProps) {
	const L = useLocale()
	const bodyRef = useRef<HTMLDivElement | null>(null)
	const [showScrollHint, setShowScrollHint] = useState(false)
	const document = useMemo(() => parseRulesContent(content), [content])
	const visibleSections = useMemo(() => getVisibleRuleSections(document), [document])
	const visibleRewards = useMemo(() => getVisibleRewards(document), [document])
	const hasStructured = visibleSections.length > 0
	const hasRewards = visibleRewards.length > 0
	const hasContent = hasStructured || hasRewards

	const updateScrollHint = useCallback(() => {
		const el = bodyRef.current
		if (!el) {
			setShowScrollHint(false)
			return
		}

		const maxScroll = el.scrollHeight - el.clientHeight
		const hasOverflow = maxScroll > 1
		const atBottom = el.scrollTop >= maxScroll - 16
		setShowScrollHint(hasOverflow && !atBottom)
	}, [])

	useEffect(() => {
		if (!open) {
			setShowScrollHint(false)
			return
		}

		const el = bodyRef.current
		if (!el) return

		const handleScroll = () => updateScrollHint()
		el.addEventListener('scroll', handleScroll, { passive: true })

		const observer = new ResizeObserver(() => updateScrollHint())
		observer.observe(el)

		const timer = window.requestAnimationFrame(() => updateScrollHint())

		return () => {
			el.removeEventListener('scroll', handleScroll)
			observer.disconnect()
			window.cancelAnimationFrame(timer)
		}
	}, [open, content, visibleSections, visibleRewards, updateScrollHint])

	return (
		<AnimatePresence>
			{open && (
				<Overlay
					initial={{ opacity: 0 }}
					animate={{ opacity: 1 }}
					exit={{ opacity: 0 }}
					onClick={onClose}>
					<Panel
						as={motion.div}
						initial={{ y: 12, opacity: 0 }}
						animate={{ y: 0, opacity: 1 }}
						exit={{ y: 12, opacity: 0 }}
						onClick={(e) => e.stopPropagation()}>
						<Header>
							<Text textTransform='uppercase' fontWeight='bold' rFontSize={16}>
								{title}
							</Text>
						</Header>
						<BodyShell>
							<BodyScroll ref={bodyRef}>
								{!hasContent ? (
									<PlainText>—</PlainText>
								) : (
									<>
										{visibleSections.map((section, index) => (
											<SectionBlock key={`${section.title}-${index}`}>
												{section.title && <SectionTitle rFontSize={12}>{section.title}</SectionTitle>}
												{section.items.length > 0 && (
													<ItemList>
														{section.items.map((item, itemIndex) => (
															<Item key={`${index}-${itemIndex}`}>{formatRuleItemText(item)}</Item>
														))}
													</ItemList>
												)}
											</SectionBlock>
										))}
										{hasRewards && (
											<SectionBlock>
												<SectionTitle rFontSize={12}>{L('ui.event_rules.rewards_title')}</SectionTitle>
												<RewardsPanel>
													<RewardsGrid>
														{visibleRewards.map((reward, index) => (
															<RewardCard key={`${reward.itemName}-${index}`}>
																<CountBadge>
																	<CountBadgeText rFontSize={10}>x{reward.count}</CountBadgeText>
																</CountBadge>
																<RewardImageArea>
																	<RewardImageSlot>
																		<EventItemImage
																			itemName={reward.itemName}
																			alt={reward.label || reward.itemName}
																		/>
																	</RewardImageSlot>
																</RewardImageArea>
																<RewardLabel rFontSize={11} fontWeight='600'>
																	{reward.label || reward.itemName}
																</RewardLabel>
															</RewardCard>
														))}
													</RewardsGrid>
												</RewardsPanel>
											</SectionBlock>
										)}
									</>
								)}
							</BodyScroll>
							{showScrollHint && (
								<ScrollHint>
									<ScrollHintContent>
										<ScrollHintArrow aria-hidden='true'>▼</ScrollHintArrow>
										<ScrollHintText rFontSize={10} fontWeight='600'>
											{L('ui.event_rules.more_below')}
										</ScrollHintText>
									</ScrollHintContent>
								</ScrollHint>
							)}
						</BodyShell>
						<Footer>
							<Button rWidth={120} rHeight={34} rFontSize={12} text={closeLabel} onClick={onClose} />
						</Footer>
					</Panel>
				</Overlay>
			)}
		</AnimatePresence>
	)
}
