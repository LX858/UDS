Config = {}

-- Debug mode (true = hiển thị tất cả log, false = chỉ hiển thị log quan trọng)
Config.Debug = false

-- Tự động mặc lại đồng phục nếu người chơi tự ý thay đổi đồ khi đang on duty (Tránh spam thông báo và xung đột phụ kiện)
Config.EnforceUniform = true

-- Whitelist đồ riêng cho job police. Nếu player đang mặc drawable/texture nào đó ở component dưới đây thì sẽ bỏ qua việc auto-apply đồng phục.
-- Ví dụ: SWAT gear có thể được thêm vào đây để giữ nguyên outfit khi on duty.
-- Cấu trúc mới: ['component_name'] = {{drawable = x, texture = y}, {drawable = a, texture = b}}
-- Cũng hỗ trợ cấu trúc cũ: ['component_name'] = {drawable1, drawable2, ...}
Config.PoliceClothingWhitelist = {
    ['torso'] = {
        {drawable = 928, texture = 6},
        {drawable = 927, texture = 9},
        {drawable = 926, texture = 7},
        {drawable = 925, texture = 2},
        {drawable = 921, texture = 2},
        {drawable = 920, texture = 2},
        {drawable = 912, texture = 0},
    },
    ['pants'] = {
        {drawable = 305, texture = 0},
        {drawable = 306, texture = 0},
    },
    ['mask'] = {
        {drawable = 169, texture = 0},
    },
    ['arms'] = {
        {drawable = 55, texture = 0},
        {drawable = 56, texture = 0},
        {drawable = 57, texture = 0},
        {drawable = 58, texture = 0},
    },
    ['tshirt'] = {
        {drawable = 224, texture = 0},
        {drawable = 220, texture = 0},
        {drawable = 222, texture = 0},

    },
}

-- Danh sách jobs cần áp dụng auto clothing
Config.Jobs = {'police', 'ambulance', 'bar', 'luxurycar', 'cardealer', 'taxi', 'realestate', 'mechanic'}

