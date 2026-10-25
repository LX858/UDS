import { useCallback, useEffect, useMemo, useState } from 'react'
import { fetchNui, isEnvBrowser } from '../utils/nui'
import { setAssetConfig } from '../utils/assets'
import { buildBrowserAdminPayload } from '../utils/adminMock'
import { clampMissedMaxClaims, missedClaimPricePreview, normalizeMissedMultiplier } from '../utils/missedPrice'
import { DEFAULT_LOCALES } from '../constants/rewards'
import ItemImage from './ItemImage'
import type { ClothingComponentOption, Locales, RewardConfig } from '../types'

export type AdminDayMap = Record<string, RewardConfig>

export type AdminStreakRow = {
	days: number
	reward: RewardConfig
}

export type AdminPayload = {
	ok?: boolean
	error?: string
	monthKey: string
	calendarYear: number
	calendarMonth: number
	daysInMonth: number
	todayDay?: number
	normal: AdminDayMap
	vip: AdminDayMap
	fromSql?: boolean
	fromTemplate?: boolean
	streaks: AdminStreakRow[]
	streaksFromSql?: boolean
	templateNormal?: AdminDayMap
	templateVip?: AdminDayMap
	templateStreaks?: AdminStreakRow[]
	itemTypes?: string[]
	clothingComponents?: ClothingComponentOption[]
	clothingImageUrl?: string
	clothingImageExt?: string
	vipPackPrice?: number
	missedDayClaimPrice?: number
	missedDayClaimMultiplier?: number
	missedDayClaimEnabled?: boolean
	maxMissedClaimsPerMonth?: number
	missedClaimPricePreview?: Array<{ claim: number; price: number }>
	settingsFromSql?: boolean
	templateVipPackPrice?: number
	templateMissedDayClaimPrice?: number
	templateMissedDayClaimMultiplier?: number
	templateMissedDayClaimEnabled?: boolean
	templateMaxMissedClaimsPerMonth?: number
}

type AdminDailyAppProps = {
	initial?: AdminPayload | null
	locales?: Locales
	onClose?: () => void
}

const FALLBACK_CLOTHES: ClothingComponentOption[] = [
	{ key: 'hat', label: 'Mũ', itemname: 'cloth_helmet', component: 0, prop: true },
	{ key: 'mask', label: 'Mặt nạ', itemname: 'cloth_mask', component: 1, prop: false },
	{ key: 'glasses', label: 'Kính', itemname: 'cloth_glasses', component: 1, prop: true },
	{ key: 'chain', label: 'Dây chuyền', itemname: 'cloth_chain', component: 7, prop: false },
	{ key: 'gloves', label: 'Găng tay', itemname: 'cloth_arms', component: 3, prop: false },
	{ key: 'torso', label: 'Áo khoác', itemname: 'cloth_torso', component: 11, prop: false },
	{ key: 'watch', label: 'Đồng hồ', itemname: 'cloth_watches', component: 6, prop: true },
	{ key: 'pants', label: 'Quần', itemname: 'cloth_pants', component: 4, prop: false },
	{ key: 'earrings', label: 'Khuyên tai', itemname: 'cloth_ears', component: 2, prop: true },
	{ key: 'bag', label: 'Túi xách', itemname: 'cloth_bags', component: 5, prop: false },
	{ key: 'shirt', label: 'Áo thun', itemname: 'cloth_tshirt', component: 8, prop: false },
	{ key: 'vest', label: 'Áo chống đạn', itemname: 'cloth_bproof', component: 9, prop: false },
	{ key: 'bracelets', label: 'Vòng tay', itemname: 'cloth_bracelets', component: 7, prop: true },
	{ key: 'shoes', label: 'Giày', itemname: 'cloth_shoes', component: 6, prop: false },
]

const emptyReward = (): RewardConfig => ({
	type: 'common',
	itemName: '',
	itemLabel: '',
	itemCount: 1,
	itemType: 'item',
	clothComponent: '',
	clothDrawable: 1,
	clothTexture: 1,
	clothSex: '',
})

function cloneReward(src?: RewardConfig): RewardConfig {
	const next = {
		...emptyReward(),
		...(src || {}),
		itemCount: Math.max(1, Number(src?.itemCount) || 1),
		clothDrawable: Math.max(1, Number(src?.clothDrawable) || 1),
		clothTexture: Math.max(1, Number(src?.clothTexture) || 1),
		clothSex: src?.clothSex === 'male' || src?.clothSex === 'female' ? src.clothSex : ('' as const),
	}
	return next
}

function cloneMap(map: AdminDayMap | undefined, daysInMonth: number): AdminDayMap {
	const total = Math.max(0, Math.floor(Number(daysInMonth) || 0))
	const out: AdminDayMap = {}
	for (let day = 1; day <= total; day += 1) {
		out[String(day)] = cloneReward(map?.[String(day)])
	}
	return out
}

