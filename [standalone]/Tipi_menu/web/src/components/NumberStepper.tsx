import React, { useCallback } from 'react'
import styled from 'styled-components'

const FIELD_HEIGHT = 40

const Wrap = styled.div<{ $compact?: boolean }>`
	display: flex;
	align-items: stretch;
	width: ${(p) => (p.$compact ? '100%' : '100%')};
	min-width: ${(p) => (p.$compact ? '108px' : '0')};
	height: ${FIELD_HEIGHT}px;
`

const StepBtn = styled.button`
	flex-shrink: 0;
	width: 34px;
	height: 100%;
	padding: 0;
	border: 1px solid var(--border-dim);
	background: rgba(0, 18, 32, 0.88);
	color: var(--text-sub);
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 18px;
	font-weight: 600;
	line-height: 1;
	cursor: pointer;
	display: flex;
	align-items: center;
	justify-content: center;
	transition:
		border-color 0.15s ease,
		color 0.15s ease,
		background-color 0.15s ease;

	&:hover:not(:disabled) {
		border-color: var(--border);
		color: var(--cyan);
		background: rgba(0, 229, 255, 0.08);
	}

	&:disabled {
		opacity: 0.35;
		cursor: not-allowed;
	}
`

const DecBtn = styled(StepBtn)`
	border-radius: 4px 0 0 4px;
	border-right: none;
`

const IncBtn = styled(StepBtn)`
	border-radius: 0 4px 4px 0;
	border-left: none;
`

const ValueInput = styled.input`
	flex: 1;
	min-width: 0;
	width: 100%;
	height: 100%;
	padding: 0 6px;
	box-sizing: border-box;
	border-radius: 0;
	border: 1px solid var(--border-dim);
	background: rgba(0, 18, 32, 0.88);
	color: #fff;
	font-family: 'Montserrat', sans-serif;
	font-size: 13px;
	text-align: center;
	outline: none;
	-moz-appearance: textfield;

	&::-webkit-outer-spin-button,
	&::-webkit-inner-spin-button {
		-webkit-appearance: none;
		margin: 0;
	}

	&:focus {
		border-color: var(--border);
	}
`

export type NumberStepperProps = {
	value: number
	onChange: (value: number) => void
	min?: number
	max?: number
	/** Cho phép -1 (dùng cho số lượt dùng giftcode) */
	allowUnlimited?: boolean
	compact?: boolean
	className?: string
}

function parseInput(raw: string, fallback: number) {
	if (raw === '' || raw === '-') return raw
	const n = Number(raw)
	return Number.isNaN(n) ? fallback : n
}

function normalizeValue(
	value: number,
	min: number,
	max: number | undefined,
	allowUnlimited: boolean,
): number {
	if (allowUnlimited && value === 0) return 1
	if (allowUnlimited && value < -1) return -1
	if (!allowUnlimited && value < min) return min
	if (max !== undefined && value > max) return max
	return value
}

function stepValue(
	current: number,
	delta: number,
	min: number,
	max: number | undefined,
	allowUnlimited: boolean,
): number {
	let next = current + delta
	if (allowUnlimited) {
		if (current === 1 && delta < 0) next = -1
		if (current === -1 && delta > 0) next = 1
		if (next === 0) next = delta > 0 ? 1 : -1
		if (next < -1) next = -1
	} else {
		if (next < min) next = min
	}
	if (max !== undefined && next > max) next = max
	return next
}

export default function NumberStepper({
	value,
	onChange,
	min = 0,
	max,
	allowUnlimited = false,
	compact = false,
	className,
}: NumberStepperProps) {
	const canDec = allowUnlimited ? value > -1 : value > min
	const canInc = max === undefined || value < max

	const commit = useCallback(
		(next: number) => {
			onChange(normalizeValue(next, min, max, allowUnlimited))
		},
		[allowUnlimited, max, min, onChange],
	)

	return (
		<Wrap $compact={compact} className={className}>
			<DecBtn
				type='button'
				aria-label='Giảm'
				disabled={!canDec}
				onClick={() => commit(stepValue(value, -1, min, max, allowUnlimited))}>
				−
			</DecBtn>
			<ValueInput
				type='number'
				inputMode='numeric'
				value={value}
				min={allowUnlimited ? -1 : min}
				max={max}
				onChange={(e) => {
					const parsed = parseInput(e.target.value, value)
					if (typeof parsed === 'string') return
					commit(parsed)
				}}
				onBlur={(e) => {
					const parsed = Number(e.target.value)
					if (Number.isNaN(parsed)) {
						commit(min)
						return
					}
					commit(parsed)
				}}
			/>
			<IncBtn
				type='button'
				aria-label='Tăng'
				disabled={!canInc}
				onClick={() => commit(stepValue(value, 1, min, max, allowUnlimited))}>
				+
			</IncBtn>
		</Wrap>
	)
}

export { FIELD_HEIGHT as NUMBER_STEPPER_HEIGHT }
