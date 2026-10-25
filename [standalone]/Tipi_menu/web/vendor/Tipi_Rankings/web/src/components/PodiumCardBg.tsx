import { useId } from 'react'
import { cn } from '@/utils'

type PodiumRank = 1 | 2 | 3

interface PodiumCardBgProps {
	rank: PodiumRank
	className?: string
	embedded?: boolean
}

const CARD_OUTER =
	'M8 4 H92 Q98 4 98 11 V105 L50 132 L2 105 V11 Q2 4 8 4 Z'

const CARD_INNER =
	'M14 12 H86 V98 L50 122 L14 98 Z'

const SCORE_WELL = 'M16 90 H84 L78 112 L22 112 Z'

const themes: Record<
	PodiumRank,
	{
		face: [string, string, string]
		frame: [string, string, string]
		innerStroke: string
		glow: string
		accent: string
		wellFill: [string, string]
	}
> = {
	1: {
		face: ['#3d2818', '#1f140e', '#120a06'],
		frame: ['#fff7c2', '#fbbf24', '#b45309'],
		innerStroke: 'rgba(251,191,36,0.22)',
		glow: 'rgba(250,204,21,0.55)',
		accent: 'rgba(239,68,68,0.55)',
		wellFill: ['rgba(70,38,141,0.22)', 'rgba(12,8,22,0.55)'],
	},
	2: {
		face: ['#243044', '#151c28', '#0a0e14'],
		frame: ['#f1f5f9', '#94a3b8', '#475569'],
		innerStroke: 'rgba(148,163,184,0.28)',
		glow: 'rgba(56,189,248,0.4)',
		accent: 'rgba(125,211,252,0.45)',
		wellFill: ['rgba(70,38,141,0.2)', 'rgba(10,8,20,0.52)'],
	},
	3: {
		face: ['#352218', '#1e120c', '#100804'],
		frame: ['#fed7aa', '#ea580c', '#9a3412'],
		innerStroke: 'rgba(251,146,60,0.25)',
		glow: 'rgba(251,146,60,0.38)',
		accent: 'rgba(234,88,12,0.4)',
		wellFill: ['rgba(70,38,141,0.2)', 'rgba(12,8,18,0.52)'],
	},
}

const embeddedWellFill: [string, string] = [
	'rgba(70,38,141,0.12)',
	'rgba(70,38,141,0.22)',
]

const embeddedFaceThemes: Record<
	PodiumRank,
	{ face: [string, string, string]; innerStroke: string; glow: string }
> = {
	1: {
		face: ['rgba(251,191,36,0.28)', 'rgba(178,146,247,0.2)', 'rgba(70,38,141,0.12)'],
		innerStroke: 'rgba(251,191,36,0.35)',
		glow: 'rgba(250,204,21,0.35)',
	},
	2: {
		face: ['rgba(148,163,184,0.25)', 'rgba(178,146,247,0.18)', 'rgba(70,38,141,0.1)'],
		innerStroke: 'rgba(148,163,184,0.35)',
		glow: 'rgba(56,189,248,0.28)',
	},
	3: {
		face: ['rgba(251,146,60,0.25)', 'rgba(178,146,247,0.18)', 'rgba(70,38,141,0.1)'],
		innerStroke: 'rgba(251,146,60,0.32)',
		glow: 'rgba(251,146,60,0.28)',
	},
}

export default function PodiumCardBg({ rank, className, embedded = false }: PodiumCardBgProps) {
	const uid = useId().replace(/:/g, '')
	const t = themes[rank]
	const emb = embedded ? embeddedFaceThemes[rank] : null
	const well = embedded ? embeddedWellFill : t.wellFill

	return (
		<svg
			className={cn('block h-full w-full', className)}
			viewBox='0 0 100 140'
			preserveAspectRatio='xMidYMax meet'
			aria-hidden>
			<defs>
				<linearGradient id={`${uid}-face`} x1='50%' y1='0%' x2='50%' y2='100%'>
					<stop offset='0%' stopColor={emb ? emb.face[0] : t.face[0]} />
					<stop offset='55%' stopColor={emb ? emb.face[1] : t.face[1]} />
					<stop offset='100%' stopColor={emb ? emb.face[2] : t.face[2]} />
				</linearGradient>
				<linearGradient id={`${uid}-frame`} x1='0%' y1='0%' x2='100%' y2='100%'>
					<stop offset='0%' stopColor={t.frame[0]} />
					<stop offset='50%' stopColor={t.frame[1]} />
					<stop offset='100%' stopColor={t.frame[2]} />
				</linearGradient>
				<linearGradient id={`${uid}-shine`} x1='0%' y1='0%' x2='0%' y2='100%'>
					<stop offset='0%' stopColor='#ffffff' stopOpacity='0.12' />
					<stop offset='35%' stopColor='#ffffff' stopOpacity='0' />
				</linearGradient>
				<linearGradient id={`${uid}-well`} x1='50%' y1='0%' x2='50%' y2='100%'>
					<stop offset='0%' stopColor={well[0]} />
					<stop offset='100%' stopColor={well[1]} />
				</linearGradient>
			</defs>

			<path
				d={CARD_OUTER}
				fill='none'
				stroke={emb ? emb.glow : t.glow}
				strokeWidth={rank === 1 ? 3 : 2.5}
				opacity={rank === 1 ? 0.55 : 0.4}
			/>
			<path
				d={CARD_OUTER}
				fill={`url(#${uid}-face)`}
				stroke={`url(#${uid}-frame)`}
				strokeWidth='2'
			/>
			<path d={CARD_OUTER} fill={`url(#${uid}-shine)`} stroke='none' />
			<path
				d={CARD_INNER}
				fill='none'
				stroke={emb ? emb.innerStroke : t.innerStroke}
				strokeWidth='0.8'
			/>

			<path
				d={SCORE_WELL}
				fill={`url(#${uid}-well)`}
				stroke={embedded ? 'rgba(178,146,247,0.2)' : 'rgba(255,255,255,0.08)'}
				strokeWidth='0.5'
			/>

			<line
				x1='22'
				y1='90'
				x2='28'
				y2='112'
				stroke='rgba(255,255,255,0.08)'
				strokeWidth='0.6'
			/>
			<line
				x1='78'
				y1='90'
				x2='72'
				y2='112'
				stroke='rgba(255,255,255,0.08)'
				strokeWidth='0.6'
			/>

			<line
				x1='18'
				y1='8'
				x2='82'
				y2='8'
				stroke={t.accent}
				strokeWidth='0.7'
				strokeLinecap='round'
				opacity={rank === 1 ? '0.35' : '0.45'}
			/>
		</svg>
	)
}
