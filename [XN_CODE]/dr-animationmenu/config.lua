AK4Y = {}

AK4Y.MenuKey = "F3"         -- Key to open the menu.
AK4Y.Language = "vi"        -- Menu language. You can add your own translations in the `Languages` table.

-- AK4Y.MaxDistancesForPreview = { -- Maximum distances for the preview character.
-- 	[0] = 5.0,          -- CAMERA VIEW - THIRD PERSON CLOSE
-- 	[1] = 7.5,          -- CAMERA VIEW - THIRD PERSON MEDIUM RANGE
-- 	[2] = 10.0,         -- CAMERA VIEW - THIRD PERSON FAR
-- 	[3] = 0.0,          -- CAMERA VIEW - CINEMATIC MODE
-- 	[4] = 4.0           -- CAMERA VIEW - FIRST PERSON
-- }

AK4Y.MaxDistancesForPreview = { -- Maximum distances for the preview character.
	[0] = 0.0,          -- CAMERA VIEW - THIRD PERSON CLOSE
	[1] = 0.0,          -- CAMERA VIEW - THIRD PERSON MEDIUM RANGE
	[2] = 0.0,         -- CAMERA VIEW - THIRD PERSON FAR
	[3] = 0.0,          -- CAMERA VIEW - CINEMATIC MODE
	[4] = 0.0           -- CAMERA VIEW - FIRST PERSON
}

AK4Y.MaxDistanceForSharedEmotes = 0.7 -- Maximum distance for shared emotes. If players are farther apart than this, they can't send invites.
AK4Y.AllowedInCars = false       -- If true, players can use emotes while in a vehicle.

AK4Y.Notify = function(msg, title, type)
	TriggerEvent("QBCore:Notify", msg, type == "info" and "primary" or type, 5000)
end

AK4Y.ShortcutKey = 21  -- Key to use the saved animation. (21 = SHIFT)
AK4Y.CrouchKey = "LCONTROL" -- Key to toggle the crouch animation. (LCONTROL)
AK4Y.CancelKey = "X"   -- Key to cancel the current animation. (X)
AK4Y.CancelCooldown = 3000 -- Cooldown in milliseconds for cancel key (3000ms = 3 seconds)
AK4Y.EmoteCooldownDuration = 3000 -- Cooldown in milliseconds for animations with cowdown: true (3000ms = 3 seconds)
AK4Y.CancelHandsUp = true -- If true, the player raises their hands if there’s no animation to cancel.
AK4Y.PointKey = "B"    -- Key to toggle the pointing animation. (B)
AK4Y.RagdollKey = false -- Key to toggle the ragdoll animation. (Set to false to disable)
AK4Y.AnimationAcceptKey = "Y" -- Key to accept the invite.
AK4Y.AnimationDeclineKey = "N" -- Key to decline the invite.

-- Danh sách các khu vực cấm sử dụng emote dưới mọi hình thức (sử dụng lib.zones)
AK4Y.ForbiddenZones = {
	{
		type = 'sphere',
		coords = vec3(4434.44, -4509.54, 3.18),
		radius = 150.0,
		debug = false,
	},
	{
		type = 'sphere',
		coords = vec3(-5284.4434, 2680.2986, 247.8109),
		radius = 150.0,
		debug = false,
	},
}