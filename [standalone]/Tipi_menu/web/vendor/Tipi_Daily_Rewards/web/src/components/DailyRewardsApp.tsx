import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import CalendarGrid from './CalendarGrid'
import CountdownTimer from './CountdownTimer'
import RewardRevealModal from './RewardRevealModal'
import StreakMilestonesBar from './StreakMilestonesBar'
import { buildDevRewards, getDevDaysInMonth } from '../constants/devRewards'
import { DEFAULT_LOCALES } from '../constants/rewards'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { buildStatusesFromServer, parseMonthCollected } from '../utils/status'
import { buildCurrentMonth, DEV_CALENDAR } from '../utils/calendar'
import { getClaimSoundUrl, getMysteryRewardImage, setAssetConfig } from '../utils/assets'
import { fetchNui, fetchParentNui, isEnvBrowser, setNuiEventPrefix } from '../utils/nui'
import { missedClaimPriceAt, normalizeMissedMultiplier } from '../utils/missedPrice'
import type {
	CheckInTrack,
	Locales,
	NuiMessage,
	OnlineSyncData,
	PlayerRewardData,
	RewardConfig,
	RewardStatus,
	SelectedReward,
	StreakPayload,
	VipPackBoughtData,
} from '../types'

export type DailyRewardsOpenPayload = {
	data: PlayerRewardData
	items?: Record<string, RewardConfig>
	locales?: Locales
	daysInMonth?: number
	monthKey?: string
	calendarYear?: number
	calendarMonth?: number
	mysteryImageUrl?: string
	inventoryImageTemplate?: string
	inventoryImageCdn?: string
	itemImageResourceTemplate?: string
	clothingImageUrl?: string
	clothingImageExt?: string
	clothingComponents?: import('../types').ClothingComponentOption[]
}

export type DailyRewardsAppProps = {
	embedded?: boolean
	onClose?: () => void
	nuiPrefix?: string
	initialOpen?: DailyRewardsOpenPayload | null
	onSyncOnline?: (data: OnlineSyncData) => void
	onMonthClaimed?: (day: number) => void
	onVipPackBought?: () => void
}

const DEV_ONLINE_MINUTES = 5
function buildInitialStatuses(rewards: Record<string, RewardConfig>) {
	const statuses: Record<number, RewardStatus> = {}
	Object.keys(rewards).forEach((key) => {
		statuses[Number(key) + 1] = 'undiscovered'
	})
	return statuses
}