-- Cấu hình đồng phục theo job, giới tính và cấp bậc
Config.Uniforms = {
    -- ==================== POLICE ====================
    police = {
    male = {
        -- Học viên (Grade 0)
        trainee = {
            grades = {1},
            clothing = {
                ['accessory'] = {drawable = 405, texture = 0},
                ['tshirt'] = {drawable = 230, texture = 0},
                ['torso'] = {drawable = 903, texture = 9},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 1, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },

        -- Sĩ quan (Grade 1-3)
        si_quan = {
            grades = {2},
            clothing = {
                ['accessory'] = {drawable = 405, texture = 0},
                ['tshirt'] = {drawable = 230, texture = 0},
                ['torso'] = {drawable = 903, texture = 9},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 1, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 207, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            },
        },
        si_quan2 = {
            grades = {3},
            clothing = {
                ['accessory'] = {drawable = 405, texture = 0},
                ['tshirt'] = {drawable = 230, texture = 0},
                ['torso'] = {drawable = 903, texture = 9},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 1, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 208, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            },
        },
        si_quan3 = {
            grades = {4},
            clothing = {
                ['accessory'] = {drawable = 405, texture = 0},
                ['tshirt'] = {drawable = 230, texture = 0},
                ['torso'] = {drawable = 903, texture = 9},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 1, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 209, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            },
        },

        -- Cấp úy (Grade 4-6)
        cap_uy = {
            grades = {5},
            clothing = {
                ['accessory'] = {drawable = 405, texture = 0},
                ['tshirt'] = {drawable = 230, texture = 0},
                ['torso'] = {drawable = 903, texture = 9},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 1, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 210, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_uy2 = {
            grades = {6},
            clothing = {
                ['accessory'] = {drawable = 405, texture = 0},
                ['tshirt'] = {drawable = 230, texture = 0},
                ['torso'] = {drawable = 903, texture = 9},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 1, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 211, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_uy3 = {
            grades = {7},
            clothing = {
                ['accessory'] = {drawable = 405, texture = 0},
                ['tshirt'] = {drawable = 230, texture = 0},
                ['torso'] = {drawable = 903, texture = 9},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 1, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 212, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },

        -- Cấp tá (Grade 7-9)
        cap_ta = {
            grades = {8},
            clothing = {
                ['accessory'] = {drawable = 409, texture = 0},
                ['tshirt'] = {drawable = 230, texture = 0},
                ['torso'] = {drawable = 904, texture = 6},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 0, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 212, texture = 1},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_ta1 = {
            grades = {9},
            clothing = {
                ['accessory'] = {drawable = 405, texture = 0},
                ['tshirt'] = {drawable = 230, texture = 0},
                ['torso'] = {drawable = 904, texture = 10},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 0, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 213, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_ta2 = {
            grades = {10},
            clothing = {
                ['accessory'] = {drawable = 405, texture = 0},
                ['tshirt'] = {drawable = 230, texture = 0},
                ['torso'] = {drawable = 904, texture = 10},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 0, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 213, texture = 1},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },

        -- Cấp tứ (Grade 10-13)
        cap_tu = {
            grades = {11},
            clothing = {
                ['tshirt'] = {drawable = 334, texture = 10},
                ['torso'] = {drawable = 905, texture = 7},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 1, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 214, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_tu1 = {
            grades = {12},
            clothing = {
                ['tshirt'] = {drawable = 334, texture = 10},
                ['torso'] = {drawable = 905, texture = 7},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 1, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 215, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_tu3 = {
            grades = {13},
            clothing = {
                ['tshirt'] = {drawable = 334, texture = 10},
                ['torso'] = {drawable = 905, texture = 7},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 84, texture = 0},
                ['arms'] = {drawable = 1, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 216, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_tu4 = {
            grades = {14},
            clothing = {
                ['tshirt'] = {drawable = 334, texture = 10},
                ['torso'] = {drawable = 905, texture = 7},
                ['pants'] = {drawable = 280, texture = 3},
                -- ['bproof'] = {drawable = 0, texture = 0},
                ['arms'] = {drawable = 1, texture = 0},
                ['shoes'] = {drawable = 284, texture = 0},
                ['decals'] = {drawable = 216, texture = 1},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
    },

    female = {
        -- Học viên (Grade 0)
        trainee = {
            grades = {1},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 286, texture = 0},
                ['torso'] = {drawable = 923, texture = 9},
            --    ['bproof'] = {drawable = 82, texture = 0},
                ['pants'] = {drawable = 279, texture = 3},
                ['arms'] = {drawable = 253, texture = 0},
                ['shoes'] = {drawable = 115, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },

        -- Sĩ quan (Grade 1-3)
        si_quan = {
            grades = {2},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 273, texture = 0},
                ['torso'] = {drawable = 927, texture = 9},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 253, texture = 0},
                ['shoes'] = {drawable = 115, texture = 0},
                ['decals'] = {drawable = 223, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        si_quan1 = {
            grades = {3},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 273, texture = 0},
                ['torso'] = {drawable = 927, texture = 9},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 253, texture = 0},
                ['shoes'] = {drawable = 115, texture = 0},
                ['decals'] = {drawable = 224, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        si_quan2 = {
            grades = {4},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 273, texture = 0},
                ['torso'] = {drawable = 927, texture = 9},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 253, texture = 0},
                ['shoes'] = {drawable = 115, texture = 0},
                ['decals'] = {drawable = 225, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        -- Cấp úy (Grade 4-6)
        cap_uy = {
            grades = {5},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 273, texture = 0},
                ['torso'] = {drawable = 927, texture = 9},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 253, texture = 0},
                ['shoes'] = {drawable = 115, texture = 0},
                ['decals'] = {drawable = 226, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_uy1 = {
            grades = {6},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 273, texture = 0},
                ['torso'] = {drawable = 927, texture = 9},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 253, texture = 0},
                ['shoes'] = {drawable = 115, texture = 0},
                ['decals'] = {drawable = 227, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_uy2 = {
            grades = {7},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 273, texture = 0},
                ['torso'] = {drawable = 927, texture = 9},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 253, texture = 0},
                ['shoes'] = {drawable = 115, texture = 0},
                ['decals'] = {drawable = 228, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },

        -- Cấp tá (Grade 7-9)
        cap_ta = {
            grades = {8},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 273, texture = 0},
                ['torso'] = {drawable = 928, texture = 6},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 14, texture = 0},
                ['shoes'] = {drawable = 115, texture = 0},
                ['decals'] = {drawable = 228, texture = 1},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_ta1 = {
            grades = {9},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 273, texture = 0},
                ['torso'] = {drawable = 928, texture = 10},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 14, texture = 0},
                ['shoes'] = {drawable = 115, texture = 0},
                ['decals'] = {drawable = 229, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_ta2 = {
            grades = {10},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 273, texture = 0},
                ['torso'] = {drawable = 928, texture = 10},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 14, texture = 0},
                ['shoes'] = {drawable = 115, texture = 0},
                ['decals'] = {drawable = 229, texture = 1},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },

        -- Cấp tứ (Grade 10-13)
        cap_tu = {
            grades = {11},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 464, texture = 10},
                ['torso'] = {drawable = 929, texture = 7},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 3, texture = 0},
                ['shoes'] = {drawable = 42, texture = 2},
                ['decals'] = {drawable = 230, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_tu1 = {
            grades = {12},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 464, texture = 10},
                ['torso'] = {drawable = 929, texture = 7},
                ['pants'] = {drawable = 233, texture = 0},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 3, texture = 0},
                ['shoes'] = {drawable = 219, texture = 0},
                ['decals'] = {drawable = 231, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_tu2 = {
            grades = {13},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 464, texture = 10},
                ['torso'] = {drawable = 929, texture = 7},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 3, texture = 0},
                ['shoes'] = {drawable = 42, texture = 2},
                ['decals'] = {drawable = 232, texture = 0},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
        cap_tu3 = {
            grades = {14},
            clothing = {
                ['accessory'] = {drawable = 553, texture = 0},
                ['tshirt'] = {drawable = 464, texture = 10},
                ['torso'] = {drawable = 929, texture = 7},
                ['pants'] = {drawable = 279, texture = 3},
                -- ['bproof'] = {drawable = 82, texture = 0},
                ['arms'] = {drawable = 3, texture = 0},
                ['shoes'] = {drawable = 42, texture = 2},
                ['decals'] = {drawable = 232, texture = 1},
                ['mask'] = {drawable = 0, texture = 0},
            }
        },
    }
    }, -- Đóng police
    
    -- ==================== AMBULANCE/EMS ====================
    ambulance = {
        male = {
            -- Học viên (Grade 0-1)
            hocvien = {
                grades = {0, 1},
                clothing = {
                   ['tshirt'] = {drawable = 15, texture = 8},
                    ['torso'] = {drawable = 582, texture = 0},
                    ['pants'] = {drawable = 260, texture = 0},
                    ['arms'] = {drawable = 85, texture = 0},
                    ['accessory'] = {drawable = 396, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0},
                    ['bproof'] = {drawable = 105, texture = 0},
                }
            },

            bacsi = {
                grades = {2, 3},
                clothing = {
                   ['tshirt'] = {drawable = 148, texture = 8},
                    ['torso'] = {drawable = 584, texture = 0},
                    ['pants'] = {drawable = 260, texture = 0},
                    ['arms'] = {drawable = 94, texture = 0},
                    ['accessory'] = {drawable = 396, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0},
                    ['bproof'] = {drawable = 105, texture = 0},
                }
            },
            
            -- Bác sĩ (Grade 2-6)
            doctor = {
                grades = {4, 5, 6},
                clothing = {
                    ['tshirt'] = {drawable = 149, texture = 8},
                    ['torso'] = {drawable = 908, texture = 0},
                    ['pants'] = {drawable = 210, texture = 0},
                    ['arms'] = {drawable = 88, texture = 0},
                    ['accessory'] = {drawable = 396, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0},
                    ['bproof'] = {drawable = 105, texture = 0},
                }
            },

            
            -- Sĩ quan cấp cao (Grade 7-8)
            director2 = {
                grades = {7, 8, 9},
                clothing = {
                    ['torso'] = {drawable = 907, texture = 0},
                    ['tshirt'] = {drawable = 149, texture = 8},
                    ['pants'] = {drawable = 260, texture = 1},
                    ['arms'] = {drawable = 93, texture = 0},
                    ['accessory'] = {drawable = 396, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0}
                }
            }
        },
        
        female = {
            -- Học viên (Grade 0-1)
            trainee = {
                grades = {0, 1, 2, 3},
                clothing = {
                    ['torso'] = {drawable = 933, texture = 0},
                    ['tshirt'] = {drawable = 15, texture = 0},
                    ['pants'] = {drawable = 273, texture = 0},
                    ['arms'] = {drawable = 257, texture = 0},
                    ['accessory'] = {drawable = 517, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0},
                    ['bproof'] = {drawable = 105, texture = 0},
                }
            },
            
            -- Bác sĩ (Grade 2-6)
            doctor1 = {
                grades = {4, 5, 6, 7, 8},
                clothing = {
                    ['torso'] = {drawable = 932, texture = 0},
                    ['tshirt'] = {drawable = 440, texture = 1},
                    ['pants'] = {drawable = 272, texture = 0},
                    ['arms'] = {drawable = 253, texture = 0},
                    ['accessory'] = {drawable = 517, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0},
                    ['bproof'] = {drawable = 105, texture = 0},
                }
            },


            doctor3 = {
                grades = {9},
                clothing = {
                    ['torso'] = {drawable = 931, texture = 0},
                    ['tshirt'] = {drawable = 440, texture = 1},
                    ['pants'] = {drawable = 272, texture = 0},
                    ['arms'] = {drawable = 253, texture = 0},
                    ['accessory'] = {drawable = 517, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0},
                    ['bproof'] = {drawable = 105, texture = 0},
                }
            }
        }
    }, -- Đóng ambulance
    
    -- ==================== BAR ====================
    bar = {
        male = {
            grade_0 = {
                grades = {0, 1, 2, 3, 4, 5},
                clothing = {
                    ['torso'] = {drawable = 933, texture = 0},
                    ['tshirt'] = {drawable = 32, texture = 0},
                    ['pants'] = {drawable = 315, texture = 0},
                    ['arms'] = {drawable = 12, texture = 0},
                }
            },
        },

        female = {
            grade_0 = {
                grades = {0, 1, 2, 3, 4, 5},
                clothing = {
                    ['torso'] = {drawable = 956, texture = 0},
                    ['tshirt'] = {drawable = 467, texture = 0},
                    ['pants'] = {drawable = 272, texture = 0},
                    ['arms'] = {drawable = 256, texture = 0},
                }
            },
        }
    },

    -- ===================LUXURY CAR=====================-
    luxurycar = {
        male = {
            grade_0 = {
                grades = {0, 1, 2, 3, 4},
                clothing = {
                    ['torso'] = {drawable = 1002, texture = 0},
                    ['tshirt'] = {drawable = 218, texture = 0},
                    ['pants'] = {drawable = 260, texture = 0},
                    ['arms'] = {drawable = 4, texture = 0},
                    ['shoes'] = {drawable = 199, texture = 0},
                }
            },
        },

        female = {
            grade_0 = {
                grades = {0, 1, 2, 3, 4},
                clothing = {
                    ['torso'] = {drawable = 1170, texture = 0},
                    ['tshirt'] = {drawable = 2, texture = 0},
                    ['pants'] = {drawable = 272, texture = 0},
                    ['arms'] = {drawable = 251, texture = 0},
                }
            },
        }
    },

    -- ==================== CARDEALER ====================
    cardealer = {
        male = {
            -- Học viên (Grade 0)
            trainee = {
                grades = {0, 1, 2, 3, 4},
                clothing = {
                    ['tshirt'] = {drawable = 150, texture = 10},
                    ['arms'] = {drawable = 1, texture = 0},
                    ['torso'] = {drawable = 932, texture = 0},
                    ['pants'] = {drawable = 308, texture = 0}
                }
            }
        },
        
        female = {
            -- Học viên (Grade 0)
            trainee = {
                grades = {0, 1, 2, 3, 4},
                clothing = {
                    ['tshirt'] = {drawable = 10, texture = 0},
                    ['arms'] = {drawable = 268, texture = 0},
                    ['torso'] = {drawable = 955, texture = 0},
                    ['pants'] = {drawable = 273, texture = 0}
                }
            }
        }
    },

    -- ==================== TAXI ====================
    taxi = {
        male = {
            -- Học viên (Grade 0)
            trainee = {
                grades = {0},
                clothing = {
                    ['tshirt'] = {drawable = 15, texture = 0},
                    ['torso'] = {drawable = 893, texture = 1},
                    ['pants'] = {drawable = 24, texture = 0},
                    ['shoes'] = {drawable = 15, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0},
                    ['bproof'] = {drawable = 0, texture = 0},
                }
            },
            
            -- Nhân viên (Grade 1-2)
            employee = {
                grades = {1, 2, 3},
                clothing = {
                    ['tshirt'] = {drawable = 15, texture = 0},
                    ['torso'] = {drawable = 893, texture = 1},
                    ['pants'] = {drawable = 24, texture = 0},
                    ['shoes'] = {drawable = 15, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0},
                    ['bproof'] = {drawable = 0, texture = 0},
                }
            },
            
            -- Nhân viên cao cấp (Grade 3)
            senior = {
                grades = {4},
                clothing = {
                    ['tshirt'] = {drawable = 15, texture = 0},
                    ['torso'] = {drawable = 893, texture = 1},
                    ['pants'] = {drawable = 24, texture = 0},
                    ['shoes'] = {drawable = 15, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0},
                    ['bproof'] = {drawable = 0, texture = 0},
                }
            }
        },
        
        female = {
            -- Học viên (Grade 0)
            trainee = {
                grades = {0},
                clothing = {
                    ['torso'] = {drawable = 1413, texture = 1},
                    ['tshirt'] = {drawable = 381, texture = 0},
                    ['pants'] = {drawable = 1, texture = 1},
                    ['arms'] = {drawable = 260, texture = 0}
                }
            },
            
            -- Nhân viên (Grade 1-2)
            employee = {
                grades = {1, 2, 3},
                clothing = {
                    ['torso'] = {drawable = 1413, texture = 1},
                    ['tshirt'] = {drawable = 381, texture = 0},
                    ['pants'] = {drawable = 1, texture = 1},
                    ['arms'] = {drawable = 260, texture = 0}
                }
            },
            
            -- Nhân viên cao cấp (Grade 3)
            senior = {
                grades = {4},
                clothing = {
                    ['torso'] = {drawable = 1413, texture = 1},
                    ['tshirt'] = {drawable = 381, texture = 0},
                    ['pants'] = {drawable = 1, texture = 1},
                    ['arms'] = {drawable = 260, texture = 0}
                }
            }
        }
    },

    -- ==================== REALESTATE ====================
    realestate = {
        male = {
            -- Nhân viên (Grade 0-2)
            employee = {
                grades = {0, 1, 2},
                clothing = {
                    ['tshirt'] = {drawable = 15, texture = 0},
                    ['torso'] = {drawable = 768, texture = 0},
                    ['pants'] = {drawable = 11, texture = 0},
                    ['shoes'] = {drawable = 15, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0},
                    ['bproof'] = {drawable = 0, texture = 0},
                    ['arms'] = {drawable = 4, texture = 0}
                }
            },
            
            -- Quản lý (Grade 3-5)
            manager = {
                grades = {3, 4, 5},
                clothing = {
                    ['tshirt'] = {drawable = 15, texture = 0},
                    ['torso'] = {drawable = 768, texture = 0},
                    ['pants'] = {drawable = 11, texture = 0},
                    ['shoes'] = {drawable = 15, texture = 0},
                    ['mask'] = {drawable = 0, texture = 0},
                    ['bproof'] = {drawable = 0, texture = 0},
                    ['arms'] = {drawable = 4, texture = 0}
                }
            }
        },
        
        female = {
            -- Nhân viên (Grade 0-2)
            employee = {
                grades = {0, 1, 2},
                clothing = {
                    ['tshirt'] = {drawable = 3, texture = 0},
                    ['torso'] = {drawable = 795, texture = 0},
                    ['pants'] = {drawable = 273, texture = 0},
                    ['arms'] = {drawable = 268, texture = 0}
                }
            },
            
            -- Quản lý (Grade 3-5)
            manager = {
                grades = {3, 4, 5},
                clothing = {
                    ['tshirt'] = {drawable = 3, texture = 0},
                    ['torso'] = {drawable = 795, texture = 0},
                    ['pants'] = {drawable = 273, texture = 0},
                    ['arms'] = {drawable = 268, texture = 0}
                }
            }
        }
    },
    ------------------------------------------------------------------------
    -- ==================== DO XE ====================
    mechanic = {
        male = {
            -- Nhân viên (Grade 0-2)
            employee = {
                grades = {0},
                clothing = {
                    ['tshirt'] = {drawable = 312, texture = 0},
                    ['torso'] = {drawable = 931, texture = 0},
                    ['pants'] = {drawable = 307, texture = 0},
                    ['arms'] = {drawable = 12, texture = 0},
                }
            },

            nhanvien = {
                grades = {1},
                clothing = {
                    ['tshirt'] = {drawable = 312, texture = 0},
                    ['torso'] = {drawable = 931, texture = 1},
                    ['pants'] = {drawable = 307, texture = 1},
                    ['arms'] = {drawable = 12, texture = 0},
                }
            },

            nhanvien2 = {
                grades = {2, 3},
                clothing = {
                    ['tshirt'] = {drawable = 312, texture = 0},
                    ['torso'] = {drawable = 931, texture = 2},
                    ['pants'] = {drawable = 307, texture = 2},
                    ['arms'] = {drawable = 12, texture = 0},
                }
            },

            nhanvien3 = {
                grades = {4, 5},
                clothing = {
                    ['tshirt'] = {drawable = 312, texture = 0},
                    ['torso'] = {drawable = 931, texture = 3},
                    ['pants'] = {drawable = 307, texture = 3},
                    ['arms'] = {drawable = 12, texture = 0},
                }
            }
        },
        
        female = {
            -- Nhân viên (Grade 0-2)
            employee = {
                grades = {0},
                clothing = {
                    ['tshirt'] = {drawable = 297, texture = 0},
                    ['torso'] = {drawable = 954, texture = 0},
                    ['pants'] = {drawable = 287, texture = 0},
                    ['arms'] = {drawable = 3, texture = 0},
                }
            },

            nhanvien = {
                grades = {1},
                clothing = {
                    ['tshirt'] = {drawable = 297, texture = 0},
                    ['torso'] = {drawable = 954, texture = 1},
                    ['pants'] = {drawable = 287, texture = 1},
                    ['arms'] = {drawable = 3, texture = 0},
                }
            },

            nhanvien2 = {
                grades = {2, 3},
                clothing = {
                    ['tshirt'] = {drawable = 297, texture = 0},
                    ['torso'] = {drawable = 954, texture = 2},
                    ['pants'] = {drawable = 287, texture = 2},
                    ['arms'] = {drawable = 3, texture = 0},
                }
            },

            nhanvien3 = {
                grades = {4,5},
                clothing = {
                    ['tshirt'] = {drawable = 297, texture = 0},
                    ['torso'] = {drawable = 954, texture = 3},
                    ['pants'] = {drawable = 287, texture = 3},
                    ['arms'] = {drawable = 3, texture = 0},
                }
            }
        }
    },
    ------------------------------------------------------------------------
      
    ------------------------------------------------------------------------
}

-- Component IDs cho GTA V
-- https://docs.fivem.net/natives/?_0x262B14F48D29DE80
Config.Components = {
    ['helmet'] = 0,    -- Prop (Mũ/Helmet)
    ['mask'] = 1,      -- Mask
    ['hair'] = 2,      -- Hair
    ['torso'] = 11,    -- Torso/Tops (Áo khoác) - ĐÃ SỬA
    ['arms'] = 3,      -- Arms (Cánh tay)
    ['pants'] = 4,     -- Legs (Quần)
    ['bag'] = 5,       -- Bags/Parachute
    ['shoes'] = 6,     -- Shoes (Giày)
    ['accessory'] = 7, -- Accessories
    ['tshirt'] = 8,    -- Undershirt (Áo trong)
    ['bproof'] = 9,    -- Body Armor (Giáp)
    ['decals'] = 10    -- Decals
}
