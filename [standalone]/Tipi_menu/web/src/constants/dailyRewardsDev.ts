import { buildDevRewards, getDevDaysInMonth } from '@tipi-daily-rewards/constants/devRewards'
import type { DailyRewardsOpenPayload } from '@tipi-daily-rewards/components/DailyRewardsApp'
import { DEFAULT_LOCALES } from '@tipi-daily-rewards/constants/rewards'
import type { StreakPayload } from '@tipi-daily-rewards/types'

export type DevCalendarScenario =
	| 'default'
	| 'fresh-start'
	| 'missed-yesterday'
	| 'missed-limit'
	| 'not-enough-money'

export type DevClaimFailMode = 'ok' | 'not_enough_money' | 'max_missed_claims_reached'

declare global {
	interface Window {
		__TIPI_DAILY_DEV_CLAIM__?: DevClaimFailMode
	}
}

export function setDevClaimFailMode(mode: DevClaimFailMode) {
	if (typeof window === 'undefined') return
	window.__TIPI_DAILY_DEV_CLAIM__ = mode
}

function buildDevStreak(current: number): StreakPayload {
	const pool = [
		{ days: 3, itemName: 'cola', itemLabel: 'coca-cola', itemCount: 5, type: 'rare' as const },
		{ days: 7, itemName: 'cigarette', itemLabel: 'Thuốc lá', itemCount: 3, type: 'epic' as const },
		{ days: 14, itemName: 'com_ga', itemLabel: 'cơm gà', itemCount: 10, type: 'goldrare' as const },
		{ days: 30, itemName: 'cola', itemLabel: 'coca-cola', itemCount: 20, type: 'goldepic' as const },
	]
	return {
		current,
		milestones: pool.map((item) => ({
			days: item.days,
			claimed: false,
			ready: current >= item.days,
			reward: {
				type: item.type,
				itemName: item.itemName,
				itemLabel: item.itemLabel,
				itemCount: item.itemCount,
				itemType: 'item',
			},
		})),
	}
}

type BuildDevOpts = {
	todayReward: number
	monthCollected: Record<string, boolean>
	monthEligibleDays: Record<string, boolean>
	monthFreeDays?: Record<string, boolean>
	missedClaimsCount?: number
	maxMissedClaimsPerMonth?: number
	missedDayClaimPrice?: number
	onlineMinutes?: number
}

function buildDevOpenPayloadBase(opts: BuildDevOpts): DailyRewardsOpenPayload {
	const daysInMonth = getDevDaysInMonth()
	const items = buildDevRewards(daysInMonth)
	const now = new Date()
	const streakCurrent = Object.keys(opts.monthCollected).length
	const missedDayClaimPrice = opts.missedDayClaimPrice ?? 5000
	const maxMissedClaimsPerMonth = opts.maxMissedClaimsPerMonth ?? 5
	const missedClaimsCount = opts.missedClaimsCount ?? 0

	return {
		data: {
			playerData: { collected: '{}', usual: '{}' },
			todayReward: opts.todayReward,
			tomorrowDate: { Hours: '05', Minutes: '30', Seconds: '00', OsTime: 19800 },
			onlineMinutes: opts.onlineMinutes ?? 5,
			presentToday: Boolean(opts.monthEligibleDays[String(opts.todayReward)]),
			items,
			vipItems: items,
			hasVipPack: false,
			vipPackPrice: 99,
			missedDayClaimEnabled: true,
			missedDayClaimPrice,
			daysInMonth,
			calendarYear: now.getFullYear(),
			calendarMonth: now.getMonth() + 1,
			monthCollected: opts.monthCollected,
			vipMonthCollected: {},
			monthEligibleDays: opts.monthEligibleDays,
			monthFreeDays: opts.monthFreeDays ?? {},
			missedClaimsCount,
			maxMissedClaimsPerMonth,
			streak: buildDevStreak(streakCurrent),
		},
		items,
		locales: DEFAULT_LOCALES,
		daysInMonth,
		calendarYear: now.getFullYear(),
		calendarMonth: now.getMonth() + 1,
	}
}

export function buildDailyRewardsDevOpenPayload(): DailyRewardsOpenPayload {
	const todayReward = new Date().getDate()
	const monthCollected: Record<string, boolean> = {}
	for (let day = 1; day < todayReward; day += 1) {
		monthCollected[String(day)] = true
	}
	setDevClaimFailMode('ok')
	return buildDevOpenPayloadBase({
		todayReward,
		monthCollected,
		monthEligibleDays: { [String(todayReward)]: true },
		missedClaimsCount: 0,
		maxMissedClaimsPerMonth: 5,
	})
}

