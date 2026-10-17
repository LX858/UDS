
local db = setmetatable({},{
	__call = function(self)

		self.insert = function(...)
			local str = 'INSERT INTO %s (%s, %s, %s, %s, %s, %s) VALUES(?, ?, ?, ?, ?, ?)'
			return MySQL.insert.await(str:format('renzu_motels','motel','hour_rate','revenue','employees','rooms','owned'),{...})
		end

		self.update = function(column, where, string, data)
			local str = 'UPDATE %s SET %s WHERE %s = ?'
			return MySQL.update(str:format('renzu_motels',column,where),{data,string})
		end

		self.updateall = function(pattern, where, string, ...)
			local str = 'UPDATE %s SET % WHERE %s = ?'
			local str = 'UPDATE renzu_motels SET '..pattern..' WHERE '..where..' = ?'
			local data = {...}
			table.insert(data,string)
			return MySQL.update(str,data)
		end

		self.query = function(column, where, string)
			local str = 'SELECT %s FROM %s WHERE %s = ?'
			return MySQL.query.await(str:format(column,'renzu_motels',where),{string})
		end

		self.fetchAll = function()
			local str = 'SELECT * FROM renzu_motels'
			local query = MySQL.query.await(str)
			local data = {}
			for k,v in pairs(query) do
				for column, value in pairs(v) do
					if v.motel then
						if column ~= 'id' and value then
							if not data[column] then data[column] = {} end
							local success, result = pcall(json.decode, value)
							result = result == nil and value or result
							if not data[v.motel] then data[v.motel] = {} end
							if column == 'owned' and result == 0 then result = nil end
							if column == 'hour_rate' and result == 0 then result = nil end
							data[v.motel][column] = result
						end
					end
				end
			end
			return data
		end

		return self
	end
})

-- =============================================
-- motel_hethan: Lưu đồ bị tịch thu khi hết hạn
-- =============================================
db.insertConfiscated = function(identifier, citizenid, pid, motel, room, items)
	return MySQL.insert.await(
		'INSERT INTO `motel_hethan` (`identifier`, `citizenid`, `pid`, `motel`, `room`, `items`, `confiscated_at`) VALUES (?, ?, ?, ?, ?, ?, ?)',
		{identifier, citizenid, tostring(pid), motel, tostring(room), json.encode(items), os.time()}
	)
end

db.getConfiscated = function(identifier)
	return MySQL.query.await('SELECT * FROM `motel_hethan` WHERE `identifier` = ? ORDER BY `confiscated_at` DESC', {identifier})
end

db.deleteConfiscated = function(id)
	return MySQL.query.await('DELETE FROM `motel_hethan` WHERE `id` = ?', {id})
end

-- =============================================
-- motel_ped: Lưu ped tùy chỉnh của player
-- =============================================
db.getPed = function(citizenid)
	local result = MySQL.query.await('SELECT * FROM `motel_ped` WHERE `citizenid` = ?', {citizenid})
	return result and result[1] or nil
end

db.savePed = function(citizenid, pedModel, comps, texs)
	return MySQL.query.await([[
		INSERT INTO `motel_ped`
			(`citizenid`, `ped_model`,
			 `comp0`,`comp1`,`comp2`,`comp3`,`comp4`,`comp5`,
			 `comp6`,`comp7`,`comp8`,`comp9`,`comp10`,`comp11`,
			 `tex0`,`tex1`,`tex2`,`tex3`,`tex4`,`tex5`,
			 `tex6`,`tex7`,`tex8`,`tex9`,`tex10`,`tex11`,
			 `updated_at`)
		VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
		ON DUPLICATE KEY UPDATE
			`ped_model`  = VALUES(`ped_model`),
			`comp0`=VALUES(`comp0`),`comp1`=VALUES(`comp1`),`comp2`=VALUES(`comp2`),
			`comp3`=VALUES(`comp3`),`comp4`=VALUES(`comp4`),`comp5`=VALUES(`comp5`),
			`comp6`=VALUES(`comp6`),`comp7`=VALUES(`comp7`),`comp8`=VALUES(`comp8`),
			`comp9`=VALUES(`comp9`),`comp10`=VALUES(`comp10`),`comp11`=VALUES(`comp11`),
			`tex0`=VALUES(`tex0`),`tex1`=VALUES(`tex1`),`tex2`=VALUES(`tex2`),
			`tex3`=VALUES(`tex3`),`tex4`=VALUES(`tex4`),`tex5`=VALUES(`tex5`),
			`tex6`=VALUES(`tex6`),`tex7`=VALUES(`tex7`),`tex8`=VALUES(`tex8`),
			`tex9`=VALUES(`tex9`),`tex10`=VALUES(`tex10`),`tex11`=VALUES(`tex11`),
			`updated_at`=VALUES(`updated_at`)
	]], {
		citizenid, pedModel,
		comps[0] or 0, comps[1] or 0, comps[2] or 0, comps[3] or 0,
		comps[4] or 0, comps[5] or 0, comps[6] or 0, comps[7] or 0,
		comps[8] or 0, comps[9] or 0, comps[10] or 0, comps[11] or 0,
		texs[0] or 0, texs[1] or 0, texs[2] or 0, texs[3] or 0,
		texs[4] or 0, texs[5] or 0, texs[6] or 0, texs[7] or 0,
		texs[8] or 0, texs[9] or 0, texs[10] or 0, texs[11] or 0,
		os.time()
	})
