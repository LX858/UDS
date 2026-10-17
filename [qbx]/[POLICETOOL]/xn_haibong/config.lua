Config = {}

Config.Farms = {
    ['haibong'] = {
        Label = 'Thu hoạch bông',
        ProcessLabel = 'Chế biến bông',
        Job = 'ambulance', -- Yêu cầu job ambulance
        Scissors = 'keo',
        Weed = 'bonggon',
        RewardWeed = 1,
        PickTime = 5,
        Cops = 0,
        Object = 'bzzz_plant_cotton_f',
        TargetModels = { 'bzzz_plant_cotton_f', 'bzzz_plant_cotton_c_coll', 'prop_weed_02' },
        ProcessLocation = vector4(405.3786, -1537.6223, 29.3778, 51.5416),
        ProcessTime = 5,
        Joint = 'bonggon',
        AmountToProcess = 2,
        RewardJoint = 1,
        Locations = {
            vector3(405.28369140625, -1528.4470214844, 28.319694519043),
            vector3(404.76959228516, -1531.3543701172, 28.322006225586),
            vector3(406.89993286133, -1530.1276855469, 28.320777893066),
            vector3(403.02377319336, -1531.8741455078, 28.321151733398),
            vector3(407.86660766602, -1532.9050292969, 28.328834533691),
            vector3(405.21630859375, -1535.0316162109, 28.334247589111),
            vector3(409.06649780273, -1533.7969970703, 28.327705383301),
            vector3(406.36730957031, -1537.9862060547, 28.392154693604),
            vector3(402.01559448242, -1535.1588134766, 28.326919555664),
            vector3(401.13116455078, -1538.2496337891, 28.334115982056),
        }
    },
    ['hailathuoc'] = {
        Label = 'Thu hoạch lá thuốc',
        ProcessLabel = 'Chế biến lá thuốc',
        Job = false, -- Không yêu cầu job (ai cũng hái được)
        Scissors = false,
        Weed = 'lathuocla', -- Item nhận được khi hái
        RewardWeed = 1,
        PickTime = 10,
        Cops = 0,
        Object = 'bzzz_new_tobacco_plant_c_coll',
        TargetModels = { 'bzzz_new_tobacco_plant_c_coll' },
        ProcessLocation = vector4(1284.5123, 1806.1105, 85.0158, 189.6636),
        ProcessTime = 10,
        Joint = 'lathuocla', -- Item nhận được khi chế biến (bạn có thể đổi thành item thành phẩm khác nếu muốn)
        AmountToProcess = 2,
        RewardJoint = 1,
        Locations = {
            vector3(1309.4177, 1813.2930, 88.3487),
            vector3(1303.5078, 1807.1112, 87.7358),
            vector3(1294.8866, 1799.0867, 86.7515),
            vector3(1290.3909, 1795.6447, 86.2544),
            vector3(1287.4630, 1793.2919, 85.9505),
            vector3(1285.8480, 1792.4158, 85.7657),
            vector3(1281.3706, 1787.9409, 85.3833),
            vector3(1276.5525, 1792.9207, 84.6135),
            vector3(1279.9996, 1796.4646, 84.8859),
            vector3(1284.1847, 1800.4590, 85.2064),
            vector3(1288.7864, 1804.9510, 85.6524),
            vector3(1293.6271, 1809.9546, 86.1932),
            vector3(1299.2219, 1815.8414, 86.8118),
            vector3(1303.0201, 1819.6823, 87.3306),
            vector3(1297.3730, 1825.0393, 86.4204),
            vector3(1293.7679, 1821.3890, 85.9405),
            vector3(1288.5876, 1816.2969, 85.4180),
            vector3(1281.8202, 1809.5728, 84.6652),
            vector3(1275.7112, 1803.6782, 84.0280),
            vector3(1269.8789, 1799.9149, 83.5584),
            vector3(1263.9083, 1793.9020, 83.1712),
        }
    }
}

-- Backward compatibility for single-config access
Config.Scissors = Config.Farms['haibong'].Scissors
Config.Weed = Config.Farms['haibong'].Weed
Config.RewardWeed = Config.Farms['haibong'].RewardWeed
Config.PickTime = Config.Farms['haibong'].PickTime
Config.Cops = Config.Farms['haibong'].Cops
Config.WeedLocations = Config.Farms['haibong'].Locations
Config.Object = Config.Farms['haibong'].Object
Config.ProcessLocation = Config.Farms['haibong'].ProcessLocation
Config.ProcessTime = Config.Farms['haibong'].ProcessTime
Config.Joint = Config.Farms['haibong'].Joint
Config.AmountToProcess = Config.Farms['haibong'].AmountToProcess
Config.RewardJoint = Config.Farms['haibong'].RewardJoint
Config.Job = Config.Farms['haibong'].Job