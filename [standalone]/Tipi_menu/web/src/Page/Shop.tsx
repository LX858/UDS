import { Box } from 'lr-components'
import React, { useCallback, useEffect, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { RootState, AppDispatch } from '../store'
import MenuPageShell from '../components/MenuPageShell'
import styled from 'styled-components'
import { fetchNui } from '../utils/fetchNui'
import { useLocale } from '../hooks/useLocale'
import { EventCardBlock } from '../components/EventCard'
import EventRulesModal from '../components/EventRulesModal'
import EventCardsCarousel from '../components/EventCardsCarousel'
import { FALLBACK_EVENT_CARDS, EVENT_CARD_CDN, resolveEventCardBackground } from '../constants/eventCards'
import { EventCardConfig } from '../types/eventCard'
import { setEventCards } from '../store/main'
import { isEnvBrowser } from '../utils/misc'

const EventGrid = styled(Box)`
	background: transparent;
	padding: 12px 16px;
	box-sizing: border-box;
	height: 100%;
	min-height: 0;
`

function Shop() {
	const L = useLocale()
	const dispatch = useDispatch<AppDispatch>()
	const store = useSelector((state: RootState) => state.main)
	const cards = store.eventCards.length > 0 ? store.eventCards : FALLBACK_EVENT_CARDS
	const [rulesModal, setRulesModal] = useState<{
		open: boolean
		title: string
		content: string
	}>({
		open: false,
		title: '',
		content: '',
	})

	useEffect(() => {
		if (store.page !== 'shop') return

		if (isEnvBrowser()) {
			if (store.eventCards.length === 0) {
				dispatch(setEventCards(FALLBACK_EVENT_CARDS))
			}
			return
		}

		fetchNui<{ cards?: EventCardConfig[] }>('eventCards:getList')
			.then((result) => {
				if (result?.cards) {
					dispatch(setEventCards(result.cards))
				}
			})
			.catch(() => {})
	}, [store.page, dispatch])

	const onButtonAction = (action: string) => {
		if (!action) return
		fetchNui('shop:action', action)
	}

	const openRules = async (card: EventCardConfig) => {
		let content = card.rulesContent
		if (!isEnvBrowser()) {
			try {
				const result = await fetchNui<{ content?: string; card?: EventCardConfig }>('eventRules:get', {
					cardKey: card.cardKey,
				})
				if (result?.content != null) {
					content = result.content
				}
			} catch {
			}
		}

		setRulesModal({
			open: true,
			title: `${L('ui.event_rules.title')} — ${card.label}`,
			content,
		})
	}

	const onJoinAction = async (event: EventCardConfig) => {
		if (!event.enabled || !event.showJoinButton) return

		if (isEnvBrowser()) {
			onButtonAction(event.action)
			return
		}

		if (event.joinExport?.trim()) {
			const result = await fetchNui<{ ok?: boolean }>('eventCards:join', { cardKey: event.cardKey })
			if (result?.ok) return
		}

		if (event.action) {
			onButtonAction(event.action)
		}
	}

	const renderCard = useCallback(
		(event: EventCardConfig) => {
			const backgroundImage = resolveEventCardBackground(event)
			const useFallbackArt = backgroundImage === EVENT_CARD_CDN.fallbackBackground
			return (
				<Box width='100%' height='100%' minWidth={0} minHeight={0}>
					<EventCardBlock
						layout='posterDock'
						title={event.label}
						subtitle={event.description}
						eventTime={event.eventTime}
						image={event.imageUrl || undefined}
						backgroundImage={backgroundImage}
						backgroundCover={!useFallbackArt}
						backgroundContain={useFallbackArt}
						backgroundPosition='center top'
						enabled={event.enabled}
						showJoinButton={event.showJoinButton}
						showOpen={false}
						openLabel={L('ui.shop.action')}
						showRules
						rulesLabel={L('ui.event_rules.button')}
						onRulesClick={() => openRules(event)}
						onJoinClick={() => onJoinAction(event)}
						onClick={() => onButtonAction(event.action)}
					/>
				</Box>
			)
		},
		[L],
	)

	return (
		<MenuPageShell active={store.page === 'shop'} className='mp-shop-panel' showPanelChrome={false}>
			<EventGrid>
				<EventCardsCarousel cards={cards} renderCard={renderCard} />
			</EventGrid>

			<EventRulesModal
				open={rulesModal.open}
				title={rulesModal.title}
				content={rulesModal.content}
				closeLabel={L('ui.common.close')}
				onClose={() => setRulesModal((prev) => ({ ...prev, open: false }))}
			/>
		</MenuPageShell>
	)
}

export default Shop
