import React, { useCallback, useEffect, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { AppActions, AppDispatch, RootState } from './store'
import { ToastContainer } from 'react-toastify'
import { Box, Text } from 'lr-components'
import AppActionHook from './components/AppActionHook'
import { isEnvBrowser } from './utils/misc'
import { fetchNui } from './utils/fetchNui'
import { UISetting } from './types'
import IndexPage from './Page'
import EventRulesAdminModal from './components/EventRulesAdminModal'
import CreateGiftCodeModal from './components/CreateGiftCodeModal'
import DailyMonthClaimHud from './components/DailyMonthClaimHud'
import { SettingContext } from './context/SettingContext'
import { applyLocaleArgs } from './utils/localeFormat'
import { mergeGameLocale } from './utils/locale'
import { setEventCardsAdmin, setGiftCodeAdmin } from './store/main'
import { FALLBACK_EVENT_CARDS } from './constants/eventCards'

function App() {
	const dispatch = useDispatch<AppDispatch>()
	const show = useSelector((state: RootState) => state.main.show)
	const eventCardsAdminOpen = useSelector((state: RootState) => state.main.eventCardsAdmin.open)
	const giftCodeAdminOpen = useSelector((state: RootState) => state.main.giftCodeAdmin.open)
	const [setting, setSetting] = useState<UISetting>({ locale: mergeGameLocale() })

	const openEventCardsAdminDev = useCallback(() => {
		dispatch(
			setEventCardsAdmin({
				open: true,
				cards: FALLBACK_EVENT_CARDS,
			}),
		)
	}, [dispatch])

	const closeGiftCodeAdminDev = useCallback(() => {
		dispatch(setGiftCodeAdmin({ open: false }))
	}, [dispatch])

	const openGiftCodeAdminDev = useCallback(() => {
		dispatch(setGiftCodeAdmin({ open: true }))
	}, [dispatch])

	const closeEventCardsAdminDev = useCallback(() => {
		dispatch(setEventCardsAdmin({ open: false }))
	}, [dispatch])

	const L = (key: string, args?: { [key: string]: string | number }) => {
		const tpl = setting.locale[key]
		if (tpl) return applyLocaleArgs(tpl, args)
		return key
	}

	useEffect(() => {
		if (isEnvBrowser()) {
			setSetting({ locale: mergeGameLocale() })
		} else {
			fetchNui<UISetting>('AppReady')
				.then((data) => setSetting({ locale: mergeGameLocale(data?.locale) }))
				.catch(() => setSetting({ locale: mergeGameLocale() }))
		}

		const keyHandler = (e: KeyboardEvent) => {
			if (isEnvBrowser() && e.ctrlKey && e.shiftKey && e.key.toLowerCase() === 'e') {
				e.preventDefault()
				if (eventCardsAdminOpen) {
					closeEventCardsAdminDev()
				} else {
					openEventCardsAdminDev()
				}
				return
			}

			if (isEnvBrowser() && e.ctrlKey && e.shiftKey && e.key.toLowerCase() === 'g') {
				e.preventDefault()
				if (giftCodeAdminOpen) {
					closeGiftCodeAdminDev()
				} else {
					openGiftCodeAdminDev()
				}
				return
			}

			if (e.key === 'Escape') {
				if (giftCodeAdminOpen) {
					if (isEnvBrowser()) {
						closeGiftCodeAdminDev()
					} else {
						fetchNui('giftCode:closeAdmin', { menuOpen: show })
					}
					return
				}
				if (eventCardsAdminOpen) {
					if (isEnvBrowser()) {
						closeEventCardsAdminDev()
					} else {
						fetchNui('eventRules:closeAdmin', { menuOpen: show })
					}
					return
				}
				if (!isEnvBrowser()) {
					fetchNui('close')
				}
			}
		}
		window.addEventListener('keydown', keyHandler)
		return () => window.removeEventListener('keydown', keyHandler)
	}, [
		eventCardsAdminOpen,
		giftCodeAdminOpen,
		show,
		openEventCardsAdminDev,
		closeEventCardsAdminDev,
		openGiftCodeAdminDev,
		closeGiftCodeAdminDev,
	])

	return (
		<SettingContext.Provider value={{ setting, setSetting, L }}>
			{Object.keys(AppActions).map((action) => (
				<AppActionHook key={action} action={action as keyof typeof AppActions} />
			))}
			{isEnvBrowser() && (
				<Box
					className='mp-dev-panel'
					display='flex'
					position='fixed'
					top={0}
					right={0}
					flexDirection='column'
					alignItems='flex-end'
					rGap={6}
					rPadding={8}
					zIndex={14000}>
					<Box
						className='mp-dev-admin-btn'
						rPadding={[8, 10]}
						backgroundColor='#103040'
						rBorderRadius={8}
						border='1px solid rgba(0,229,255,0.35)'
						cursor='pointer'
						onClick={openGiftCodeAdminDev}>
						<Text rFontSize={11} fontWeight='bold' color='var(--cyan)'>
							/creategiftcode
						</Text>
						<Text rFontSize={9} color='var(--text-sub)'>
							Ctrl+Shift+G
						</Text>
					</Box>
					<Box
						className='mp-dev-admin-btn'
						rPadding={[8, 10]}
						backgroundColor='#103040'
						rBorderRadius={8}
						border='1px solid rgba(0,229,255,0.35)'
						cursor='pointer'
						onClick={openEventCardsAdminDev}>
						<Text rFontSize={11} fontWeight='bold' color='var(--cyan)'>
							/thelesukien
						</Text>
						<Text rFontSize={9} color='var(--text-sub)'>
							Ctrl+Shift+E
						</Text>
					</Box>
					{Object.keys(AppActions).map((action) => (
						<Box key={action} rPadding={5} backgroundColor='#1f1f1f' rBorderRadius={10} opacity={0.5}>
							{action}
						</Box>
					))}
				</Box>
			)}
			<EventRulesAdminModal />
			<CreateGiftCodeModal />
			<DailyMonthClaimHud />
			{show && (
				<Box
					width='100vw'
					height='100vh'
					position='fixed'
					top={0}
					left={0}
					display='flex'
					justifyContent='center'
					alignItems='center'
					className='mp-menu-root'>
					<IndexPage />
				</Box>
			)}

			<ToastContainer pauseOnFocusLoss={false} hideProgressBar={true} />
		</SettingContext.Provider>
	)
}

export default App
