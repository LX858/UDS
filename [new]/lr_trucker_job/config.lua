Config = {
  Locale = 'vi',
  Debug = false,
  Dev = false,

  Framework = {
    Name = 'qbx',
  },

  Modules = {
    main = false,
    trucker = true,
  },

  Job = {
    RequiredName = '', -- Empty allows every Qbox job.
    RequireOnDuty = false,
  },

  NPC = {
    coords = vector4(-424.27, -2789.87, 6.53, 318.56),
    model = 's_m_m_dockwork_01',
  },

  ReturnPoint = vector4(-527.38, -2850.93, 6.00, 314.17),

  Market = {
    RefreshMs = 300000,
    CategoryLabels = {
      fish = 'Hải Sản',
      phelieu = 'Phế Liệu',
      mining = 'Khoáng Sản',
      nuoithu = 'Nuôi Thú',
      traicay = 'Nông Nghiệp',
    },
    UnitsPerPackage = 12,
    MaxOrderUnits = 250,
    NpcContractFee = 5000,
    NpcPayPerUnit = 100,
    NpcDeadlineBaseMinutes = 10,
    NpcDeadlineMinutesPerKm = 5,
    NpcTimeBonusMin = 1500,
    NpcTimeBonusMax = 3000,
    -- Route categories only. Current price and stock always come from xn-sellitem.
    Items = {
      orange = { category = 'traicay' },
      coconut = { category = 'traicay' },
      fish = { category = 'fish' },
      wood = { category = 'phelieu' },
      ore = { category = 'mining' },
      grain = { category = 'nuoithu' },
    },
  },

  Fleet = {
    -- Local-space marker behind each closed van. Shared by client and server.
    RearLoading = {
      speedo = { x = 0.0, y = -3.6, z = 0.0 },
      mule = { x = 0.0, y = -5.0, z = 0.0 },
      benson = { x = 0.0, y = -6.0, z = 0.0 },
      pounder = { x = 0.0, y = -6.8, z = 0.0 },
    },
    CategoryTier = {
      traicay = 0,
      fish = 0,
      phelieu = 1,
      nuoithu = 2,
      mining = 3,
    },
    Rentals = {
      mule = { label = 'Mule', model = 'mule', fee = 5000, capacity = 50, rewardMultiplier = 100 },
      benson = { label = 'Benson', model = 'benson', fee = 10000, capacity = 100, rewardMultiplier = 100 },
      pounder = { label = 'Pounder', model = 'pounder', fee = 15000, capacity = 150, rewardMultiplier = 100 },
      hauler = { label = 'Hauler', model = 'hauler', fee = 20000, capacity = 200, rewardMultiplier = 100 },
      packer = { label = 'Packer', model = 'packer', fee = 25000, capacity = 200, rewardMultiplier = 100 },
      phantom = { label = 'Phantom', model = 'phantom', fee = 30000, capacity = 250, rewardMultiplier = 100 },
    },
    RentalMinutes = 60,
    OveragePercentPerMinute = 3,
    TrailerRentals = { hauler = true, packer = true, phantom = true },
    FuelRentals = { packer = true, phantom = true },
    Owned = {
      models = { phantom = true, phantom2 = true },
      tiers = {
        [1] = { capacity = 120, upgradePrice = 200000 },
        [2] = { capacity = 180, upgradePrice = 350000 },
        [3] = { capacity = 250, upgradePrice = 0 },
      },
    },
  },

  BusinessOrders = {
    Enabled = true,
    PageSize = 20,
    MaxLines = 6,
    MaxPackages = 21,
    MaxUnits = 250,
    InteractionDistance = 2.0,
    ActionDistance = 12.0,
    Fees = { percent = 10 },
    Pickup = {
      label = 'Kho trung chuyển Los Santos',
      vehicles = {
        truck = { coords = vector4(-446.87, -2788.98, 6.07, 47.05) },
        trailer = vector4(-459.77, -2803.29, 6.07, 45.85),
        escort = vector4(-513.23, -2856.48, 5.98, 45.64),
      },
      parking = vector4(-535.2277, -2810.6501, 6.0642, 222.4278),
      packages = vector4(-554.25, -2807.90, 6.00, 132.79),
      forklifts = {
        vector4(-534.9573, -2788.3689, 5.4526, 225.2150),
        vector4(-535.1185, -2790.7095, 5.4535, 219.1465),
        vector4(-537.7719, -2791.7109, 5.4545, 216.7437),
        vector4(-521.28, -2788.23, 6.00, 236.59),
      },
    },
    Items = {
      coconut = { unitsPerPackage = 12, destinationMultiplier = 1, destinationUnit = 'item', destinationItemId = 'dua_soche', destinationLabel = 'Dừa sơ chế' },
      la_che = { unitsPerPackage = 12, destinationMultiplier = 1, destinationUnit = 'item', destinationItemId = 'tra_kho', destinationLabel = 'Trà khô' },
      luami = { unitsPerPackage = 12, destinationMultiplier = 1, destinationUnit = 'item', destinationItemId = 'gao', destinationLabel = 'Gạo' },
      conheo = { unitsPerPackage = 12, destinationMultiplier = 1, destinationUnit = 'item', destinationItemId = 'conheo', destinationLabel = 'Heo' },
      conbo = { unitsPerPackage = 12, destinationMultiplier = 1, destinationUnit = 'item', destinationItemId = 'conbo', destinationLabel = 'Bò' },
      luanuoc = { unitsPerPackage = 12, destinationMultiplier = 1, destinationUnit = 'item', destinationItemId = 'luanuoc', destinationLabel = 'Lúa nước' },
      dau_tho = { unitsPerPackage = 12, destinationMultiplier = 20, destinationUnit = 'liter', destinationItemId = '', destinationLabel = 'Nhiên liệu' },
    },
    -- Điểm giao tịnh tiến theo quán hiện tại; kiểm tra va chạm và heading trên staging.
    Businesses = {
      bar = {
        label = 'Quán nước', adapter = 'stash', job = 'quannuoc', stashId = 'bar',
        orderPoint = vector4(214.6596, -961.8030, 32.9034, 160.0000),
        delivery = {
          parking = vector4(206.8376, -1144.8131, 31.3624, 250.5054),
          packages = vector3(172.1558, -1112.4521, 31.4633),
          forklifts = {
            vector4(212.1724, -1123.2708, 31.3501, 205.9767), vector4(206.7799, -1121.4774, 31.3569, 203.5906),
          },
        },
        allowedItems = { coconut = true, la_che = true },
      },
      restaurant_shop = {
        label = 'Quán ăn', adapter = 'stash', job = 'quanan', stashId = 'restaurant_shop',
        orderPoint = vector4(321.5259, -1645.8512, 32.5832, 90.0000),
        delivery = {
          parking = vector4(311.7239, -1695.5260, 32.4171, 0.2916),
          packages = vector3(312.9580, -1677.6419, 32.4171),
          forklifts = {
            vector4(300.9114, -1682.8808, 32.4171, 289.7035), vector4(296.6638, -1677.4493, 32.4171, 273.5532),
          },
        },
        allowedItems = { coconut = true, luami = true, conheo = true, conbo = true, luanuoc = true },
      },
    },
    Fuel = {
      enabled = true, provider = 'cdn-fuel', itemId = 'dau_tho',
      stationPrefix = 'gas_station_', label = 'Trạm xăng', deliveryRadius = 30.0,
    },
  },
}

