import { Box, Text } from 'lr-components'
import React, { useEffect, useMemo, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import styled from 'styled-components'
import { motion, AnimatePresence } from 'framer-motion'
import Button from './Button'
import EventRulesEditor from './EventRulesEditor'
import EventRewardsEditor from './EventRewardsEditor'
import { menuCardBase } from '../styles/menuCardStyles'
import { AppDispatch, RootState } from '../store'
import { setEventCards, setEventCardsAdmin } from '../store/main'
import { fetchNui } from '../utils/fetchNui'
import { useLocale } from '../hooks/useLocale'
import { isEnvBrowser } from '../utils/misc'
import { EMPTY_EVENT_CARD, EventCardConfig } from '../types/eventCard'
import { FALLBACK_EVENT_CARDS } from '../constants/eventCards'
import {
	emptyRulesDocument,
	EventRulesDocument,
	parseRulesContent,
	serializeRulesContent,
} from '../utils/eventRulesContent'

const Overlay = styled(motion.div)`
	position: fixed;
	inset: 0;
	z-index: 13000;
	display: flex;
	align-items: center;
	justify-content: center;
	background: rgba(0, 6, 14, 0.82);
	padding: 24px;
	box-sizing: border-box;
`

const Panel = styled(Box)`
	${menuCardBase}
	width: min(760px, 94vw);
	height: min(82vh, 760px);
	max-height: min(82vh, 760px);
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

const Tabs = styled(Box)`
	display: flex;
	flex-wrap: wrap;
	gap: 8px;
	padding: 12px 16px;
	border-bottom: 1px solid var(--border-dim);
	flex-shrink: 0;
`

const Tab = styled.button<{ $active?: boolean }>`
	border: 1px solid ${(p) => (p.$active ? 'var(--border)' : 'var(--border-dim)')};
	background: ${(p) => (p.$active ? 'rgba(0, 229, 255, 0.12)' : 'rgba(0, 18, 32, 0.72)')};
	color: ${(p) => (p.$active ? 'var(--cyan)' : 'var(--text-sub)')};
	padding: 8px 12px;
	border-radius: 4px;
	cursor: pointer;
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 12px;
	text-transform: uppercase;
	letter-spacing: 0.06em;
`

const ScrollBody = styled(Box)`
	flex: 1;
	min-height: 0;
	overflow-y: auto;
	overflow-x: hidden;
	padding: 14px 16px 16px;
	display: flex;
	flex-direction: column;
	gap: 12px;
	scrollbar-width: none;
	-ms-overflow-style: none;

	&::-webkit-scrollbar {
		display: none;
	}
`

const Field = styled(Box)`
	display: flex;
	flex-direction: column;
	gap: 6px;
	flex-shrink: 0;
`

const FieldLabel = styled(Text)`
	text-transform: uppercase;
	color: var(--text-sub);
`

const Input = styled.input`
	width: 100%;
	padding: 10px 12px;
	box-sizing: border-box;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 18, 32, 0.88);
	color: #fff;
	font-family: 'Montserrat', sans-serif;
	font-size: 13px;
	outline: none;

	&:focus {
		border-color: var(--border);
	}
`

const CheckRow = styled.label`
	display: flex;
	align-items: center;
	gap: 8px;
	color: #e8f4ff;
	font-family: 'Montserrat', sans-serif;
	font-size: 13px;
	cursor: pointer;
	flex-shrink: 0;
`

const Footer = styled(Box)`
	display: flex;
	justify-content: space-between;
	gap: 10px;
	padding: 14px 16px;
	flex-shrink: 0;
	border-top: 1px solid var(--border-dim);
`

const FooterActions = styled(Box)`
	display: flex;
	gap: 10px;
	margin-left: auto;
`

const FooterBtn = styled.button<{ $variant: 'gray' | 'red' }>`
	min-width: 110px;
	height: 34px;
	padding: 0 14px;
	border-radius: 4px;
	border: 1px solid
		${(p) => (p.$variant === 'red' ? 'rgba(255, 61, 87, 0.55)' : 'rgba(255, 255, 255, 0.22)')};
	background: ${(p) =>
		p.$variant === 'red' ? 'rgba(255, 61, 87, 0.12)' : 'rgba(255, 255, 255, 0.06)'};
	color: ${(p) => (p.$variant === 'red' ? '#ff8a98' : 'rgba(220, 230, 240, 0.88)')};
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 12px;
	font-weight: 600;
	text-transform: uppercase;
	letter-spacing: 0.05em;
	cursor: pointer;
	transition:
		background-color 0.15s ease,
		border-color 0.15s ease,
		color 0.15s ease,
		transform 0.1s ease;

	&:hover {
		border-color: ${(p) => (p.$variant === 'red' ? 'rgba(255, 61, 87, 0.85)' : 'rgba(255, 255, 255, 0.35)')};
		background: ${(p) =>
			p.$variant === 'red' ? 'rgba(255, 61, 87, 0.2)' : 'rgba(255, 255, 255, 0.1)'};
		color: ${(p) => (p.$variant === 'red' ? '#ffb3bc' : '#fff')};
	}

	&:active {
		transform: scale(0.98);
	}
