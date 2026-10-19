export type EventRuleSection = {
	title: string
	items: string[]
}

export type EventRewardItem = {
	itemName: string
	label: string
	count: number
}

export type EventRulesDocument = {
	sections: EventRuleSection[]
	rewards?: EventRewardItem[]
}

export function emptyRulesDocument(): EventRulesDocument {
	return {
		sections: [{ title: '', items: [''] }],
		rewards: [],
	}
}

function normalizeReward(reward: Partial<EventRewardItem>, forEditor: boolean): EventRewardItem {
	const itemName = forEditor ? String(reward?.itemName ?? '') : String(reward?.itemName ?? '').trim()
	const label = forEditor ? String(reward?.label ?? '') : String(reward?.label ?? '').trim()
	const count = Math.max(1, Math.floor(Number(reward?.count) || 1))
	return { itemName, label, count }
}

function isRewardEmpty(reward: EventRewardItem): boolean {
	return !reward.itemName.trim() && !reward.label.trim()
}

function normalizeRewards(raw: unknown, forEditor: boolean): EventRewardItem[] {
	if (!Array.isArray(raw)) {
		return forEditor ? [] : []
	}
	const rewards = raw.map((item) => normalizeReward(item as Partial<EventRewardItem>, forEditor))
	if (forEditor) return rewards
	return rewards.filter((reward) => !isRewardEmpty(reward))
}

function normalizeSection(section: Partial<EventRuleSection>, forEditor: boolean): EventRuleSection {
	const title = forEditor ? String(section?.title ?? '') : String(section?.title ?? '').trim()
	const rawItems = Array.isArray(section?.items)
		? section.items.map((item) => String(item ?? ''))
		: ['']

	if (forEditor) {
		return {
			title,
			items: rawItems.length > 0 ? rawItems : [''],
		}
	}

	const items = rawItems
		.map((item) => String(item ?? '').replace(/[\r\n\s]+$/g, ''))
		.filter((item) => !isItemEmpty(item))
	return { title, items }
}

/** Hiển thị tiêu chí: hỗ trợ xuống dòng/tab thật hoặc ký tự \\n \\t */
export function formatRuleItemText(raw: string): string {
	return String(raw ?? '')
		.replace(/\\n/g, '\n')
		.replace(/\\t/g, '\t')
}

function isItemEmpty(item: string): boolean {
	const text = formatRuleItemText(String(item ?? ''))
	return text.replace(/\s/g, '') === ''
}

function isSectionEmpty(section: EventRuleSection): boolean {
	return !section.title.trim() && section.items.every((item) => isItemEmpty(item))
}

export function parseRulesContent(raw: string, forEditor = false): EventRulesDocument {
	if (!raw?.trim()) {
		return emptyRulesDocument()
	}

	try {
		const parsed = JSON.parse(raw) as EventRulesDocument
		if (parsed?.sections && Array.isArray(parsed.sections)) {
			const sections = parsed.sections.map((section) => normalizeSection(section, forEditor))
			const rewards = normalizeRewards(parsed.rewards, forEditor)

			if (forEditor) {
				return {
					sections: sections.length > 0 ? sections : emptyRulesDocument().sections,
					rewards,
				}
			}

			const visibleSections = sections.filter((section) => !isSectionEmpty(section))
			if (visibleSections.length > 0 || rewards.length > 0) {
				return { sections: visibleSections, rewards }
			}
		}
	} catch {
		// legacy plain text
	}

	const lines = raw
		.split('\n')
		.map((line) => line.trim())
		.filter(Boolean)

	return {
		sections: [
			{
				title: '',
				items: lines.length > 0 ? lines : [''],
			},
		],
		rewards: [],
	}
}

export function serializeRulesContent(doc: EventRulesDocument, forSave = false): string {
	if (forSave) {
		const sections = doc.sections
			.map((section) => normalizeSection(section, false))
			.filter((section) => !isSectionEmpty(section))
		const rewards = normalizeRewards(doc.rewards, false)

		return JSON.stringify({ sections, rewards })
	}

	const sections =
		doc.sections.length > 0
			? doc.sections.map((section) => normalizeSection(section, true))
			: emptyRulesDocument().sections
	const rewards = normalizeRewards(doc.rewards, true)

	return JSON.stringify({ sections, rewards })
}

export function getVisibleRuleSections(doc: EventRulesDocument): EventRuleSection[] {
	return doc.sections
		.map((section) => normalizeSection(section, false))
		.filter((section) => !isSectionEmpty(section))
}

export function getVisibleRewards(doc: EventRulesDocument): EventRewardItem[] {
	return normalizeRewards(doc.rewards, false)
}

export function clampSortOrder(value: number): number {
	if (!Number.isFinite(value)) return 0
	return Math.max(0, Math.floor(value))
}
