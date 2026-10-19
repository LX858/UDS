import { Box, Text, useWindowSize } from 'lr-components'
import React, { useCallback, useEffect, useRef, useState } from 'react'

import { useSelector } from 'react-redux'
import { RootState } from '../store'
import ProfileSidebar, { ProfilePanel, ProfileSlot } from '../components/ProfileSidebar'
import DevelopingCardBlock, { DevelopingCardContent, developingCardStyles } from '../components/DevelopingCardBlock'
import MenuPageShell from '../components/MenuPageShell'
import { motion } from 'framer-motion'
import Button from '../components/Button'
import { format } from 'date-fns'
import { fetchNui } from '../utils/fetchNui'
import styled from 'styled-components'
import { useLocale } from '../hooks/useLocale'
import { menuCardBase, menuCardHover } from '../styles/menuCardStyles'
import { EventCardBlock, PointBalance, PointBalanceAmount, PointBalanceCoin, PointBalanceDivider, PointBalanceLabel, PointBalanceValue } from '../components/EventCard'
import { DONATE_BANNER_ASPECT_RATIO, EVENT_CARD_CDN, GIFTCODE_BANNER_ASPECT_RATIO } from '../constants/eventCards'
import DailyRewardsCompactCard from '../components/DailyRewardsCompactCard'
import { isEnvBrowser } from '../utils/misc'
import type { DailyRewardsOpenPayload } from '@tipi-daily-rewards/components/DailyRewardsApp'
import DailyRewardsEmbed, { useDailyRewardsSummaryLoader } from './DailyRewardsEmbed'
import { buildDailyRewardsDevPayloadByScenario, buildSummaryFromDevPayload, type DevCalendarScenario } from '../constants/dailyRewardsDev'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { setEmbedAssetBase, setEmbeddedResourceName } from '@tipi-daily-rewards/utils/assets'

const DonateCardSlot = styled(Box)`
	width: 100%;
	flex-shrink: 0;
	aspect-ratio: ${DONATE_BANNER_ASPECT_RATIO};
	min-height: 0;
`

const GiftCodeSection = styled(Box)`
	width: 100%;
	flex-shrink: 0;
	display: flex;
	flex-direction: column;
	gap: 8px;
	min-height: 0;
`

const CodeTabRail = styled(Box)`
	width: 100%;
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 8px;
	flex-shrink: 0;
`

const CodeTabBtn = styled.button<{ $active?: boolean }>`
	width: 100%;
	border: 1px solid ${(p) => (p.$active ? 'var(--cyan)' : 'var(--border-dim)')};
	border-radius: 4px;
	padding: 9px 12px;
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 11px;
	font-weight: 700;
	line-height: 1;
	text-transform: uppercase;
	letter-spacing: 0.07em;
	cursor: pointer;
	transition:
		background-color 0.2s ease,
		border-color 0.2s ease,
		color 0.2s ease,
		box-shadow 0.2s ease,
		transform 0.15s ease;
	background: ${(p) =>
		p.$active
			? 'linear-gradient(180deg, rgba(0, 229, 255, 0.22) 0%, rgba(0, 18, 36, 0.92) 100%)'
			: 'rgba(0, 10, 22, 0.72)'};
	color: ${(p) => (p.$active ? 'var(--cyan)' : 'var(--text-sub)')};
	box-shadow: ${(p) =>
		p.$active
			? '0 0 16px var(--cyan-glow-active), inset 0 1px 0 rgba(255,255,255,0.1)'
			: 'inset 0 1px 0 rgba(255,255,255,0.03)'};
	text-shadow: ${(p) => (p.$active ? '0 0 10px rgba(0, 229, 255, 0.35)' : 'none')};

	&:hover {
		border-color: ${(p) => (p.$active ? 'var(--cyan)' : 'var(--border)')};
		background: ${(p) =>
			p.$active
				? 'linear-gradient(180deg, rgba(0, 229, 255, 0.28) 0%, rgba(0, 18, 36, 0.95) 100%)'
				: 'var(--cyan-tab-hover)'};
		color: ${(p) => (p.$active ? 'var(--cyan)' : '#fff')};
	}

	&:active {
		transform: scale(0.98);
	}
`

