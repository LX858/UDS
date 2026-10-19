import { Box, Text } from 'lr-components'
import React from 'react'
import styled from 'styled-components'
import { menuCardBase } from '../styles/menuCardStyles'

export const ProfilePanel = styled(Box)`
	position: relative;
	height: 100%;
	flex-shrink: 0;
	min-height: 0;
	box-sizing: border-box;
	display: flex;
	flex-direction: column;
	gap: 14px;
`

export const ProfileSlot = styled(Box)`
	flex: 0 0 auto;
	min-height: 0;
`

const ProfileCard = styled(Box)`
	${menuCardBase}
	width: 100%;
	height: auto;
	display: flex;
	flex-direction: column;
	padding: 12px;
	box-sizing: border-box;
	flex-shrink: 0;
	gap: 8px;
`

const IdentityPanel = styled(Box)`
	padding: 10px 12px;
	border-radius: 4px;
	border: 1px solid rgba(0, 229, 255, 0.28);
	background: linear-gradient(135deg, rgba(0, 16, 32, 0.88) 0%, rgba(0, 8, 18, 0.74) 100%);
	box-shadow:
		0 4px 14px rgba(0, 0, 0, 0.28),
		inset 0 1px 0 rgba(0, 229, 255, 0.08);
`

const IdentityTop = styled(Box)`
	display: flex;
	align-items: baseline;
	justify-content: space-between;
	gap: 10px;
	min-width: 0;
`

const IdentityStatus = styled(Box)`
	display: flex;
	align-items: center;
	gap: 6px;
	margin-top: 8px;
	padding-top: 8px;
	border-top: 1px solid rgba(0, 229, 255, 0.12);
`

const StatusDot = styled.span`
	width: 5px;
	height: 5px;
	border-radius: 50%;
	background: var(--green);
	flex-shrink: 0;
	box-shadow: 0 0 6px rgba(0, 230, 118, 0.5);
`

const FieldStrip = styled(Box)`
	padding: 8px 10px;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 30, 50, 0.82);
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 10px;
	min-width: 0;
`

const FieldLabel = styled(Text)`
	flex: 0 1 48%;
	min-width: 0;
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 9px;
	font-weight: 500;
	line-height: 1.25;
	text-transform: uppercase;
	letter-spacing: 0.06em;
	color: var(--text-sub);
`

const FieldValue = styled(Text)<{ $accent?: boolean }>`
	flex: 1 1 52%;
	min-width: 0;
	text-align: right;
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: ${(p) => (p.$accent ? 11 : 10)}px;
	font-weight: 700;
	line-height: 1.25;
	text-transform: uppercase;
	letter-spacing: 0.02em;
	color: ${(p) => (p.$accent ? 'var(--cyan)' : '#fff')};
	word-break: break-word;
	overflow-wrap: anywhere;
`

const HERO_KEYS = new Set(['account', 'id', 'status'])
const ACCENT_KEYS = new Set(['job'])

export type ProfileSidebarRow = {
	key: string
	label: string
	value: React.ReactNode
}

type ProfileSidebarProps = {
	rows: ProfileSidebarRow[]
	title?: string
}

function getRow(rows: ProfileSidebarRow[], key: string) {
	return rows.find((row) => row.key === key)
}

function ProfileSidebar({ rows, title }: ProfileSidebarProps) {
	const accountRow = getRow(rows, 'account')
	const idRow = getRow(rows, 'id')
	const statusRow = getRow(rows, 'status')
	const detailRows = rows.filter((row) => !HERO_KEYS.has(row.key))

	return (
		<ProfileCard className='mp-profile-sidebar'>
			{title && (
				<Text
					textTransform='uppercase'
					fontWeight='bold'
					rFontSize={14}
					rLineHeight={18}
					color='#fff'
					textShadow='0 2px 10px rgba(0,0,0,0.55)'>
					{title}
				</Text>
			)}

			{(accountRow || idRow || statusRow) && (
				<IdentityPanel>
					<IdentityTop>
						{accountRow && (
							<Text
								flex={1}
								minWidth={0}
								textTransform='uppercase'
								fontWeight='bold'
								rFontSize={15}
								rLineHeight={19}
								color='#fff'
								wordBreak='break-word'>
								{String(accountRow.value)}
							</Text>
						)}
						{idRow && (
							<Text
								flexShrink={0}
								fontWeight='bold'
								rFontSize={11}
								color='var(--cyan)'
								fontFamily="'Goldman', 'Oswald', sans-serif">
								{String(idRow.value)}
							</Text>
						)}
					</IdentityTop>
					{statusRow && (
						<IdentityStatus>
							<StatusDot />
							<Text rFontSize={9} fontWeight='600' textTransform='uppercase' color='var(--green)'>
								{String(statusRow.value)}
							</Text>
						</IdentityStatus>
					)}
				</IdentityPanel>
			)}

			<Box className='mp-profile-rows' display='flex' flexDirection='column' rGap={6}>
				{detailRows.map((row) => (
					<FieldStrip
						key={row.key}
						className={`mp-profile-row${row.key === 'job' ? ' mp-profile-row--job' : ''}`}>
						<FieldLabel className='mp-profile-label'>{row.label}</FieldLabel>
						<FieldValue $accent={ACCENT_KEYS.has(row.key)} className='mp-profile-value'>
							{String(row.value)}
						</FieldValue>
					</FieldStrip>
				))}
			</Box>
		</ProfileCard>
	)
}

export default ProfileSidebar
