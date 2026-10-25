import { cn } from '@/utils'

export const MP_MENU_CYAN = '#00e5ff'
export const MP_MENU_CYAN_DIM = '#00b8d4'

export const MP_SHOP_CARD_LIGHT =
	'mp-shop-card-light bg-[#ffffff16] border border-[#FFFFFF40] rounded-lg transition-all duration-200'

export const MP_SHOP_CARD_HOVER =
	'hover:border-[#00e5ff] hover:shadow-[0_0_10px_rgba(0,229,255,0.45)]'

export const MP_SHOP_TAB_ACTIVE =
	'border border-[#00e5ff] bg-[#00e5ff] shadow-[0_0_8px_rgba(0,229,255,0.45)] rounded-lg'

export const LB_NAV_SKEW_BTN = 'lb-nav-skew-btn'
export const LB_NAV_SKEW_CARD = 'lb-nav-skew-card'
export const LB_NAV_SKEW_CARD_ACTIVE = 'lb-nav-skew-card lb-nav-skew-card--active'
export const LB_NAV_SKEW_INNER = 'lb-nav-skew-inner'
export const LB_NAV_SKEW_LABEL = 'lb-nav-skew-label min-w-0 flex-1 truncate leading-tight'

export const MP_LIST_ROW_BORDER = 'border border-[#FFFFFF40]'
export const MP_LB_ROW_GLASS = 'mp-lb-row-glass'

export const mpMenuUi = {
	panel: 'lb-panel--mp-menu h-full min-h-0 w-full',
	layout: 'mp-lb-layout flex h-full min-h-0 w-full gap-6 p-6 box-border bg-transparent',
	navColumn: 'lb-nav-column flex w-[212px] shrink-0 flex-col gap-3',
	navHeader: 'mp-lb-glass-block lb-nav-header rounded-lg px-3 py-3',
	navSkewBtn: LB_NAV_SKEW_BTN,
	navSkewCard: LB_NAV_SKEW_CARD,
	navSkewCardActive: LB_NAV_SKEW_CARD_ACTIVE,
	navSkewInner: LB_NAV_SKEW_INNER,
	navSkewLabel: LB_NAV_SKEW_LABEL,
	navTitleActive: 'text-black font-bold uppercase text-xs tracking-wide',
	navTitleIdle: 'text-white font-bold uppercase text-xs tracking-wide drop-shadow-sm',
	mainColumn: 'mp-lb-main-column flex min-h-0 min-w-0 flex-1 flex-col gap-4',
	titleBar: 'flex shrink-0 items-center gap-6',
	titleAccent: 'w-1 shrink-0 rounded bg-[#00e5ff] shadow-[0_0_5px_#00e5ff]',
	titleAccentH: 'h-8',
	titleText: 'text-2xl font-bold uppercase leading-tight text-white drop-shadow-sm',
	titleTextAccent: 'text-[#00e5ff]',
	subtitle: 'mt-1 text-[10px] font-medium uppercase text-white/65',
	contentCard: 'mp-lb-content-panel flex min-h-0 flex-1 flex-col overflow-hidden bg-transparent',
	iconBtn: cn(MP_SHOP_CARD_LIGHT, 'flex h-9 w-9 items-center justify-center', MP_SHOP_CARD_HOVER, 'text-white/80'),
	iconBtnActive: cn(MP_SHOP_TAB_ACTIVE, 'flex h-9 w-9 items-center justify-center text-black'),
	searchBar: 'flex shrink-0 items-center gap-2 border-b border-[#FFFFFF40] px-4 py-2',
	input: cn(
		MP_SHOP_CARD_LIGHT,
		'min-w-0 flex-1 px-3 py-2 text-sm text-white placeholder:text-white/35 focus:border-[#00e5ff] focus:shadow-[0_0_10px_rgba(0,229,255,0.45)] focus:outline-none'
	),
	top3Zone: 'lb-top3-zone-dark shrink-0 border-b border-[#FFFFFF40] bg-transparent px-4 py-4',
	listBody: 'lb-list-scroll lb-list-table-zone leaderboard-scroll min-h-0 flex-1 overflow-y-auto',
	rank4Head: 'mp-lb-glass-block lb-rank4-head sticky top-0 z-20 border-b border-[#FFFFFF40] px-4 py-2.5',
	rank4Label: 'text-[10px] font-bold uppercase tracking-[0.12em] text-white/75',
	tableHead: 'text-[10px] font-bold uppercase tracking-[0.08em] text-white/80',
	listInner: 'space-y-1.5 px-4 py-3',
	row: cn(
		'lb-entry-row',
		MP_LB_ROW_GLASS,
		MP_LIST_ROW_BORDER,
		'rounded-md px-3 py-2 min-h-[38px] items-center transition-colors duration-150',
		'hover:border-[#00e5ff]'
	),
	rowSelf: cn(
		'lb-entry-row lb-entry-row--self mp-lb-row-glass--self',
		'rounded-md px-3 py-2 min-h-[38px] items-center',
		'border-2 border-[#00e5ff]'
	),
	rankBadge:
		'mp-lb-rank-badge flex h-8 w-8 shrink-0 items-center justify-center rounded-md text-sm font-bold text-white',
	rankBadgeSelf:
		'mp-lb-rank-badge mp-lb-rank-badge--self flex h-8 w-8 shrink-0 items-center justify-center rounded-md text-sm font-bold text-black',
	rankBadgeTop:
		'mp-lb-rank-badge mp-lb-rank-badge--top flex h-8 w-8 shrink-0 items-center justify-center rounded-md text-sm font-bold text-[#b8f4ff]',
	name: 'truncate text-[13px] font-bold leading-none text-white',
	nameSelf: 'truncate text-[13px] font-bold leading-none text-white',
	nameYou: 'ml-1.5 shrink-0 text-[10px] font-semibold normal-case text-[#00e5ff]',
	levelCol: 'text-center text-[13px] font-bold tabular-nums leading-none text-white/90',
	value: 'text-right text-[15px] font-bold tabular-nums leading-none text-[#7fdfff]',
	valueSelf: 'text-right text-[15px] font-bold tabular-nums leading-none text-[#00e5ff]',
	badge: 'shrink-0 rounded border px-1.5 py-0.5 text-[9px] font-bold uppercase leading-none',
	badgeTop10: 'border-[#00e5ff]/50 bg-[#00e5ff]/25 text-[#d6f9ff]',
	badgeUp: 'border-emerald-400/50 bg-emerald-900/50 text-emerald-200',
	badgeDown: 'border-red-400/50 bg-red-900/50 text-red-200',
	badgeSteady:
		'border-[#FFFFFF55] bg-[rgba(0,98,114,0.55)] text-white shadow-[0_0_6px_rgba(0,229,255,0.25)]',
	footer: 'mp-lb-glass-block shrink-0 border-t border-[#FFFFFF40] px-3 py-2',
	myRankBadge:
		'inline-flex min-w-[2.25rem] items-center justify-center rounded bg-[#00e5ff] px-1.5 py-0.5 text-base font-black leading-none text-black',
	myRankBtn:
		'rounded-md border border-[#00e5ff] bg-[#00e5ff] px-2.5 py-1 text-[9px] font-bold uppercase tracking-wide text-black transition-colors hover:bg-[#7fdfff] hover:border-[#7fdfff]',
	empty: 'text-sm font-medium uppercase text-white/55',
	updatedAt:
		'lb-footer-updated text-center text-[11px] font-semibold tracking-wide text-white/90',
} as const
