-- File này chứa định nghĩa item cho ox_inventory
-- Copy nội dung bên dưới vào file items.lua của ox_inventory

return {
	['chieungu'] = {
		label = 'Chiếu ngủ di động',
		weight = 2000,
		stack = false,
		close = true,
		description = 'Một tấm chiếu để bạn có thể ngủ bất cứ nơi đâu',
		client = {
			export = 'sleep_system.SleepWithItem',
			-- Hoặc sử dụng event:
			-- event = 'sleep:useSleepItem'
		},
		server = {
			export = 'sleep_system.useSleepItem'
		},
		-- Có thể thêm icon nếu muốn
		-- image = 'chieungu.png',
	},
}
