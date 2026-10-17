return {
	-- --Quan an
	-- {
	-- 	items = {
	-- 		{
	-- 			name = 'pizza_ht',
	-- 			ingredients = {
	-- 				conheo = 1,
	-- 				luami = 3,
	-- 			},
	-- 			duration = 5000,
	-- 			count = 3,
	-- 			metadata = { durability = 100 }
	-- 		},
	-- 		{
	-- 			name = 'banhran_ht',
	-- 			ingredients = {
	-- 				luami = 3,
	-- 				coconut = 3,
	-- 			},
	-- 			duration = 5000,
	-- 			count = 7,
	-- 			metadata = { durability = 100 }
	-- 		},
	-- 	},
	-- 	points = {
	-- 		vec3(-591.06469726562,-1056.4379882812,22.215854644775)
	-- 	},

	-- 	groups = {["quanan"] = 3},

	-- 	zones = {
	-- 		{
	-- 			coords = vec3(-591.06469726562,-1056.4379882812,22.215854644775),
	-- 			size = vec3(3.8, 1.05, 0.15),
	-- 			distance = 2.0,
	-- 			rotation = 315.0,
	-- 		}
	-- 	},
	-- },
	-- --quannuoc
	-- {
	-- 	items = {
	-- 		{
	-- 			name = 'nuocdua_utso',
	-- 			ingredients = {
	-- 				coconut = 1,

	-- 			},
	-- 			duration = 5000,
	-- 			count = 1,
	-- 			metadata = { durability = 100 }
	-- 		},
	-- 		{
	-- 			name = 'trada_utso',
	-- 			ingredients = {
	-- 				la_che = 1,
	-- 				nuocloc = 1,
	-- 			},
	-- 			duration = 5000,
	-- 			count = 1,
	-- 			metadata = { durability = 100 }
	-- 		},
	-- 	},
	-- 	points = {
	-- 		vec3(188.16038513184,-863.71081542969,30.509141921997)
	-- 	},

	-- 	groups = {["quannuoc"] = 3},

	-- 	zones = {
	-- 		{
	-- 			coords = vec3(188.16038513184,-863.71081542969,30.509141921997),
	-- 			size = vec3(3.8, 1.05, 0.15),
	-- 			distance = 2.0,
	-- 			rotation = 315.0,
	-- 		}
	-- 	},
	-- },

	{
		items = {
			{
				name = 'bandage',
				ingredients = {
				bonggon = 5,
				},
				duration = 5000,
				count = 1
			},
		},
		points = {
			vec3(342.84939575195,-1423.3151855469,32.70735168457)
		},

		groups = {["ambulance"] = 7},

		zones = {
			{
				coords = vec3(342.84939575195,-1423.3151855469,32.70735168457),
				size = vec3(3.8, 1.05, 0.15),
				distance = 2.0,
				rotation = 315.0,
			}
		},
	},

	{
		items = {
			{
				name = 'phoinangcap1',
				ingredients = {
				vairach = 3,
				},
				duration = 5000,
				count = 1,
				metadata = { DoHiem = 'Common' }
			},
		},
		points = {
			vec3(196.74, -430.07, 45.25)
		},
		zones = {
			{
				coords = vec3(196.74, -430.07, 45.25),
				size = vec3(3.8, 1.05, 0.15),
				distance = 1.5,
				rotation = 315.0,
			}
		},
	},

	{
		items = {
			{
				name = 'mechanic_toolbox',
				ingredients = {
					money = 1000,
				},
				duration = 5000,
				count = 1,
				metadata = { DoHiem = 'Common' }
			},
			{
				name = 'phutung',
				ingredients = {
					metalscrap = 5,
					hdpe = 5, 
				},
				duration = 3000,
				count = 1,
				metadata = { DoHiem = 'Common' }
			},
			{
				name = 'thanvo',
				ingredients = {
					hdpe = 6,
					glass = 2, 
				},
				duration = 3000,
				count = 1,
				metadata = { DoHiem = 'Common' }
			},
			{
				name = 'bolauxe',
				ingredients = {
					vaivun = 2,
					hdpe = 1,
				},
				duration = 3000,
				count = 1,
				metadata = { DoHiem = 'Common' }
			},
		},
		points = {
			vec3(-314.78, -124.81, 38.96)
		},

		groups = {["mechanic"] = 2},
		
		zones = {
			{
				coords = vec3(-314.78, -124.81, 38.96),
				size = vec3(3.8, 1.05, 0.15),
				distance = 2.5,
				rotation = 315.0,
			}
		},
	},

	{
		items = {
			{
                name = 'tuner_pad',
                ingredients = {
                  money = 10000,
                },
                duration = 5000,
                count = 1
            },
		--    {
        --         name = 'dochoixe',
        --         ingredients = {
        --           money = 1000,
        --         },
        --         duration = 5000,
        --         count = 1
        --     },

        --     {
        --         name = 'neons_controller',
        --         ingredients = {
        --           money = 1000,
        --         },
        --         duration = 5000,
        --         count = 1
        --     },
			{
                name = 'cosmetics',
                ingredients = {
                    dochoixe = 16,
                    hdpe = 120,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },

			{
                name = 'neon_custom',
                ingredients = {
                    dochoixe = 20,
                },
                duration = 5000,
                count = 1
            },

            {
                name = 'extras_controller',
                ingredients = {
                    dochoixe = 16,
                    hdpe = 120,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },
            
            -- Cosmetics Items
            {
                name = 'mechspray',
                ingredients = {
                    dochoixe = 8,
                    metalscrap = 30,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'car_wheel',
                ingredients = {
                    dochoixe = 16,
                    metalscrap = 60,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'spoiler',
                ingredients = {
                    dochoixe = 16,
                    hdpe = 120,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'front_bumper',
                ingredients = {
                    dochoixe = 16,
                    hdpe = 120,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'rear_bumper',
                ingredients = {
                    dochoixe = 16,
                    hdpe = 120,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'skirtcar',
                ingredients = {
                    dochoixe = 16,
                    hdpe = 120,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'exhaust',
                ingredients = {
                    dochoixe = 16,
                    metalscrap = 60,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'car_hood',
                ingredients = {
                    dochoixe = 16,
                    hdpe = 120,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'horn',
                ingredients = {
                    dochoixe = 16,
                    hdpe = 120,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'internals',
                ingredients = {
                    dochoixe = 16,
                    hdpe = 120,
                    metalscrap = 60,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'seats',
                ingredients = {
                    dochoixe = 16,
                    hdpe = 120,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'engine_block',
                ingredients = {
                    dochoixe = 16,
                    metalscrap = 120,
                },
                duration = 5000,
                count = 1
            },
            {
                name = 'vanity_plate',
                ingredients = {
                    dochoixe = 16,
                    metalscrap = 60,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },
						{
                name = 'cosmetics',
                ingredients = {
                    dochoixe = 16,
                    hdpe = 120,
                    rubber = 60,
                },
                duration = 5000,
                count = 1
            },

		},
		points = {
			vec3(-195.73408508301,-1318.6350097656,31.137662887573),
		},
		
		zones = {
			{
				coords = vec3(-195.73408508301,-1318.6350097656,31.137662887573),
				size = vec3(3.8, 1.05, 0.15),
				distance = 1.5,
				rotation = 315.0,
			}
		},
	},

	{
		items = {
			{
				name = 'hopquagiangsinh',
				ingredients = {
					chuonggiangsinh = 1,
					tatgiangsinh = 1,
					giaygoiqua = 1,
				},
				duration = 5000,
				count = 1,
				metadata = { DoHiem = 'Rare' }
			},
		},
		points = {
			vec3(266.86, -444.97, 45.33)
		},
		zones = {
			{
				coords = vec3(202.54, -946.28, 29.5),
				size = vec3(3.8, 1.05, 0.15),
				distance = 1.5,
				rotation = 315.0,
			}
		},
	},
}