end

db.deletePed = function(citizenid)
	return MySQL.query.await('DELETE FROM `motel_ped` WHERE `citizenid` = ?', {citizenid})
end

Citizen.CreateThreadNow(function()
	local success, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM renzu_motels')
	if not success then
		MySQL.query.await([[CREATE TABLE `renzu_motels` (
			`id` int NOT NULL AUTO_INCREMENT KEY,
			`motel` varchar(64) DEFAULT NULL,
			`hour_rate` int DEFAULT 0,
			`revenue` int DEFAULT 0,
			`employees` longtext DEFAULT NULL,
			`rooms` longtext DEFAULT NULL,
			`owned` varchar(64) DEFAULT NULL
		)]])
		print("^2SQL INSTALL SUCCESSFULLY ^0")
	end
	pcall(MySQL.query.await, 'ALTER TABLE renzu_motels ADD COLUMN `additional_premium` INT DEFAULT 10')
	-- Tạo bảng motel_hethan nếu chưa có
	local ok2 = pcall(MySQL.scalar.await, 'SELECT 1 FROM motel_hethan')
	if not ok2 then
		MySQL.query.await([[CREATE TABLE `motel_hethan` (
			`id` int NOT NULL AUTO_INCREMENT KEY,
			`identifier` varchar(64) NOT NULL,
			`citizenid` varchar(64) DEFAULT NULL,
			`pid` varchar(32) DEFAULT NULL,
			`motel` varchar(64) DEFAULT NULL,
			`room` varchar(16) DEFAULT NULL,
			`items` longtext DEFAULT NULL,
			`confiscated_at` int DEFAULT 0
		)]])
		print("^2SQL motel_hethan INSTALL SUCCESSFULLY ^0")
	end
	-- Tạo bảng motel_ped nếu chưa có
	local ok3 = pcall(MySQL.scalar.await, 'SELECT 1 FROM motel_ped')
	if not ok3 then
		MySQL.query.await([[CREATE TABLE `motel_ped` (
			`id` int NOT NULL AUTO_INCREMENT KEY,
			`citizenid` varchar(64) NOT NULL UNIQUE,
			`ped_model` varchar(128) DEFAULT NULL,
			`comp0` int DEFAULT 0,
			`comp1` int DEFAULT 0,
			`comp2` int DEFAULT 0,
			`comp3` int DEFAULT 0,
			`comp4` int DEFAULT 0,
			`comp5` int DEFAULT 0,
			`comp6` int DEFAULT 0,
			`comp7` int DEFAULT 0,
			`comp8` int DEFAULT 0,
			`comp9` int DEFAULT 0,
			`comp10` int DEFAULT 0,
			`comp11` int DEFAULT 0,
			`tex0` int DEFAULT 0,
			`tex1` int DEFAULT 0,
			`tex2` int DEFAULT 0,
			`tex3` int DEFAULT 0,
			`tex4` int DEFAULT 0,
			`tex5` int DEFAULT 0,
			`tex6` int DEFAULT 0,
			`tex7` int DEFAULT 0,
			`tex8` int DEFAULT 0,
			`tex9` int DEFAULT 0,
			`tex10` int DEFAULT 0,
			`tex11` int DEFAULT 0,
			`updated_at` int DEFAULT 0
		)]])
		print("^2SQL motel_ped INSTALL SUCCESSFULLY ^0")
	end
	Wait(500)
	for k,v in pairs(config.motels) do
		local query = MySQL.query.await('SELECT rooms FROM renzu_motels WHERE `motel` = ?',{v.motel})
		if not query[1] then
			local doors = {}
			for doorindex,_ in pairs(v.doors) do
				if not doors.rooms then doors.rooms = {} end
				if not doors.rooms[doorindex] then doors.rooms[doorindex] = {} end
				if not doors.rooms[doorindex].players then doors.rooms[doorindex].players = {} end
				doors.rooms[doorindex].lock = true
			end
			db.insert(v.motel,0,0,'[]',json.encode(doors.rooms),0)
		elseif query[1] and #v.doors > #json.decode(query[1].rooms) then
			local addnew = (#v.doors - #json.decode(query[1].rooms))
			local rooms = json.decode(query[1].rooms) or {}
			for i = 1, addnew do
				table.insert(rooms,{players = {}, lock = true})
			end
			db.updateall('rooms = ?', '`motel`', v.motel, json.encode(rooms))
		end
	end
end)

return db()