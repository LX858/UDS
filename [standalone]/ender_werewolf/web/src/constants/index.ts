export const HOUSING_MANAGE_ITEMS = [
	{
		id: 'personal-warehouse',
		icon: 'streamline:safe-vault',
		title: 'Kho cá nhân',
		loadingTitle: 'Đang mở kho',
		event: 'openPlayerWarehouse',
		type: 'personal'
	},
	{
		id: 'gang-store',
		icon: 'teenyicons:shop-outline',
		title: 'Shop gia tộc',
		loadingTitle: 'Đang mở kho',
		event: 'openGangStore',
		type: 'gang-facility'
	},
	{
		id: 'gang-stash',
		icon: 'mdi:warehouse',
		title: 'Kho gia tộc',
		loadingTitle: 'Đang mở kho',
		event: 'openGangStash',
		type: 'gang-facility'
	}
] as const
