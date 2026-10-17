if not QBCORE then return end

-- Function to get player by server source ID
GetPlayerFromId = function(src)
	local self = QBCORE.Functions.GetPlayer(src)
	if not self then return end
	
	if self.identifier == nil then
		self.identifier = self.PlayerData.citizenid
	end

	self.getMoney = function(value)
		return self.PlayerData.money['cash']
	end

	self.removeMoney = function(value)
		self.Functions.RemoveMoney('cash',tonumber(value))
		return true
	end
	if self.PlayerData and self.PlayerData.charinfo then
		self.name = self.PlayerData.charinfo.firstname .. " " .. self.PlayerData.charinfo.lastname
	else
		self.name = 'Unknown'
	end

	self.addMoney = function(value)
		return self.Functions.AddMoney('cash',tonumber(value))
	end

	self.removeAccountMoney = function(type,val)
		if type == 'money' then type = 'cash' end
		self.Functions.RemoveMoney(type,tonumber(val))
		return true
	end

	self.getAccount = function(type)
		if type == 'money' then type = 'cash' end
		return {money = self.PlayerData.money[type]}
	end

	return self
end

-- Function to get player by PID (Player ID number)
GetPlayerFromPid = function(pid)
	if not pid then return nil end
	local numPid = tonumber(pid)
	if not numPid then return nil end

	-- 1. Direct O(1) lookup via qbx_core if available
	if exports.qbx_core and exports.qbx_core.GetPlayerByPid then
		local qbxPlayer = exports.qbx_core:GetPlayerByPid(numPid)
		if qbxPlayer and qbxPlayer.PlayerData and qbxPlayer.PlayerData.source then
			return GetPlayerFromId(qbxPlayer.PlayerData.source)
		end
	end

	-- 2. Direct lookup if PID is passed as server source directly
	local directPlayer = QBCORE.Functions.GetPlayer(numPid)
	if directPlayer and directPlayer.PlayerData and directPlayer.PlayerData.pid == numPid then
		return GetPlayerFromId(numPid)
	end

	-- 3. Fallback search only if direct lookup didn't match
	local Players = QBCORE.Functions.GetQBPlayers and QBCORE.Functions.GetQBPlayers()
	if Players then
		for src, Player in pairs(Players) do
			if Player.PlayerData and Player.PlayerData.pid == numPid then
				return GetPlayerFromId(src)
			end
		end
	end

	return nil
end