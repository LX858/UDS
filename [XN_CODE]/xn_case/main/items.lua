-- File thêm items chìa khóa cho hệ thống case
-- Bạn cần thêm những items này vào file shared/items.lua của QBCore

--[[
Thêm những items sau vào QBCore.Shared.Items trong file qb-core/shared/items.lua:

	['keygacha_premium'] = {
		['name'] = 'keygacha_premium',
		['label'] = 'Chìa Khóa Hòm Premium',
		['weight'] = 100,
		['type'] = 'item',
		['image'] = 'keygacha_premium.png',
		['unique'] = false,
		['useable'] = false,
		['shouldClose'] = false,
		['combinable'] = nil,
		['description'] = 'Chìa khóa để mở hòm Premium'
	},
	
	['keygacha_basic'] = {
		['name'] = 'keygacha_basic',
		['label'] = 'Chìa Khóa Hòm Cơ Bản',
		['weight'] = 100,
		['type'] = 'item',
		['image'] = 'keygacha_basic.png',
		['unique'] = false,
		['useable'] = false,
		['shouldClose'] = false,
		['combinable'] = nil,
		['description'] = 'Chìa khóa để mở hòm cơ bản'
	},

Nếu bạn muốn thêm nhiều loại hòm khác, có thể thêm:

	['keygacha_legendary'] = {
		['name'] = 'keygacha_legendary',
		['label'] = 'Chìa Khóa Hòm Huyền Thoại',
		['weight'] = 100,
		['type'] = 'item',
		['image'] = 'keygacha_legendary.png',
		['unique'] = false,
		['useable'] = false,
		['shouldClose'] = false,
		['combinable'] = nil,
		['description'] = 'Chìa khóa để mở hòm huyền thoại'
	},
	
	['keygacha_epic'] = {
		['name'] = 'keygacha_epic',
		['label'] = 'Chìa Khóa Hòm Epic',
		['weight'] = 100,
		['type'] = 'item',
		['image'] = 'keygacha_epic.png',
		['unique'] = false,
		['useable'] = false,
		['shouldClose'] = false,
		['combinable'] = nil,
		['description'] = 'Chìa khóa để mở hòm epic'
	},

	-- IC Keys
	['keygachaic_tshirt'] = {
		['name'] = 'keygachaic_tshirt',
		['label'] = 'Chìa Khóa Hòm Tshirt IC',
		['weight'] = 100,
		['type'] = 'item',
		['image'] = 'homic.png',
		['unique'] = false,
		['useable'] = false,
		['shouldClose'] = false,
		['combinable'] = nil,
		['description'] = 'Chìa khóa để mở hòm Tshirt IC'
	},

	['keygachaic_torso'] = {
		['name'] = 'keygachaic_torso',
		['label'] = 'Chìa Khóa Hòm Áo Khoác IC',
		['weight'] = 100,
		['type'] = 'item',
		['image'] = 'homic.png',
		['unique'] = false,
		['useable'] = false,
		['shouldClose'] = false,
		['combinable'] = nil,
		['description'] = 'Chìa khóa để mở hòm Áo Khoác IC'
	},

	['keygachaic_pants'] = {
		['name'] = 'keygachaic_pants',
		['label'] = 'Chìa Khóa Hòm Quần IC',
		['weight'] = 100,
		['type'] = 'item',
		['image'] = 'homic.png',
		['unique'] = false,
		['useable'] = false,
		['shouldClose'] = false,
		['combinable'] = nil,
		['description'] = 'Chìa khóa để mở hòm Quần IC'
	},

	['keygachaic_shoes'] = {
		['name'] = 'keygachaic_shoes',
		['label'] = 'Chìa Khóa Hòm Giày IC',
		['weight'] = 100,
		['type'] = 'item',
		['image'] = 'homic.png',
		['unique'] = false,
		['useable'] = false,
		['shouldClose'] = false,
		['combinable'] = nil,
		['description'] = 'Chìa khóa để mở hòm Giày IC'
	},

	['keygachaic_glasses'] = {
		['name'] = 'keygachaic_glasses',
		['label'] = 'Chìa Khóa Hòm Kính IC',
		['weight'] = 100,
		['type'] = 'item',
		['image'] = 'homic.png',
		['unique'] = false,
		['useable'] = false,
		['shouldClose'] = false,
		['combinable'] = nil,
		['description'] = 'Chìa khóa để mở hòm Kính IC'
	},

--]]
-- Hàm helper
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end
