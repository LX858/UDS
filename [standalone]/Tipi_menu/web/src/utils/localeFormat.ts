/** Thay `{key}` trong chuỗi locale (đủ cho UI hiện tại, tránh gọi namespace stringd trong bundler). */
export function applyLocaleArgs(tpl: string, args?: { [key: string]: string | number }): string {
	if (!args) return tpl
	return Object.entries(args).reduce(
		(acc, [k, v]) => acc.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v)),
		tpl,
	)
}
