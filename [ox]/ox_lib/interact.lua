--[[
    ox_lib interaction points (NoPixel V style "[E] LABEL" prompts in the world)

    Colours come from theme.lua: text (label), key and keyText (the [E] badge).
    Sizes are in pixels on a 1080p screen and scale with the resolution.
]]

return {
    enabled = true,

    key = 'E',              -- letter shown on the badge
    control = 38,           -- the control that uses the option (38 = E / INPUT_PICKUP)
    uppercase = true,       -- write labels in capitals

    textSize = 13,          -- height of the label capitals
    keySize = 20,           -- size of the [E] badge
    dotSize = 15,           -- ring shown on points you can walk up to
    rowSpacing = 24,        -- space between options when a point has several
    dimmedAlpha = 140,      -- how visible the non-selected options are (0 - 255)
    shadow = true,          -- dark shadow behind labels so they read on bright walls

    crosshair = true,       -- small dot in the middle of the screen while points are near
    hoverRadius = 0.06,     -- how close to the middle of the screen a point must be to select it

    -- How close you must be to see a point's ring, and then to get the [E]
    -- prompt and be able to press it. These are the fallback for any point that
    -- does not set its own `distance` / `interactDst`.
    --
    -- They were 1.0 and 0.4, which meant a ring only inside one metre and the
    -- prompt only inside forty centimetres -- close enough that you had to be
    -- standing on a point to see anything, which is why points looked like they
    -- were not working.
    defaultDistance = 2.5,
    defaultInteractDst = 1.2,

    -- Use the new [E] prompt on the whole server.
    -- Every script that shows an "E" prompt through ox_lib's TextUI (ESX.TextUI and
    -- ESX.ShowHelpNotification on this server, ox_inventory, fs-banking, prp-police, ...)
    -- gets drawn as a NoPixel V "[E] LABEL" prompt in the world instead of the text box.
    -- The script itself still handles the key press, nothing else changes.
    -- Text without a key in it ("You are in a safe zone") keeps the normal TextUI.
    replaceTextUI = {
        -- Off. Prompts that belong to a place are registered at that place with
        -- lib.addInteraction, which draws them on the exact coordinate and never
        -- moves them. Turning this on instead makes ox_lib guess a position for
        -- every prompt from where the player happens to be standing and looking,
        -- and a guess is different on every visit.
        enabled = false,
        -- 'world'  = the prompt stays where you were standing when it appeared (NoPixel style);
        --            it moves with you if you walk away or it leaves the screen.
        -- 'player' = the prompt always floats next to your character.
        anchor = 'world',
        -- true = shows a ring like other interaction points; the [E] prompt appears when you
        -- look at the ring, and E only works then. false = the prompt is always shown.
        requireLook = true,
        -- How close to the middle of the screen the ring must be to count as looking at it.
        hoverRadius = 0.06,
        -- Words between the key and the action that are dropped from the label,
        -- so "Press [E] to open garage" becomes "[E] OPEN GARAGE".
        connectors = { 'to', 'pour', 'om', 'hogy', 'para', 'per', 'um', 'zum', 'zur', 'aby', 'чтобы' },
    },

    -- Hide all points while...
    disable = {
        dead = true,
        nuiFocus = true,    -- a menu / phone / inventory has the cursor
        inVehicle = true,
        cuffed = true,
    },
}
