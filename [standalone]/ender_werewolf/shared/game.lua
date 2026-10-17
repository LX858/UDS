Game = {}

Game.Phases = {
	LOBBY = 'lobby',
	NIGHT = 'night',
	DAY = 'day',
	VOTING = 'voting',
	ENDED = 'ended',
}

Game.NightPhases = {
	WEREWOLF = 'werewolf',
	WITCH = 'witch',
	DOCTOR = 'doctor',
	SEER = 'seer',
}

Game.Roles = {
	WEREWOLF = 'werewolf',
	VILLAGER = 'villager',
	SEER = 'seer',
	DOCTOR = 'doctor',
	WITCH = 'witch',
	HUNTER = 'hunter',
}

Game.RoleInfo = {
	werewolf = {
		label = 'Ma Sói',
		team = 'werewolf',
		description = 'Ban đêm chọn một người để giết. Chiến thắng khi số Ma Sói bằng hoặc nhiều hơn dân làng.',
		color = '#ef4444',
		icon = 'wolf',
	},
	villager = {
		label = 'Dân Làng',
		team = 'villager',
		description = 'Ban ngày thảo luận và bỏ phiếu loại người nghi ngờ. Chiến thắng khi loại hết Ma Sói.',
		color = '#22c55e',
		icon = 'user',
	},
	seer = {
		label = 'Tiên Tri',
		team = 'villager',
		description = 'Ban đêm kiểm tra một người: Ma Sói hay Dân Làng.',
		color = '#a855f7',
		icon = 'eye',
	},
	doctor = {
		label = 'Bác Sĩ',
		team = 'villager',
		description = 'Ban đêm chọn một người để bảo vệ khỏi Ma Sói.',
		color = '#3b82f6',
		icon = 'heart',
	},
	witch = {
		label = 'Phù Thủy',
		team = 'villager',
		description = 'Có 1 lọ cứu và 1 lọ độc. Ban đêm có thể cứu nạn nhân Ma Sói hoặc đầu độc ai đó.',
		color = '#ec4899',
		icon = 'flask',
	},
	hunter = {
		label = 'Thợ Săn',
		team = 'villager',
		description = 'Khi bị loại, có thể bắn chết một người trước khi chết.',
		color = '#f97316',
		icon = 'crosshair',
	},
}

Game.TeamLabels = {
	werewolf = 'Phe Ma Sói',
	villager = 'Phe Dân Làng',
}

function Game.IsWerewolf(role)
	return role == Game.Roles.WEREWOLF
end

function Game.IsVillagerTeam(role)
	local info = Game.RoleInfo[role]
	return info and info.team == 'villager'
end

function Game.GetAlignment(role)
	if Game.IsWerewolf(role) then
		return 'werewolf'
	end
	return 'villager'
end