const GiftCodeCardSlot = styled(Box)`
	width: 100%;
	flex-shrink: 0;
	aspect-ratio: ${GIFTCODE_BANNER_ASPECT_RATIO};
	min-height: 0;
`

const InfoCard = styled(Box)`
	${menuCardBase}
`

const GiftCodeCard = styled(InfoCard)<{ $developing?: boolean }>`
	position: relative;
	overflow: hidden;
	width: 100%;
	height: 100%;
	display: flex;
	flex-direction: column;
	justify-content: center;
	box-sizing: border-box;
	padding: 14px 12px 16px;
	gap: 8px;
	min-height: 0;
	background-color: rgba(0, 8, 18, 0.35);
	${(p) => p.$developing && developingCardStyles}
`

const GiftCodeBackground = styled(Box)`
	position: absolute;
	inset: 0;
	z-index: 0;
	background-image: url(${EVENT_CARD_CDN.giftcodeBanner});
	background-size: cover;
	background-position: center center;
	background-repeat: no-repeat;
	pointer-events: none;
`

const GiftCodeContent = styled(Box)`
	position: relative;
	z-index: 1;
	flex: 1;
	min-height: 0;
	display: flex;
	flex-direction: column;
	justify-content: center;
`

const CodeTabPanel = styled(Box)`
	flex: 1;
	min-height: 0;
	display: flex;
	flex-direction: column;
	justify-content: center;
	align-items: center;
	gap: 16px;
	padding: 6px 0 2px;
`

const GiftCodeInputRow = styled(Box)`
	width: 100%;
	flex-shrink: 0;
	display: flex;
	justify-content: center;
`

const GiftCodeInput = styled(Box)`
	width: 78%;
	max-width: 240px;
	min-width: 0;
`

const GiftCodeButtonRow = styled(Box)`
	width: 100%;
	flex-shrink: 0;
	display: flex;
	justify-content: center;
	margin-top: 2px;
`

const ClickCard = styled(Box)`
	${menuCardBase}
	cursor: pointer;

	&:hover {
		${menuCardHover}
	}
`

const MapCard = styled(ClickCard)`
	background-color: rgba(0, 20, 36, 0.28);

	&:hover {
		filter: brightness(1.03);
		border-color: var(--border);
	}
`

const CardTitle = styled(Box)`
	position: absolute;
	z-index: 3;
	display: flex;
	align-items: center;
	gap: 10px;
	pointer-events: none;
`

const CardMediaFill = styled(motion.div)`
	position: absolute;
	inset: 0;
	z-index: 0;
	width: 100%;
	height: 100%;
`

const MapMedia = styled(CardMediaFill)`
	filter: brightness(1.12) saturate(1.06);
`

const DevPanel = styled(Box)`
	position: fixed;
	right: 14px;
	bottom: 14px;
	z-index: 150;
	display: flex;
	flex-direction: column;
	gap: 8px;
	padding: 10px;
	border-radius: 6px;
	border: 1px solid rgba(0, 229, 255, 0.35);
	background: rgba(0, 8, 16, 0.88);
	box-shadow: 0 8px 20px rgba(0, 0, 0, 0.45);
`

const DevPanelTitle = styled(Text)`
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 10px;
	font-weight: 700;
	letter-spacing: 0.08em;
	text-transform: uppercase;
	color: var(--cyan);
`

const DevPanelGrid = styled(Box)`
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 6px;
`

const DevPanelHint = styled(Text)`
	font-size: 9px;
	line-height: 1.35;
	color: var(--text-muted);
	max-width: 220px;
`