export function buildDailyRewardsDevFreshStartPayload(): DailyRewardsOpenPayload {
	const todayReward = new Date().getDate()
	setDevClaimFailMode('ok')
	return buildDevOpenPayloadBase({
		todayReward,
		monthCollected: {},
		monthEligibleDays: { [String(todayReward)]: true },
		missedClaimsCount: 0,
		maxMissedClaimsPerMonth: 5,
	})
}


export function buildDailyRewardsDevMissedYesterdayPayload(): DailyRewardsOpenPayload {
	const daysInMonth = getDevDaysInMonth()
	const realToday = new Date().getDate()
	const todayReward = Math.min(realToday + 1, daysInMonth)
	const missedDay = todayReward - 1

	const monthCollected: Record<string, boolean> = {}
	for (let day = 1; day < missedDay; day += 1) {
		monthCollected[String(day)] = true
	}

	setDevClaimFailMode('ok')
	return buildDevOpenPayloadBase({
		todayReward,
		monthCollected,
		monthEligibleDays: {
			[String(missedDay)]: true,
			[String(todayReward)]: true,
		},
		monthFreeDays: { [String(missedDay)]: true },
		missedClaimsCount: 0,
		maxMissedClaimsPerMonth: 5,
	})
}


export function buildDailyRewardsDevMissedLimitPayload(): DailyRewardsOpenPayload {
	const todayReward = Math.max(12, Math.min(new Date().getDate(), getDevDaysInMonth()))
	const monthCollected: Record<string, boolean> = {}
	for (let day = 1; day <= todayReward - 6; day += 1) {
		monthCollected[String(day)] = true
	}

	const monthEligibleDays: Record<string, boolean> = { [String(todayReward)]: true }
	for (let day = todayReward - 5; day < todayReward; day += 1) {
		if (day >= 1) monthEligibleDays[String(day)] = true
	}

	setDevClaimFailMode('max_missed_claims_reached')
	return buildDevOpenPayloadBase({
		todayReward,
		monthCollected,
		monthEligibleDays,
		monthFreeDays: {},
		missedClaimsCount: 5,
		maxMissedClaimsPerMonth: 5,
		missedDayClaimPrice: 5000,
	})
}

export function buildDailyRewardsDevNotEnoughMoneyPayload(): DailyRewardsOpenPayload {
	const todayReward = Math.max(8, Math.min(new Date().getDate(), getDevDaysInMonth()))
	const monthCollected: Record<string, boolean> = {}
	for (let day = 1; day <= todayReward - 4; day += 1) {
		monthCollected[String(day)] = true
	}

	const monthEligibleDays: Record<string, boolean> = { [String(todayReward)]: true }
	for (let day = todayReward - 3; day < todayReward; day += 1) {
		if (day >= 1) monthEligibleDays[String(day)] = true
	}

	setDevClaimFailMode('not_enough_money')
	return buildDevOpenPayloadBase({
		todayReward,
		monthCollected,
		monthEligibleDays,
		monthFreeDays: {},
		missedClaimsCount: 1,
		maxMissedClaimsPerMonth: 5,
		missedDayClaimPrice: 5000,
	})
}

export function buildDailyRewardsDevPayloadByScenario(
	scenario: DevCalendarScenario,
): DailyRewardsOpenPayload {
	if (scenario === 'fresh-start') return buildDailyRewardsDevFreshStartPayload()
	if (scenario === 'missed-yesterday') return buildDailyRewardsDevMissedYesterdayPayload()
	if (scenario === 'missed-limit') return buildDailyRewardsDevMissedLimitPayload()
	if (scenario === 'not-enough-money') return buildDailyRewardsDevNotEnoughMoneyPayload()
	return buildDailyRewardsDevOpenPayload()
}

export function buildSummaryFromDevPayload(payload: DailyRewardsOpenPayload) {
	const data = payload.data
	const monthCollected = data.monthCollected ?? {}
	const checkedCount = Object.values(monthCollected).filter(Boolean).length
	const todayKey = String(data.todayReward)
	const claimedToday = Boolean(monthCollected[todayKey])

	return {
		checkedCount,
		daysInMonth: data.daysInMonth ?? payload.daysInMonth ?? 31,
		onlineMinutes: data.onlineMinutes ?? 0,
		presentToday: data.presentToday ?? false,
		todayReward: data.todayReward,
		canClaimToday: Boolean(data.presentToday) && !claimedToday,
		hasVipPack: data.hasVipPack ?? false,
		vipPackPrice: data.vipPackPrice ?? 99,
	}
}
