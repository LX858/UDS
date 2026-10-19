import { Box, Text } from 'lr-components'
import React, { ReactNode } from 'react'
import styled from 'styled-components'

const TabLabel = styled(Text)<{ $active: boolean }>`
	color: #ffffff !important;
	text-shadow: ${(p) =>
		p.$active ? '0 0 10px rgba(255, 255, 255, 0.35)' : 'none'};
	transition: text-shadow 0.25s ease;
`

const TabButton = styled(Box)<{ $active: boolean }>`
	background-color: ${(p) => (p.$active ? 'var(--cyan-tab-active)' : 'var(--cyan-faint)')};
	border: ${(p) =>
		p.$active ? '1px solid var(--cyan-dim)' : '1px solid var(--border-dim)'};
	box-shadow: ${(p) => (p.$active ? '0 0 10px var(--cyan-glow-active)' : 'none')};
	transition: background-color 0.25s ease, border-color 0.25s ease, box-shadow 0.25s ease;
	cursor: pointer;

	&:hover {
		background-color: ${(p) =>
			p.$active ? 'var(--cyan-tab-active-hover)' : 'var(--cyan-tab-hover)'};
		border-color: ${(p) => (p.$active ? 'var(--cyan)' : 'var(--border)')};
		box-shadow: ${(p) =>
			p.$active ? '0 0 12px var(--cyan-glow-active)' : '0 0 6px var(--cyan-glow)'};

		${TabLabel} {
			color: #ffffff !important;
			text-shadow: 0 0 10px rgba(255, 255, 255, 0.35);
		}
	}
`

type NavTabProps = {
	active: boolean
	icon: ReactNode
	label: string
	onClick: () => void
}

function NavTab({ active, icon, label, onClick }: NavTabProps) {
	return (
		<TabButton
			flexGrow={1}
			flexBasis={0}
			minWidth={0}
			rHeight={72}
			rPadding={24}
			display='flex'
			alignItems='center'
			justifyContent='left'
			rBorderRadius={4}
			rGap={16}
			$active={active}
			onClick={onClick}>
			{icon}
			<TabLabel
				$active={active}
				rFontSize={16}
				fontWeight='bold'
				textTransform='uppercase'
				flexGrow={1}
				minWidth={0}>
				{label}
			</TabLabel>
		</TabButton>
	)
}

export default NavTab
