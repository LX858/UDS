local inSkillCheck
local result
RegisterCommand("game", function()
    gameCheck('normal',6)
	-- TriggerEvent('no_quest:action','rice',2)
	-- TriggerEvent('no_quest:action','fixlight',2)
	-- TriggerEvent('no_quest:action','fixcar',3)
	-- TriggerEvent('no_quest:action','steel_scrap',4)
	-- TriggerEvent('no_quest:action','tn_wood',4)
	-- TriggerEvent('no_quest:action','tn_cabbage',4)
	-- TriggerEvent('no_quest:action','chrome_stone',4)
	-- TriggerEvent('no_quest:action','orange',4)
	-- TriggerEvent('no_quest:action','copper_scrap',4)
	-- TriggerEvent('no_quest:action','tn_mushroom',4)

	
end)

-- local Result = exports["no_wasd"]:gameCheck("normal",4)

function startGame(difficulty,lenght)

	-- print(difficulty)
	SetNuiFocus(true, false)
	SendNUIMessage({
        data = "start", 
        difficulty = difficulty,
        lenght = lenght
    })
end

RegisterNUICallback('result', function(data, cb)
    -- print(data.result)
	Wait(800)
    SetNuiFocus(false, false)
	result = data.result
	inSkillCheck = false
end)

function gameCheck(difficulty,lenght)
	if inSkillCheck then return end
	inSkillCheck = true
	startGame(difficulty,lenght)
	while inSkillCheck do
		Citizen.Wait(2)
	end
	
	Citizen.Wait(100)
    SetNuiFocus(false, false)
	return result
end