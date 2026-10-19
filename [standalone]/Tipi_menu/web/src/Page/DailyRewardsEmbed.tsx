import { useCallback, useEffect, useState } from 'react'
import { Box } from 'lr-components'
import DailyRewardsApp, { type DailyRewardsOpenPayload } from '@tipi-daily-rewards/components/DailyRewardsApp'
import { setAssetConfig, setEmbeddedResourceName, setEmbedAssetBase } from '@tipi-daily-rewards/utils/assets'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { fetchNui } from '../utils/fetchNui'
import { isEnvBrowser } from '../utils/misc'
import type { OnlineSyncData } from '@tipi-daily-rewards/types'

type DailyRewardsEmbedProps = {
	openPayload: DailyRewardsOpenPayload
	onClose: () => void
	onSummaryChange?: (patch: Partial<DailyRewardsSummary>) => void
}

export type DailyRewardsSummary = {
	checkedCount: number
	daysInMonth: number
	onlineMinutes: number
	presentToday: boolean
	todayReward: number
	canClaimToday: boolean
	hasVipPack?: boolean
	vipPackPrice?: number
	inventoryImageTemplate?: string
	inventoryImageCdn?: string
	itemImageResourceTemplate?: string
	error?: string
}

function applySummaryAssetConfig(summary: Pick<
	DailyRewardsSummary,
	'inventoryImageTemplate' | 'inventoryImageCdn' | 'itemImageResourceTemplate'
>) {
	if (
		!summary.inventoryImageTemplate &&
		!summary.inventoryImageCdn &&
		!summary.itemImageResourceTemplate
	) {
		return
	}
	setAssetConfig({
		inventoryImageTemplate: summary.inventoryImageTemplate,
		inventoryImageCdn: summary.inventoryImageCdn,
		itemImageResourceTemplate: summary.itemImageResourceTemplate,
	})
}

function patchSummaryFromSync(
	prev: DailyRewardsSummary | null,
	data: OnlineSyncData,
): Partial<DailyRewardsSummary> {
	const presentToday = data.presentToday ?? prev?.presentToday ?? false
	return {
		onlineMinutes: data.onlineMinutes,
		presentToday,
		todayReward: data.todayReward ?? prev?.todayReward ?? 0,
		// Không ép canClaimToday=true mỗi lần sync (tránh hiện lại "có quà" sau khi đã nhận)
		canClaimToday:
			data.presentToday === false
				? false
				: (prev?.canClaimToday ?? data.presentToday === true),
		hasVipPack: data.hasVipPack ?? prev?.hasVipPack,
		vipPackPrice: data.vipPackPrice ?? prev?.vipPackPrice,
	}
}

function applyEmbedAssets(payload: DailyRewardsOpenPayload) {
	setEmbeddedResourceName('Tipi_Daily_Rewards')
	setEmbedAssetBase(isEnvBrowser() ? '/images/daily-rewards' : './images/daily-rewards')
	setAssetConfig({
		mysteryImageUrl: isEnvBrowser()
			? '/images/daily-rewards/common.png'
			: './images/daily-rewards/common.png',
		inventoryImageTemplate: payload.inventoryImageTemplate,
		inventoryImageCdn: payload.inventoryImageCdn,
		itemImageResourceTemplate: payload.itemImageResourceTemplate,
		clothingImageUrl: payload.clothingImageUrl,
		clothingImageExt: payload.clothingImageExt,
		clothingComponents: payload.clothingComponents,
	})
}

export default function DailyRewardsEmbed({ openPayload, onClose, onSummaryChange }: DailyRewardsEmbedProps) {
	useEffect(() => {
		applyEmbedAssets(openPayload)
		// Giữ embed asset base sau khi đóng — compact card / remount vẫn tìm được common.png
	}, [openPayload])

	const handleSync = useCallback(
		(data: OnlineSyncData) => {
			onSummaryChange?.(patchSummaryFromSync(null, data))
		},
		[onSummaryChange],
	)

	useNuiEvent<OnlineSyncData>('dailyRewardsSync', handleSync)

	return (
		<Box
			width='100%'
			height='100%'
			minHeight={0}
			flexGrow={1}
			position='relative'
			className='mp-dr-embed-shell mp-dr-inline-shell'>
			<DailyRewardsApp
				embedded
				nuiPrefix='dailyRewards:'
				initialOpen={openPayload}
				onClose={onClose}
				onMonthClaimed={() => {
					onSummaryChange?.({ canClaimToday: false })
				}}
			/>
		</Box>
	)
}

export function useDailyRewardsSummaryLoader(active: boolean) {
	const [summary, setSummary] = useState<DailyRewardsSummary | null>(null)
	const [loading, setLoading] = useState(false)

	useEffect(() => {
		// Init path ảnh hộp quà sớm (không đợi mở bảng tháng)
		setEmbeddedResourceName('Tipi_Daily_Rewards')
		setEmbedAssetBase(isEnvBrowser() ? '/images/daily-rewards' : './images/daily-rewards')
		setAssetConfig({
			mysteryImageUrl: isEnvBrowser()
				? '/images/daily-rewards/common.png'
				: './images/daily-rewards/common.png',
		})
	}, [])

	const reload = useCallback(async () => {
		setLoading(true)
		try {
			const payload = await fetchNui<DailyRewardsSummary>(
				'dailyRewards:getSummary',
				undefined,
				isEnvBrowser()
					? {
							checkedCount: 12,
							daysInMonth: 31,
							onlineMinutes: 5,
							presentToday: true,
							todayReward: 8,
							canClaimToday: true,
							hasVipPack: false,
							vipPackPrice: 99,
						}
					: undefined,
			)
			setSummary(payload)
			if (payload && !payload.error) applySummaryAssetConfig(payload)
		} catch {
			setSummary({
				checkedCount: 0,
				daysInMonth: 31,
				onlineMinutes: 0,
				presentToday: false,
				todayReward: 0,
				canClaimToday: false,
				hasVipPack: false,
				vipPackPrice: 99,
				error: 'load_failed',
			})
		} finally {
			setLoading(false)
		}
	}, [])

	useEffect(() => {
		if (!active) return
		void reload()
	}, [active, reload])

	useNuiEvent<Partial<DailyRewardsSummary>>('dailyRewardsSummary', (patch) => {
		setSummary((prev) => (prev ? { ...prev, ...patch } : null))
	})

	useNuiEvent<OnlineSyncData>('dailyRewardsSync', (data) => {
		setSummary((prev) => (prev ? { ...prev, ...patchSummaryFromSync(prev, data) } : prev))
	})

	useNuiEvent<{ hasVipPack?: boolean; vipPackPrice?: number }>('dailyRewardsVipBought', (data) => {
		setSummary((prev) =>
			prev
				? {
						...prev,
						hasVipPack: data?.hasVipPack ?? true,
						vipPackPrice: data?.vipPackPrice ?? prev.vipPackPrice,
					}
				: prev,
		)
	})

	return { summary, loading, reload, setSummary }
}
