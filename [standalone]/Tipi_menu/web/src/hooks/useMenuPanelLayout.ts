import { useMemo } from 'react'
import { useWindowSize } from 'lr-components'

export const MENU_PANEL_DESIGN = {
	width: 1729,
	height: 800,
	bottomPad: 72,
	categoryTop: 120,
	categoryHeight: 72,
	gapBelowCategory: 16,
} as const

const DESIGN_W = 1920
const DESIGN_H = 1080
const DESIGN_ASPECT = DESIGN_W / DESIGN_H

export function useMenuPanelLayout() {
	const windowSize = useWindowSize()

	return useMemo(() => {
		const rw = windowSize.width / DESIGN_W
		const rh = Math.min(windowSize.ratioHeight, windowSize.height / DESIGN_H)
		const aspect = windowSize.width / windowSize.height
		const isUltrawide = aspect > DESIGN_ASPECT + 0.02
		const vScale = isUltrawide ? rh : rw
		const vh = windowSize.height

		const desiredH = rh * MENU_PANEL_DESIGN.height
		const bottomPad = rh * MENU_PANEL_DESIGN.bottomPad
		const categoryBottom =
			vScale * (MENU_PANEL_DESIGN.categoryTop + MENU_PANEL_DESIGN.categoryHeight)
		const minTop = categoryBottom + vScale * MENU_PANEL_DESIGN.gapBelowCategory

		let top = vh - bottomPad - desiredH
		if (top < minTop) {
			top = minTop
		}

		const maxH = Math.max(rw * 360, vh - top - 8)
		const height = Math.min(desiredH, maxH)

		return {
			width: rw * MENU_PANEL_DESIGN.width,
			height,
			top,
			contentScale: height / desiredH,
			designHeight: desiredH,
			rw,
			rh,
			isUltrawide,
		}
	}, [windowSize.height, windowSize.width, windowSize.ratioHeight])
}
