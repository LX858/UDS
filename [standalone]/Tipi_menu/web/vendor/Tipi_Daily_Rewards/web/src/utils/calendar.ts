import type { RewardConfig } from '../types'

export interface CalendarDayCell {
	dayOfMonth: number
	month: number
	year: number
	reward?: RewardConfig
}

export interface CalendarMonth {
	year: number
	month: number
	daysInMonth: number
	label: string
	leadEmpty?: number
	cells: CalendarDayCell[]
}

function pad2(value: number) {
	return value < 10 ? `0${value}` : String(value)
}

export function getDaysInMonth(year: number, month: number) {
	return new Date(year, month, 0).getDate()
}

export function getCurrentCalendarInfo() {
	const now = new Date()
	return {
		year: now.getFullYear(),
		month: now.getMonth() + 1,
		daysInMonth: getDaysInMonth(now.getFullYear(), now.getMonth() + 1),
		todayDay: now.getDate(),
		monthKey: `${now.getFullYear()}-${pad2(now.getMonth() + 1)}`,
	}
}

export function buildCurrentMonth(
	year: number,
	month: number,
	rewards: Record<string, RewardConfig>,
): CalendarMonth {
	const daysInMonth = getDaysInMonth(year, month)
	const cells: CalendarDayCell[] = []
	// JS: 0=CN … 6=T7 → Monday-first lead
	const sundayIndex = new Date(year, month - 1, 1).getDay()
	const leadEmpty = (sundayIndex + 6) % 7

	for (let dayOfMonth = 1; dayOfMonth <= daysInMonth; dayOfMonth += 1) {
		cells.push({
			dayOfMonth,
			month,
			year,
			reward: rewards[String(dayOfMonth - 1)],
		})
	}

	return {
		year,
		month,
		daysInMonth,
		leadEmpty,
		label: `Tháng ${pad2(month)}/${year}`,
		cells,
	}
}

export function formatCalendarDate(dayOfMonth: number, month: number) {
	return `${pad2(dayOfMonth)}/${pad2(month)}`
}

export const DEV_CALENDAR = getCurrentCalendarInfo()