Config.Routes = {
  {
    itemId = 'orange', destination = 'Kho phân phối Cypress Flats', packages = { 5, 10 },
    vehicles = {
      truck = { model = 'phantom', coords = vector4(-446.87, -2788.98, 6.07, 47.05) },
      trailer = vector4(-459.77, -2803.29, 6.07, 45.85),
      escort = vector4(-513.23, -2856.48, 5.98, 45.64),
    },
    pickup = {
      parking = vector4(-535.2277, -2810.6501, 6.0642, 222.4278),
      packages = vector4(-554.25, -2807.90, 6.00, 132.79),
      forklifts = {
        vector4(-534.9573, -2788.3689, 5.4526, 225.2150), vector4(-535.1185, -2790.7095, 5.4535, 219.1465),
        vector4(-537.7719, -2791.7109, 5.4545, 216.7437), vector4(-521.28, -2788.23, 6.00, 236.59),
      },
    },
    delivery = {
      parking = vector4(164.21, -3182.15, 5.92, 177.02), packages = vector3(189.47, -3202.52, 5.79),
      forklifts = {
        vector4(163.05, -3210.20, 5.94, 263.02), vector4(164.16, -3220.13, 5.92, 262.23),
        vector4(163.45, -3228.58, 5.93, 263.72), vector4(163.75, -3234.98, 5.93, 273.15),
      },
    },
    reward = 10000, xp = 150,
  },
  {
    itemId = 'coconut', destination = 'Nhà máy Elysian', packages = { 7, 14 },
    vehicles = {
      truck = { model = 'phantom', coords = vector4(-405.95, -2847.99, 6.00, 311.32) },
      trailer = vector4(-371.92, -2799.18, 6.00, 134.41),
      escort = vector4(-376.61, -2820.13, 6.00, 38.20),
    },
    pickup = {
      parking = vector4(-495.82, -2768.00, 6.00, 132.96), packages = vector4(-484.26, -2733.10, 6.00, 332.03),
      forklifts = {
        vector4(-522.99, -2756.01, 6.00, 257.91), vector4(-513.85, -2749.48, 6.00, 278.19),
        vector4(-521.19, -2766.15, 6.00, 125.65), vector4(-512.18, -2752.88, 6.00, 304.29),
      },
    },
    delivery = {
      parking = vector4(1133.93, -3302.07, 5.90, 179.73), packages = vector3(1148.55, -3270.67, 5.90),
      forklifts = {
        vector4(1127.22, -3276.49, 5.90, 101.10), vector4(1117.56, -3294.09, 5.90, 275.15),
        vector4(1119.22, -3310.91, 5.91, 274.40), vector4(1127.77, -3250.80, 5.90, 181.97),
      },
    },
    reward = 15000, xp = 200,
  },
  {
    itemId = 'fish', destination = 'Trung tâm thực phẩm East Los Santos', packages = { 10, 15 },
    vehicles = {
      truck = { model = 'phantom3', coords = vector4(-334.49, -2741.68, 6.03, 317.83) },
      trailer = vector4(-412.44, -2748.22, 6.00, 354.73),
      escort = vector4(-327.70, -2748.48, 6.02, 313.32),
    },
    pickup = {
      parking = vector4(-308.02, -2715.75, 6.00, 136.81), packages = vector4(-295.39, -2702.91, 6.00, 197.82),
      forklifts = {
        vector4(-307.21, -2731.88, 6.00, 313.38), vector4(-301.31, -2731.48, 6.00, 21.01),
        vector4(-296.84, -2725.42, 6.00, 314.85), vector4(-303.50, -2727.69, 6.00, 305.28),
      },
    },
    delivery = {
      parking = vector4(2566.15, -418.46, 92.99, 178.28), packages = vector3(2550.05, -399.16, 92.99),
      forklifts = {
        vector4(2551.31, -435.00, 92.99, 325.94), vector4(2548.96, -422.84, 92.99, 20.17),
        vector4(2541.00, -414.17, 92.99, 42.53), vector4(2534.40, -405.85, 92.99, 356.79),
      },
    },
    reward = 20000, xp = 300,
  },
  {
    itemId = 'wood', destination = 'Công trường Sandy Shores', packages = { 15, 20 },
    vehicles = {
      truck = { model = 'phantom3', coords = vector4(-366.12, -2632.40, 6.00, 45.10) },
      trailer = vector4(-349.54, -2617.34, 6.00, 49.60),
      escort = vector4(-379.53, -2652.00, 6.00, 317.94),
    },
    pickup = {
      parking = vector4(-389.95, -2475.61, 6.00, 229.32), packages = vector4(-404.91, -2483.56, 6.00, 228.54),
      forklifts = {
        vector4(-416.21, -2450.93, 6.00, 103.87), vector4(-411.32, -2456.88, 6.05, 223.72),
        vector4(-401.66, -2462.26, 6.00, 195.85), vector4(-414.71, -2459.02, 6.00, 47.47),
      },
    },
    delivery = {
      parking = vector4(1650.76, 3259.29, 40.95, 104.24), packages = vector3(1691.39, 3271.68, 40.93),
      forklifts = {
        vector4(1677.75, 3280.00, 40.84, 221.10), vector4(1682.50, 3279.07, 40.89, 182.84),
        vector4(1672.83, 3286.21, 40.95, 124.75), vector4(1670.71, 3278.27, 41.20, 119.72),
      },
    },
    reward = 40000, xp = 600,
  },
  {
    itemId = 'ore', destination = 'Xưởng chế tác Vinewood', packages = { 15, 20 },
    vehicles = {
      truck = { model = 'phantom3', coords = vector4(-258.58, -2497.70, 6.00, 230.98) },
      trailer = vector4(-246.50, -2566.34, 6.00, 358.35),
      escort = vector4(-264.69, -2503.42, 6.00, 228.77),
    },
    pickup = {
      parking = vector4(-141.27, -2480.68, 6.02, 322.81), packages = vector4(-160.83, -2476.21, 6.02, 220.12),
      forklifts = {
        vector4(-163.10, -2511.46, 6.01, 347.46), vector4(-158.40, -2512.97, 6.01, 324.85),
        vector4(-152.21, -2516.67, 6.01, 332.12), vector4(-147.59, -2520.79, 6.00, 339.46),
      },
    },
    delivery = {
      parking = vector4(701.39, 605.84, 128.91, 249.43), packages = vector3(675.39, 617.04, 128.91),
      forklifts = {
        vector4(682.73, 606.69, 128.91, 263.34), vector4(690.13, 603.23, 128.94, 244.41),
        vector4(702.01, 613.06, 128.91, 62.27), vector4(677.94, 621.37, 128.91, 220.34),
      },
    },
    reward = 35000, xp = 500,
  },
  {
    itemId = 'grain', destination = 'Nhà máy xử lý Senora', packages = { 15, 20 },
    vehicles = {
      truck = { model = 'phantom3', coords = vector4(-100.32, -2462.03, 6.02, 58.91) },
      trailer = vector4(-145.21, -2413.04, 6.00, 171.87),
      escort = vector4(-95.50, -2456.12, 6.02, 54.48),
    },
    pickup = {
      parking = vector4(-106.55, -2541.73, 6.00, 145.58), packages = vector4(-121.26, -2534.99, 6.00, 141.73),
      forklifts = {
        vector4(-109.61, -2523.15, 6.00, 10.13), vector4(-103.48, -2513.40, 5.65, 242.96),
        vector4(-115.98, -2523.55, 6.00, 152.28), vector4(-107.81, -2520.84, 6.00, 141.76),
      },
    },
    delivery = {
      parking = vector4(3573.85, 3766.01, 29.92, 263.05), packages = vector3(3573.42, 3785.42, 29.98),
      forklifts = {
        vector4(3592.06, 3781.61, 29.95, 270.43), vector4(3598.34, 3774.35, 29.92, 241.34),
        vector4(3602.98, 3780.55, 29.94, 326.45), vector4(3608.40, 3773.41, 29.92, 170.82),
      },
    },
    reward = 45000, xp = 650,
  },
}

Config.Settings = {
  locale = SetLocale(Config.Locale),
  dev = Config.Dev,
}
