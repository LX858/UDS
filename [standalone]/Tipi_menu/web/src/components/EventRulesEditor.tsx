import { Box, Text } from 'lr-components'
import React from 'react'
import styled from 'styled-components'
import Button from './Button'
import { useLocale } from '../hooks/useLocale'
import { EventRulesDocument, EventRuleSection } from '../utils/eventRulesContent'

const Block = styled(Box)`
	display: flex;
	flex-direction: column;
	gap: 10px;
	padding: 12px;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 14, 28, 0.72);
`

const SectionCard = styled(Box)`
	display: flex;
	flex-direction: column;
	gap: 8px;
	padding: 10px;
	border-radius: 4px;
	border: 1px solid rgba(0, 229, 255, 0.18);
	background: rgba(0, 8, 18, 0.55);
`

const Input = styled.input`
	width: 100%;
	padding: 9px 11px;
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

const TextArea = styled.textarea`
	width: 100%;
	min-height: 56px;
	padding: 9px 11px;
	box-sizing: border-box;
	border-radius: 4px;
	border: 1px solid var(--border-dim);
	background: rgba(0, 18, 32, 0.88);
	color: #fff;
	font-family: 'Montserrat', sans-serif;
	font-size: 13px;
	line-height: 1.5;
	outline: none;
	resize: vertical;
	white-space: pre-wrap;
	word-break: break-word;
	overflow-wrap: anywhere;

	&:focus {
		border-color: var(--border);
	}
`

const ItemRow = styled(Box)`
	display: grid;
	grid-template-columns: 1fr auto;
	gap: 8px;
	align-items: start;
`

const SectionActions = styled(Box)`
	display: flex;
	justify-content: space-between;
	align-items: center;
	gap: 8px;
`

const MiniBtn = styled.button`
	border: 1px solid var(--border-dim);
	background: rgba(0, 229, 255, 0.08);
	color: var(--text-sub);
	padding: 4px 8px;
	border-radius: 4px;
	cursor: pointer;
	font-family: 'Montserrat', sans-serif;
	font-size: 11px;
	text-transform: uppercase;

	&:hover {
		border-color: var(--border);
		color: #fff;
	}
`

type Props = {
	value: EventRulesDocument
	onChange: (next: EventRulesDocument) => void
}

function updateSection(
	doc: EventRulesDocument,
	index: number,
	patch: Partial<EventRuleSection>,
): EventRulesDocument {
	return {
		...doc,
		sections: doc.sections.map((section, i) => (i === index ? { ...section, ...patch } : section)),
	}
}

export default function EventRulesEditor({ value, onChange }: Props) {
	const L = useLocale()

	const addSection = () => {
		onChange({
			...value,
			sections: [...value.sections, { title: '', items: [''] }],
		})
	}

	const removeSection = (index: number) => {
		if (value.sections.length <= 1) {
			onChange({ ...value, sections: [{ title: '', items: [''] }] })
			return
		}
		onChange({ ...value, sections: value.sections.filter((_, i) => i !== index) })
	}

	const addItem = (sectionIndex: number) => {
		const section = value.sections[sectionIndex]
		onChange(updateSection(value, sectionIndex, { items: [...section.items, ''] }))
	}

	const updateItem = (sectionIndex: number, itemIndex: number, text: string) => {
		const section = value.sections[sectionIndex]
		const items = section.items.map((item, i) => (i === itemIndex ? text : item))
		onChange(updateSection(value, sectionIndex, { items }))
	}

	const removeItem = (sectionIndex: number, itemIndex: number) => {
		const section = value.sections[sectionIndex]
		const items = section.items.filter((_, i) => i !== itemIndex)
		onChange(updateSection(value, sectionIndex, { items: items.length > 0 ? items : [''] }))
	}

	return (
		<Block>
			<SectionActions>
				<Text rFontSize={10} color='var(--text-sub)' textTransform='uppercase'>
					{L('ui.event_rules.sections')}
				</Text>
				<MiniBtn type='button' onClick={addSection}>
					+ {L('ui.event_rules.add_section')}
				</MiniBtn>
			</SectionActions>

			{value.sections.map((section, sectionIndex) => (
				<SectionCard key={`section-${sectionIndex}`}>
					<ItemRow>
						<Input
							value={section.title}
							onChange={(e) => onChange(updateSection(value, sectionIndex, { title: e.target.value }))}
							placeholder={L('ui.event_rules.section_title_placeholder')}
						/>
						<MiniBtn type='button' onClick={() => removeSection(sectionIndex)}>
							{L('ui.event_rules.remove_section')}
						</MiniBtn>
					</ItemRow>

					<Box display='flex' flexDirection='column' rGap={6}>
						{section.items.map((item, itemIndex) => (
							<ItemRow key={`item-${sectionIndex}-${itemIndex}`}>
								<TextArea
									value={item}
									rows={2}
									onChange={(e) => updateItem(sectionIndex, itemIndex, e.target.value)}
									placeholder={L('ui.event_rules.item_placeholder')}
								/>
								<MiniBtn type='button' onClick={() => removeItem(sectionIndex, itemIndex)}>
									×
								</MiniBtn>
							</ItemRow>
						))}
					</Box>

					<Box>
						<Button
							rWidth={120}
							rHeight={28}
							rFontSize={10}
							text={`+ ${L('ui.event_rules.add_item')}`}
							onClick={() => addItem(sectionIndex)}
						/>
					</Box>
				</SectionCard>
			))}
		</Block>
	)
}
