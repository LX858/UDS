Keys = {
	["ESC"] = 322,
	["F1"] = 288,
	["F2"] = 289,
	["F3"] = 170,
	["F5"] = 166,
	["F6"] = 167,
	["F7"] = 168,
	["F8"] = 169,
	["F9"] = 56,
	["F10"] = 57,
	["~"] = 243,
	["1"] = 157,
	["2"] = 158,
	["3"] = 160,
	["4"] = 164,
	["5"] = 165,
	["6"] = 159,
	["7"] = 161,
	["8"] = 162,
	["9"] = 163,
	["-"] = 84,
	["="] = 83,
	["BACKSPACE"] = 177,
	["TAB"] = 37,
	["Q"] = 44,
	["W"] = 32,
	["E"] = 38,
	["R"] = 45,
	["T"] = 245,
	["Y"] = 246,
	["U"] = 303,
	["P"] = 199,
	["["] = 39,
	["]"] = 40,
	["ENTER"] = 18,
	["CAPS"] = 137,
	["A"] = 34,
	["S"] = 8,
	["D"] = 9,
	["F"] = 23,
	["G"] = 47,
	["H"] = 74,
	["K"] = 311,
	["L"] = 182,
	["LEFTSHIFT"] = 21,
	["Z"] = 20,
	["X"] = 73,
	["C"] = 26,
	["V"] = 0,
	["B"] = 29,
	["N"] = 249,
	["M"] = 244,
	[","] = 82,
	["."] = 81,
	["LEFTCTRL"] = 36,
	["LEFTALT"] = 19,
	["SPACE"] = 22,
	["RIGHTCTRL"] = 70,
	["HOME"] = 213,
	["PAGEUP"] = 10,
	["PAGEDOWN"] = 11,
	["DELETE"] = 178,
	["LEFT"] = 174,
	["RIGHT"] = 175,
	["TOP"] = 27,
	["DOWN"] = 173,
	["NENTER"] = 201,
	["N4"] = 108,
	["N5"] = 60,
	["N6"] = 107,
	["N+"] = 96,
	["N-"] = 97,
	["N7"] = 117,
	["N8"] = 61,
	["N9"] = 118
}

--- A simple wrapper around SendNUIMessage that you can use to
--- dispatch actions to the React frame.
---
---@param action string The action you wish to target
---@param data any The data you wish to send along with this action
function SendReactMessage(action, data)
	SendNUIMessage({
		action = action,
		data = data
	})
end

local currentResourceName = GetCurrentResourceName()

local debugIsEnabled = GetConvarInt(('%s-debugMode'):format(currentResourceName), 0) == 1

--- A simple debug print function that is dependent on a convar
--- will output a nice prettfied message if debugMode is on
function debugPrint(...)
	if not debugIsEnabled then return end
	local args <const> = { ... }

	local appendStr = ''
	for _, v in ipairs(args) do
		appendStr = appendStr .. ' ' .. tostring(v)
	end
	local msgTemplate = '^3[%s]^0%s'
	local finalMsg = msgTemplate:format(currentResourceName, appendStr)
	print(finalMsg)
end

function CreateBlip(coord, name, sprite, scale, color, display)
	local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
	SetBlipSprite(blip, sprite)
	SetBlipDisplay(blip, display or 2)
	SetBlipScale(blip, scale)
	SetBlipColour(blip, color)
	SetBlipAsShortRange(blip, true)
	SetBlipHighDetail(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(name)
	EndTextCommandSetBlipName(blip)
	return blip
end

function CreateBlipRadius(coord, radius, colour, alpha, display)
	local blip = AddBlipForRadius(coord.x, coord.y, coord.z, radius)
	SetBlipHighDetail(blip, true)
	SetBlipColour(blip, colour)
	SetBlipAlpha(blip, alpha)
	SetBlipDisplay(blip, display or 2)
	return blip
end

function ConvertObjectToArray(objectTable)
	local arrayTable = {}
	for key, value in pairs(objectTable) do
		arrayTable[#arrayTable + 1] = value
	end
	return arrayTable
end

function ProgressBar(data)
	if not data then return end
	local duration = data.duration or 5000
	if type(duration) == 'table' then
		duration = math.random(duration[1], duration[2])
	end

	local success = lib.progressBar(
		{
			label = data.label,
			duration = duration,
			position = data.position or 'bottom',
			useWhileDead = data.useWhileDead,
			canCancel = data.canCancel,
			disable = data.disable,
			anim = data.anim or nil,
			prop = data.prop or nil,
		}
	)
	return success
end