function shiftMonth(monthKey: string, delta: number) {
	const year = Number(monthKey.slice(0, 4))
	const month = Number(monthKey.slice(5, 7))
	const date = new Date(year, month - 1 + delta, 1)
	return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`
}

function rewardSummary(reward: RewardConfig) {
	if (reward.itemType === 'clothing') {
		const sex = reward.clothSex === 'male' ? 'Nam' : reward.clothSex === 'female' ? 'Nữ' : 'Auto'
		return `${reward.itemLabel || reward.clothComponent || 'Quần áo'} · d${reward.clothDrawable ?? 0}/t${reward.clothTexture ?? 0} · ${sex}`
	}
	if (reward.itemType === 'cash' || reward.itemType === 'money') {
		return `$${reward.itemCount}`
	}
	return `${reward.itemLabel || reward.itemName || '—'} x${reward.itemCount}`
}

function itemTypeLabel(type: string) {
	if (type === 'clothing') return 'Quần áo'
	if (type === 'cash' || type === 'money') return 'Cash'
	if (type === 'item') return 'Item'
	return type
}

function isMoneyRewardType(type?: string) {
	return type === 'cash' || type === 'money'
}

function clothComponentLabel(clothingComponents: ClothingComponentOption[], key?: string) {
	const found = clothingComponents.find((item) => item.key === key)
	return found?.label || key || 'Quần áo'
}

function suggestClothLabel(
	clothingComponents: ClothingComponentOption[],
	opts: { clothComponent?: string; itemName?: string; clothDrawable?: number; clothTexture?: number; clothSex?: string },
) {
	const base = clothComponentLabel(clothingComponents, opts.clothComponent || opts.itemName)
	const drawable = opts.clothDrawable ?? 1
	const texture = opts.clothTexture ?? 1
	const sex =
		opts.clothSex === 'male' ? ' Nam' : opts.clothSex === 'female' ? ' Nữ' : ''
	return `${base} #${drawable}/${texture}${sex}`
}

type NumberStepperProps = {
	label: string
	value: number
	min?: number
	max?: number
	step?: number
	allowFloat?: boolean
	className?: string
	onChange: (value: number) => void
}

function NumberStepper({
	label,
	value,
	min = 1,
	max,
	step = 1,
	allowFloat = false,
	className = '',
	onChange,
}: NumberStepperProps) {
	const setValue = (next: number) => {
		let parsed = Number.isFinite(next) ? next : min
		if (!allowFloat) parsed = Math.floor(parsed)
		else parsed = Math.round(parsed * 100) / 100
		parsed = Math.max(min, parsed)
		if (typeof max === 'number') parsed = Math.min(max, parsed)
		onChange(parsed)
	}

	return (
		<label className={`admin-field${className ? ` ${className}` : ''}`}>
			<span className='admin-field-label'>{label}</span>
			<div className='admin-stepper'>
				<button
					type='button'
					className='admin-stepper-btn'
					aria-label={`Giảm ${label}`}
					onClick={() => setValue(value - step)}>
					−
				</button>
				<input
					type='number'
					min={min}
					max={max}
					step={step}
					value={value}
					onChange={(event) => setValue(Number(event.target.value))}
				/>
				<button
					type='button'
					className='admin-stepper-btn'
					aria-label={`Tăng ${label}`}
					disabled={typeof max === 'number' && value >= max}
					onClick={() => setValue(value + step)}>
					+
				</button>
			</div>
		</label>
	)
}

type RewardEditorProps = {
	reward: RewardConfig
	itemTypes: string[]
	clothingComponents: ClothingComponentOption[]
	onChange: (patch: Partial<RewardConfig>) => void
}

