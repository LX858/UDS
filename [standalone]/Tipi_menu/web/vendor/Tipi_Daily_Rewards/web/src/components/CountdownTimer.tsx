import { useEffect, useRef, useState } from 'react'
import { dispTime, padTime } from '../utils/nui'
import type { Locales, TimeParts } from '../types'

interface CountdownTimerProps {
	initialOsTime: number
	locales: Locales
}

export default function CountdownTimer({ initialOsTime, locales }: CountdownTimerProps) {
	const osRef = useRef(Math.max(0, Math.floor(initialOsTime || 0)))
	const [time, setTime] = useState<TimeParts>(() => dispTime(osRef.current))

	useEffect(() => {
		osRef.current = Math.max(0, Math.floor(initialOsTime || 0))
		setTime(dispTime(osRef.current))

		const id = window.setInterval(() => {
			if (osRef.current <= 0) {
				setTime({ Hours: '00', Minutes: '00', Seconds: '00', OsTime: 0 })
				return
			}
			osRef.current -= 1
			setTime(dispTime(osRef.current))
		}, 1000)

		return () => window.clearInterval(id)
	}, [initialOsTime])

	const blocks = [
		{ value: padTime(time.Hours), label: locales.Hours },
		{ value: padTime(time.Minutes), label: locales.Minutes },
		{ value: padTime(time.Seconds), label: locales.Seconds },
	]

	return (
		<div className='countdown-block'>
			<span className='countdown-label tipi-label'>
				{locales.ResetDaily ?? locales.TimerRemaining ?? 'Reset ngày mới'}
			</span>
			<div className='countdown-units'>
				{blocks.map((block) => (
					<div key={block.label} className='countdown-unit'>
						<span className='countdown-value'>{block.value}</span>
						<span className='countdown-unit-label'>{block.label}</span>
					</div>
				))}
			</div>
		</div>
	)
}
