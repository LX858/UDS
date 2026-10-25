import { useCallback, useEffect, useState } from 'react'
import DailyRewardsApp from './components/DailyRewardsApp'
import AdminDailyApp, { applyAdminAssets, type AdminPayload } from './components/AdminDailyApp'
import { DEFAULT_LOCALES } from './constants/rewards'
import type { Locales } from './types'
import { isEnvBrowser } from './utils/nui'
import { buildBrowserAdminPayload } from './utils/adminMock'

export default function App() {
	const [mode, setMode] = useState<'player' | 'admin'>('player')
	const [adminPayload, setAdminPayload] = useState<AdminPayload | null>(null)
	const [adminLocales, setAdminLocales] = useState<Locales>(DEFAULT_LOCALES)

	const openAdminBrowser = useCallback(() => {
		const payload = buildBrowserAdminPayload()
		setAdminLocales(DEFAULT_LOCALES)
		setAdminPayload(payload)
		setMode('admin')
	}, [])

	const handleMessage = useCallback(
		(
			event: MessageEvent<
				{ type?: string; bool?: string; data?: AdminPayload; locales?: Locales } & Record<string, unknown>
			>,
		) => {
			const message = event.data
			if (!message || typeof message !== 'object') return

			if (message.type === 'admin' && message.bool === 'open') {
				applyAdminAssets(message as {
					mysteryImageUrl?: string
					inventoryImageTemplate?: string
					inventoryImageCdn?: string
					itemImageResourceTemplate?: string
				})
				setAdminLocales(message.locales || DEFAULT_LOCALES)
				setAdminPayload(message.data || null)
				setMode('admin')
				return
			}

			if (message.type === 'main' && message.bool === 'open') {
				setMode('player')
			}
		},
		[],
	)

	useEffect(() => {
		window.addEventListener('message', handleMessage)
		return () => window.removeEventListener('message', handleMessage)
	}, [handleMessage])

	if (mode === 'admin') {
		return (
			<AdminDailyApp
				initial={adminPayload}
				locales={adminLocales}
				onClose={() => {
					setMode('player')
					setAdminPayload(null)
				}}
			/>
		)
	}

	return (
		<>
			{isEnvBrowser() ? (
				<button
					type='button'
					style={{
						position: 'fixed',
						top: 12,
						right: 12,
						zIndex: 100,
						padding: '8px 12px',
						cursor: 'pointer',
					}}
					onClick={openAdminBrowser}>
					Test Admin /admindaily
				</button>
			) : null}
			<DailyRewardsApp />
		</>
	)
}
