-- gravity           : downward acceleration of the green bar when not holding input
-- lift              : upward acceleration of the green bar when holding input
-- maxBarSpeed       : maximum speed green bar can move
-- fishMaxSpeed      : maximum speed of fish movement
-- fishAccel         : acceleration factor for fish movements / darts
-- fishDartChance    : chance per frame for fish to make a sudden dart
-- fillRate          : % increase in catch meter when fish is inside green bar
-- drainRate         : % decrease in catch meter when fish is outside green bar
-- bounceDamping     : multiplier applied when green bar hits bottom and bounces
-- stopThreshold     : velocity threshold to stop green bar after bouncing
-- startCatchPercent : initial % of catch meter filled
-- barHeightPercent  : height of the green bar in % of fish-box height

config = {
    global = {
        gravity = -0.10,
        lift = 0.1,
        maxBarSpeed = 2,
        bounceDamping = 0.85,
        stopThreshold = 0.05,
        startCatchPercent = 20,
        fillRate = 0.12,    -- global now
        drainRate = 0.08,    -- global now
        barHeightPercent = 25,      
    },

    difficulties = {
        easy = {
            fishMaxSpeed = 1.2,
            fishAccel = 0.08,
            fishDartChance = 0.01,
            barHeightPercent = 20,  -- Thanh green bar cao hơn để dễ dàng hơn
            fillRate = 0.18         -- Tăng catch meter nhanh hơn khi dễ
        },
        medium = {
            fishMaxSpeed = 2.0,
            fishAccel = 0.1,
            fishDartChance = 0.03,
            barHeightPercent = 18,  -- Chiều cao tiêu chuẩn
            fillRate = 0.12         -- Tốc độ tăng tiêu chuẩn
        },
        hard = {
            fishMaxSpeed = 2.8,
            fishAccel = 0.15,
            fishDartChance = 0.05,
            maxBarSpeed = 2.4,
            lift = 0.12,
            gravity = -0.12,
            barHeightPercent = 16,  -- Thanh green bar thấp hơn để khó khăn hơn
            fillRate = 0.08,        -- Tăng catch meter chậm hơn khi khó
            fishSineAmpMax = 0.4    -- Giảm dao động triều ở hard
        },
        veryhard = {
            fishMaxSpeed = 3.5,
            fishAccel = 0.2,
            fishDartChance = 0.08,
            maxBarSpeed = 2.8,
            lift = 0.14,
            gravity = -0.14,
            barHeightPercent = 14,  -- Thanh green bar thấp hơn để khó khăn hơn
            fillRate = 0.05,        -- Tăng catch meter rất chậm khi rất khó
            fishSineAmpMax = 0.25   -- Giảm mạnh dao động triều ở veryhard
        }
    },
}
