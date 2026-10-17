BackEngineVehicles = {
    [`ninef`] = true,
    [`adder`] = true,
    [`vagner`] = true,
    [`t20`] = true,
    [`infernus`] = true,
    [`zentorno`] = true,
    [`reaper`] = true,
    [`comet2`] = true,
    [`jester`] = true,
    [`jester2`] = true,
    [`cheetah`] = true,
    [`cheetah2`] = true,
    [`prototipo`] = true,
    [`turismor`] = true,
    [`pfister811`] = true,
    [`ardent`] = true,
    [`nero`] = true,
    [`nero2`] = true,
    [`tempesta`] = true,
    [`vacca`] = true,
    [`bullet`] = true,
    [`osiris`] = true,
    [`entityxf`] = true,
    [`turismo2`] = true,
    [`fmj`] = true,
    [`re7b`] = true,
    [`tyrus`] = true,
    [`italigtb`] = true,
    [`penetrator`] = true,
    [`monroe`] = true,
    [`ninef2`] = true,
    [`stingergt`] = true,
    [`surfer`] = true,
    [`surfer2`] = true,
    [`comet3`] = true,
}

-- Configuration:

-- IMPORTANT: Some of these values MUST be defined as a floating point number. ie. 10.0 instead of 10
    Config              = {}
    Config.Paid = true
    Config.Price = 750

cfg = {
    deformationMultiplier = -1,           -- Giữ nguyên, không chỉnh
    deformationExponent = 0.5,
    collisionDamageExponent = 0.5,

damageFactorEngine = 18.0,					-- Sane values are 1 to 100. Higher values means more damage to vehicle. A good starting point is 10
	damageFactorBody = 10.0,					-- Sane values are 1 to 100. Higher values means more damage to vehicle. A good starting point is 10
	damageFactorPetrolTank = 55.0,				-- Sane values are 1 to 200. Higher values means more damage to vehicle. A good starting point is 64
	engineDamageExponent = 1,					-- How much should the handling file engine damage setting be compressed toward 1.0. (Make cars more similar). A value of 1=no change. Lower values will compress more, values above 1 it will expand. Dont set to zero or negative.
	weaponsDamageMultiplier = 1.2,				-- How much damage should the vehicle get from weapons fire. Range 0.0 to 10.0, where 0.0 is no damage and 10.0 is 10x damage. -1 = don't touch

    degradingHealthSpeedFactor = 0,        -- 0 = Không tự tụt máu theo thời gian
    cascadingFailureSpeedFactor = 0,       -- 0 = Không tụt máu nhanh khi dưới ngưỡng

    degradingFailureThreshold = 0.0,       -- Không kích hoạt degrade
    cascadingFailureThreshold = 0.0,       -- Không kích hoạt cascade
    engineSafeGuard = 20.0,

    torqueMultiplierEnabled = true,

    limpMode = false,
    limpModeMultiplier = 0.15,

    preventVehicleFlip = false,

    sundayDriver = false,
    sundayDriverAcceleratorCurve = 7.5,
    sundayDriverBrakeCurve = 5.0,

    displayBlips = false,
    compatibilityMode = false,

    randomTireBurstInterval = 0,

	classDamageMultiplier = {
		[0] = 	0.15,		--	0: Compacts
				0.15,		--	1: Sedans
				0.15,		--	2: SUVs
				0.15,		--	3: Coupes
				0.15,		--	4: Muscle
				0.15,		--	5: Sports Classics
				0.15,		--	6: Sports
				0.15,		--	7: Super
				0.15,		--	8: Motorcycles
				0.15,		--	9: Off-road
				0.15,		--	10: Industrial
				0.15,		--	11: Utility
				0.15,		--	12: Vans
				0.15,		--	13: Cycles
				0.15,		--	14: Boats
				0.15,		--	15: Helicopters
				0.15,		--	16: Planes
				0.15,		--	17: Service
				0.15,		--	18: Emergency
				0.15,		--	19: Military
				0.15,		--	20: Commercial
				0.15			--	21: Trains
    }
}


repairCfg = {
    mechanics = {
        {name='Garage', id=446, r=25.0, x=-337.0,  y=-135.0,  z=39.0},	-- LSC Burton
        {name='Garage', id=446, r=25.0, x=-1155.0, y=-2007.0, z=13.0},	-- LSC by airport
        {name='Garage', id=446, r=25.0, x=734.0,   y=-1085.0, z=22.0},	-- LSC La Mesa
        {name='Garage', id=446, r=25.0, x=1177.0,  y=2640.0,  z=37.0},	-- LSC Harmony
        {name='Garage', id=446, r=25.0, x=108.0,   y=6624.0,  z=31.0},	-- LSC Paleto Bay
        {name='Garage', id=446, r=18.0, x=538.0,   y=-183.0,  z=54.0},	-- Mechanic Hawic
        {name='Garage', id=446, r=15.0, x=1774.0,  y=3333.0,  z=41.0},	-- Mechanic Sandy Shores Airfield
        {name='Garage', id=446, r=15.0, x=1143.0,  y=-776.0,  z=57.0},	-- Mechanic Mirror Park
        {name='Garage', id=446, r=30.0, x=2508.0,  y=4103.0,  z=38.0},	-- Mechanic East Joshua Rd.
        {name='Garage', id=446, r=16.0, x=2006.0,  y=3792.0,  z=32.0},	-- Mechanic Sandy Shores gas station
        {name='Garage', id=446, r=25.0, x=484.0,   y=-1316.0, z=29.0},	-- Hayes Auto, Little Bighorn Ave.
        {name='Garage', id=446, r=33.0, x=-1419.0, y=-450.0,  z=36.0},	-- Hayes Auto Body Shop, Del Perro
        {name='Garage', id=446, r=33.0, x=268.0,   y=-1810.0, z=27.0},	-- Hayes Auto Body Shop, Davis
    --	{name='Mechanic', id=446, r=24.0, x=288.0,   y=-1730.0, z=29.0},	-- Hayes Auto, Rancho (Disabled, looks like a warehouse for the Davis branch)
        {name='Garage', id=446, r=27.0, x=1915.0,  y=3729.0,  z=32.0},	-- Otto's Auto Parts, Sandy Shores
        {name='Garage', id=446, r=45.0, x=-29.0,   y=-1665.0, z=29.0},	-- Mosley Auto Service, Strawberry
        {name='Garage', id=446, r=44.0, x=-212.0,  y=-1378.0, z=31.0},	-- Glass Heroes, Strawberry
        {name='Garage', id=446, r=33.0, x=258.0,   y=2594.0,  z=44.0},	-- Mechanic Harmony
        {name='Garage', id=446, r=18.0, x=-32.0,   y=-1090.0, z=26.0},	-- Simeons
        --{name='Garage', id=446, r=25.0, x=-211.0,  y=-1325.0, z=31.0},	-- Bennys
        {name='Garage', id=446, r=25.0, x=903.0,   y=3563.0,  z=34.0},	-- Auto Repair, Grand Senora Desert
        {name='Garage', id=446, r=25.0, x=437.0,   y=3568.0,  z=38.0}		-- Auto Shop, Grand Senora Desert
    },

    fixMessageCount = 7,
    noFixMessageCount = 6
}
