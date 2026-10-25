import type { LeaderboardEntry } from '@/types/leaderboard'

export interface EntryBadge {
	key: string
	label: string
	className: string
}

export function getEntryBadges(entry: LeaderboardEntry): EntryBadge[] {
	const badges: EntryBadge[] = []

	if (entry.rank <= 10) {
		badges.push({
			key: 'top10',
			label: 'Top 10',
			className: 'border-uls/30 bg-uls/15 text-uls',
		})
	}

	if (entry.rankDelta !== undefined && entry.rankDelta > 0) {
		badges.push({
			key: 'up',
			label: `↑${entry.rankDelta}`,
			className: 'border-emerald-400/30 bg-emerald-500/15 text-emerald-300',
		})
	} else if (entry.rankDelta !== undefined && entry.rankDelta < 0) {
		badges.push({
			key: 'down',
			label: `↓${Math.abs(entry.rankDelta)}`,
			className: 'border-red-400/30 bg-red-500/15 text-red-300',
		})
	}

	if (entry.rank >= 15 && entry.rankDelta === undefined) {
		badges.push({
			key: 'steady',
			label: 'Ổn định',
			className: 'border-white/30 bg-uls/20 text-white/85',
		})
	}

	return badges
}
