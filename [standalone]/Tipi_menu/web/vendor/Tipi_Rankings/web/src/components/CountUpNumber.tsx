import { useCountUp } from '@/hooks/useCountUp'
import { formatNumber } from '@/utils'

interface CountUpNumberProps {
	value: number
	active: boolean
	className?: string
}

export default function CountUpNumber({ value, active, className }: CountUpNumberProps) {
	const display = useCountUp(value, active)
	return <span className={className}>{formatNumber(display)}</span>
}
