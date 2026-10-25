import type { RewardType } from '../types'

export const REWARD_THEME: Record<
	RewardType,
	{
		label: string
		card: string
		border: string
		glow: string
		badge: string
		isGold?: boolean
		isSpecial?: boolean
	}
> = {
	common: {
		label: 'Thường',
		card: 'bg-[rgba(0,18,32,0.92)]',
		border: 'border-[var(--border-dim)]',
		glow: '',
		badge: 'bg-[var(--cyan-faint)] text-[var(--text-sub)]',
	},
	rare: {
		label: 'Hiếm',
		card: 'bg-[linear-gradient(135deg,rgba(0,24,42,0.95)_0%,rgba(0,12,24,0.88)_100%)]',
		border: 'border-[var(--border)]',
		glow: 'shadow-cyan-soft',
		badge: 'bg-[rgba(0,229,255,0.12)] text-[var(--cyan-dim)]',
	},
	epic: {
		label: 'Sử thi',
		card: 'bg-[linear-gradient(135deg,rgba(0,32,48,0.96)_0%,rgba(0,14,28,0.9)_100%)]',
		border: 'border-[var(--cyan)]',
		glow: 'shadow-cyan',
		badge: 'bg-[rgba(0,229,255,0.18)] text-[var(--cyan)]',
	},
	goldcommon: {
		label: 'Vàng',
		card: 'bg-[linear-gradient(135deg,rgba(20,28,36,0.96)_0%,rgba(8,16,24,0.9)_100%)]',
		border: 'border-[rgba(255,171,0,0.45)]',
		glow: 'shadow-[0_0_14px_rgba(255,171,0,0.22)]',
		badge: 'bg-[rgba(255,171,0,0.14)] text-[var(--amber)]',
		isGold: true,
	},
	goldrare: {
		label: 'Vàng hiếm',
		card: 'bg-[linear-gradient(135deg,rgba(24,32,40,0.96)_0%,rgba(10,18,26,0.9)_100%)]',
		border: 'border-[rgba(255,171,0,0.55)]',
		glow: 'shadow-[0_0_16px_rgba(255,171,0,0.28)]',
		badge: 'bg-[rgba(255,171,0,0.18)] text-[var(--amber)]',
		isGold: true,
	},
	goldepic: {
		label: 'Vàng sử thi',
		card: 'bg-[linear-gradient(135deg,rgba(28,36,44,0.96)_0%,rgba(12,20,28,0.92)_100%)]',
		border: 'border-[rgba(255,171,0,0.65)]',
		glow: 'shadow-[0_0_18px_rgba(255,171,0,0.32)]',
		badge: 'bg-[rgba(255,171,0,0.22)] text-[var(--amber)]',
		isGold: true,
	},
	specialgold: {
		label: 'Đặc biệt',
		card: 'bg-[linear-gradient(135deg,rgba(0,32,48,0.98)_0%,rgba(16,24,12,0.92)_100%)]',
		border: 'border-[var(--cyan)]',
		glow: 'shadow-[0_0_20px_rgba(0,229,255,0.28),0_0_14px_rgba(255,171,0,0.24)]',
		badge: 'bg-[rgba(0,229,255,0.2)] text-[var(--cyan)]',
		isGold: true,
		isSpecial: true,
	},
}

export const DEFAULT_LOCALES = {
	Daily: 'ĐIỂM DANH',
	Rewards: 'TRONG THÁNG',
	Description: 'Online 1 phút để nhận quà ngày · Ngày bỏ lỡ có thể bù bằng tiền · VIP mua theo tháng',
	TabNormal: 'THƯỜNG',
	TabVip: 'VIP',
	VipLocked: 'Mua gói VIP tháng này để mở điểm danh VIP',
	VipBuy: 'MUA GÓI VIP THÁNG',
	VipOwned: 'Đã kích hoạt VIP tháng này',
	VipPrice: '%d COIN',
	VipNeedPack: 'Cần mua gói VIP tháng này',
	MissedDayPrice: 'Bù %s$',
	MissedDayHint: 'Ngày bỏ lỡ — trả %s$ để nhận',
	MissedDayNeedMoney: 'Không đủ tiền để nhận bù ngày (cần %s$)',
	MissedDayPaid: 'Đã trừ %s$ để nhận bù ngày',
	StreakTitle: 'CHUỖI ĐIỂM DANH',
	StreakCurrent: 'Chuỗi của bạn: %d ngày',
	Day: 'NGÀY',
	Hours: 'giờ',
	Minutes: 'phút',
	Seconds: 'giây',
	Collect: 'NHẬN QUÀ',
	Open: 'ĐIỂM DANH',
	Progress: 'Tiến độ',
	Checked: 'Đã nhận',
	Today: 'Hôm nay',
	TimerRemaining: 'Reset ngày mới',
	Close: 'Đóng',
	ClaimStreak: 'NHẬN QUÀ',
	ResetDaily: 'Reset ngày mới sau',
	MysteryReward: 'Hộp quà bí ẩn',
	MissedLimitReached: 'Đã hết lượt nhận bù ngày trong tháng này tối đa %d lượt',
	MissedFreeClaim: 'Nhận miễn phí',
	ClaimBusy: 'Đang xử lý quà, vui lòng chờ...',
	ClaimFailed: 'Không nhận được quà',
	AlreadyClaimed: 'Ngày này đã nhận rồi',
	NotYetAvailable: 'Ngày chưa đến',
	NotYetEligible: 'Chưa đủ điều kiện nhận',
}
