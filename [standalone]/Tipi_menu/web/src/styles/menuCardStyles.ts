import { css } from 'styled-components'

export const menuCardBase = css`
	position: relative;
	overflow: hidden;
	background-color: var(--bg-card);
	border: 1px solid var(--border-dim);
	border-radius: 4px;
	box-sizing: border-box;
	transition: filter 0.2s ease, border-color 0.2s ease;
`

export const menuCardHover = css`
	filter: brightness(1.04);
	border-color: var(--border);
`
