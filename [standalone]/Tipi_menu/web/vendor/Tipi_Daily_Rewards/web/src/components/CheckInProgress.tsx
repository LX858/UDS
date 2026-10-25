import type { Locales } from '../types'

interface CheckInProgressProps {
	checked: number
	total: number
	locales: Locales
}

export default function CheckInProgress({ checked, total, locales }: CheckInProgressProps) {
	const percent = total > 0 ? Math.min(100, Math.round((checked / total) * 100)) : 0

	return (
		<div className='min-w-[200px] flex-1'>
			<div className='mb-1 flex items-center justify-between'>
				<span className='tipi-label text-[10px]'>{locales.Progress ?? 'Tiến độ'}</span>
				<span className='font-accent text-xs font-bold text-[var(--cyan)]'>
					{checked}/{total}
				</span>
			</div>
			<div className='cal-cell-progress'>
				<div className='cal-cell-progress-fill' style={{ width: `${percent}%` }} />
			</div>
		</div>
	)
}
