import { useCallback, useContext } from 'react'
import { SettingContext } from '../context/SettingContext'
import { applyLocaleArgs } from '../utils/localeFormat'
import { viLocale } from '../locales/vi'

/** Chuỗi UI từ `setting.locale` (game) + fallback `vi.ts` khi thiếu key. */
export function useLocale() {
	const { setting } = useContext(SettingContext)
	return useCallback(
		(key: string, args?: { [key: string]: string | number }) => {
			const tpl = setting.locale[key] ?? viLocale[key]
			if (tpl) return applyLocaleArgs(tpl, args)
			return key
		},
		[setting.locale],
	)
}
