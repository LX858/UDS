import { buildDevRewards } from '../constants/devRewards'
import { getDaysInMonth } from './calendar'
import type { AdminPayload } from '../components/AdminDailyApp'

function parseMonthKey(monthKey?: string) {
	const now = new Date()
	if (monthKey && /^\d{4}-\d{2}$/.test(monthKey)) {
		const year = Number(monthKey.slice(0, 4))
		const month = Number(monthKey.slice(5, 7))
		if (year > 0 && month >= 1 && month <= 12) {
			return { year, month, monthKey }
		}
	}
	const year = now.getFullYear()
	const month = now.getMonth() + 1
	return {
		year,
		month,
		monthKey: `${year}-${String(month).padStart(2, '0')}`,
	}
}

export function buildBrowserAdminPayload(targetMonthKey?: string): AdminPayload {
	const { year, month, monthKey } = parseMonthKey(targetMonthKey)
	const daysInMonth = getDaysInMonth(year, month)
	const items = buildDevRewards(daysInMonth, `dev:${monthKey}`)
	const normal: AdminPayload['normal'] = {}
	const vip: AdminPayload['vip'] = {}

	for (let day = 1; day <= daysInMonth; day += 1) {
		const reward = items[String(day - 1)]
		if (reward) {
			normal[String(day)] = { ...reward, type: 'common' }
			vip[String(day)] = {
				...reward,
				itemCount: reward.itemCount * 2,
				type: 'common',
			}
		}
	}

	const now = new Date()
	const isCurrentMonth = year === now.getFullYear() && month === now.getMonth() + 1

	return {
		ok: true,
		monthKey,
		calendarYear: year,
		calendarMonth: month,
		daysInMonth,
		todayDay: isCurrentMonth ? now.getDate() : 1,
		normal,
		vip,
		fromSql: false,
		fromTemplate: true,
		streaks: [
			{ days: 3, reward: { type: 'common', itemName: 'cola', itemLabel: 'coca-cola', itemCount: 5, itemType: 'item' } },
			{ days: 7, reward: { type: 'common', itemName: 'cigarette', itemLabel: 'Thuốc lá', itemCount: 3, itemType: 'item' } },
			{ days: 14, reward: { type: 'common', itemName: 'com_ga', itemLabel: 'cơm gà', itemCount: 10, itemType: 'item' } },
			{ days: 30, reward: { type: 'common', itemName: 'cola', itemLabel: 'coca-cola', itemCount: 20, itemType: 'item' } },
		],
		streaksFromSql: false,
		templateNormal: normal,
		templateVip: vip,
		templateStreaks: [
			{ days: 3, reward: { type: 'common', itemName: 'cola', itemLabel: 'coca-cola', itemCount: 5, itemType: 'item' } },
			{ days: 7, reward: { type: 'common', itemName: 'cigarette', itemLabel: 'Thuốc lá', itemCount: 3, itemType: 'item' } },
		],
		itemTypes: ['item', 'cash', 'clothing'],
		clothingImageUrl: 'https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main',
		clothingImageExt: 'webp',
		clothingComponents: [
			{ key: 'hat', label: 'Mũ', itemname: 'cloth_helmet', component: 0, prop: true },
			{ key: 'mask', label: 'Mặt nạ', itemname: 'cloth_mask', component: 1, prop: false },
			{ key: 'shirt', label: 'Áo thun', itemname: 'cloth_tshirt', component: 8, prop: false },
			{ key: 'torso', label: 'Áo khoác', itemname: 'cloth_torso', component: 11, prop: false },
			{ key: 'pants', label: 'Quần', itemname: 'cloth_pants', component: 4, prop: false },
			{ key: 'shoes', label: 'Giày', itemname: 'cloth_shoes', component: 6, prop: false },
			{ key: 'bag', label: 'Túi xách', itemname: 'cloth_bags', component: 5, prop: false },
		],
		vipPackPrice: 99,
		missedDayClaimPrice: 5000,
		missedDayClaimMultiplier: 2,
		missedDayClaimEnabled: true,
		maxMissedClaimsPerMonth: 5,
		missedClaimPricePreview: [
			{ claim: 1, price: 5000 },
			{ claim: 2, price: 10000 },
			{ claim: 3, price: 15000 },
			{ claim: 4, price: 20000 },
			{ claim: 5, price: 25000 },
		],
		settingsFromSql: false,
		templateVipPackPrice: 99,
		templateMissedDayClaimPrice: 5000,
		templateMissedDayClaimMultiplier: 2,
		templateMissedDayClaimEnabled: true,
		templateMaxMissedClaimsPerMonth: 5,
	}
}
