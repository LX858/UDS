import type {
	BoardSummary,
	LeaderboardBranding,
	LeaderboardData,
	LeaderboardEntry,
} from '@/types/leaderboard'

export const mockBranding: LeaderboardBranding = {
	seasonTagline: 'UnderStars',
	logoUrl: 'https://r2.fivemanage.com/NDMhm0dqVgoz51MxrSmBn/logo_PNG.png',
}

export const mockBoards: BoardSummary[] = [
	{
		id: 'sellitem_vuanghe',
		label: '👑 Vua Nghề',
		description: 'Điểm trung bình từ 5 nghề bán hàng',
		icon: 'trophy',
		order: 1,
		theme: 'player',
	},
	{
		id: 'sellitem_fish',
		label: '🐟 Hải Sản',
		description: 'Top doanh thu bán hải sản',
		icon: 'trophy',
		order: 2,
		theme: 'player',
	},
	{
		id: 'sellitem_phelieu',
		label: '🔩 Phế Liệu',
		description: 'Top doanh thu bán phế liệu',
		icon: 'trophy',
		order: 3,
		theme: 'player',
	},
	{
		id: 'sellitem_mining',
		label: '⛏️ Khoáng Sản',
		description: 'Top doanh thu bán khoáng sản',
		icon: 'trophy',
		order: 4,
		theme: 'player',
	},
	{
		id: 'sellitem_nuoithu',
		label: '🐄 Nuôi Thú',
		description: 'Top doanh thu bán thú',
		icon: 'trophy',
		order: 5,
		theme: 'player',
	},
	{
		id: 'sellitem_traicay',
		label: '🍊 Nông Nghiệp',
		description: 'Top doanh thu bán nông sản',
		icon: 'trophy',
		order: 6,
		theme: 'player',
	},
]

const sellSeed = [
	{ name: 'ABC12345', label: 'Nguyễn Văn A', level: 0, value: 1250000, rankDelta: 0 },
	{ name: 'DEF67890', label: 'Trần Thị B', level: 0, value: 980500, rankDelta: 1 },
	{ name: 'GHI11223', label: 'Lê Văn C', level: 0, value: 742300, rankDelta: -1 },
	{ name: 'JKL44556', label: 'Phạm Thị D', level: 0, value: 615000 },
	{ name: 'MNO77889', label: 'Hoàng Văn E', level: 0, value: 488200 },
	{ name: 'PQR00112', label: 'Võ Thị F', level: 0, value: 352100 },
	{ name: 'STU33445', label: 'Đặng Văn G', level: 0, value: 298400 },
	{ name: 'VWX66778', label: 'Bùi Thị H', level: 0, value: 241800 },
	{ name: 'YZA99001', label: 'Đỗ Văn I', level: 0, value: 195600 },
	{ name: 'BCD22334', label: 'Hồ Thị K', level: 0, value: 152300 },
]

function toEntries(
	seed: {
		name: string
		label: string
		level: number
		value: number
		logoUrl?: string
		rankDelta?: number
	}[]
): LeaderboardEntry[] {
	return seed.map((entry, i) => ({ rank: i + 1, ...entry }))
}

function buildMockBoard(boardId: string, label: string, description: string): LeaderboardData {
	return {
		boardId,
		label,
		description,
		entryType: 'player',
		valueLabel: 'Điểm',
		theme: 'player',
		branding: mockBranding,
		updatedAt: Math.floor(Date.now() / 1000),
		listLimit: 10,
		entries: toEntries(sellSeed),
		player: {
			myEntryKey: 'MNO77889',
			myRank: 5,
			myValue: 488200,
			myLabel: 'Hoàng Văn E',
			inTopList: true,
		},
	}
}

const mockData: Record<string, LeaderboardData> = Object.fromEntries(
	mockBoards.map((board) => [
		board.id,
		buildMockBoard(board.id, board.label, board.description ?? ''),
	])
)

export function getMockLeaderboard(boardId: string): LeaderboardData {
	return mockData[boardId] ?? mockData.sellitem_vuanghe
}