const DevPanelBtn = styled.button`
	border: 1px solid rgba(0, 229, 255, 0.35);
	border-radius: 4px;
	padding: 6px 8px;
	background: rgba(0, 24, 40, 0.75);
	color: #d8f9ff;
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 10px;
	font-weight: 700;
	letter-spacing: 0.04em;
	text-transform: uppercase;
	cursor: pointer;
	transition: background-color 0.15s ease, border-color 0.15s ease, transform 0.12s ease;

	&:hover {
		background: rgba(0, 34, 54, 0.88);
		border-color: rgba(0, 229, 255, 0.58);
	}

	&:active {
		transform: scale(0.98);
	}
`

type CodeTab = 'gift' | 'invite'

function Main() {
	const L = useLocale()
	const store = useSelector((state: RootState) => state.main)
	const windowSize = useWindowSize()
	const [giftCode, setGiftCode] = useState('')
	const [codeTab, setCodeTab] = useState<CodeTab>('gift')
	const [loading, setLoading] = useState(false)
	const [dailyOpen, setDailyOpen] = useState(false)
	const [dailyPayload, setDailyPayload] = useState<DailyRewardsOpenPayload | null>(null)
	const [dailyLoading, setDailyLoading] = useState(false)
	const [devCalendarScenario, setDevCalendarScenario] = useState<DevCalendarScenario>('default')
	const dailyEmbedRef = useRef<HTMLDivElement>(null)
	const dailyCompactRef = useRef<HTMLDivElement>(null)
	const isMainActive = store.page === 'main'
	const { summary: dailySummary, loading: dailySummaryLoading, reload: reloadDailySummary, setSummary: setDailySummary } =
		useDailyRewardsSummaryLoader(isMainActive)
	const showDevPanel = isEnvBrowser() && isMainActive

	const openDailyRewards = useCallback(async () => {
		if (dailyLoading || dailyOpen) return
		setDailyLoading(true)
		try {
			const payload = await fetchNui<DailyRewardsOpenPayload & { error?: string }>(
				'dailyRewards:open',
				undefined,
				isEnvBrowser()
					? buildDailyRewardsDevPayloadByScenario(devCalendarScenario)
					: undefined,
			)
			if (payload?.error) return
			setDailyPayload(payload)
			setDailyOpen(true)
			void fetchNui('dailyRewards:setOpen', true)
		} finally {
			setDailyLoading(false)
		}
	}, [dailyLoading, dailyOpen, devCalendarScenario])

	const closeDailyRewards = useCallback(() => {
		setDailyOpen(false)
		setDailyPayload(null)
		void fetchNui('dailyRewards:setOpen', false)
		void reloadDailySummary()
	}, [reloadDailySummary])

	const toggleDailyRewards = useCallback(() => {
		if (dailyOpen) {
			closeDailyRewards()
			return
		}
		void openDailyRewards()
	}, [closeDailyRewards, dailyOpen, openDailyRewards])

	useEffect(() => {
		if (!isMainActive) return
		setEmbeddedResourceName('Tipi_Daily_Rewards')
		setEmbedAssetBase(isEnvBrowser() ? '/images/daily-rewards' : './images/daily-rewards')
	}, [isMainActive])

	useEffect(() => {
		if (!dailyOpen) return
		const onKeyDown = (event: KeyboardEvent) => {
			if (event.key === 'Escape') {
				event.stopPropagation()
				closeDailyRewards()
			}
		}
		window.addEventListener('keydown', onKeyDown, true)
		return () => window.removeEventListener('keydown', onKeyDown, true)
	}, [closeDailyRewards, dailyOpen])

	useEffect(() => {
		if (!dailyOpen) return
		const onPointerDown = (event: PointerEvent) => {
			const target = event.target as Node
			if (dailyEmbedRef.current?.contains(target)) return
			if (dailyCompactRef.current?.contains(target)) return
			closeDailyRewards()
		}
		document.addEventListener('pointerdown', onPointerDown, true)
		return () => document.removeEventListener('pointerdown', onPointerDown, true)
	}, [closeDailyRewards, dailyOpen])

	useEffect(() => {
		if (!isMainActive && dailyOpen) closeDailyRewards()
	}, [closeDailyRewards, dailyOpen, isMainActive])

	useNuiEvent('openDailyRewards', () => {
		void openDailyRewards()
	})
	const onButtonAction = (key: string, value?: string) => {
		fetchNui('main:action', { key, value })
	}

	const handleCodeSubmit = () => {
		if (loading || codeTab !== 'gift') return
		if (!giftCode.trim()) return

		setLoading(true)
		fetchNui('giftCode:redeem', giftCode.trim(), 1)
		setGiftCode('')
		setTimeout(() => setLoading(false), 10000)
	}

	const previewMilestoneHud = useCallback((minutes: number) => {
		window.postMessage(
			{ action: 'dailyMonthClaimReady', data: { minutes: Math.max(1, minutes) } },
			'*',
		)
	}, [])

	useNuiEvent<{ minutes?: number }>('dailyMonthClaimReady', () => {
		// HUD render ở App (DailyMonthClaimHud) — Main chỉ reload summary khi đang xem
		if (isMainActive) void reloadDailySummary()
	})

	const applyDevCalendarScenario = useCallback(
		(scenario: DevCalendarScenario) => {
			if (!isEnvBrowser()) return
			const payload = buildDailyRewardsDevPayloadByScenario(scenario)
			setDevCalendarScenario(scenario)
			setDailyPayload(payload)
			setDailySummary((prev) => ({
				...(prev ?? buildSummaryFromDevPayload(payload)),
				...buildSummaryFromDevPayload(payload),
			}))
			setDailyOpen(true)
		},
		[setDailySummary],
	)

	const date = new Date(store.playerInfo.timeRegistered)

	const SHOW_MARRIAGE = false // tạm ẩn — đổi true để bật lại

	const profileRows = [
		{ key: 'account', label: L('ui.profile.account_name'), value: store.playerInfo.name },
		{ key: 'id', label: L('ui.profile.player_id'), value: `#${store.playerInfo.id}` },
		{ key: 'status', label: L('ui.profile.status'), value: L('ui.profile.status_verified') },
		{
			key: 'phone',
			label: L('ui.profile.phone'),
			value: String(store.playerInfo.phoneNumber ?? L('ui.profile.phone_empty')),
		},
		{ key: 'job', label: L('ui.profile.job'), value: store.playerInfo.job },
		...(SHOW_MARRIAGE
			? [{ key: 'marriage', label: L('ui.profile.marriage'), value: L('ui.profile.marriage_single') }]
			: []),
		{
			key: 'age',
			label: L('ui.profile.age'),
			value:
				store.playerInfo.age != null && store.playerInfo.age !== ''
					? String(store.playerInfo.age)
					: L('ui.profile.phone_empty'),
		},
		{ key: 'registered', label: L('ui.profile.registered_at'), value: format(date, 'dd/MM/yyyy') },
	]

	return (
		<MenuPageShell active={isMainActive} showPanelChrome={false}>
			<Box width='100%' height='100%' position='relative' display='flex' rGap={14} alignItems='stretch' rPadding={4}>
				<ProfilePanel rWidth={262}>
					<ProfileSlot>
						<ProfileSidebar rows={profileRows} title={L('ui.profile.panel_title')} />
					</ProfileSlot>
					<Box ref={dailyCompactRef} width='100%' flex={1} minHeight={0} display='flex'>
						<DailyRewardsCompactCard
							title={L('ui.main.daily_title')}
							highlight={L('ui.main.daily_highlight')}
							subtitle={L('ui.main.daily_subtitle')}
							monthProgressLabel={L('ui.main.daily_month_progress')}
							todayStatLabel={L('ui.main.daily_today_stat')}
							todayLabel={L('ui.main.daily_today')}
							loadingLabel={L('ui.main.daily_loading')}
							unavailableLabel={L('ui.main.daily_unavailable')}
							summary={dailySummary}
							loading={dailySummaryLoading || dailyLoading}
							monthBoardLoading={dailyLoading}
							expanded={dailyOpen}
							onToggle={() => toggleDailyRewards()}
						/>
					</Box>
				</ProfilePanel>

				<Box
					flexGrow={1}
					minWidth={0}
					height='100%'
					display='flex'
					alignItems='stretch'
					rGap={14}
					minHeight={0}
					className='mp-main-content'>
					{dailyOpen && dailyPayload ? (
						<Box
							ref={dailyEmbedRef}
							width='100%'
							height='100%'
							minHeight={0}
							flexGrow={1}
							minWidth={0}
							className='mp-daily-embed-host'>
							<DailyRewardsEmbed
								openPayload={dailyPayload}
								onClose={closeDailyRewards}
								onSummaryChange={(patch) =>
									setDailySummary((prev) => {
										if (!prev) return prev
										const next = { ...prev, ...patch }
										if (patch.canClaimToday === false && prev.canClaimToday) {
											next.checkedCount = Math.min(
												(prev.checkedCount || 0) + 1,
												prev.daysInMonth || 31,
											)
										}
										return next
									})
								}
							/>
						</Box>
					) : (
						<>
					<Box flex={1.55} minWidth={0} height='100%' minHeight={0} display='flex' flexDirection='column' rGap={14}>
						<MapCard
							width='100%'
							flex={1}
							minHeight={0}
							onClick={() => onButtonAction('openMap')}>
							<Box
								position='absolute'
								rTop={0}
								rLeft={0}
								rRight={0}
								rHeight={52}
								zIndex={1}
								background='linear-gradient(180deg, rgba(0, 14, 26, 0.48) 0%, transparent 100%)'
								pointerEvents='none'
							/>
							<CardTitle rTop={10} rLeft={10}>
								<Text textTransform='uppercase' fontWeight='bold' rFontSize={18}>
									{L('ui.main.map')}
								</Text>
							</CardTitle>
							<MapMedia
								whileTap={{ scale: 0.98 }}
								style={{
									backgroundImage: 'url(./assets/webp/map2.png)',
									backgroundPosition: 'center bottom',
									backgroundRepeat: 'no-repeat',
									backgroundSize: 'cover',
								}}
							/>
						</MapCard>

						<DonateCardSlot>
							<EventCardBlock
								variant='banner'
								backgroundImage={EVENT_CARD_CDN.donateBanner}
								backgroundContain
								showOpen={false}
								title={
									<Box display='flex' alignItems='center' rGap={8}>
										<Box
											rWidth={20}
											rHeight={17}
											backgroundImage='url(./assets/svg/coin.svg)'
											backgroundPosition='center'
											backgroundRepeat='no-repeat'
											backgroundSize='cover'
											flexShrink={0}
										/>
										<Text
											textTransform='uppercase'
											fontWeight='bold'
											rFontSize={16}
											rLineHeight={20}
											textShadow='0 2px 12px rgba(0,0,0,0.65)'>
											{L('ui.main.donate_title')}{' '}
											<span style={{ color: 'var(--cyan)' }}>{L('ui.main.donate_highlight')}</span>
										</Text>
									</Box>
								}
								subtitle={L('ui.main.donate_desc')}
								onClick={() => fetchNui('shop:action', 'openXnCase')}>
								<PointBalance $compact>
									<PointBalanceLabel $compact>{L('ui.main.donate_balance')}</PointBalanceLabel>
									<PointBalanceDivider />
									<PointBalanceAmount>
										<PointBalanceValue $compact>
											{store.playerCoin.toLocaleString('vi-VN')}
										</PointBalanceValue>
										<PointBalanceCoin $compact />
									</PointBalanceAmount>
								</PointBalance>
							</EventCardBlock>
						</DonateCardSlot>
					</Box>

					<Box flex={1} minWidth={0} height='100%' minHeight={0} display='flex' flexDirection='column' rGap={14}>
						<GiftCodeSection>
							<CodeTabRail>
								<CodeTabBtn
									type='button'
									$active={codeTab === 'gift'}
									onClick={() => setCodeTab('gift')}>
									{L('ui.main.code_tab_gift')}
								</CodeTabBtn>
								<CodeTabBtn
									type='button'
									$active={codeTab === 'invite'}
									onClick={() => setCodeTab('invite')}>
									{L('ui.main.code_tab_invite')}
								</CodeTabBtn>
							</CodeTabRail>

							<GiftCodeCardSlot>
								<GiftCodeCard $developing={codeTab === 'invite'}>
									<GiftCodeBackground />
									<GiftCodeContent>
										{codeTab === 'gift' ? (
											<CodeTabPanel>
												<GiftCodeInputRow>
													<GiftCodeInput
														rHeight={36}
														backgroundColor='rgba(0, 30, 50, 0.82)'
														border='1px solid var(--border-dim)'
														rBorderRadius={6}
														display='flex'
														alignItems='center'
														rPadding={8}>
														<input
															type='text'
															value={giftCode}
															onChange={(e) => setGiftCode(e.target.value)}
															onKeyDown={(e) => e.key === 'Enter' && handleCodeSubmit()}
															placeholder={L('ui.main.giftcode_placeholder')}
															style={{
																width: '100%',
																height: '100%',
																background: 'transparent',
																border: 'none',
																color: '#FFFFFF',
																fontSize: `${Math.max(windowSize.ratioWidth * 12, 11)}px`,
																outline: 'none',
															}}
														/>
													</GiftCodeInput>
												</GiftCodeInputRow>
												<GiftCodeButtonRow>
													<Button
														rWidth={140}
														rHeight={34}
														rFontSize={11}
														text={
															loading
																? L('ui.main.giftcode_loading')
																: L('ui.main.giftcode_confirm')
														}
														cursor={loading ? 'not-allowed' : 'pointer'}
														onClick={handleCodeSubmit}
														disabled={loading}
													/>
												</GiftCodeButtonRow>
											</CodeTabPanel>
										) : (
											<DevelopingCardContent
												compact
												title={L('ui.main.developing_title')}
												description={L('ui.main.invite_dev')}
											/>
										)}
									</GiftCodeContent>
								</GiftCodeCard>
							</GiftCodeCardSlot>
						</GiftCodeSection>

						<DevelopingCardBlock
							fill
							title={L('ui.main.developing_title')}
							description={L('ui.main.developing_desc')}
						/>
					</Box>
						</>
					)}
				</Box>
			</Box>
			{showDevPanel ? (
				<DevPanel>
					<DevPanelTitle>Dev Panel Rewards</DevPanelTitle>
					<DevPanelGrid>
						<DevPanelBtn type='button' onClick={() => previewMilestoneHud(1)}>
							HUD tháng 1p
						</DevPanelBtn>
						<DevPanelBtn type='button' onClick={() => applyDevCalendarScenario('fresh-start')}>
							Mới chơi
						</DevPanelBtn>
						<DevPanelBtn type='button' onClick={() => applyDevCalendarScenario('missed-yesterday')}>
							Quên hôm qua
						</DevPanelBtn>
						<DevPanelBtn type='button' onClick={() => applyDevCalendarScenario('missed-limit')}>
							Hết lượt bù
						</DevPanelBtn>
						<DevPanelBtn type='button' onClick={() => applyDevCalendarScenario('not-enough-money')}>
							Thiếu tiền bù
						</DevPanelBtn>
					</DevPanelGrid>
					<DevPanelHint>
						HUD 1p hiện cả khi đóng ESC. Hết lượt bù: badge HẾT LƯỢT + toast đúng. Thiếu tiền: toast Bù
						$5000.
					</DevPanelHint>
				</DevPanel>
			) : null}
		</MenuPageShell>
	)
}

export default Main
