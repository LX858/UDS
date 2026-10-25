import type { RewardConfig } from '../types'
import { getDaysInMonth } from '../utils/calendar'

export const DEV_REWARD_POOL: Array<{
	itemName: string
	itemLabel: string
	itemCount: number
	itemType: string
}> = [
	{ itemName: 'com_ga', itemLabel: 'cơm gà', itemCount: 5, itemType: 'item' },
	{ itemName: 'cola', itemLabel: 'coca-cola', itemCount: 5, itemType: 'item' },
	{ itemName: 'cigarette', itemLabel: 'Thuốc lá', itemCount: 1, itemType: 'item' },
]

function hashString(value: string) {
	let hash = 5381
	for (let i = 0; i < value.length; i += 1) {
		hash = (hash * 33 + value.charCodeAt(i)) % 2147483647
	}
	return hash
}

function nextSeed(seed: number) {
	return (seed * 1103515245 + 12345) % 2147483647
}

function pickFromPool<T>(pool: T[], seed: number) {
	if (pool.length === 0) return { item: null as T | null, seed }
	const index = seed % pool.length
	return { item: pool[index], seed: nextSeed(seed) }
}

export function getDevDaysInMonth() {
	const now = new Date()
	return getDaysInMonth(now.getFullYear(), now.getMonth() + 1)
}

function getDevMonthKey() {
	const now = new Date()
	return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
}

export function buildDevRewards(totalDays = getDevDaysInMonth(), seedKey = `dev:${getDevMonthKey()}`): Record<string, RewardConfig> {
	const rewards: Record<string, RewardConfig> = {}
	let seed = hashString(seedKey)

	for (let day = 1; day <= totalDays; day += 1) {
		const picked = pickFromPool(DEV_REWARD_POOL, seed)
		seed = picked.seed
		if (!picked.item) continue

		rewards[String(day - 1)] = {
			type: 'common',
			itemName: picked.item.itemName,
			itemLabel: picked.item.itemLabel,
			itemCount: picked.item.itemCount,
			itemType: picked.item.itemType,
		}
	}

	return rewards
}
