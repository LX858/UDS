import { Box, Text } from 'lr-components'
import { AnimatePresence, motion } from 'framer-motion'
import { useCallback, useEffect, useRef, useState } from 'react'
import styled, { keyframes } from 'styled-components'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { useLocale } from '../hooks/useLocale'
import { isEnvBrowser } from '../utils/misc'
import { setEmbedAssetBase, setEmbeddedResourceName, getMysteryRewardImage } from '@tipi-daily-rewards/utils/assets'

const giftSway = keyframes`
	0%, 100% { transform: rotate(-5deg); }
	50% { transform: rotate(5deg); }
`

const HudWrap = styled(motion.div)`
	position: fixed;
	left: 50%;
	bottom: 28px;
	z-index: 20000;
	pointer-events: none;
`

const HudCard = styled(Box)`
	width: 128px;
	height: 128px;
	display: flex;
	align-items: center;
	justify-content: center;
	border-radius: 6px;
	border: 1px solid rgba(0, 229, 255, 0.45);
	background: linear-gradient(180deg, rgba(0, 20, 34, 0.94) 0%, rgba(0, 10, 20, 0.95) 100%);
	box-shadow:
		0 8px 22px rgba(0, 0, 0, 0.45),
		0 0 18px rgba(0, 229, 255, 0.24);
`

const HudGift = styled.img`
	width: 84px;
	height: 84px;
	object-fit: contain;
	transform-origin: center bottom;
	animation: ${giftSway} 0.68s ease-in-out infinite;
`

const HudCaption = styled(Text)`
	margin-top: 8px;
	max-width: 260px;
	text-align: center;
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 11px;
	font-weight: 700;
	letter-spacing: 0.04em;
	text-transform: uppercase;
	color: #c8f7ff;
	text-shadow: 0 2px 8px rgba(0, 0, 0, 0.65);
`

/**
 * HUD điểm danh tháng — mount ở App (ngoài `show`) để hiện cả khi ESC đóng.
 */
export default function DailyMonthClaimHud() {
	const L = useLocale()
	const [hud, setHud] = useState<{ id: number; minutes: number } | null>(null)
	const timerRef = useRef<number | null>(null)

	useEffect(() => {
		setEmbeddedResourceName('Tipi_Daily_Rewards')
		setEmbedAssetBase(isEnvBrowser() ? '/images/daily-rewards' : './images/daily-rewards')
	}, [])

	const showHud = useCallback((minutes: number) => {
		if (timerRef.current != null) {
			window.clearTimeout(timerRef.current)
			timerRef.current = null
		}
		setHud({ id: Date.now(), minutes: Math.max(1, Math.floor(minutes || 1)) })
	}, [])

	useEffect(() => {
		if (!hud) return
		timerRef.current = window.setTimeout(() => {
			setHud(null)
			timerRef.current = null
		}, 2400)
		return () => {
			if (timerRef.current != null) {
				window.clearTimeout(timerRef.current)
				timerRef.current = null
			}
		}
	}, [hud])

	useNuiEvent<{ minutes?: number }>('dailyMonthClaimReady', (data) => {
		showHud(Number(data?.minutes) || 1)
	})

	return (
		<AnimatePresence>
			{hud ? (
				<HudWrap
					key={hud.id}
					initial={{ x: '-50%', y: 86, opacity: 0 }}
					animate={{ x: '-50%', y: 0, opacity: 1 }}
					exit={{ x: '-50%', y: 108, opacity: 0 }}
					transition={{ duration: 0.33, ease: 'easeOut' }}>
					<Box display='flex' flexDirection='column' alignItems='center'>
						<HudCard>
							<HudGift src={getMysteryRewardImage()} alt='' draggable={false} />
						</HudCard>
						<HudCaption>
							{L('ui.main.daily_hud_month_reached').replace('{minutes}', String(hud.minutes))}
						</HudCaption>
					</Box>
				</HudWrap>
			) : null}
		</AnimatePresence>
	)
}
