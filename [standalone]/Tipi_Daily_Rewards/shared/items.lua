ItemsHelper = ItemsHelper or {}

function ItemsHelper.IsMoneyType(itemType)
	return itemType == 'money' or itemType == 'cash'
end

function ItemsHelper.GetLabel(itemName, fallback)
	if not itemName then return fallback end

	if GetResourceState('ox_inventory') == 'started' then
		local ok, item = pcall(function()
			return exports.ox_inventory:Items(itemName)
		end)
		if ok and type(item) == 'table' and item.label then
			return item.label
		end
	end

	return fallback or itemName
end

function ItemsHelper.EnrichReward(reward)
	if type(reward) ~= 'table' then return reward end

	local itemType = reward.itemType or 'item'
	-- Chuẩn hoá money cũ → cash (cùng logic FrameworkAddMoney)
	if itemType == 'money' then
		itemType = 'cash'
	end

	local clothComponent = reward.clothComponent or (itemType == 'clothing' and reward.itemName) or nil
	local itemName = reward.itemName
	if itemType == 'clothing' and (not itemName or itemName == '') then
		itemName = clothComponent
	end

	local enriched = {
		type = 'common',
		itemName = itemName,
		itemLabel = reward.itemLabel or ItemsHelper.GetLabel(itemName, itemName),
		itemCount = math.max(1, math.floor(tonumber(reward.itemCount) or 1)),
		itemType = itemType,
	}

	if ItemsHelper.IsMoneyType(itemType) then
		if not enriched.itemName or enriched.itemName == '' then
			enriched.itemName = 'cash'
		end
		if not enriched.itemLabel or enriched.itemLabel == '' then
			enriched.itemLabel = ('$%s'):format(enriched.itemCount)
		end
	elseif itemType == 'clothing' then
		enriched.clothComponent = clothComponent
		-- Drawable / texture luôn bắt đầu từ 1 (XNClothes index thực tế)
		enriched.clothDrawable = math.max(1, math.floor(tonumber(reward.clothDrawable) or 1))
		enriched.clothTexture = math.max(1, math.floor(tonumber(reward.clothTexture) or 1))
		local sex = reward.clothSex
		if sex == 'male' or sex == 'female' then
			enriched.clothSex = sex
		else
			enriched.clothSex = ''
		end
		if not enriched.itemLabel or enriched.itemLabel == '' then
			enriched.itemLabel = ('%s #%s'):format(clothComponent or 'cloth', enriched.clothDrawable)
		end
	end

	return enriched
end

function ItemsHelper.GetClothingComponents()
	if GetResourceState('XNClothes') == 'started' then
		local ok, list = pcall(function()
			return exports['XNClothes']:GetComponentList()
		end)
		if ok and type(list) == 'table' and #list > 0 then
			return list
		end
	end

	return {
		{ key = 'hat', label = 'Mũ', itemname = 'cloth_helmet', component = 0, prop = true },
		{ key = 'mask', label = 'Mặt nạ', itemname = 'cloth_mask', component = 1, prop = false },
		{ key = 'glasses', label = 'Kính', itemname = 'cloth_glasses', component = 1, prop = true },
		{ key = 'chain', label = 'Dây chuyền', itemname = 'cloth_chain', component = 7, prop = false },
		{ key = 'gloves', label = 'Găng tay', itemname = 'cloth_arms', component = 3, prop = false },
		{ key = 'torso', label = 'Áo khoác', itemname = 'cloth_torso', component = 11, prop = false },
		{ key = 'watch', label = 'Đồng hồ', itemname = 'cloth_watches', component = 6, prop = true },
		{ key = 'pants', label = 'Quần', itemname = 'cloth_pants', component = 4, prop = false },
		{ key = 'earrings', label = 'Khuyên tai', itemname = 'cloth_ears', component = 2, prop = true },
		{ key = 'bag', label = 'Túi xách', itemname = 'cloth_bags', component = 5, prop = false },
		{ key = 'shirt', label = 'Áo thun', itemname = 'cloth_tshirt', component = 8, prop = false },
		{ key = 'vest', label = 'Áo chống đạn', itemname = 'cloth_bproof', component = 9, prop = false },
		{ key = 'bracelets', label = 'Vòng tay', itemname = 'cloth_bracelets', component = 7, prop = true },
		{ key = 'shoes', label = 'Giày', itemname = 'cloth_shoes', component = 6, prop = false },
	}
end
