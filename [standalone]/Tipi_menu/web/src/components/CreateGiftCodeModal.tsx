import { Box, Text } from 'lr-components'
import React, { useEffect, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import styled from 'styled-components'
import { motion, AnimatePresence } from 'framer-motion'
import Button from './Button'
import NumberStepper, { NUMBER_STEPPER_HEIGHT } from './NumberStepper'
import { menuCardBase } from '../styles/menuCardStyles'
import { AppDispatch, RootState } from '../store'
import { setGiftCodeAdmin } from '../store/main'
import { fetchNui } from '../utils/fetchNui'
import { useLocale } from '../hooks/useLocale'
import { XN_CLOTHING_COMPONENTS } from '../constants/clothingComponents'
import {
	ClothingComponentOption,
	GiftBundleItem,
	GiftCodeCreatePayload,
	GiftCodeCreateResult,
	GiftClothingComponentsResult,
	GiftCreateMode,
	GiftRewardType,
} from '../types/giftCodeAdmin'
import { isEnvBrowser } from '../utils/misc'

const Overlay = styled(motion.div)`
	position: fixed;
	inset: 0;
	z-index: 13000;
	display: flex;
	align-items: center;
	justify-content: center;
	background: rgba(0, 6, 14, 0.82);
	padding: 24px;
	box-sizing: border-box;
`

const Panel = styled(Box)`
	${menuCardBase}
	width: min(640px, 94vw);
	max-height: min(88vh, 760px);
	display: flex;
	flex-direction: column;
	overflow: hidden;
	border-color: var(--border);
`

const Header = styled(Box)`
	padding: 12px 16px 10px;
	border-bottom: 1px solid var(--border-dim);
	flex-shrink: 0;
`

const Tabs = styled(Box)`
	display: grid;
	grid-template-columns: repeat(3, minmax(0, 1fr));
	gap: 6px;
	padding: 10px 16px;
	border-bottom: 1px solid var(--border-dim);
	flex-shrink: 0;
`

const Tab = styled.button<{ $active?: boolean }>`
	width: 100%;
	min-width: 0;
	border: 1px solid ${(p) => (p.$active ? 'var(--border)' : 'var(--border-dim)')};
	background: ${(p) => (p.$active ? 'rgba(0, 229, 255, 0.12)' : 'rgba(0, 18, 32, 0.72)')};
	color: ${(p) => (p.$active ? 'var(--cyan)' : 'var(--text-sub)')};
	padding: 8px 6px;
	border-radius: 4px;
	cursor: pointer;
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 11px;
	text-transform: uppercase;
	letter-spacing: 0.04em;
	text-align: center;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
`

const ScrollBody = styled(Box)`
	flex: 1;
	min-height: 0;
	overflow-y: auto;
	overflow-x: hidden;
	padding: 12px 16px;
	display: flex;
	flex-direction: column;
	gap: 8px;
	scrollbar-width: none;
	-ms-overflow-style: none;

	&::-webkit-scrollbar {
		display: none;
	}
`

const FormSection = styled(Box)`
	display: flex;
	flex-direction: column;
	gap: 10px;
	min-height: 280px;
`

const FormRow = styled(Box)<{ $cols: string }>`
	display: grid;
	grid-template-columns: ${(p) => p.$cols};
	gap: 8px;
	align-items: end;
`

const Field = styled(Box)`
	display: flex;
	flex-direction: column;
	gap: 4px;
	flex-shrink: 0;
	min-width: 0;
`

const FieldLabel = styled(Text)`
	text-transform: uppercase;
	color: var(--text-sub);
`

const Input = styled.input`
	width: 100%;
	min-height: ${NUMBER_STEPPER_HEIGHT}px;
	padding: 10px 12px;
	box-sizing: border-box;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 18, 32, 0.88);
	color: #fff;
	font-family: 'Montserrat', sans-serif;
	font-size: 13px;
	outline: none;

	&:focus {
		border-color: var(--border);
	}
`

const Select = styled.select`
	width: 100%;
	min-height: ${NUMBER_STEPPER_HEIGHT}px;
	padding: 10px 12px;
	box-sizing: border-box;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 18, 32, 0.88);
	color: #fff;
	font-family: 'Montserrat', sans-serif;
	font-size: 13px;
	outline: none;
	cursor: pointer;

	&:focus {
		border-color: var(--border);
	}
`

const Hint = styled(Text)`
	color: var(--text-sub);
	line-height: 1.35;
`

const CheckRow = styled.label`
	display: flex;
	align-items: center;
	gap: 8px;
	color: var(--text-sub);
	font-family: 'Montserrat', sans-serif;
	font-size: 12px;
	cursor: pointer;
	flex-shrink: 0;
`

const FormFootnote = styled(Text)`
	color: var(--text-sub);
	line-height: 1.35;
	padding-top: 2px;
`

const BundleList = styled(Box)`
	display: flex;
	flex-direction: column;
	gap: 10px;
	max-height: 320px;
	overflow-y: auto;
	overflow-x: hidden;
	padding-right: 2px;
	scrollbar-width: thin;
	scrollbar-color: rgba(0, 229, 255, 0.35) transparent;

	&::-webkit-scrollbar {
		width: 4px;
	}

	&::-webkit-scrollbar-thumb {
		background: rgba(0, 229, 255, 0.35);
		border-radius: 4px;
	}
`

const BundleItemCard = styled(Box)`
	display: flex;
	flex-direction: column;
	gap: 8px;
	padding: 10px;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 18, 32, 0.55);
	flex-shrink: 0;
`

const BundleTopRow = styled(Box)`
	display: grid;
	grid-template-columns: 96px 1fr 40px;
	gap: 8px;
	align-items: center;
`

const BundleItemRow = styled(Box)`
	display: grid;
	grid-template-columns: 96px 1fr 112px 40px;
	gap: 8px;
	align-items: center;
`

const BundleClothingRow = styled(Box)`
	display: grid;
	grid-template-columns: 1fr 1fr 1fr;
	gap: 8px;
	align-items: end;
`

const DEFAULT_BUNDLE: GiftBundleItem[] = [{ type: 'item', name: '', count: 1 }]

const RemoveBtn = styled.button`
	width: 40px;
	height: ${NUMBER_STEPPER_HEIGHT}px;
	padding: 0;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 18, 32, 0.72);
	color: var(--text-sub);
	font-family: 'Oswald', sans-serif;
	font-size: 18px;
	line-height: 1;
	display: flex;
	align-items: center;
	justify-content: center;
	flex-shrink: 0;
	cursor: pointer;

	&:hover {
		border-color: rgba(255, 61, 87, 0.55);
		color: #ff8a98;
		background: rgba(255, 61, 87, 0.1);
	}
`

const AddItemBtn = styled.button`
	height: ${NUMBER_STEPPER_HEIGHT}px;
	padding: 0 14px;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 18, 32, 0.72);
	color: var(--text-sub);
	font-family: 'Oswald', sans-serif;
	font-size: 11px;
	text-transform: uppercase;
	cursor: pointer;
	align-self: flex-start;

	&:hover {
		border-color: var(--border);
		color: var(--cyan);
	}
`

const Footer = styled(Box)`
	display: flex;
	justify-content: flex-end;
	gap: 10px;
	padding: 14px 16px;
	flex-shrink: 0;
	border-top: 1px solid var(--border-dim);
`

const FooterBtn = styled.button<{ $variant?: 'gray' | 'cyan' }>`
	min-width: 110px;
	height: 34px;
	padding: 0 14px;
	border-radius: 4px;
	border: 1px solid
		${(p) => (p.$variant === 'cyan' ? 'rgba(0, 229, 255, 0.45)' : 'rgba(255, 255, 255, 0.22)')};
	background: ${(p) =>
		p.$variant === 'cyan' ? 'rgba(0, 229, 255, 0.1)' : 'rgba(255, 255, 255, 0.06)'};
	color: ${(p) => (p.$variant === 'cyan' ? 'var(--cyan)' : 'rgba(220, 230, 240, 0.88)')};
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 12px;
	font-weight: 600;
	text-transform: uppercase;
	letter-spacing: 0.05em;
	cursor: pointer;

	&:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}
`

const SuccessBox = styled(Box)`
	padding: 16px;
	border-radius: 6px;
	border: 1px solid rgba(0, 229, 255, 0.35);
	background: rgba(0, 229, 255, 0.08);
	display: flex;
	flex-direction: column;
	gap: 8px;
	align-items: center;
	text-align: center;
`

const CodeDisplay = styled(Text)`
	font-family: 'Montserrat', monospace;
	font-size: 18px;
	font-weight: 700;
	color: var(--cyan);
	letter-spacing: 0.08em;
	word-break: break-all;
`

function buildAnnounceFields(
	form: ReturnType<typeof emptyForm>,
	setError: (msg: string) => void,
	L: (key: string) => string,
): Pick<GiftCodeCreatePayload, 'announceToPlayers' | 'announceTitle'> | null {
	if (!form.announceEnabled) return {}
	const title = form.announceTitle.trim()
	if (!title) {
		setError(L('ui.giftcode_admin.err_announce_title'))
		return null
	}
	return { announceToPlayers: true, announceTitle: title }
}

function emptyForm() {
	return {
		mode: 'random' as GiftCreateMode,
		code: '',
		type: 'item' as GiftRewardType,
		name: '',
		count: 1,
		component: '',
		maleDrawable: 0,
		femaleDrawable: 0,
		texture: 1,
		autoGender: true,
		items: [...DEFAULT_BUNDLE.map((i) => ({ ...i }))],
		remaining: 1,
		minLevel: 0,
		expireHours: 0,
		announceEnabled: false,
		announceTitle: '',
	}
}

function validateClothingFields(
	form: ReturnType<typeof emptyForm>,
	setError: (msg: string) => void,
	L: (key: string) => string,
): Pick<
	GiftCodeCreatePayload,
	'component' | 'maleDrawable' | 'femaleDrawable' | 'texture' | 'autoGender'
> | null {
	const component = form.component.trim()
	if (!component) {
		setError(L('ui.giftcode_admin.err_clothing_component'))
		return null
	}
	const maleDrawable = Number(form.maleDrawable)
	const femaleDrawable = Number(form.femaleDrawable)
	if (
		Number.isNaN(maleDrawable) ||
		Number.isNaN(femaleDrawable) ||
		maleDrawable < 0 ||
		femaleDrawable < 0
	) {
		setError(L('ui.giftcode_admin.err_clothing_drawable'))
		return null
	}
	return {
		component,
		maleDrawable: Math.floor(maleDrawable),
		femaleDrawable: Math.floor(femaleDrawable),
		texture: (() => {
			const raw = Number(form.texture)
			return Number.isNaN(raw) ? 1 : Math.max(0, Math.floor(raw))
		})(),
		autoGender: form.autoGender,
	}
}

export default function CreateGiftCodeModal() {
	const L = useLocale()
	const dispatch = useDispatch<AppDispatch>()
	const admin = useSelector((state: RootState) => state.main.giftCodeAdmin)
	const menuOpen = useSelector((state: RootState) => state.main.show)
	const [form, setForm] = useState(emptyForm)
	const [creating, setCreating] = useState(false)
	const [createdCode, setCreatedCode] = useState<string | null>(null)
	const [error, setError] = useState('')
	const [clothingComponents, setClothingComponents] = useState<ClothingComponentOption[]>([])
	const [clothingLoading, setClothingLoading] = useState(false)

	const loadClothingComponents = async () => {
		setClothingLoading(true)
		try {
			if (isEnvBrowser()) {
				setClothingComponents(XN_CLOTHING_COMPONENTS)
				return
			}
			const result = await fetchNui<GiftClothingComponentsResult>('giftCode:getClothingComponents')
			if (result?.status && Array.isArray(result.components) && result.components.length > 0) {
				setClothingComponents(result.components)
			} else {
				setClothingComponents(XN_CLOTHING_COMPONENTS)
			}
		} finally {
			setClothingLoading(false)
		}
	}

	useEffect(() => {
		if (admin.open) {
			setForm(emptyForm())
			setCreatedCode(null)
			setError('')
			loadClothingComponents()
		}
	}, [admin.open])

	const close = () => {
		if (isEnvBrowser()) {
			dispatch(setGiftCodeAdmin({ open: false }))
			return
		}
		fetchNui('giftCode:closeAdmin', { menuOpen })
	}

	const setMode = (mode: GiftCreateMode) => {
		setForm((prev) => ({ ...prev, mode }))
		setError('')
		setCreatedCode(null)
	}

	const updateBundleItem = (index: number, patch: Partial<GiftBundleItem>) => {
		setForm((prev) => ({
			...prev,
			items: prev.items.map((item, i) => (i === index ? { ...item, ...patch } : item)),
		}))
	}

	const addBundleItem = () => {
		setForm((prev) => ({
			...prev,
			items: [...prev.items, { type: 'item', name: '', count: 1 }],
		}))
	}

	const removeBundleItem = (index: number) => {
		setForm((prev) => {
			if (prev.items.length <= 1) return prev
			return { ...prev, items: prev.items.filter((_, i) => i !== index) }
		})
	}

	const buildPayload = (): GiftCodeCreatePayload | null => {
		const code = form.code.trim()
		const name = form.name.trim()
		const remaining = Number(form.remaining)
		const minLevel = Number(form.minLevel)
		const expireHours = Number(form.expireHours)

		if (Number.isNaN(remaining) || (remaining < 1 && remaining !== -1)) {
			setError(L('ui.giftcode_admin.err_remaining'))
			return null
		}
		if (Number.isNaN(minLevel) || minLevel < 0) {
			setError(L('ui.giftcode_admin.err_min_level'))
			return null
		}
		if (Number.isNaN(expireHours) || expireHours < 0) {
			setError(L('ui.giftcode_admin.err_expire'))
			return null
		}

		const announceFields = buildAnnounceFields(form, setError, L)
		if (!announceFields) return null

		if (form.mode === 'random') {
			if (form.type === 'clothing') {
				const clothingFields = validateClothingFields(form, setError, L)
				if (!clothingFields) return null
				return {
					mode: 'random',
					type: 'clothing',
					remaining,
					minLevel,
					expireHours,
					...clothingFields,
					...announceFields,
				}
			}
			if (!name) {
				setError(L('ui.giftcode_admin.err_name'))
				return null
			}
			return {
				mode: 'random',
				type: form.type,
				name,
				count: form.type === 'vehicle' ? 1 : Math.max(1, Number(form.count) || 1),
				remaining,
				minLevel,
				expireHours,
				...announceFields,
			}
		}

		if (!code) {
			setError(L('ui.giftcode_admin.err_code'))
			return null
		}

		if (form.mode === 'bundle') {
			const items: GiftBundleItem[] = []
			for (const item of form.items) {
				if (item.type === 'clothing') {
					const component = (item.component || item.name || '').trim()
					const maleDrawable = Number(item.maleDrawable)
					const femaleDrawable = Number(item.femaleDrawable)
					if (
						!component ||
						Number.isNaN(maleDrawable) ||
						Number.isNaN(femaleDrawable) ||
						maleDrawable < 0 ||
						femaleDrawable < 0
					) {
						continue
					}
					items.push({
						type: 'clothing',
						component,
						name: component,
						count: 1,
						maleDrawable: Math.floor(maleDrawable),
						femaleDrawable: Math.floor(femaleDrawable),
						texture: (() => {
							const raw = Number(item.texture)
							return Number.isNaN(raw) ? 1 : Math.max(0, Math.floor(raw))
						})(),
						autoGender: item.autoGender !== false,
					})
					continue
				}
				const itemName = item.name.trim()
				const count = Math.max(1, Number(item.count) || 1)
				if (!itemName) continue
				items.push({ type: 'item', name: itemName, count })
			}
			if (items.length < 1) {
				setError(L('ui.giftcode_admin.err_bundle'))
				return null
			}
			return {
				mode: 'bundle',
				code,
				items,
				remaining,
				minLevel,
				expireHours,
				...announceFields,
			}
		}

		if (form.type === 'clothing') {
			const clothingFields = validateClothingFields(form, setError, L)
			if (!clothingFields) return null
			return {
				mode: 'fixed',
				code,
				type: 'clothing',
				remaining,
				minLevel,
				expireHours,
				...clothingFields,
				...announceFields,
			}
		}

		if (!name) {
			setError(L('ui.giftcode_admin.err_name'))
			return null
		}
		return {
			mode: 'fixed',
			code,
			type: form.type,
			name,
			count: form.type === 'vehicle' ? 1 : Math.max(1, Number(form.count) || 1),
			remaining,
			minLevel,
			expireHours,
			...announceFields,
		}
	}

	const submit = async () => {
		if (creating) return
		setError('')
		const payload = buildPayload()
		if (!payload) return

		setCreating(true)
		try {
			if (isEnvBrowser()) {
				setCreatedCode(payload.code ?? 'DEMO-RANDOM-CODE-1234')
				return
			}
			const result = await fetchNui<GiftCodeCreateResult>('giftCode:create', payload)
			if (result?.status) {
				setCreatedCode(result.data?.code ?? payload.code ?? '')
			} else {
				setError(result?.message || L('ui.giftcode_admin.err_unknown'))
			}
		} finally {
			setCreating(false)
		}
	}

	const showCount = form.mode !== 'bundle' && form.type === 'item'
	const showClothing = form.mode !== 'bundle' && form.type === 'clothing'

	const rewardLabel =
		form.type === 'vehicle'
			? L('ui.giftcode_admin.vehicle_model')
			: form.type === 'clothing'
				? L('ui.giftcode_admin.clothing_component')
				: L('ui.giftcode_admin.item_name')
	const rewardPlaceholder =
		form.type === 'vehicle'
			? L('ui.giftcode_admin.vehicle_placeholder')
			: L('ui.giftcode_admin.item_placeholder')

	const renderClothingFields = () => (
		<>
			<Field>
				<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.clothing_component')}</FieldLabel>
				<Select
					value={form.component}
					onChange={(e) => setForm((p) => ({ ...p, component: e.target.value }))}>
					<option value=''>{L('ui.giftcode_admin.clothing_component_placeholder')}</option>
					{clothingComponents.map((component) => (
						<option key={component.key} value={component.key}>
							{component.label}
						</option>
					))}
				</Select>
				{clothingLoading && (
					<Hint rFontSize={10}>{L('ui.giftcode_admin.clothing_loading')}</Hint>
				)}
				{!clothingLoading && clothingComponents.length === 0 && (
					<Hint rFontSize={10}>{L('ui.giftcode_admin.clothing_unavailable')}</Hint>
				)}
			</Field>
			<FormRow $cols='1fr 1fr 1fr'>
				<Field>
					<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.clothing_male_drawable')}</FieldLabel>
					<NumberStepper
						value={form.maleDrawable}
						min={0}
						onChange={(maleDrawable) => setForm((p) => ({ ...p, maleDrawable }))}
					/>
				</Field>
				<Field>
					<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.clothing_female_drawable')}</FieldLabel>
					<NumberStepper
						value={form.femaleDrawable}
						min={0}
						onChange={(femaleDrawable) => setForm((p) => ({ ...p, femaleDrawable }))}
					/>
				</Field>
				<Field>
					<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.clothing_texture')}</FieldLabel>
					<NumberStepper
						value={form.texture}
						min={0}
						onChange={(texture) => setForm((p) => ({ ...p, texture }))}
					/>
				</Field>
			</FormRow>
			<CheckRow>
				<input
					type='checkbox'
					checked={form.autoGender}
					onChange={(e) => setForm((p) => ({ ...p, autoGender: e.target.checked }))}
				/>
				{L('ui.giftcode_admin.clothing_auto_gender')}
			</CheckRow>
			{!form.autoGender && (
				<Hint rFontSize={10}>{L('ui.giftcode_admin.clothing_auto_gender_hint')}</Hint>
			)}
		</>
	)

	const renderTypeSelect = (index: number, item: GiftBundleItem) => (
		<Select
			value={item.type || 'item'}
			onChange={(e) => {
				const nextType = e.target.value as GiftBundleItem['type']
				if (nextType === 'clothing') {
					updateBundleItem(index, {
						type: 'clothing',
						name: '',
						component: clothingComponents[0]?.key || '',
						count: 1,
						maleDrawable: 0,
						femaleDrawable: 0,
						texture: 1,
						autoGender: true,
					})
					return
				}
				updateBundleItem(index, {
					type: 'item',
					name: '',
					count: 1,
				})
			}}>
			<option value='item'>{L('ui.giftcode_admin.bundle_type_item')}</option>
			<option value='clothing'>{L('ui.giftcode_admin.bundle_type_clothing')}</option>
		</Select>
	)

	const renderBundleItem = (item: GiftBundleItem, index: number) => {
		if (item.type === 'clothing') {
			return (
				<BundleItemCard key={`bundle-${index}`}>
					<BundleTopRow>
						{renderTypeSelect(index, item)}
						<Select
							value={item.component || item.name}
							onChange={(e) =>
								updateBundleItem(index, {
									component: e.target.value,
									name: e.target.value,
								})
							}>
							<option value=''>{L('ui.giftcode_admin.clothing_component_placeholder')}</option>
							{clothingComponents.map((component) => (
								<option key={component.key} value={component.key}>
									{component.label}
								</option>
							))}
						</Select>
						<RemoveBtn type='button' onClick={() => removeBundleItem(index)}>
							×
						</RemoveBtn>
					</BundleTopRow>
					<BundleClothingRow>
						<Field>
							<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.clothing_male_short')}</FieldLabel>
							<NumberStepper
								compact
								value={item.maleDrawable ?? 0}
								min={0}
								onChange={(maleDrawable) => updateBundleItem(index, { maleDrawable })}
							/>
						</Field>
						<Field>
							<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.clothing_female_short')}</FieldLabel>
							<NumberStepper
								compact
								value={item.femaleDrawable ?? 0}
								min={0}
								onChange={(femaleDrawable) => updateBundleItem(index, { femaleDrawable })}
							/>
						</Field>
						<Field>
							<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.clothing_texture')}</FieldLabel>
							<NumberStepper
								compact
								value={item.texture ?? 1}
								min={0}
								onChange={(texture) => updateBundleItem(index, { texture })}
							/>
						</Field>
					</BundleClothingRow>
				</BundleItemCard>
			)
		}

		return (
			<BundleItemCard key={`bundle-${index}`}>
				<BundleItemRow>
					{renderTypeSelect(index, item)}
					<Input
						value={item.name}
						onChange={(e) => updateBundleItem(index, { name: e.target.value })}
						placeholder={L('ui.giftcode_admin.item_placeholder')}
					/>
					<NumberStepper
						compact
						value={item.count}
						min={1}
						onChange={(count) => updateBundleItem(index, { count })}
					/>
					<RemoveBtn type='button' onClick={() => removeBundleItem(index)}>
						×
					</RemoveBtn>
				</BundleItemRow>
			</BundleItemCard>
		)
	}

	return (
		<AnimatePresence>
			{admin.open && (
				<Overlay initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={close}>
					<Panel
						as={motion.div}
						initial={{ y: 12, opacity: 0 }}
						animate={{ y: 0, opacity: 1 }}
						exit={{ y: 12, opacity: 0 }}
						onClick={(e) => e.stopPropagation()}>
						<Header>
							<Text textTransform='uppercase' fontWeight='bold' rFontSize={15}>
								{L('ui.giftcode_admin.title')}
							</Text>
						</Header>

						<Tabs>
							<Tab type='button' $active={form.mode === 'random'} onClick={() => setMode('random')}>
								{L('ui.giftcode_admin.tab_random')}
							</Tab>
							<Tab type='button' $active={form.mode === 'fixed'} onClick={() => setMode('fixed')}>
								{L('ui.giftcode_admin.tab_fixed')}
							</Tab>
							<Tab type='button' $active={form.mode === 'bundle'} onClick={() => setMode('bundle')}>
								{L('ui.giftcode_admin.tab_bundle')}
							</Tab>
						</Tabs>

						<ScrollBody>
							{createdCode ? (
								<SuccessBox>
									<Text textTransform='uppercase' fontWeight='bold' rFontSize={13} color='var(--cyan)'>
										{L('ui.giftcode_admin.success_title')}
									</Text>
									<CodeDisplay>{createdCode}</CodeDisplay>
									<Hint rFontSize={11}>{L('ui.giftcode_admin.success_hint')}</Hint>
								</SuccessBox>
							) : (
								<FormSection>
									<CheckRow>
										<input
											type='checkbox'
											checked={form.announceEnabled}
											onChange={(e) =>
												setForm((p) => ({ ...p, announceEnabled: e.target.checked }))
											}
										/>
										{L('ui.giftcode_admin.announce_to_players')}
									</CheckRow>

									{form.announceEnabled && (
										<Field>
											<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.announce_title')}</FieldLabel>
											<Input
												value={form.announceTitle}
												onChange={(e) => setForm((p) => ({ ...p, announceTitle: e.target.value }))}
												placeholder={L('ui.giftcode_admin.announce_placeholder')}
												maxLength={200}
											/>
											<Hint rFontSize={10}>{L('ui.giftcode_admin.announce_hint')}</Hint>
										</Field>
									)}

									{form.mode === 'bundle' ? (
										<>
											<Field>
												<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.code')}</FieldLabel>
												<Input
													value={form.code}
													onChange={(e) => setForm((p) => ({ ...p, code: e.target.value }))}
													placeholder={L('ui.giftcode_admin.code_placeholder')}
												/>
											</Field>
											<Field>
												<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.bundle_items')}</FieldLabel>
												<BundleList>
													{form.items.map((item, index) => renderBundleItem(item, index))}
												</BundleList>
												<AddItemBtn type='button' onClick={addBundleItem}>
													+ {L('ui.giftcode_admin.add_item')}
												</AddItemBtn>
											</Field>
										</>
									) : form.mode === 'fixed' ? (
										<>
											<FormRow $cols='1fr 128px'>
												<Field>
													<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.code')}</FieldLabel>
													<Input
														value={form.code}
														onChange={(e) => setForm((p) => ({ ...p, code: e.target.value }))}
														placeholder={L('ui.giftcode_admin.code_placeholder')}
													/>
												</Field>
												<Field>
													<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.reward_type')}</FieldLabel>
													<Select
														value={form.type}
														onChange={(e) =>
															setForm((p) => ({ ...p, type: e.target.value as GiftRewardType }))
														}>
														<option value='item'>{L('ui.giftcode_admin.type_item')}</option>
														<option value='vehicle'>{L('ui.giftcode_admin.type_vehicle')}</option>
														<option value='clothing'>{L('ui.giftcode_admin.type_clothing')}</option>
													</Select>
												</Field>
											</FormRow>
											{showClothing ? (
												renderClothingFields()
											) : (
												<FormRow $cols={showCount ? '1fr 112px' : '1fr'}>
													<Field>
														<FieldLabel rFontSize={9}>{rewardLabel}</FieldLabel>
														<Input
															value={form.name}
															onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
															placeholder={rewardPlaceholder}
														/>
													</Field>
													{showCount && (
														<Field>
															<FieldLabel rFontSize={9}>
																{L('ui.giftcode_admin.item_count')}
															</FieldLabel>
															<NumberStepper
																value={form.count}
																min={1}
																onChange={(count) => setForm((p) => ({ ...p, count }))}
															/>
														</Field>
													)}
												</FormRow>
											)}
										</>
									) : (
										<>
											<Field>
												<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.reward_type')}</FieldLabel>
												<Select
													value={form.type}
													onChange={(e) =>
														setForm((p) => ({ ...p, type: e.target.value as GiftRewardType }))
													}>
													<option value='item'>{L('ui.giftcode_admin.type_item')}</option>
													<option value='vehicle'>{L('ui.giftcode_admin.type_vehicle')}</option>
													<option value='clothing'>{L('ui.giftcode_admin.type_clothing')}</option>
												</Select>
											</Field>
											{showClothing ? (
												renderClothingFields()
											) : (
												<FormRow $cols={showCount ? '1fr 112px' : '1fr'}>
													<Field>
														<FieldLabel rFontSize={9}>{rewardLabel}</FieldLabel>
														<Input
															value={form.name}
															onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
															placeholder={rewardPlaceholder}
														/>
													</Field>
													{showCount && (
														<Field>
															<FieldLabel rFontSize={9}>
																{L('ui.giftcode_admin.item_count')}
															</FieldLabel>
															<NumberStepper
																value={form.count}
																min={1}
																onChange={(count) => setForm((p) => ({ ...p, count }))}
															/>
														</Field>
													)}
												</FormRow>
											)}
										</>
									)}

									<FormRow $cols='1fr 1fr 1fr'>
										<Field>
											<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.remaining')}</FieldLabel>
											<NumberStepper
												value={form.remaining}
												min={1}
												allowUnlimited
												onChange={(remaining) => setForm((p) => ({ ...p, remaining }))}
											/>
										</Field>
										<Field>
											<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.min_level')}</FieldLabel>
											<NumberStepper
												value={form.minLevel}
												min={0}
												onChange={(minLevel) => setForm((p) => ({ ...p, minLevel }))}
											/>
										</Field>
										<Field>
											<FieldLabel rFontSize={9}>{L('ui.giftcode_admin.expire_hours')}</FieldLabel>
											<NumberStepper
												value={form.expireHours}
												min={0}
												onChange={(expireHours) => setForm((p) => ({ ...p, expireHours }))}
											/>
										</Field>
									</FormRow>

									<FormFootnote rFontSize={9}>
										{L('ui.giftcode_admin.remaining_hint')} · {L('ui.giftcode_admin.expire_hint')} ·{' '}
										{L('ui.giftcode_admin.announce_hint')}
									</FormFootnote>

									{error && (
										<Hint rFontSize={11} color='#ff8a98'>
											{error}
										</Hint>
									)}
								</FormSection>
							)}
						</ScrollBody>

						<Footer>
							{createdCode ? (
								<>
									<FooterBtn type='button' $variant='cyan' onClick={() => setCreatedCode(null)}>
										{L('ui.giftcode_admin.create_another')}
									</FooterBtn>
									<FooterBtn type='button' onClick={close}>
										{L('ui.common.close')}
									</FooterBtn>
								</>
							) : (
								<>
									<FooterBtn type='button' onClick={close}>
										{L('ui.common.close')}
									</FooterBtn>
									<Button
										rWidth={150}
										rHeight={34}
										rFontSize={12}
										text={creating ? L('ui.giftcode_admin.creating') : L('ui.giftcode_admin.create')}
										disabled={creating}
										cursor={creating ? 'not-allowed' : 'pointer'}
										onClick={submit}
									/>
								</>
							)}
						</Footer>
					</Panel>
				</Overlay>
			)}
		</AnimatePresence>
	)
}
