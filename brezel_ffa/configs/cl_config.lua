BS_C = {}

BS_C.Lang = "en"

BS_C.LeaveFFACommand = "leaveffa"
BS_C.KickFFACommand = "kickffa"
BS_C.StartFFACommand = "startffa"
BS_C.StopFFACommand = "stopffa"
BS_C.KickFFACommandPermission = "group.admin"

BS_C.CountdownSeconds = 5
BS_C.SpawnHeightOffset = 1.0
BS_C.AntiFallCheck = true
BS_C.AntiFallMinZOffset = 25.0 -- Khoảng cách rơi tối đa dưới tâm map trước khi auto-teleport

BS_C.DefaultClothing = {
    male = {
        ['mask'] = { drawable = 97, texture = 0 },      -- Mặt nạ 97 (Component 1)
        ['arms'] = { drawable = 25, texture = 0 },      -- Găng tay 25 (Component 3)
        ['pants'] = { drawable = 110, texture = 0 },    -- Quần 110 (Component 4)
        ['shoes'] = { drawable = 88, texture = 0 },     -- Giày 88 (Component 6)
        ['torso'] = { drawable = 287, texture = 0 },    -- Áo 287 (Component 11)
        ['tshirt'] = { drawable = 15, texture = 0 },    -- Áo lót trong (Component 8)
        ['bproof'] = { drawable = 0, texture = 0 },     -- Giáp (Component 9)
        ['decals'] = { drawable = 0, texture = 0 },     -- Decal (Component 10)
        ['bag'] = { drawable = 0, texture = 0 },        -- Balo (Component 5)
    },
    female = {
        ['mask'] = { drawable = 98, texture = 0 },      -- Mặt nạ 98 (Component 1)
        ['arms'] = { drawable = 207, texture = 0 },     -- Găng tay 207 (Component 3)
        ['pants'] = { drawable = 117, texture = 0 },    -- Quần 117 (Component 4)
        ['shoes'] = { drawable = 92, texture = 0 },     -- Giày 92 (Component 6)
        ['torso'] = { drawable = 296, texture = 0 },    -- Áo 296 (Component 11)
        ['tshirt'] = { drawable = 14, texture = 0 },    -- Áo lót trong (Component 8)
        ['bproof'] = { drawable = 0, texture = 0 },     -- Giáp (Component 9)
        ['decals'] = { drawable = 0, texture = 0 },     -- Decal (Component 10)
        ['bag'] = { drawable = 0, texture = 0 },        -- Balo (Component 5)
    }
}

BS_C.FFA = {
  ["open_coords"] = vector3(-1755.6165, 185.7929, 64.4387),
  ["regenerate_health_onkill"] = false,
  ["blip"] = {
    ["sprite"] = 1,
    ["color"] = 0,
    ["scale"] = 0.8,
    ["name"] = "FFA Arena",
    ["coords"] = vector3(-1755.6165, 185.7929, 64.4387)
  },
  ["marker"] = {
    ["type"] = 1,
    ["scale"] = vector3(1.0, 1.0, 1.0),
    ["color"] = vector3(255, 255, 255),
    ["coords"] = vector3(-1755.6165, 185.7929, 64.4387)
  },
  ["ped"] = {
    ["model"] = "a_m_m_skater_01",
    ["coords"] = vector4(-1755.6165, 185.7929, 63.4387, 210.7659),
    ["animation"] = {
      ["dict"] = "amb@world_human_hang_out_street@male_c@base",
      ["name"] = "base",
      ["flag"] = 1,
      ["duration"] = -1,
      ["playback"] = 1
    }
  },
  ["maps"] = {
    ["map1"] = {
      ["name"] = "ARENA P1",
      ["maxplayers"] = 100,
      ["image"] = "https://media.discordapp.net/attachments/1498217871401287690/1498233198721765376/image__1450438014374383660_00.png?ex=6aae41e6&is=6aacf066&hm=2ee3b7472c9808d8247540128f4fe28dad778654aa21c62e32df48f9101d99f8&=&format=webp&quality=lossless",
      ["weapons"] = {
        "weapon_wrench",
      },
      ["spawncoords"] = {
        vec4(-5330.5166, 1512.3302, 41.1550, 236.1592),
        vec4(-5312.1465, 1512.1887, 41.1550, 270.3938),
        vec4(-5282.5562, 1511.9725, 41.1550, 269.9913),
        vec4(-5257.2661, 1511.9282, 41.1550, 270.1517),
        vec4(-5237.5508, 1510.5048, 41.1550, 175.6089),
        vec4(-5237.7505, 1490.7799, 41.1550, 180.1786),
        vec4(-5237.9292, 1467.0883, 41.1549, 179.7368),
        vec4(-5238.0303, 1443.1862, 41.1549, 180.1344),
        vec4(-5238.2363, 1421.4504, 41.1549, 177.2769),
        vec4(-5255.0957, 1419.0251, 41.1549, 89.6391),
        vec4(-5278.2998, 1419.2617, 41.1549, 88.8709),
        vec4(-5297.6055, 1419.3202, 41.1550, 89.7011),
        vec4(-5323.7402, 1419.3990, 41.1550, 87.3181),

        -- Khu 2
        vec4(-5283.9590, 1392.2800, 41.1550, 267.8461),
        vec4(-5259.1099, 1391.8364, 41.1550, 269.4526),
        vec4(-5240.0371, 1391.6626, 41.1551, 269.5135),
        vec4(-5238.3989, 1371.8213, 41.1550, 177.1683),
        vec4(-5238.3716, 1346.3511, 41.1550, 179.9311),
        vec4(-5238.6367, 1314.1432, 41.1549, 179.0036),
        vec4(-5245.8125, 1298.9578, 41.1550, 96.6044),
        vec4(-5269.6558, 1299.1586, 41.1550, 88.3717),
        vec4(-5297.2349, 1299.2606, 41.1549, 92.4875),
        vec4(-5329.9907, 1299.5461, 41.1549, 88.6103),
        vec4(-5331.4097, 1316.8834, 41.1548, 358.5012),
        vec4(-5331.3989, 1347.8875, 41.1549, 0.4234),
      },
      ["border"] = {
        ["coords"] = vector3(-5284.6895, 1405.9972, 41.1528),
        ["radius"] = 150.0,
        ["visible"] = true
      }
    },
  }
}

BS_C.Notify = function(msg, notifyType)
    lib.notify({
        title = 'FFA Arena',
        description = msg,
        type = notifyType or 'info'
    })
end

BS_C.OnLeave = function ()
    -- Hook when player leaves FFA
end

BS_C.OnJoin = function ()
    -- Hook when player joins FFA
end

BS_C.OnDeath = function ()
    -- Hook when player dies in FFA
end

BS_C.OnRespawn = function ()
    -- Hook when player respawns in FFA
end
