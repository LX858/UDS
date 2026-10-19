import { Box, Text } from 'lr-components'
import React from 'react'
import styled from 'styled-components'
import EventItemImage from './EventItemImage'
import NumberStepper from './NumberStepper'
import { useLocale } from '../hooks/useLocale'
import { EventRewardItem, EventRulesDocument } from '../utils/eventRulesContent'

const Block = styled(Box)`
	display: flex;
	flex-direction: column;
	gap: 10px;
	padding: 12px;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 14, 28, 0.72);
`

const Row = styled(Box)`
	display: grid;
	grid-template-columns: 52px minmax(0, 1fr) minmax(0, 1fr) 112px 32px;
	gap: 8px;
	align-items: end;
`

const Input = styled.input`
	width: 100%;
	min-width: 0;
	padding: 9px 11px;
	box-sizing: border-box;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 18, 32, 0.88);
	color: #fff;
	font-family: 'Montserrat', sans-serif;
	font-size: 13px;
	outline: none;
	pointer-events: auto;

	&:focus {
		border-color: var(--border);
	}
`

const Thumb = styled(Box)`
	width: 52px;
	height: 52px;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 8, 18, 0.72);
	overflow: hidden;
	flex-shrink: 0;
`

const IconBtn = styled.button`
	width: 32px;
	height: 40px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 229, 255, 0.08);
	color: var(--text-sub);
	border-radius: 4px;
	cursor: pointer;
	font-size: 16px;
	line-height: 1;
	flex-shrink: 0;

	&:hover {
		border-color: var(--border);
		color: #ff8a98;
	}
`

const AddBtn = styled.button`
	align-self: flex-start;
	height: 32px;
	padding: 0 14px;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 229, 255, 0.08);
	color: var(--cyan);
	font-family: 'Oswald', 'Montserrat', sans-serif;
	font-size: 11px;
	text-transform: uppercase;
	letter-spacing: 0.04em;
	cursor: pointer;

	&:hover {
		border-color: var(--border);
		background: rgba(0, 229, 255, 0.14);
	}
`

const HeaderRow = styled(Box)`
	display: grid;
	grid-template-columns: 52px minmax(0, 1fr) minmax(0, 1fr) 112px 32px;
	gap: 8px;
	padding: 0 0 2px;
`

const ColLabel = styled(Text)`
	text-transform: uppercase;
	color: var(--text-sub);
`

type Props = {
	value: EventRulesDocument
	onChange: (next: EventRulesDocument) => void
}

const EMPTY_REWARD = (): EventRewardItem => ({ itemName: '', label: '', count: 1 })

function editorRewards(raw: EventRewardItem[] | undefined): EventRewardItem[] {
	if (raw && raw.length > 0) return raw
	return [EMPTY_REWARD()]
}

export default function EventRewardsEditor({ value, onChange }: Props) {
	const L = useLocale()
	const rewards = editorRewards(value.rewards)

	const setRewards = (next: EventRewardItem[]) => {
		onChange({ ...value, rewards: next.length > 0 ? next : [EMPTY_REWARD()] })
	}

	const updateReward = (index: number, patch: Partial<EventRewardItem>) => {
		setRewards(rewards.map((item, i) => (i === index ? { ...item, ...patch } : item)))
	}

	const addReward = () => {
		setRewards([...rewards, EMPTY_REWARD()])
	}

	const removeReward = (index: number) => {
		const next = rewards.filter((_, i) => i !== index)
		setRewards(next.length > 0 ? next : [EMPTY_REWARD()])
	}

	return (
		<Block>
			<HeaderRow>
				<ColLabel rFontSize={9}>{L('ui.event_rules.reward_image')}</ColLabel>
				<ColLabel rFontSize={9}>{L('ui.event_rules.reward_item_name')}</ColLabel>
				<ColLabel rFontSize={9}>{L('ui.event_rules.reward_label')}</ColLabel>
				<ColLabel rFontSize={9}>{L('ui.event_rules.reward_count')}</ColLabel>
				<Box />
			</HeaderRow>

			{rewards.map((reward, index) => (
				<Row key={`reward-${index}`}>
					<Thumb>
						<EventItemImage itemName={reward.itemName} alt={reward.label || reward.itemName} />
					</Thumb>
					<Input
						value={reward.itemName}
						onChange={(e) => updateReward(index, { itemName: e.target.value.replace(/\s/g, '') })}
						placeholder={L('ui.event_rules.reward_item_placeholder')}
					/>
					<Input
						value={reward.label}
						onChange={(e) => updateReward(index, { label: e.target.value })}
						placeholder={L('ui.event_rules.reward_label_placeholder')}
					/>
					<NumberStepper
						compact
						value={reward.count}
						min={1}
						onChange={(count) => updateReward(index, { count })}
					/>
					<IconBtn type='button' onClick={() => removeReward(index)}>
						×
					</IconBtn>
				</Row>
			))}

			<AddBtn type='button' onClick={addReward}>
				+ {L('ui.event_rules.add_reward')}
			</AddBtn>
		</Block>
	)
}