export default function DailyRewardsApp({
	embedded = false,
	onClose,
	nuiPrefix = '',
	initialOpen = null,
	onMonthClaimed,
	onVipPackBought,
}: DailyRewardsAppProps = {}) {
	const devDaysInMonth = getDevDaysInMonth()
	const devRewards = useMemo(() => buildDevRewards(devDaysInMonth), [devDaysInMonth])
	const [visible, setVisible] = useState(isEnvBrowser() || Boolean(embedded && initialOpen))
	const [closing, setClosing] = useState(false)
	const [track, setTrack] = useState<CheckInTrack>('normal')
	const [rewards, setRewards] = useState<Record<string, RewardConfig>>(isEnvBrowser() ? devRewards : {})
	const [vipRewards, setVipRewards] = useState<Record<string, RewardConfig>>(isEnvBrowser() ? devRewards : {})
	const [locales, setLocales] = useState<Locales>(DEFAULT_LOCALES)
	const [statuses, setStatuses] = useState<Record<number, RewardStatus>>(() => buildInitialStatuses({}))
	const [vipStatuses, setVipStatuses] = useState<Record<number, RewardStatus>>(() => buildInitialStatuses({}))
	const [selectedReward, setSelectedReward] = useState<SelectedReward | null>(null)
	const [onlineMinutes, setOnlineMinutes] = useState(isEnvBrowser() ? DEV_ONLINE_MINUTES : 0)
	const [presentToday, setPresentToday] = useState(isEnvBrowser())
	const [hasVipPack, setHasVipPack] = useState(isEnvBrowser())
	const [vipPackPrice, setVipPackPrice] = useState(99)
	const [missedDayClaimPrice, setMissedDayClaimPrice] = useState(isEnvBrowser() ? 5000 : 0)
	const [missedDayClaimBasePrice, setMissedDayClaimBasePrice] = useState(isEnvBrowser() ? 5000 : 0)
	const [missedDayClaimMultiplier, setMissedDayClaimMultiplier] = useState(isEnvBrowser() ? 2 : 1)
	const [buyingVip, setBuyingVip] = useState(false)
	const [streak, setStreak] = useState<StreakPayload>({ current: isEnvBrowser() ? 2 : 0, milestones: [] })
	const [claimingStreakDays, setClaimingStreakDays] = useState<number | null>(null)
	const [todayReward, setTodayReward] = useState(isEnvBrowser() ? DEV_CALENDAR.todayDay : 0)
	const [daysInMonth, setDaysInMonth] = useState(isEnvBrowser() ? devDaysInMonth : 31)
	const [calendarYear, setCalendarYear] = useState(isEnvBrowser() ? DEV_CALENDAR.year : new Date().getFullYear())
	const [calendarMonth, setCalendarMonth] = useState(isEnvBrowser() ? DEV_CALENDAR.month : new Date().getMonth() + 1)
	const [monthFreeDays, setMonthFreeDays] = useState<Record<string, boolean>>({})
	const [missedClaimsCount, setMissedClaimsCount] = useState(0)
	const [maxMissedClaimsPerMonth, setMaxMissedClaimsPerMonth] = useState(0)
	const [milestoneHudQueue, setMilestoneHudQueue] = useState<Array<{ id: number; minutes: number }>>([])
	const [milestoneHudActive, setMilestoneHudActive] = useState<{ id: number; minutes: number } | null>(null)
	const [resetOsTime, setResetOsTime] = useState(isEnvBrowser() ? 7200 : 0)

	const milestoneHudTimerRef = useRef<number | null>(null)
	const collectedRef = useRef<Record<string, boolean>>({})
	const vipCollectedRef = useRef<Record<string, boolean>>({})
	const eligibleRef = useRef<Record<string, boolean>>({})
	const hasVipPackRef = useRef(hasVipPack)
	const missedClaimsCountRef = useRef(missedClaimsCount)
	const maxMissedClaimsRef = useRef(maxMissedClaimsPerMonth)
	const onlineMinutesRef = useRef(onlineMinutes)
	const presentTodayRef = useRef(presentToday)
	const todayRewardRef = useRef(todayReward)
	const [toast, setToast] = useState<{ id: number; message: string; type: 'error' | 'info' | 'success' } | null>(
		null,
	)
	const toastTimerRef = useRef<number | null>(null)

	const showToast = useCallback((message: string, type: 'error' | 'info' | 'success' = 'error') => {
		const text = (message || '').trim()
		if (!text) return
		if (toastTimerRef.current !== null) {
			window.clearTimeout(toastTimerRef.current)
		}
		setToast({ id: Date.now(), message: text, type })
		toastTimerRef.current = window.setTimeout(() => {
			setToast(null)
			toastTimerRef.current = null
		}, 3200)
	}, [])

	const showClaimError = useCallback(
		(msg: string) => {
			showToast(msg, 'error')
		},
		[showToast],
	)

	useEffect(() => {
		hasVipPackRef.current = hasVipPack
	}, [hasVipPack])

	useEffect(() => {
		missedClaimsCountRef.current = missedClaimsCount
	}, [missedClaimsCount])

	useEffect(() => {
		maxMissedClaimsRef.current = maxMissedClaimsPerMonth
	}, [maxMissedClaimsPerMonth])

	useEffect(() => {
		onlineMinutesRef.current = onlineMinutes
	}, [onlineMinutes])

	useEffect(() => {
		presentTodayRef.current = presentToday
	}, [presentToday])

	useEffect(() => {
		todayRewardRef.current = todayReward
	}, [todayReward])

	const calendarMonthView = useMemo(
		() => buildCurrentMonth(calendarYear, calendarMonth, rewards),
		[calendarYear, calendarMonth, rewards],
	)
	const vipCalendarMonthView = useMemo(
		() => buildCurrentMonth(calendarYear, calendarMonth, vipRewards),
		[calendarYear, calendarMonth, vipRewards],
	)

	const rebuildStatuses = useCallback(
		(totalDays: number, today: number) => {
			const missedRemaining = maxMissedClaimsRef.current - missedClaimsCountRef.current
				setStatuses(
				buildStatusesFromServer(totalDays, today, collectedRef.current, eligibleRef.current, {
					missedClaimsRemaining: maxMissedClaimsRef.current > 0 ? missedRemaining : undefined,
				}),
			)
			setVipStatuses(
				buildStatusesFromServer(totalDays, today, vipCollectedRef.current, eligibleRef.current, {
					requireVipPack: true,
					hasVipPack: hasVipPackRef.current,
					missedClaimsRemaining: maxMissedClaimsRef.current > 0 ? missedRemaining : undefined,
				}),
			)
		},
		[],
	)

	const closeUi = useCallback(() => {
		if (closing) return
		setClosing(true)
		setSelectedReward(null)
		// Gửi NUI fire-and-forget — UI tự đóng sau 250ms bất kể NUI có response hay không
		const event = embedded ? 'close' : 'Close'
		fetchNui(event).catch(() => {})
		window.setTimeout(() => {
			setVisible(false)
			setClosing(false)
			onClose?.()
		}, 250)
	}, [closing, embedded, onClose])

	const handleExit = useCallback(() => {
		if (selectedReward) {
			setSelectedReward(null)
			return
		}
		closeUi()
	}, [closeUi, selectedReward])

	const applyServerState = useCallback(
		(payload: PlayerRewardData | OnlineSyncData, totalDays: number) => {
			let collectedChanged = false
			if ('monthCollected' in payload && payload.monthCollected) {
				collectedRef.current = payload.monthCollected
				collectedChanged = true
			} else if ('playerData' in payload && payload.playerData) {
				const raw = JSON.parse(payload.playerData.collected || '{}') as Record<string, boolean>
				const monthKey =
					('monthKey' in payload && payload.monthKey) ||
					`${calendarYear}-${String(calendarMonth).padStart(2, '0')}`
				collectedRef.current = parseMonthCollected(raw, monthKey)
				collectedChanged = true
			}

			if ('vipMonthCollected' in payload && payload.vipMonthCollected) {
				vipCollectedRef.current = payload.vipMonthCollected
				collectedChanged = true
			}

			const today =
				('todayReward' in payload && payload.todayReward) || todayRewardRef.current
			const minutes = payload.onlineMinutes ?? onlineMinutesRef.current
			const present =
				'presentToday' in payload && payload.presentToday !== undefined
					? payload.presentToday
					: presentTodayRef.current

			let eligibilityChanged = false
			if ('monthEligibleDays' in payload && payload.monthEligibleDays) {
				eligibleRef.current = payload.monthEligibleDays
				eligibilityChanged = true
			} else if (present !== presentTodayRef.current) {
				if (present) {
					eligibleRef.current = { [String(today)]: true }
				} else {
					eligibleRef.current = {}
				}
				eligibilityChanged = true
			}

			if ('monthFreeDays' in payload && payload.monthFreeDays) {
				setMonthFreeDays(payload.monthFreeDays)
			} else if ('monthFreeDays' in payload && !payload.monthFreeDays) {
				setMonthFreeDays({})
			}

			if ('missedClaimsCount' in payload && typeof payload.missedClaimsCount === 'number') {
				setMissedClaimsCount(payload.missedClaimsCount)
				missedClaimsCountRef.current = payload.missedClaimsCount
				collectedChanged = true
			}

			if ('maxMissedClaimsPerMonth' in payload && typeof payload.maxMissedClaimsPerMonth === 'number') {
				setMaxMissedClaimsPerMonth(payload.maxMissedClaimsPerMonth)
				maxMissedClaimsRef.current = payload.maxMissedClaimsPerMonth
			}

			let vipChanged = false
			if ('hasVipPack' in payload && payload.hasVipPack !== undefined) {
				if (payload.hasVipPack !== hasVipPackRef.current) vipChanged = true
				setHasVipPack(payload.hasVipPack)
				hasVipPackRef.current = payload.hasVipPack
			}
			if ('vipPackPrice' in payload && typeof payload.vipPackPrice === 'number') {
				setVipPackPrice(payload.vipPackPrice)
			}
			if ('vipItems' in payload && payload.vipItems) {
				setVipRewards(payload.vipItems)
			}
			if ('streak' in payload && payload.streak) {
				setStreak(payload.streak)
			}

			const prevToday = todayRewardRef.current
			if ('todayReward' in payload && payload.todayReward) {
				setTodayReward(payload.todayReward)
				todayRewardRef.current = payload.todayReward
			}
			setOnlineMinutes(minutes)
			onlineMinutesRef.current = minutes
			setPresentToday(present)
			presentTodayRef.current = present

			if (collectedChanged || eligibilityChanged || vipChanged || today !== prevToday) {
				rebuildStatuses(totalDays, today)
			}
		},
		[calendarMonth, calendarYear, rebuildStatuses],
	)

	const applyCalendarMeta = useCallback(
		(message: NuiMessage, data?: PlayerRewardData) => {
			if (
				!embedded &&
				(message.mysteryImageUrl ||
					message.inventoryImageTemplate ||
					message.inventoryImageCdn ||
					message.itemImageResourceTemplate ||
					message.clothingImageUrl ||
					message.clothingImageExt)
			) {
				setAssetConfig({
					mysteryImageUrl: message.mysteryImageUrl,
					inventoryImageTemplate: message.inventoryImageTemplate,
					inventoryImageCdn: message.inventoryImageCdn,
					itemImageResourceTemplate: message.itemImageResourceTemplate,
					clothingImageUrl: message.clothingImageUrl,
					clothingImageExt: message.clothingImageExt,
				})
			}

			const total =
				data?.daysInMonth ??
				message.daysInMonth ??
				(message.items ? Object.keys(message.items).length : daysInMonth)

			if (data?.daysInMonth ?? message.daysInMonth) setDaysInMonth(total)
			if (data?.calendarYear ?? message.calendarYear) setCalendarYear(data?.calendarYear ?? message.calendarYear!)
			if (data?.calendarMonth ?? message.calendarMonth) {
				setCalendarMonth(data?.calendarMonth ?? message.calendarMonth!)
			}

			return total
		},
		[daysInMonth, embedded],
	)

	const handleNuiMessage = useCallback(
		(message: NuiMessage) => {
			if (message.bool === 'update' && message.items) {
				applyCalendarMeta(message)
				setRewards(message.items)
				setStatuses(buildInitialStatuses(message.items))
				if (message.locales) setLocales(message.locales)
				setTodayReward(DEV_CALENDAR.todayDay)
				return
			}

			if (message.bool === 'open' && message.data && 'playerData' in message.data) {
				const data = message.data as PlayerRewardData
				const total = applyCalendarMeta(message, data)
				if (message.items) {
					setRewards(message.items)
				} else if (data.items) {
					setRewards(data.items)
				}
				if (data.vipItems) setVipRewards(data.vipItems)
				if (message.locales) setLocales(message.locales)
				if (data.presentToday !== undefined) setPresentToday(data.presentToday)
				if (data.hasVipPack !== undefined) {
					setHasVipPack(data.hasVipPack)
					hasVipPackRef.current = data.hasVipPack
				}
				if (typeof data.vipPackPrice === 'number') setVipPackPrice(data.vipPackPrice)
				if (typeof data.missedDayClaimPrice === 'number') setMissedDayClaimPrice(data.missedDayClaimPrice)
				if (typeof data.missedDayClaimBasePrice === 'number') setMissedDayClaimBasePrice(data.missedDayClaimBasePrice)
				if (typeof data.missedDayClaimMultiplier === 'number') {
					setMissedDayClaimMultiplier(normalizeMissedMultiplier(data.missedDayClaimMultiplier))
				}
				if (data.missedDayClaimEnabled === false) setMissedDayClaimPrice(0)
				if (data.vipMonthCollected) vipCollectedRef.current = data.vipMonthCollected
				if (data.streak) setStreak(data.streak)
				setTodayReward(data.todayReward)
				applyServerState(data, total)
				setResetOsTime(data.tomorrowDate?.OsTime ?? 0)
				setVisible(true)
				setClosing(false)
				return
			}

			if (message.bool === 'syncOnline' && message.data) {
				const syncData = message.data as OnlineSyncData
				const total = daysInMonth || Object.keys(rewards).length || devDaysInMonth
				applyServerState(syncData, total)
			}

			if (message.bool === 'vipPackBought' && message.data) {
				const bought = message.data as VipPackBoughtData
				if (bought.ok) {
					setHasVipPack(true)
					hasVipPackRef.current = true
					if (bought.vipItems) setVipRewards(bought.vipItems)
					if (bought.vipMonthCollected) vipCollectedRef.current = bought.vipMonthCollected
					rebuildStatuses(daysInMonth || Object.keys(vipRewards).length || devDaysInMonth, todayReward)
					onVipPackBought?.()
				}
			}

			if (message.bool === 'milestoneHud' && typeof message.minutes === 'number' && message.minutes > 0) {
				setMilestoneHudQueue((prev) => [...prev, { id: Date.now() + Math.random(), minutes: message.minutes! }])
			}

			if (message.bool === 'close') closeUi()
		},
		[
			applyCalendarMeta,
			applyServerState,
			closeUi,
			daysInMonth,
			devDaysInMonth,
			onVipPackBought,
			rebuildStatuses,
			rewards,
			todayReward,
			vipRewards,
		],
	)

	useNuiEvent(handleNuiMessage)

	useEffect(() => {
		if (!embedded || !nuiPrefix) return
		setNuiEventPrefix(nuiPrefix)
		return () => setNuiEventPrefix('')
	}, [embedded, nuiPrefix])

	const openFromPayload = useCallback(
		(payload: DailyRewardsOpenPayload) => {
			const message: NuiMessage = {
				type: 'main',
				bool: 'open',
				data: payload.data,
				items: payload.items ?? payload.data.items,
				locales: payload.locales,
				daysInMonth: payload.daysInMonth ?? payload.data.daysInMonth,
				monthKey: payload.monthKey ?? payload.data.monthKey,
				calendarYear: payload.calendarYear ?? payload.data.calendarYear,
				calendarMonth: payload.calendarMonth ?? payload.data.calendarMonth,
				mysteryImageUrl: payload.mysteryImageUrl,
				inventoryImageTemplate: payload.inventoryImageTemplate,
				inventoryImageCdn: payload.inventoryImageCdn,
				itemImageResourceTemplate: payload.itemImageResourceTemplate,
				clothingImageUrl: payload.clothingImageUrl,
				clothingImageExt: payload.clothingImageExt,
			}
			if (payload.clothingImageUrl || payload.clothingComponents?.length) {
				setAssetConfig({
					clothingImageUrl: payload.clothingImageUrl,
					clothingImageExt: payload.clothingImageExt,
					clothingComponents: payload.clothingComponents,
				})
			}
			handleNuiMessage(message)
		},
		[handleNuiMessage],
	)

	const openFromPayloadRef = useRef(openFromPayload)
	openFromPayloadRef.current = openFromPayload

	useEffect(() => {
		if (!embedded || !initialOpen) return
		openFromPayloadRef.current(initialOpen)
		// Chỉ mở lại khi payload object đổi (mở menu mới) — tránh re-open mỗi lần sync
	}, [embedded, initialOpen])

	useEffect(() => {
		if (!embedded) return
		const listener = (
			event: MessageEvent<{
				action?: string
				data?: OnlineSyncData | VipPackBoughtData | { message?: string; type?: 'error' | 'info' | 'success' }
			}>,
		) => {
			if (event.data?.action === 'dailyRewardsSync' && event.data.data) {
				handleNuiMessage({ type: 'main', bool: 'syncOnline', data: event.data.data as OnlineSyncData })
			}
			if (event.data?.action === 'dailyRewardsVipBought' && event.data.data) {
				handleNuiMessage({ type: 'main', bool: 'vipPackBought', data: event.data.data as VipPackBoughtData })
			}
			if (event.data?.action === 'dailyRewardsToast' && event.data.data) {
				const payload = event.data.data as { message?: string; type?: 'error' | 'info' | 'success' }
				if (payload.message) {
					showToast(payload.message, payload.type ?? 'error')
				}
			}
		}
		window.addEventListener('message', listener)
		return () => window.removeEventListener('message', listener)
	}, [embedded, handleNuiMessage, showToast])

	useEffect(() => {
		if (embedded) return
		const onKeyDown = (event: KeyboardEvent) => {
			if (event.key === 'Escape') handleExit()
		}
		window.addEventListener('keydown', onKeyDown)
		return () => window.removeEventListener('keydown', onKeyDown)
	}, [embedded, handleExit])

	useEffect(() => {
		if (!isEnvBrowser()) return
		const pastDays = Math.max(0, DEV_CALENDAR.todayDay - 1)
		const collected: Record<string, boolean> = {}
		// Demo: để 2 ngày gần nhất chưa nhận → hiện “Bù $” trên UI
		for (let day = 1; day <= Math.max(0, pastDays - 2); day += 1) {
			collected[String(day)] = true
		}
		const eligible: Record<string, boolean> = {}
		for (let day = 1; day <= DEV_CALENDAR.todayDay; day += 1) {
			eligible[String(day)] = true
		}
		collectedRef.current = collected
		eligibleRef.current = eligible
		rebuildStatuses(devDaysInMonth, DEV_CALENDAR.todayDay)
		setMissedDayClaimPrice(5000)
		setStreak({
			current: Object.keys(collected).length,
			milestones: [
				{
					days: 3,
					claimed: false,
					ready: pastDays >= 3,
					reward: { itemName: 'cola', itemLabel: 'coca-cola', itemCount: 5, itemType: 'item' },
				},
				{
					days: 7,
					claimed: false,
					ready: pastDays >= 7,
					reward: { itemName: 'cigarette', itemLabel: 'Thuốc lá', itemCount: 3, itemType: 'item' },
				},
				{
					days: 14,
					claimed: false,
					ready: pastDays >= 14,
					reward: {
						itemName: 'com_ga',
						itemLabel: 'cơm gà',
						itemCount: 10,
						itemType: 'item',
					},
				},
				{
					days: 30,
					claimed: false,
					ready: pastDays >= 30,
					reward: { itemName: 'cola', itemLabel: 'coca-cola', itemCount: 20, itemType: 'item' },
				},
			],
		})
		setResetOsTime(7200)
	}, [devDaysInMonth, rebuildStatuses])

	useEffect(() => {
		if (milestoneHudActive || milestoneHudQueue.length === 0) return
		const [next, ...rest] = milestoneHudQueue
		setMilestoneHudActive(next)
		setMilestoneHudQueue(rest)
	}, [milestoneHudActive, milestoneHudQueue])

	useEffect(() => {
		if (!milestoneHudActive) return
		if (milestoneHudTimerRef.current !== null) {
			window.clearTimeout(milestoneHudTimerRef.current)
		}
		milestoneHudTimerRef.current = window.setTimeout(() => {
			setMilestoneHudActive(null)
			milestoneHudTimerRef.current = null
		}, 2400)
		return () => {
			if (milestoneHudTimerRef.current !== null) {
				window.clearTimeout(milestoneHudTimerRef.current)
				milestoneHudTimerRef.current = null
			}
		}
	}, [milestoneHudActive])

	const playClaimSound = () => {
		const playFrontend = () => {
			void fetchParentNui('playClick')
				.catch(() => fetchNui('playClick'))
				.catch(() => {})
		}

		if (!isEnvBrowser()) {
			playFrontend()
			return
		}

		try {
			const audio = new Audio(getClaimSoundUrl())
			audio.volume = 0.4
			const played = audio.play()
			if (played && typeof played.catch === 'function') {
				played.catch(() => playFrontend())
			}
		} catch {
			playFrontend()
		}
	}

	const claimingDayRef = useRef(false)

	const handleClaimStreak = async (day: number, reward: RewardConfig, claimTrack: CheckInTrack) => {
		if (claimTrack === 'vip' && !hasVipPackRef.current) return
		if (claimingDayRef.current) return
		if (selectedReward) return

		// Frontend check: đã hết lượt bù → không gọi NUI (tránh spam / treo)
		const isMissedClaim = day < todayReward
		if (
			isMissedClaim &&
			maxMissedClaimsRef.current > 0 &&
			missedClaimsCountRef.current >= maxMissedClaimsRef.current
		) {
			showClaimError(
				(locales.MissedLimitReached ?? 'Đã hết lượt nhận bù ngày trong tháng này (tối đa %d lượt)').replace(
					'%d',
					String(maxMissedClaimsRef.current),
				),
			)
			return
		}

		claimingDayRef.current = true
		// Optimistic: đánh dấu đang claim để chặn double-click cùng ô
		const prevStatus = claimTrack === 'vip' ? vipStatuses[day] : statuses[day]
		if (claimTrack === 'vip') {
			setVipStatuses((prev) => ({ ...prev, [day]: 'collected' }))
		} else {
			setStatuses((prev) => ({ ...prev, [day]: 'collected' }))
		}

		let claimResult: {
			ok?: boolean
			error?: string
			price?: number
			paid?: number
			missed?: boolean
			isFreeClaim?: boolean
			missedClaimsCount?: number
			maxAllowed?: number
			nextMissedClaimPrice?: number
			streak?: StreakPayload
		} | null = null
		try {
			if (isEnvBrowser()) {
				const mode =
					(window as Window & { __TIPI_DAILY_DEV_CLAIM__?: string }).__TIPI_DAILY_DEV_CLAIM__ ?? 'ok'
				const isMissedPaid =
					day < todayReward && !monthFreeDays[String(day)] && missedDayClaimPrice > 0
				if (mode === 'not_enough_money' && isMissedPaid) {
					claimResult = {
						ok: false,
						error: 'not_enough_money',
						price: missedDayClaimPrice,
					}
				} else if (mode === 'max_missed_claims_reached' && day < todayReward) {
					claimResult = {
						ok: false,
						error: 'max_missed_claims_reached',
						maxAllowed: maxMissedClaimsRef.current || 5,
					}
				} else {
					const nextCount =
						day < todayReward && !monthFreeDays[String(day)]
							? missedClaimsCountRef.current + 1
							: missedClaimsCountRef.current
					claimResult = {
						ok: true,
						missed: day < todayReward,
						isFreeClaim: day < todayReward && Boolean(monthFreeDays[String(day)]),
						missedClaimsCount: nextCount,
						nextMissedClaimPrice: missedClaimPriceAt(
							missedDayClaimBasePrice,
							missedDayClaimMultiplier,
							nextCount,
						),
					}
				}
			} else {
				claimResult = await fetchNui<{
					ok?: boolean
					error?: string
					price?: number
					paid?: number
					missed?: boolean
					isFreeClaim?: boolean
					missedClaimsCount?: number
					maxAllowed?: number
					nextMissedClaimPrice?: number
					streak?: StreakPayload
				}>('Claimed', { day, track: claimTrack })
			}

			if (!claimResult?.ok) {
				// Rollback optimistic UI
				if (claimTrack === 'vip') {
					setVipStatuses((prev) => ({ ...prev, [day]: prevStatus }))
				} else {
					setStatuses((prev) => ({ ...prev, [day]: prevStatus }))
				}
				if (claimResult?.error === 'max_missed_claims_reached') {
					const maxAllowed = claimResult.maxAllowed ?? maxMissedClaimsRef.current
					missedClaimsCountRef.current = maxAllowed
					setMissedClaimsCount(maxAllowed)
					rebuildStatuses(daysInMonth, todayReward)
				}
				if (claimResult?.error === 'not_enough_money') {
					showClaimError(
						(locales.MissedDayNeedMoney ?? 'Không đủ tiền để nhận bù ngày (cần %s$)')
							.replace('%s', String(claimResult.price ?? missedDayClaimPrice))
							.replace('%d', String(claimResult.price ?? missedDayClaimPrice)),
					)
				} else if (claimResult?.error === 'max_missed_claims_reached') {
					showClaimError(
						(locales.MissedLimitReached ?? 'Đã hết lượt nhận bù ngày trong tháng này (tối đa %d lượt)').replace(
							'%d',
							String(claimResult.maxAllowed ?? maxMissedClaimsRef.current),
						),
					)
				} else if (claimResult?.error === 'busy') {
					showClaimError(locales.ClaimBusy ?? 'Đang xử lý quà, vui lòng chờ...')
				} else if (claimResult?.error === 'already_claimed') {
					showClaimError(locales.AlreadyClaimed ?? 'Ngày này đã nhận rồi')
				} else if (claimResult?.error === 'not_eligible') {
					showClaimError(locales.NotYetEligible ?? 'Chưa đủ điều kiện nhận')
				} else if (claimResult?.error === 'need_vip_pack') {
					showClaimError(locales.VipNeedPack ?? 'Cần mua gói VIP tháng này')
				} else {
					showClaimError(locales.ClaimFailed ?? 'Không nhận được quà')
				}
				return
			}
		} catch {
			if (claimTrack === 'vip') {
				setVipStatuses((prev) => ({ ...prev, [day]: prevStatus }))
			} else {
				setStatuses((prev) => ({ ...prev, [day]: prevStatus }))
			}
			showClaimError(locales.ClaimFailed ?? 'Không nhận được quà')
			return
		} finally {
			claimingDayRef.current = false
		}

		if (claimTrack === 'vip') {
			vipCollectedRef.current = { ...vipCollectedRef.current, [String(day)]: true }
		} else {
			collectedRef.current = { ...collectedRef.current, [String(day)]: true }
		}

		if (claimResult && typeof claimResult.missedClaimsCount === 'number') {
			missedClaimsCountRef.current = claimResult.missedClaimsCount
			setMissedClaimsCount(claimResult.missedClaimsCount)
		}
		if (typeof claimResult?.nextMissedClaimPrice === 'number') {
			setMissedDayClaimPrice(claimResult.nextMissedClaimPrice)
		} else if (
			claimResult?.missed &&
			!claimResult?.isFreeClaim &&
			typeof claimResult.missedClaimsCount === 'number'
		) {
			setMissedDayClaimPrice(
				missedClaimPriceAt(missedDayClaimBasePrice, missedDayClaimMultiplier, claimResult.missedClaimsCount),
			)
		}
		rebuildStatuses(daysInMonth, todayReward)

		if (claimTrack === 'vip') {
			setVipStatuses((prev) => ({ ...prev, [day]: 'collected' }))
		} else {
			setStatuses((prev) => ({ ...prev, [day]: 'collected' }))
			if (claimResult?.streak) {
				setStreak(claimResult.streak)
			} else if (isEnvBrowser()) {
				let current = 0
				for (let d = todayReward; d >= 1; d -= 1) {
					if (collectedRef.current[String(d)]) current += 1
					else break
				}
				setStreak((prev) => ({
					...prev,
					current,
					milestones: (prev.milestones || []).map((milestone) => ({
						...milestone,
						ready: !milestone.claimed && current >= milestone.days,
					})),
				}))
			}
		}
		setSelectedReward({
			day,
			itemName: reward.itemName,
			itemLabel: reward.itemLabel,
			itemCount: reward.itemCount,
			itemType: reward.itemType,
			clothComponent: reward.clothComponent,
			clothDrawable: reward.clothDrawable,
			clothSex: reward.clothSex,
			kind: claimTrack === 'vip' ? 'vip' : 'streak',
		})
		onMonthClaimed?.(day)
		playClaimSound()
	}

	const showDenyToast = useCallback((msg: string) => showToast(msg, 'info'), [showToast])

	const claimNormalDay = useCallback(
		(day: number, reward: RewardConfig) => {
			void handleClaimStreak(day, reward, 'normal')
		},
		// handleClaimStreak đóng over state — intentional rebind khi claim deps đổi
		// eslint-disable-next-line react-hooks/exhaustive-deps
		[selectedReward, todayReward, statuses, vipStatuses, locales, onMonthClaimed, showClaimError],
	)

	const claimVipDay = useCallback(
		(day: number, reward: RewardConfig) => {
			void handleClaimStreak(day, reward, 'vip')
		},
		// eslint-disable-next-line react-hooks/exhaustive-deps
		[selectedReward, todayReward, statuses, vipStatuses, locales, onMonthClaimed, showClaimError],
	)

	const handleClaimChain = async (days: number) => {
		if (claimingStreakDays != null) return
		setClaimingStreakDays(days)
		try {
			const result = await fetchNui<{ ok: boolean; reward?: RewardConfig; streak?: StreakPayload }>(
				'ClaimStreak',
				{ days },
			)
			if (isEnvBrowser()) {
				const milestone = streak.milestones.find((item) => item.days === days)
				setStreak((prev) => ({
					...prev,
					milestones: prev.milestones.map((item) =>
						item.days === days ? { ...item, claimed: true, ready: false } : item,
					),
				}))
				if (milestone?.reward) {
					setSelectedReward({
						day: days,
						itemName: milestone.reward.itemName,
						itemLabel: milestone.reward.itemLabel,
						itemCount: milestone.reward.itemCount,
						itemType: milestone.reward.itemType,
						clothComponent: milestone.reward.clothComponent,
						clothDrawable: milestone.reward.clothDrawable,
						clothSex: milestone.reward.clothSex,
						kind: 'chain',
					})
				}
				playClaimSound()
			} else if (result?.ok) {
				if (result.streak) setStreak(result.streak)
				if (result.reward) {
					setSelectedReward({
						day: days,
						itemName: result.reward.itemName,
						itemLabel: result.reward.itemLabel,
						itemCount: result.reward.itemCount,
						itemType: result.reward.itemType,
						clothComponent: result.reward.clothComponent,
						clothDrawable: result.reward.clothDrawable,
						clothSex: result.reward.clothSex,
						kind: 'chain',
					})
				}
				playClaimSound()
			}
		} catch {
			// claim failed
		} finally {
			setClaimingStreakDays(null)
		}
	}

	const handleBuyVipPack = async () => {
		if (buyingVip || hasVipPack) return
		setBuyingVip(true)
		try {
			let result: VipPackBoughtData | undefined
			if (isEnvBrowser()) {
				result = {
					ok: true,
					hasVipPack: true,
					vipPackPrice,
					vipItems: vipRewards,
					vipMonthCollected: {},
				}
			} else {
				result = await fetchNui<VipPackBoughtData>('BuyVipPack')
			}
			if (result?.ok) {
				handleNuiMessage({ type: 'main', bool: 'vipPackBought', data: result })
				playClaimSound()
			}
		} catch {
			// buy failed
		} finally {
			setBuyingVip(false)
		}
	}

	const milestoneHudNode = milestoneHudActive ? (
		<div className='dr-milestone-hud-wrap'>
			<div className='dr-milestone-hud-card'>
				<img
					src={getMysteryRewardImage()}
					alt={`milestone-${milestoneHudActive.minutes}`}
					className='dr-milestone-hud-gift'
					draggable={false}
				/>
			</div>
		</div>
	) : null

	if (!visible) {
		return <>{milestoneHudNode}</>
	}

	if (embedded) {
		return (
			<>
				<div
					className={`mp-dr-embed mp-dr-inline flex h-full min-h-0 w-full flex-col transition-opacity duration-250 ${
						closing ? 'opacity-0' : 'opacity-100'
					}`}>
					<div
						className={`tipi-panel relative flex h-full min-h-0 w-full flex-col overflow-hidden border border-[var(--border-dim)] bg-[var(--bg-card)] transition-all duration-250 ${
							closing ? 'scale-[0.99] opacity-0' : 'scale-100 opacity-100'
						}`}>
						{renderPanelContent()}
					</div>
				</div>
				{milestoneHudNode}
			</>
		)
	}

	return (
		<>
			<div
				className={`fixed inset-0 z-50 flex items-center justify-center p-6 transition-opacity duration-250 mp-dr-embed ${
					closing ? 'opacity-0' : 'opacity-100'
				}`}
				style={{ background: 'rgba(0, 6, 14, 0.72)' }}>
				<div
					className={`tipi-panel relative flex h-[min(820px,90vh)] w-[min(1729px,96vw)] flex-col overflow-hidden transition-all duration-250 ${
						closing ? 'scale-[0.98] opacity-0' : 'scale-100 opacity-100 animate-[fadeIn_0.25s_ease]'
					}`}>
					{renderPanelContent()}
				</div>
			</div>
			{milestoneHudNode}
		</>
	)

	function renderPanelContent() {
		const priceLabel = (locales.VipPrice ?? '%d COIN').replace('%d', String(vipPackPrice))
		const normalChecked = Object.values(statuses).filter((status) => status === 'collected').length
		const vipChecked = Object.values(vipStatuses).filter((status) => status === 'collected').length

		return (
			<>
				<header className='header-shell relative shrink-0'>
					{!embedded && (
						<button
							type='button'
							onClick={handleExit}
							className='tipi-btn-ghost header-close-btn px-3 py-1.5 text-xs font-semibold tracking-wider'>
							{locales.Close ?? 'Đóng'}
						</button>
					)}

					<div className={`header-grid${embedded ? ' header-grid--embedded' : ''}`}>
						<div className='header-left'>
							<div className='header-title-row'>
								<h1 className='tipi-title header-title-main'>{locales.Daily}</h1>
								<span className='header-title-sep' aria-hidden='true' />
								<span className='tipi-accent header-title-accent'>{locales.Rewards}</span>
							</div>
							<p className='header-desc'>{locales.Description}</p>
						</div>

						<div className='header-right'>
							<CountdownTimer initialOsTime={resetOsTime} locales={locales} />
						</div>
					</div>
				</header>

				<div className='dr-track-bar px-6 pt-3'>
					<div className='dr-track-tabs'>
						<button
							type='button'
							className={`dr-track-tab${track === 'normal' ? ' dr-track-tab-active' : ''}`}
							onClick={() => setTrack('normal')}>
							{locales.TabNormal ?? 'THƯỜNG'}
						</button>
						<button
							type='button'
							className={`dr-track-tab dr-track-tab-vip${track === 'vip' ? ' dr-track-tab-active' : ''}`}
							onClick={() => setTrack('vip')}>
							{locales.TabVip ?? 'VIP'}
						</button>
					</div>
					{track === 'vip' && hasVipPack && (
						<div className='dr-vip-actions'>
							<span className='dr-vip-owned'>{locales.VipOwned ?? 'VIP đã kích hoạt'}</span>
						</div>
					)}
				</div>

				<div className='tipi-scroll relative flex min-h-0 flex-1 flex-col overflow-hidden px-6 py-4'>
					<StreakMilestonesBar
						current={streak.current}
						milestones={streak.milestones}
						locales={locales}
						claimingDays={claimingStreakDays}
						onClaim={(days) => void handleClaimChain(days)}
					/>
					{track === 'normal' ? (
						<CalendarGrid
							month={calendarMonthView}
							statuses={statuses}
							todayReward={todayReward}
							locales={locales}
							track='normal'
							missedClaimPrice={missedDayClaimPrice}
							checkedCount={normalChecked}
							monthFreeDays={monthFreeDays}
							missedClaimsCount={missedClaimsCount}
							maxMissedClaimsPerMonth={maxMissedClaimsPerMonth}
							title={`${locales.TabNormal ?? 'THƯỜNG'} · ${calendarMonthView.label}`}
							onClaimStreak={claimNormalDay}
							onDenyFeedback={showDenyToast}
						/>
					) : (
						<>
							<CalendarGrid
								month={vipCalendarMonthView}
								statuses={vipStatuses}
								todayReward={todayReward}
								locales={locales}
								track='vip'
								locked={!hasVipPack}
								lockHint={locales.VipLocked}
								missedClaimPrice={missedDayClaimPrice}
								checkedCount={vipChecked}
								monthFreeDays={monthFreeDays}
								missedClaimsCount={missedClaimsCount}
								maxMissedClaimsPerMonth={maxMissedClaimsPerMonth}
								title={`${locales.TabVip ?? 'VIP'} · ${vipCalendarMonthView.label}`}
								onClaimStreak={claimVipDay}
								onDenyFeedback={showDenyToast}
							/>
							{!hasVipPack && (
								<div className='dr-vip-buy-container'>
									<button
										type='button'
										className='dr-vip-buy-btn'
										disabled={buyingVip}
										onClick={() => void handleBuyVipPack()}>
										{locales.VipBuy ?? 'MUA VIP THÁNG'} · {priceLabel}
									</button>
								</div>
							)}
						</>
					)}
				</div>

				{selectedReward && (
					<RewardRevealModal reward={selectedReward} onCollect={() => setSelectedReward(null)} />
				)}

				{toast ? (
					<div
						key={toast.id}
						className={`dr-toast dr-toast--${toast.type}`}
						role='status'
						aria-live='polite'>
						<span className='dr-toast-text'>{toast.message}</span>
					</div>
				) : null}
			</>
		)
	}
}
