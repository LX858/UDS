

Config = {}

Config.Framework = "qbcore"  -- types (standalone, qbcore, esx)

Config.ESXFramework = {
	newversion = true, -- use this if you using new esx version (if you get error with old esxsharedobjectmethod in console)
	getsharedobject = "esx:getSharedObject",
	resourcename = "es_extended"
}

Config.QBCoreFrameworkResourceName = "qb-core" -- qb-core resource name, change this if you have different name of main resource of qbcore

Config.InterfaceColor = "#ff66ff" -- change interface color, color must be in hex

Config.Language = "English" -- text language from code (English)

Config.Target = true -- enable this if you want use target

Config.Targettype = "oxtarget" -- types - qtarget, qbtarget, oxtarget 

Config.TargetSystemsNames = {qtarget = "qtarget", qbtarget = "qb-target", oxtarget = "ox_target"}

Config.TargetIcons = {djicon = "fa-solid fa-bars-progress"} 

Config.DjInteractionSystem = 1 -- 1 == Our custom interact system, 2 == 3D Text Interact, 3 == Gta V Online Interaction Style

Config.DjOpenKey = "E" -- key for open dj menu

Config.ForwardBackwardTime = 10 -- time in seconds for forward and backward button

Config.DjMenuMaxOpenDistance = 2.0 -- max distance for open menu

Config.InGameDjCreator = true -- enable this if you want to enable the ingame creator (configure perms in server/other.lua in CheckDjCreatorPermission function)

Config.InGameCreatorCommand = "djcreator" -- command for ingame creator

Config.IngameCreatorNoPermission = false -- require permissions for dj creator

Config.RequireBarJobForDj = true -- require bar job or admin permissions to open DJ tables

-- Jobs allowed to access DJ tables and DJ Creator
Config.AllowedBarJobs = {
	["bar"] = true,
	["barman"] = true,
	["vanilla"] = true,
	["nightclub"] = true,
	["tequilala"] = true,
	["galaxy"] = true,
	["bahama"] = true,
}

Config.StreamerModeCommand = "mutedj" -- command for disable music for example for streamers

Config.StreamerModeTriggerEvent = "rtx_dj:StreamerMode" -- trigger event for disable music for example for streamers - example TriggerEvent("rtx_dj:StreamerMode", true) for enable streamer mode

