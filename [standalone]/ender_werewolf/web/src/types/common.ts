export interface Player {
	id: number
	identifier: string
	source: number
	name: string
	job: {
		name: string
		label: string
		grade: number
		gradeName: string
		gradeLabel: string
		gradeSalary: number
	}
}

export interface NotificationProps {
	msg: string
	type: string
	time: number
}

export interface HelpNotificationProps {
	key: string
	description: string
	percent: number
}

export interface HouseData {
	door: {
		x: number
		y: number
		z: number
	}
	price: number
	prop: string
	taxRate: number
	maxSlot: number
	maxWeight: number
	address?: string
	allowGangOwner: boolean
	garages?: {
		slot: number
		description: string
		props: string
	}
}

export type HouseUIType = 'owned' | 'unowned' | 'inside' | 'manage'

export interface House {
	id: number
	owner?: string
	gangOwner?: {
		name: string
		label: string
	}
	houseData: HouseData
	locked: boolean
}
