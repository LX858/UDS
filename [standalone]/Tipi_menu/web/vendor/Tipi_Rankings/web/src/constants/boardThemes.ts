import type { BoardThemeId } from '@/types/leaderboard'

export interface BoardTheme {
	accent: string
	accentMuted: string
	border: string
	glow: string
	navActive: string
	progress: string
}

const cyanTheme: BoardTheme = {
	accent: 'text-uls',
	accentMuted: 'text-uls/70',
	border: 'border-uls/25',
	glow: 'shadow-[0_0_24px_rgba(0,229,255,0.15)]',
	navActive: 'border-uls/35 bg-uls/12',
	progress: 'from-uls/80 to-cyan-700/80',
}

export const BOARD_THEMES: Record<BoardThemeId, BoardTheme> = {
	gang: cyanTheme,
	bus: cyanTheme,
	police: cyanTheme,
	ems: cyanTheme,
	mechanic: cyanTheme,
	player: cyanTheme,
	default: cyanTheme,
}

export function getBoardTheme(themeId?: BoardThemeId): BoardTheme {
	return BOARD_THEMES[themeId ?? 'default'] ?? BOARD_THEMES.default
}