`

function cloneCards(cards: EventCardConfig[]) {
	return cards.map((card) => ({ ...card }))
}

export default function EventRulesAdminModal() {
	const L = useLocale()
	const dispatch = useDispatch<AppDispatch>()
	const admin = useSelector((state: RootState) => state.main.eventCardsAdmin)
	const menuOpen = useSelector((state: RootState) => state.main.show)
	const [activeIndex, setActiveIndex] = useState(0)
	const [draft, setDraft] = useState<EventCardConfig[]>([])
	const [rulesDraft, setRulesDraft] = useState<EventRulesDocument>(() => emptyRulesDocument())
	const [saving, setSaving] = useState(false)

	useEffect(() => {
		if (admin.open) {
			const source = admin.cards.length > 0 ? admin.cards : FALLBACK_EVENT_CARDS
			setDraft(cloneCards(source))
			setActiveIndex(0)
			setRulesDraft(parseRulesContent(source[0]?.rulesContent ?? '', true))
		}
	}, [admin.open, admin.cards])

	useEffect(() => {
		const card = draft[activeIndex]
		if (!card) return
		setRulesDraft(parseRulesContent(card.rulesContent, true))
	}, [activeIndex])

	const activeCard = draft[activeIndex] ?? EMPTY_EVENT_CARD()

	const updateActive = (patch: Partial<EventCardConfig>) => {
		setDraft((prev) =>
			prev.map((card, index) => (index === activeIndex ? { ...card, ...patch } : card)),
		)
	}

	const close = () => {
		if (isEnvBrowser()) {
			dispatch(setEventCardsAdmin({ open: false }))
			return
		}
		fetchNui('eventRules:closeAdmin', { menuOpen })
	}

	const addCard = () => {
		const next = cloneCards(draft)
		next.push({
			...EMPTY_EVENT_CARD(),
			cardKey: `event_${Date.now()}`,
			sortOrder: next.length + 1,
		})
		setDraft(next)
		setActiveIndex(next.length - 1)
	}

	const removeCard = async () => {
		if (draft.length <= 1) return
		const card = draft[activeIndex]
		if (!isEnvBrowser() && card.cardKey) {
			await fetchNui('eventCards:delete', { cardKey: card.cardKey })
		}
		const next = draft.filter((_, index) => index !== activeIndex)
		setDraft(next)
		setActiveIndex(Math.max(0, activeIndex - 1))
		dispatch(setEventCardsAdmin({ open: true, cards: next }))
	}

	const save = async () => {
		if (saving || !activeCard.cardKey.trim()) return
		setSaving(true)
		try {
			const payload = {
				...activeCard,
				cardKey: activeCard.cardKey.trim(),
				label: activeCard.label.trim() || activeCard.cardKey.trim(),
				sortOrder: activeIndex + 1,
				rulesContent: serializeRulesContent(rulesDraft, true),
			}

			if (isEnvBrowser()) {
				const next = draft.map((card, index) => (index === activeIndex ? payload : card))
				setDraft(next)
				dispatch(setEventCardsAdmin({ open: true, cards: next }))
				dispatch(setEventCards(next))
				return
			}

			const result = await fetchNui<{ ok?: boolean; card?: EventCardConfig }>('eventCards:save', payload)
			if (result?.ok) {
				const next = draft.map((card, index) =>
					index === activeIndex ? (result.card ?? payload) : card,
				)
				setDraft(next)
				dispatch(setEventCardsAdmin({ open: true, cards: next }))
				dispatch(setEventCards(next))
			}
		} finally {
			setSaving(false)
		}
	}

	const tabLabels = useMemo(
		() => draft.map((card) => card.label || card.cardKey || L('ui.event_cards.new_card')),
		[draft, L],
	)

	return (
		<AnimatePresence>
			{admin.open && (
				<Overlay initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={close}>
					<Panel
						as={motion.div}
						initial={{ y: 12, opacity: 0 }}
						animate={{ y: 0, opacity: 1 }}
						exit={{ y: 12, opacity: 0 }}
						onClick={(e) => e.stopPropagation()}>
						<Header>
							<Text textTransform='uppercase' fontWeight='bold' rFontSize={16}>
								{L('ui.event_cards.admin_title')}
							</Text>
							<Button rWidth={110} rHeight={32} rFontSize={11} text={L('ui.event_cards.add')} onClick={addCard} />
						</Header>

						<Tabs>
							{tabLabels.map((label, index) => (
								<Tab
									key={`${draft[index]?.cardKey}-${index}`}
									type='button'
									$active={activeIndex === index}
									onClick={() => setActiveIndex(index)}>
									{label}
								</Tab>
							))}
						</Tabs>

						<ScrollBody>
							<Field>
								<FieldLabel rFontSize={10}>{L('ui.event_cards.card_key')}</FieldLabel>
								<Input
									value={activeCard.cardKey}
									onChange={(e) => updateActive({ cardKey: e.target.value.replace(/\s/g, '_').toLowerCase() })}
									placeholder='racing'
								/>
							</Field>

							<Field>
								<FieldLabel rFontSize={10}>{L('ui.event_cards.label')}</FieldLabel>
								<Input value={activeCard.label} onChange={(e) => updateActive({ label: e.target.value })} />
							</Field>

							<Field>
								<FieldLabel rFontSize={10}>{L('ui.event_cards.description')}</FieldLabel>
								<Input value={activeCard.description} onChange={(e) => updateActive({ description: e.target.value })} />
							</Field>

							<Field>
								<FieldLabel rFontSize={10}>{L('ui.event_cards.event_time')}</FieldLabel>
								<Input
									value={activeCard.eventTime}
									onChange={(e) => updateActive({ eventTime: e.target.value })}
									placeholder='20:00 - 22:00'
								/>
							</Field>

							<Field>
								<FieldLabel rFontSize={10}>{L('ui.event_cards.image_url')}</FieldLabel>
								<Input
									value={activeCard.imageUrl}
									onChange={(e) => updateActive({ imageUrl: e.target.value })}
									placeholder='./assets/webp/car.webp'
								/>
							</Field>

							<Field>
								<FieldLabel rFontSize={10}>{L('ui.event_cards.background_url')}</FieldLabel>
								<Input
									value={activeCard.backgroundUrl}
									onChange={(e) => updateActive({ backgroundUrl: e.target.value })}
									placeholder='https://...'
								/>
							</Field>

							<Field>
								<FieldLabel rFontSize={10}>{L('ui.event_cards.action')}</FieldLabel>
								<Input
									value={activeCard.action}
									onChange={(e) => updateActive({ action: e.target.value })}
									placeholder='openRacing'
								/>
							</Field>

							<CheckRow>
								<input
									type='checkbox'
									checked={activeCard.enabled}
									onChange={(e) => updateActive({ enabled: e.target.checked })}
								/>
								{L('ui.event_cards.enabled')}
							</CheckRow>

							<CheckRow>
								<input
									type='checkbox'
									checked={activeCard.showJoinButton}
									onChange={(e) => updateActive({ showJoinButton: e.target.checked })}
								/>
								{L('ui.event_cards.show_join')}
							</CheckRow>

							<Field>
								<FieldLabel rFontSize={10}>{L('ui.event_cards.join_export')}</FieldLabel>
								<Input
									value={activeCard.joinExport}
									onChange={(e) => updateActive({ joinExport: e.target.value })}
									placeholder='resource_name:exportName'
									disabled={!activeCard.showJoinButton}
								/>
							</Field>

							<Field>
								<FieldLabel rFontSize={10}>{L('ui.event_rules.admin_hint')}</FieldLabel>
								<EventRulesEditor
									value={rulesDraft}
									onChange={(doc) => {
										setRulesDraft(doc)
										updateActive({ rulesContent: serializeRulesContent(doc, false) })
									}}
								/>
							</Field>

							<Field>
								<FieldLabel rFontSize={10}>{L('ui.event_rules.rewards_title')}</FieldLabel>
								<EventRewardsEditor
									value={rulesDraft}
									onChange={(doc) => {
										setRulesDraft(doc)
										updateActive({ rulesContent: serializeRulesContent(doc, false) })
									}}
								/>
							</Field>
						</ScrollBody>

						<Footer>
							<FooterBtn type='button' $variant='red' onClick={removeCard}>
								{L('ui.event_cards.delete')}
							</FooterBtn>
							<FooterActions>
								<Button
									rWidth={130}
									rHeight={34}
									rFontSize={12}
									text={saving ? L('ui.event_rules.saving') : L('ui.event_rules.save')}
									disabled={saving}
									cursor={saving ? 'not-allowed' : 'pointer'}
									onClick={save}
								/>
								<FooterBtn type='button' $variant='gray' onClick={close}>
									{L('ui.common.close')}
								</FooterBtn>
							</FooterActions>
						</Footer>
					</Panel>
				</Overlay>
			)}
		</AnimatePresence>
	)
}