function RewardEditor({ reward, itemTypes, clothingComponents, onChange }: RewardEditorProps) {
	const isCloth = reward.itemType === 'clothing'
	const isMoney = isMoneyRewardType(reward.itemType)

	return (
		<div className='admin-reward-fields'>
			<label className='admin-field'>
				<span className='admin-field-label'>Loại quà</span>
				<select
					value={isMoney ? 'cash' : reward.itemType}
					onChange={(event) => {
						const nextType = event.target.value
							if (nextType === 'clothing') {
								const first = clothingComponents[0]
								const key = reward.clothComponent || first?.key || 'shirt'
								const next = {
									itemType: nextType,
									clothComponent: key,
									itemName: key,
									itemCount: 1,
									clothDrawable: Math.max(1, reward.clothDrawable || 1),
									clothTexture: Math.max(1, reward.clothTexture || 1),
									clothSex: (reward.clothSex || '') as '' | 'male' | 'female',
								}
							onChange({
								...next,
								itemLabel: suggestClothLabel(clothingComponents, next),
							})
							return
						}
						if (nextType === 'cash') {
							const count = Math.max(1, reward.itemCount || 1)
							onChange({
								itemType: 'cash',
								itemName: 'cash',
								itemLabel: reward.itemLabel?.startsWith('$') ? reward.itemLabel : `$${count}`,
								itemCount: count,
							})
							return
						}
						onChange({ itemType: nextType })
					}}>
					{itemTypes.map((type) => (
						<option key={type} value={type}>
							{itemTypeLabel(type)}
						</option>
					))}
				</select>
			</label>

			{isCloth ? (
				<>
					<div className='admin-field-row'>
						<label className='admin-field'>
							<span className='admin-field-label'>Component</span>
							<select
								value={reward.clothComponent || reward.itemName || ''}
								onChange={(event) => {
									const key = event.target.value
									const next = {
										clothComponent: key,
										itemName: key,
										clothDrawable: Math.max(1, reward.clothDrawable || 1),
										clothTexture: Math.max(1, reward.clothTexture || 1),
										clothSex: (reward.clothSex || '') as '' | 'male' | 'female',
									}
									onChange({
										...next,
										itemLabel: suggestClothLabel(clothingComponents, next),
									})
								}}>
								{clothingComponents.map((item) => (
									<option key={item.key} value={item.key}>
										{item.label} ({item.key})
									</option>
								))}
							</select>
						</label>
						<label className='admin-field'>
							<span className='admin-field-label'>Giới tính</span>
							<select
								value={reward.clothSex || ''}
								onChange={(event) => {
									const clothSex = (event.target.value as '' | 'male' | 'female') || ''
									onChange({
										clothSex,
										itemLabel: suggestClothLabel(clothingComponents, {
											clothComponent: reward.clothComponent,
											itemName: reward.itemName,
											clothDrawable: reward.clothDrawable,
											clothTexture: reward.clothTexture,
											clothSex,
										}),
									})
								}}>
								<option value=''>Theo ped (auto)</option>
								<option value='male'>Nam</option>
								<option value='female'>Nữ</option>
							</select>
						</label>
					</div>
					<div className='admin-field-row admin-field-row-3'>
						<NumberStepper
							label='Drawable'
							value={reward.clothDrawable ?? 1}
							min={1}
							onChange={(clothDrawable) =>
								onChange({
									clothDrawable,
									itemLabel: suggestClothLabel(clothingComponents, {
										clothComponent: reward.clothComponent,
										itemName: reward.itemName,
										clothDrawable,
										clothTexture: reward.clothTexture,
										clothSex: reward.clothSex,
									}),
								})
							}
						/>
						<NumberStepper
							label='Texture'
							value={reward.clothTexture ?? 1}
							min={1}
							onChange={(clothTexture) =>
								onChange({
									clothTexture,
									itemLabel: suggestClothLabel(clothingComponents, {
										clothComponent: reward.clothComponent,
										itemName: reward.itemName,
										clothDrawable: reward.clothDrawable,
										clothTexture,
										clothSex: reward.clothSex,
									}),
								})
							}
						/>
						<NumberStepper
							label='Số lượng'
							value={reward.itemCount}
							min={1}
							onChange={(itemCount) => onChange({ itemCount })}
						/>
					</div>
					<div className='admin-field-row admin-label-row'>
						<label className='admin-field'>
							<span className='admin-field-label'>Tên hiển thị</span>
							<input
								value={reward.itemLabel}
								placeholder={suggestClothLabel(clothingComponents, reward)}
								onChange={(event) => onChange({ itemLabel: event.target.value })}
							/>
						</label>
						<button
							type='button'
							className='tipi-btn-ghost admin-sync-label-btn'
							onClick={() =>
								onChange({
									itemLabel: suggestClothLabel(clothingComponents, {
										clothComponent: reward.clothComponent,
										itemName: reward.itemName,
										clothDrawable: reward.clothDrawable,
										clothTexture: reward.clothTexture,
										clothSex: reward.clothSex,
									}),
								})
							}>
							Đồng bộ tên
						</button>
					</div>
				</>
			) : (
				<div className='admin-field-row admin-field-row-3'>
					{!isMoney ? (
						<label className='admin-field'>
							<span className='admin-field-label'>Item code</span>
							<input
								value={reward.itemName}
								onChange={(event) =>
									onChange({
										itemName: event.target.value,
										itemLabel: reward.itemLabel || event.target.value,
									})
								}
							/>
						</label>
					) : null}
					<label className='admin-field'>
						<span className='admin-field-label'>Label</span>
						<input value={reward.itemLabel} onChange={(event) => onChange({ itemLabel: event.target.value })} />
					</label>
					<NumberStepper
						label={isMoney ? 'Số tiền' : 'Count'}
						value={reward.itemCount}
						min={1}
						onChange={(itemCount) => onChange({ itemCount })}
					/>
				</div>
			)}

			<div className='admin-reward-summary'>{rewardSummary(reward)}</div>
		</div>
	)
}