Config.DjLocations = {
	[1] = { 
		label = "SD BAR", -- name of dj location
		coords = vector3(411.6123, -333.7220, 50.8440), -- coords for open menu
		maxdistance = 100.0, -- max distance for sound
		soundtype = "linear", -- types - linear, quadratic, expo
		lights = {
			enabled = false, -- allow lights in club
			locations = {
				-- {handler = nil, handler2 = nil, coords = vector3(698.5024, 156.5504, 76.6523), rotation = vector3(13.91, 0.0, -160.36)},
				-- {handler = nil, handler2 = nil, coords = vector3(698.5024, 156.5504, 76.6523), rotation = vector3(10.50, 9.17, 158.92)},
			},
		},
		smoke = {
			enabled = false, -- allow smoke in club
			locations = {
				-- {handler = nil, handler2 = nil, coords = vector3(698.5024, 156.5504, 74.6523), rotation = vector3(0.0,0.0,-169.77)},
				-- {handler = nil, handler2 = nil, coords = vector3(698.5024, 156.5504, 74.6523), rotation = vector3(0.0,0.0,-169.77)},
			},
		},	
		lasers = {
			enabled = false, -- allow lasers in club
			locations = {
				-- {handler = nil, handler2 = nil, coords = vector3(698.5024, 156.5504, 75.6523), rotation = vector3(27.38,0.0,-178.06)},
			},
		},	
		particles = {
			enabled = false, -- allow particles in club
			locations = {
				-- {handler = nil, handler2 = nil, animdict = "weap_xs_vehicle_weapons", animname = "muz_xs_turret_flamethrower_looping", coords = vector3(698.5024, 156.5504, 75.6523), rotation = vector3(0.00,0.00,-154.47)},
				-- {handler = nil, handler2 = nil, animdict = "weap_xs_vehicle_weapons", animname = "muz_xs_turret_flamethrower_looping", coords = vector3(698.5024, 156.5504, 75.6523), rotation = vector3(0.00,0.00,167.91)},
			},
		},				
		permissions = {
			everyone = false, -- require bar job / permissions
			permissions = { -- permission type is ace, job, identifier
				{permissiontype = "job", permission = "bar"},
				{permissiontype = "job", permission = "barman"},
				{permissiontype = "job", permission = "vanilla"},
				{permissiontype = "job", permission = "nightclub"},
			},
		},
	},	
	-- [2] = {
	-- 	label = "MALIBU CLUB", -- name of dj location
	-- 	coords = vector3(-802.886, -1238.021, 6.223), -- coords for open menu
	-- 	maxdistance = 100.0, -- max distance for sound
	-- 	soundtype = "linear", -- types - linear, quadratic, expo
	-- 	lights = {
	-- 		enabled = true, -- allow lights in club
	-- 		locations = {
	-- 			{ handler = nil, handler2 = nil, coords = vector3(-807.445, -1239.013, 9.149), rotation = vector3(-0.82, 0.00, -156.12) },
	-- 			{ handler = nil, handler2 = nil, coords = vector3(-802.557, -1233.080, 9.289), rotation = vector3( 0.00, 0.00,  -94.54) },
	-- 		},
	-- 	},
	-- 	smoke = {
	-- 		enabled = true, -- allow smoke in club  
	-- 		locations = { 
	-- 			{ handler = nil, handler2 = nil, coords = vector3(-805.890, -1232.742, 4.236), rotation = vector3(0.00, 0.00, -134.38) },
	-- 			{ handler = nil, handler2 = nil, coords = vector3(-808.984, -1235.510, 5.144), rotation = vector3(0.00, 0.00, -135.86) },
	-- 			{ handler = nil, handler2 = nil, coords = vector3(-812.481, -1233.481, 5.144), rotation = vector3(0.00, 0.00, -135.86) },
	-- 			{ handler = nil, handler2 = nil, coords = vector3(-809.612, -1229.908, 5.147), rotation = vector3(0.00, 0.00, -112.19) },
	-- 		},
	-- 	},
	-- 	lasers = {
	-- 		enabled = true, -- allow lasers in club
	-- 		locations = {
	-- 			{ handler = nil, handler2 = nil, coords = vector3(-805.239,-1236.517,9.157), rotation = vector3(25.39,0.70,-129.63) },
	-- 		},
	-- 	},
	-- 	particles = {
	-- 		enabled = true,  -- allow particles in club
	-- 		locations = {
	-- 			{ handler = nil, handler2 = nil, animdict = "weap_xs_vehicle_weapons", animname = "muz_xs_turret_flamethrower_looping", coords = vector3(-804.239, -1234.820, 6.444), rotation = vector3(0.00, 0.00, -118.64) },
	-- 			{ handler = nil, handler2 = nil, animdict = "weap_xs_vehicle_weapons", animname = "muz_xs_turret_flamethrower_looping", coords = vector3(-807.868, -1239.205, 6.405), rotation = vector3(0.00, 0.00, -157.54) },
	-- 		},
	-- 	},
	-- 	permissions = {
	-- 		everyone = true, -- allow usage of dj menu to everyone
	-- 		permissions = {
	-- 			{permissiontype = "ace", permission = "club.access"},
	
	-- 		},
	-- 	},
	-- },

}

Config.DjLocationMarker = {
	enabled = false, -- enable this if you want display marker when player is nearby a dj location
	markerdistance = 25.0, -- minimum distance to see a marker.
	markertype = 1, 
	markercolor = {r = 255, g = 102, b = 255}, 
	markersize = {x = 1.5, y = 1.5, z = 1.0},
}

Config.DjSoundBoard = { -- sounds are located in html/sounds folder
    [1] = { 
        soundlabel = "Airhorn",
        soundpath  = "sounds/airhorn.mp3",
        soundicon  = "fas fa-bullhorn",
    },
    [2] = { 
        soundlabel = "Cheer",
        soundpath  = "sounds/cheer.mp3",
        soundicon  = "fas fa-users",
    },
    [3] = { 
        soundlabel = "Claps",
        soundpath  = "sounds/claps.mp3",
        soundicon  = "fas fa-hands-clapping",
    },
    [4] = { 
        soundlabel = "Explosion",
        soundpath  = "sounds/explosion.mp3",
        soundicon  = "fas fa-bomb",
    },
    [5] = { 
        soundlabel = "Let's Go!",
        soundpath  = "sounds/letsgo.mp3",
        soundicon  = "fas fa-fire",
    },
    [6] = { 
        soundlabel = "Rewind",
        soundpath  = "sounds/rewind.mp3",
        soundicon  = "fas fa-backward",
    },
    [7] = { 
        soundlabel = "Hands Up",
        soundpath  = "sounds/handsup.mp3",
        soundicon  = "fas fa-hand-paper",
    },
    [8] = { 
        soundlabel = "Scratch",
        soundpath  = "sounds/scratch.mp3",
        soundicon  = "fas fa-record-vinyl",
    },
}

