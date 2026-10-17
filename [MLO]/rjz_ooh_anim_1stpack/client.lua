Citizen.CreateThread(function()
    for iplName, state in pairs(rjz_ooh_anim_1stpack) do
        if state then
            RequestIpl(iplName)
        else
            RemoveIpl(iplName)
        end
    end
end)

rjz_ooh_anim_1stpack = {
    ['rjz_ooh_anim_001'] = true,
	['rjz_ooh_anim_001_lod'] = true,
	-- (-1015.03, -752.57, 46.87)
	
    ['rjz_ooh_anim_002'] = true,
	['rjz_ooh_anim_002_lod'] = true,
	-- (-798.76, -599.74, 61.79)
	
	['rjz_ooh_anim_003'] = true,
	['rjz_ooh_anim_003_lod'] = true,
	-- (-600.93, 50.17, 78.43)
	
	['rjz_ooh_anim_004'] = true,
	['rjz_ooh_anim_004_lod'] = true,
	-- (335.88, -1640.11, 64.59)
	
	['rjz_ooh_anim_005'] = true,
	['rjz_ooh_anim_005_lod'] = true,
	-- (133.29, -640.95, 153.31)
	
	['rjz_ooh_anim_006'] = true,
	['rjz_ooh_anim_006_lod'] = true,
	-- (-225.43, -835.59, 78.26)
	
	['rjz_ooh_anim_007'] = true,
	['rjz_ooh_anim_007_lod'] = true,
	-- (-148.41, -601.07, 135.57)
	
	['rjz_ooh_anim_008'] = true,
	['rjz_ooh_anim_008_lod'] = true,
	-- (472.05, -101.78, 100.66)
	
	['rjz_ooh_anim_009'] = true,
	['rjz_ooh_anim_009_lod'] = true,
	-- (-1568.48, -570.79, 74.90)
	
	['rjz_ooh_anim_010'] = true,
	-- models spread across "PALETO BAY"
}