export default function AdminDailyApp({ initial = null, locales = DEFAULT_LOCALES, onClose }: AdminDailyAppProps) {
	const [visible, setVisible] = useState(Boolean(initial) || isEnvBrowser())
	const [loading, setLoading] = useState(false)
	const [saving, setSaving] = useState(false)
	const [tab, setTab] = useState<'normal' | 'vip' | 'streak' | 'pricing'>('normal')
	const [message, setMessage] = useState('')
	const [monthKey, setMonthKey] = useState(initial?.monthKey ?? '')
	const [daysInMonth, setDaysInMonth] = useState(initial?.daysInMonth ?? 31)
	const [fromSql, setFromSql] = useState(false)
	const [streaksFromSql, setStreaksFromSql] = useState(false)
	const [settingsFromSql, setSettingsFromSql] = useState(false)
	const [normal, setNormal] = useState<AdminDayMap>({})
	const [vip, setVip] = useState<AdminDayMap>({})
	const [streaks, setStreaks] = useState<AdminStreakRow[]>([])
	const [templateNormal, setTemplateNormal] = useState<AdminDayMap>({})
	const [templateVip, setTemplateVip] = useState<AdminDayMap>({})
	const [templateStreaks, setTemplateStreaks] = useState<AdminStreakRow[]>([])
	const [vipPackPrice, setVipPackPrice] = useState(initial?.vipPackPrice ?? 99)
	const [missedDayClaimPrice, setMissedDayClaimPrice] = useState(initial?.missedDayClaimPrice ?? 5000)
	const [missedDayClaimMultiplier, setMissedDayClaimMultiplier] = useState(
		normalizeMissedMultiplier(initial?.missedDayClaimMultiplier ?? 2),
	)
	const [missedDayClaimEnabled, setMissedDayClaimEnabled] = useState(initial?.missedDayClaimEnabled !== false)
	const [maxMissedClaimsPerMonth, setMaxMissedClaimsPerMonth] = useState(initial?.maxMissedClaimsPerMonth ?? 5)
	const [templateVipPackPrice, setTemplateVipPackPrice] = useState(initial?.templateVipPackPrice ?? 99)
	const [templateMissedDayClaimPrice, setTemplateMissedDayClaimPrice] = useState(
		initial?.templateMissedDayClaimPrice ?? 5000,
	)
	const [templateMissedDayClaimMultiplier, setTemplateMissedDayClaimMultiplier] = useState(
		normalizeMissedMultiplier(initial?.templateMissedDayClaimMultiplier ?? 2),
	)
	const [templateMissedDayClaimEnabled, setTemplateMissedDayClaimEnabled] = useState(
		initial?.templateMissedDayClaimEnabled !== false,
	)
	const [templateMaxMissedClaimsPerMonth, setTemplateMaxMissedClaimsPerMonth] = useState(
		initial?.templateMaxMissedClaimsPerMonth ?? 5,
	)
	const [clothingComponents, setClothingComponents] = useState<ClothingComponentOption[]>(
		initial?.clothingComponents?.length ? initial.clothingComponents : FALLBACK_CLOTHES,
	)
	const [selectedDay, setSelectedDay] = useState(1)
	const [selectedStreak, setSelectedStreak] = useState(0)
	const itemTypes = useMemo(() => initial?.itemTypes ?? ['item', 'cash', 'clothing'], [initial?.itemTypes])
	const pricingPreview = useMemo(
		() =>
			missedClaimPricePreview(
				missedDayClaimPrice,
				missedDayClaimMultiplier,
				clampMissedMaxClaims(maxMissedClaimsPerMonth, daysInMonth),
			),
		[missedDayClaimPrice, missedDayClaimMultiplier, maxMissedClaimsPerMonth, daysInMonth],
	)

	const applyPayload = useCallback((payload: AdminPayload) => {
		if (!payload?.monthKey || !payload.daysInMonth) return
		setMonthKey(payload.monthKey)
		setDaysInMonth(payload.daysInMonth)
		setFromSql(Boolean(payload.fromSql))
		setStreaksFromSql(Boolean(payload.streaksFromSql))
		setSettingsFromSql(Boolean(payload.settingsFromSql))
		setNormal(cloneMap(payload.normal, payload.daysInMonth))
		setVip(cloneMap(payload.vip, payload.daysInMonth))
		setStreaks((payload.streaks || []).map((row) => ({ days: row.days, reward: cloneReward(row.reward) })))
		setTemplateNormal(payload.templateNormal || {})
		setTemplateVip(payload.templateVip || {})
		setTemplateStreaks(payload.templateStreaks || [])
		if (typeof payload.vipPackPrice === 'number') setVipPackPrice(payload.vipPackPrice)
		if (typeof payload.missedDayClaimPrice === 'number') setMissedDayClaimPrice(payload.missedDayClaimPrice)
		if (typeof payload.missedDayClaimMultiplier === 'number') {
			setMissedDayClaimMultiplier(normalizeMissedMultiplier(payload.missedDayClaimMultiplier))
		}
		if (payload.missedDayClaimEnabled !== undefined) setMissedDayClaimEnabled(payload.missedDayClaimEnabled !== false)
		if (typeof payload.maxMissedClaimsPerMonth === 'number') {
			setMaxMissedClaimsPerMonth(clampMissedMaxClaims(payload.maxMissedClaimsPerMonth, payload.daysInMonth))
		}
		if (typeof payload.templateVipPackPrice === 'number') setTemplateVipPackPrice(payload.templateVipPackPrice)
		if (typeof payload.templateMissedDayClaimPrice === 'number') {
			setTemplateMissedDayClaimPrice(payload.templateMissedDayClaimPrice)
		}
		if (typeof payload.templateMissedDayClaimMultiplier === 'number') {
			setTemplateMissedDayClaimMultiplier(normalizeMissedMultiplier(payload.templateMissedDayClaimMultiplier))
		}
		if (payload.templateMissedDayClaimEnabled !== undefined) {
			setTemplateMissedDayClaimEnabled(payload.templateMissedDayClaimEnabled !== false)
		}
		if (typeof payload.templateMaxMissedClaimsPerMonth === 'number') {
			setTemplateMaxMissedClaimsPerMonth(payload.templateMaxMissedClaimsPerMonth)
		}
		if (payload.clothingComponents?.length) setClothingComponents(payload.clothingComponents)
	}, [])

	const loadMonth = useCallback(
		async (key?: string) => {
			setLoading(true)
			setMessage('')
			try {
				if (isEnvBrowser()) {
					applyPayload(buildBrowserAdminPayload(key))
					setMessage('Browser mock — chưa gọi SQL')
					return
				}

				const payload = await fetchNui<AdminPayload>('AdminGet', { monthKey: key })
				if (payload?.ok === false) {
					setMessage(payload.error === 'no_permission' ? 'Không có quyền admin' : 'Tải thất bại')
				} else if (payload?.ok && payload.monthKey) {
					applyPayload(payload)
					setMessage(payload.fromSql ? 'Đã tải từ SQL' : 'Đang dùng mẫu config (chưa lưu SQL)')
				} else {
					setMessage('Tải thất bại')
				}
			} catch {
				setMessage('Tải thất bại')
			} finally {
				setLoading(false)
			}
		},
		[applyPayload],
	)

	useEffect(() => {
		if (!initial) return
		applyPayload(initial)
		setAssetConfig({
			clothingImageUrl: (initial as AdminPayload & { clothingImageUrl?: string }).clothingImageUrl,
			clothingImageExt: (initial as AdminPayload & { clothingImageExt?: string }).clothingImageExt,
			clothingComponents: initial.clothingComponents?.length ? initial.clothingComponents : FALLBACK_CLOTHES,
		})
		setVisible(true)
	}, [applyPayload, initial])

	const closeUi = async () => {
		setVisible(false)
		fetchNui('Close').catch(() => {})
		onClose?.()
	}

	const updateDay = (track: 'normal' | 'vip', day: number, patch: Partial<RewardConfig>) => {
		const setter = track === 'normal' ? setNormal : setVip
		setter((prev) => ({
			...prev,
			[String(day)]: { ...cloneReward(prev[String(day)]), ...patch },
		}))
	}

	const saveMonth = async () => {
		setSaving(true)
		setMessage('')
		try {
			const result = await fetchNui<{ ok: boolean; error?: string }>('AdminSaveMonth', {
				monthKey,
				normal,
				vip,
			})
			if (isEnvBrowser() || result?.ok) {
				setFromSql(true)
				setMessage('Đã lưu quà tháng (Thường + VIP) vào SQL')
			} else {
				setMessage(result?.error || 'Lưu thất bại')
			}
		} catch {
			setMessage('Lưu thất bại')
		} finally {
			setSaving(false)
		}
	}

	const saveStreaks = async () => {
		setSaving(true)
		setMessage('')
		try {
			const result = await fetchNui<{ ok: boolean; error?: string }>('AdminSaveStreaks', {
				milestones: streaks,
			})
			if (isEnvBrowser() || result?.ok) {
				setStreaksFromSql(true)
				setMessage('Đã lưu mốc chuỗi vào SQL')
			} else {
				setMessage(result?.error || 'Lưu thất bại')
			}
		} catch {
			setMessage('Lưu thất bại')
		} finally {
			setSaving(false)
		}
	}

	const saveSettings = async () => {
		setSaving(true)
		setMessage('')
		try {
			const result = await fetchNui<{
				ok: boolean
				error?: string
				vipPackPrice?: number
				missedDayClaimPrice?: number
				missedDayClaimMultiplier?: number
				missedDayClaimEnabled?: boolean
				maxMissedClaimsPerMonth?: number
			}>('AdminSaveSettings', {
				vipPackPrice,
				missedDayClaimPrice,
				missedDayClaimMultiplier,
				missedDayClaimEnabled,
				maxMissedClaimsPerMonth: clampMissedMaxClaims(maxMissedClaimsPerMonth, daysInMonth),
			})
			if (isEnvBrowser() || result?.ok) {
				setSettingsFromSql(true)
				if (typeof result?.vipPackPrice === 'number') setVipPackPrice(result.vipPackPrice)
				if (typeof result?.missedDayClaimPrice === 'number') setMissedDayClaimPrice(result.missedDayClaimPrice)
				if (typeof result?.missedDayClaimMultiplier === 'number') {
					setMissedDayClaimMultiplier(normalizeMissedMultiplier(result.missedDayClaimMultiplier))
				}
				if (result?.missedDayClaimEnabled !== undefined) {
					setMissedDayClaimEnabled(result.missedDayClaimEnabled !== false)
				}
				if (typeof result?.maxMissedClaimsPerMonth === 'number') {
					setMaxMissedClaimsPerMonth(clampMissedMaxClaims(result.maxMissedClaimsPerMonth, daysInMonth))
				}
				setMessage('Đã lưu cấu hình VIP / bù ngày vào SQL')
			} else {
				setMessage(result?.error || 'Lưu thất bại')
			}
		} catch {
			setMessage('Lưu thất bại')
		} finally {
			setSaving(false)
		}
	}

	const loadTemplate = () => {
		if (tab === 'pricing') {
			setVipPackPrice(templateVipPackPrice)
			setMissedDayClaimPrice(templateMissedDayClaimPrice)
			setMissedDayClaimMultiplier(templateMissedDayClaimMultiplier)
			setMissedDayClaimEnabled(templateMissedDayClaimEnabled)
			setMaxMissedClaimsPerMonth(templateMaxMissedClaimsPerMonth)
			setMessage('Đã tải cấu hình mặc định từ config')
			return
		}
		if (tab === 'streak') {
			setStreaks((templateStreaks || []).map((row) => ({ days: row.days, reward: cloneReward(row.reward) })))
			setMessage('Đã tải chuỗi mặc định từ config')
			return
		}
		if (tab === 'normal') {
			setNormal(cloneMap(templateNormal, daysInMonth))
			setMessage('Đã tải quà thường mặc định từ config')
			return
		}
		setVip(cloneMap(templateVip, daysInMonth))
		setMessage('Đã tải quà VIP mặc định từ config')
	}

	if (!visible) return null

	const activeMap = tab === 'vip' ? vip : normal
	const sourceLabel =
		tab === 'pricing'
			? settingsFromSql
				? 'SQL'
				: 'Config template'
			: tab === 'streak'
				? streaksFromSql
					? 'SQL'
					: 'Config template'
				: fromSql
					? 'SQL'
					: 'Config template'
	const safeDay = Math.min(Math.max(1, selectedDay), daysInMonth || 1)
	const editingReward = activeMap[String(safeDay)] || emptyReward()
	const safeStreakIndex = Math.min(Math.max(0, selectedStreak), Math.max(0, streaks.length - 1))
	const editingStreak = streaks[safeStreakIndex]

	return (
		<div className='admin-daily-overlay'>
			<div className='admin-daily-panel'>
				<header className='admin-daily-header'>
					<div>
						<h1 className='tipi-title'>ADMIN DAILY</h1>
						<p className='admin-daily-sub'>
							{monthKey} · {sourceLabel} · {daysInMonth} ngày · item / tiền / quần áo
						</p>
					</div>
					<button type='button' className='tipi-btn-ghost' onClick={() => void closeUi()}>
						{locales.Close ?? 'Đóng'}
					</button>
				</header>

				<div className='admin-daily-toolbar'>
					<div className='admin-daily-toolbar-row'>
						<div className='admin-daily-month-nav'>
							<button type='button' className='tipi-btn-ghost' disabled={loading} onClick={() => void loadMonth(shiftMonth(monthKey, -1))}>
								←
							</button>
							<span className='admin-month-label'>{monthKey || '----/--'}</span>
							<button type='button' className='tipi-btn-ghost' disabled={loading} onClick={() => void loadMonth(shiftMonth(monthKey, 1))}>
								→
							</button>
							<button type='button' className='tipi-btn-cyan' disabled={loading} onClick={() => void loadMonth(monthKey)}>
								{loading ? '...' : 'Reload'}
							</button>
						</div>

						<div className='admin-daily-actions'>
							<button type='button' className='tipi-btn-ghost' onClick={loadTemplate}>
								Tải dữ liệu mặc định
							</button>
							<button
								type='button'
								className='tipi-btn-cyan'
								disabled={saving}
								onClick={() => {
									if (tab === 'streak') void saveStreaks()
									else if (tab === 'pricing') void saveSettings()
									else void saveMonth()
								}}>
								Lưu
							</button>
						</div>
					</div>

					<div className='admin-daily-toolbar-row admin-daily-toolbar-tabs'>
						<div className='dr-track-tabs'>
							<button
								type='button'
								className={`dr-track-tab${tab === 'normal' ? ' dr-track-tab-active' : ''}`}
								onClick={() => {
									setTab('normal')
									setSelectedDay(1)
								}}>
								Thường
							</button>
							<button
								type='button'
								className={`dr-track-tab${tab === 'vip' ? ' dr-track-tab-active' : ''}`}
								onClick={() => {
									setTab('vip')
									setSelectedDay(1)
								}}>
								VIP
							</button>
							<button
								type='button'
								className={`dr-track-tab${tab === 'streak' ? ' dr-track-tab-active' : ''}`}
								onClick={() => {
									setTab('streak')
									setSelectedStreak(0)
								}}>
								Chuỗi
							</button>
							<button
								type='button'
								className={`dr-track-tab${tab === 'pricing' ? ' dr-track-tab-active' : ''}`}
								onClick={() => setTab('pricing')}>
								Giá
							</button>
						</div>
					</div>
				</div>

				{message ? <p className='admin-daily-message'>{message}</p> : null}

				<div className='admin-daily-workspace'>
					{tab === 'pricing' ? (
						<section className='admin-day-editor admin-pricing-editor'>
							<div className='admin-day-editor-head'>
								<h2>Giá hệ thống</h2>
								<span className='admin-day-badge'>{settingsFromSql ? 'SQL' : 'Config'}</span>
							</div>
							<div className='admin-pricing-grid'>
								<NumberStepper
									label='Giá gói VIP (coin)'
									value={vipPackPrice}
									min={0}
									onChange={setVipPackPrice}
								/>
								<NumberStepper
									label='Giá bù lần đầu ($)'
									value={missedDayClaimPrice}
									min={0}
									onChange={setMissedDayClaimPrice}
								/>
								<NumberStepper
									label='Hệ số tăng mỗi lần'
									value={missedDayClaimMultiplier}
									min={1}
									step={0.1}
									allowFloat
									onChange={(value) => setMissedDayClaimMultiplier(normalizeMissedMultiplier(value))}
								/>
								<NumberStepper
									label={`Giới hạn bù (tối đa ${daysInMonth})`}
									value={maxMissedClaimsPerMonth}
									min={0}
									max={daysInMonth}
									onChange={(value) => setMaxMissedClaimsPerMonth(clampMissedMaxClaims(value, daysInMonth))}
								/>
							</div>
							<label className='admin-pricing-toggle'>
								<input
									type='checkbox'
									checked={missedDayClaimEnabled}
									onChange={(event) => setMissedDayClaimEnabled(event.target.checked)}
								/>
								<span>Bật nhận bù ngày bằng tiền</span>
							</label>
							<div className='admin-reward-summary'>
								VIP: {vipPackPrice} coin · Bù:{' '}
								{missedDayClaimEnabled
									? `${missedDayClaimPrice}$ +${Math.round((missedDayClaimMultiplier - 1) * 100)}% gốc/lần (tối đa ${maxMissedClaimsPerMonth}/${daysInMonth})`
									: 'tắt'}
							</div>
							{missedDayClaimEnabled && pricingPreview.length > 0 ? (
								<div className='admin-pricing-preview'>
									<div className='admin-pricing-preview-head'>
										<strong>Mẫu giá sau khi chỉnh</strong>
										<span>
											{missedDayClaimPrice}$ × (1 + ({missedDayClaimMultiplier}−1)×(n−1))
										</span>
									</div>
									<div className='admin-pricing-preview-table'>
										{pricingPreview.map((row) => (
											<div key={`missed-price-${row.claim}`} className='admin-pricing-preview-row'>
												<span>Lần {row.claim}</span>
												<strong>{row.price.toLocaleString('vi-VN')}$</strong>
											</div>
										))}
									</div>
								</div>
							) : null}
						</section>
					) : tab !== 'streak' ? (
						<>
							<aside className='admin-day-list tipi-scroll'>
								{Array.from({ length: daysInMonth }, (_, index) => {
									const day = index + 1
									const reward = activeMap[String(day)] || emptyReward()
									const active = day === safeDay
									return (
										<button
											key={`${tab}-list-${day}`}
											type='button'
											className={`admin-day-list-item${active ? ' is-active' : ''}${
												reward.itemType === 'clothing' ? ' is-cloth' : ''
											}`}
											onClick={() => setSelectedDay(day)}>
											<span className='admin-day-list-num'>Ngày {day}</span>
											<span className='admin-day-list-type'>{itemTypeLabel(reward.itemType)}</span>
											<span className='admin-day-list-summary'>{rewardSummary(reward)}</span>
										</button>
									)
								})}
							</aside>

							<section className={`admin-day-editor${editingReward.itemType === 'clothing' ? ' is-cloth' : ''}`}>
								<div className='admin-day-editor-head'>
									<h2>Chỉnh ngày {safeDay}</h2>
									<span className='admin-day-badge'>{itemTypeLabel(editingReward.itemType)}</span>
								</div>
								<div className='admin-reward-preview'>
									<ItemImage
										itemName={editingReward.itemName || editingReward.clothComponent || 'common'}
										alt={editingReward.itemLabel || 'Quà'}
										className='admin-reward-preview-img'
										mystery={false}
										itemType={editingReward.itemType}
										clothComponent={editingReward.clothComponent}
										clothDrawable={editingReward.clothDrawable}
										clothSex={editingReward.clothSex}
									/>
									<div className='admin-reward-preview-meta'>
										<strong>{editingReward.itemLabel || editingReward.itemName || '—'}</strong>
										<span>{rewardSummary(editingReward)}</span>
									</div>
								</div>
								<RewardEditor
									reward={editingReward}
									itemTypes={itemTypes}
									clothingComponents={clothingComponents}
									onChange={(patch) => updateDay(tab, safeDay, patch)}
								/>
							</section>
						</>
					) : (
						<>
							<aside className='admin-day-list tipi-scroll'>
								{streaks.map((row, index) => (
									<button
										key={`streak-list-${index}`}
										type='button'
										className={`admin-day-list-item${index === safeStreakIndex ? ' is-active' : ''}${
											row.reward.itemType === 'clothing' ? ' is-cloth' : ''
										}`}
										onClick={() => setSelectedStreak(index)}>
										<span className='admin-day-list-num'>Mốc {row.days} ngày</span>
										<span className='admin-day-list-type'>{itemTypeLabel(row.reward.itemType)}</span>
										<span className='admin-day-list-summary'>{rewardSummary(row.reward)}</span>
									</button>
								))}
								<button
									type='button'
									className='tipi-btn-cyan admin-add-streak-btn'
									onClick={() => {
										setStreaks((prev) => [...prev, { days: 1, reward: emptyReward() }])
										setSelectedStreak(streaks.length)
									}}>
									+ Thêm mốc chuỗi
								</button>
							</aside>

							<section className='admin-day-editor'>
								{editingStreak ? (
									<>
										<div className='admin-day-editor-head'>
											<NumberStepper
												label='Số ngày chuỗi'
												className='admin-streak-days-field'
												value={editingStreak.days}
												min={1}
												onChange={(days) => {
													setStreaks((prev) =>
														prev.map((item, i) => (i === safeStreakIndex ? { ...item, days } : item)),
													)
												}}
											/>
											<button
												type='button'
												className='tipi-btn-ghost'
												onClick={() => {
													setStreaks((prev) => prev.filter((_, i) => i !== safeStreakIndex))
													setSelectedStreak(0)
												}}>
												Xóa mốc
											</button>
										</div>
										<div className='admin-reward-preview'>
											<ItemImage
												itemName={editingStreak.reward.itemName || editingStreak.reward.clothComponent || 'common'}
												alt={editingStreak.reward.itemLabel || 'Quà'}
												className='admin-reward-preview-img'
												mystery={false}
												itemType={editingStreak.reward.itemType}
												clothComponent={editingStreak.reward.clothComponent}
												clothDrawable={editingStreak.reward.clothDrawable}
												clothSex={editingStreak.reward.clothSex}
											/>
											<div className='admin-reward-preview-meta'>
												<strong>{editingStreak.reward.itemLabel || editingStreak.reward.itemName || '—'}</strong>
												<span>{rewardSummary(editingStreak.reward)}</span>
											</div>
										</div>
										<RewardEditor
											reward={editingStreak.reward}
											itemTypes={itemTypes}
											clothingComponents={clothingComponents}
											onChange={(patch) =>
												setStreaks((prev) =>
													prev.map((item, i) =>
														i === safeStreakIndex
															? { ...item, reward: { ...cloneReward(item.reward), ...patch } }
															: item,
													),
												)
											}
										/>
									</>
								) : (
									<p className='admin-empty-hint'>Chưa có mốc chuỗi. Bấm “Thêm mốc chuỗi”.</p>
								)}
							</section>
						</>
					)}
				</div>
			</div>
		</div>
	)
}

export function applyAdminAssets(message: {
	mysteryImageUrl?: string
	inventoryImageTemplate?: string
	inventoryImageCdn?: string
	itemImageResourceTemplate?: string
	clothingImageUrl?: string
	clothingImageExt?: string
	clothingComponents?: ClothingComponentOption[]
}) {
	setAssetConfig({
		mysteryImageUrl: message.mysteryImageUrl,
		inventoryImageTemplate: message.inventoryImageTemplate,
		inventoryImageCdn: message.inventoryImageCdn,
		itemImageResourceTemplate: message.itemImageResourceTemplate,
		clothingImageUrl: message.clothingImageUrl,
		clothingImageExt: message.clothingImageExt,
		clothingComponents: message.clothingComponents,
	})
}
