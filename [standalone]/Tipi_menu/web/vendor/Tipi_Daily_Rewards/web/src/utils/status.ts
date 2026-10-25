import type { RewardStatus } from '../types'

export function parseMonthCollected(raw: Record<string, boolean>, monthKey: string) {
	const filtered: Record<string, boolean> = {}

	Object.entries(raw).forEach(([key, value]) => {
		if (!value) return
		if (key.includes('#vip')) return

		if (key.startsWith(`${monthKey}-`)) {
			const day = Number.parseInt(key.slice(8, 10), 10)
			if (!Number.isNaN(day)) filtered[String(day)] = true
			return
		}

		if (!key.includes('-')) {
			filtered[key] = true
		}
	})

	return filtered
}

export function parseVipMonthCollected(raw: Record<string, boolean>, monthKey: string) {
	const filtered: Record<string, boolean> = {}

	Object.entries(raw).forEach(([key, value]) => {
		if (!value) return
		if (!key.includes('#vip')) return
		if (!key.startsWith(`${monthKey}-`)) return
		const day = Number.parseInt(key.slice(8, 10), 10)
		if (!Number.isNaN(day)) filtered[String(day)] = true
	})

	return filtered
}

export function resolveDayStatus(
	day: number,
	todayReward: number,
	collected: Record<string, boolean>,
	eligibleDays: Record<string, boolean>,
	options?: {
		requireVipPack?: boolean
		hasVipPack?: boolean
		missedClaimsRemaining?: number
	},
): RewardStatus {
	if (collected[String(day)]) return 'collected'
	if (day > todayReward) return 'undiscovered'
	if (options?.requireVipPack && !options.hasVipPack) {
		if (eligibleDays[String(day)]) return 'vip_locked'
		return 'undiscovered'
	}
	if (eligibleDays[String(day)]) {
		if (day === todayReward) return 'usual'
		// Hết lượt bù → khóa ô, toast riêng (không lẫn “chưa đủ điều kiện”)
		if (options?.missedClaimsRemaining !== undefined && options.missedClaimsRemaining <= 0) {
			return 'missed_limit'
		}
		return 'missed_claimable'
	}
	return 'undiscovered'
}

export function buildStatusesFromServer(
	totalDays: number,
	todayReward: number,
	collected: Record<string, boolean>,
	eligibleDays: Record<string, boolean>,
	options?: {
		requireVipPack?: boolean
		hasVipPack?: boolean
		missedClaimsRemaining?: number
	},
) {
	const statuses: Record<number, RewardStatus> = {}
	for (let day = 1; day <= totalDays; day += 1) {
		statuses[day] = resolveDayStatus(day, todayReward, collected, eligibleDays, options)
	}
	return statuses
}