function Notify(text)
	--exports["rtx_notify"]:Notify("DJ", text, 5000, "info") -- if you get error in this line its because you dont use our notify system buy it here https://rtx.tebex.io/package/5402098 or you can use some other notify system just replace this notify line with your notify system
	--exports["mythic_notify"]:SendAlert("inform", text, 5000)
	exports['qb-core']:GetCoreObject().Functions.Notify(text, 'info', 5000)
	--exports['okokNotify']:Alert("DJ", text, 5000, 'info')
end

function DrawText3D(x, y, z, text)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local px,py,pz=table.unpack(GetGameplayCamCoords()) 
	if onScreen then
		SetTextScale(0.35, 0.35)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 255)
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
        DrawText(_x,_y)
        local factor = (string.len(text)) / 240
		DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 255, 102, 255, 150)
	end
end

function AddTargetZone(targettype, targetnamedata, targettypedata, targetheading, targetdistance, targetlabel, targeticon, targetevent)
	if Config.Targettype == "qtarget" then
		if targettype == "coords" then
			local targetcoordsdata = vector3(targettypedata.x, targettypedata.y, targettypedata.z+0.5)
			exports[Config.TargetSystemsNames.qtarget]:AddBoxZone(targetnamedata, targetcoordsdata, 2.5, 2.5, {
				name = targetnamedata,
				heading = targetheading,
				debugPoly = false,
				minZ = targetcoordsdata.z-1.5,
				maxZ = targetcoordsdata.z+1.5,
				}, {
					options = {
						{
							event = targetevent,
							icon = targeticon,
							label = targetlabel
						},
					},
					distance = targetdistance
			})	
		else
			exports[Config.TargetSystemsNames.qtarget]:AddTargetModel({GetHashKey(targettypedata)}, {
				options = {
					{
						name = targetnamedata,
						event = targetevent,
						icon = targeticon,
						label = targetlabel,
					},
				},
				distance = targetdistance
			})		
		end
	elseif Config.Targettype == "qbtarget" then
		if targettype == "coords" then
			local targetcoordsdata = vector3(targettypedata.x, targettypedata.y, targettypedata.z+0.5)
			exports[Config.TargetSystemsNames.qbtarget]:AddBoxZone(targetnamedata, targetcoordsdata, 2.5, 2.5, {
				name = targetnamedata,
				heading = targetheading,
				debugPoly = false,
				minZ = targetcoordsdata.z-1.5,
				maxZ = targetcoordsdata.z+1.5,
			}, {
				options = {
					{
					  type = "client",
					  action = function(entity) 
						TriggerEvent(targetevent)
					  end,
					  icon = targeticon,
						  label = targetlabel,
						},
					},
				distance = targetdistance
			})	
		else
			exports[Config.TargetSystemsNames.qbtarget]:AddTargetModel({GetHashKey(targettypedata)}, {
				options = {
					{
						name = targetnamedata,
						event = targetevent,
						icon = targeticon,
						label = targetlabel,
					},
				},
				distance = targetdistance
			})				
		end
	elseif Config.Targettype == "oxtarget" then								
		if targettype == "coords" then
			local targetcoordsdata = vector3(targettypedata.x, targettypedata.y, targettypedata.z+0.5)
			exports[Config.TargetSystemsNames.oxtarget]:addBoxZone({
				coords = targetcoordsdata,
				size = vec3(2, 2, 2),
				rotation = targetheading,
				options = {
					{
						name = targetnamedata,
						event = targetevent,
						icon = targeticon,
						distance = targetdistance,
						label = targetlabel,
						canInteract = function(entity, distance, coords, name)
							return true
						end
					}
				}
			})	
		else
			exports[Config.TargetSystemsNames.oxtarget]:addModel(GetHashKey(targettypedata), {
				{
					name = targetnamedata,
					event = targetevent,
					icon = targeticon,
					label = targetlabel,
				}						
			})				
		end
	end
end