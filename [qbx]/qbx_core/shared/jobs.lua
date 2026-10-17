---Job names must be lower case (top level table key)
---@type table<string, Job>
return {
    ['unemployed'] = {
        label = 'Nghề nghiệp',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Tự do',
                payment = 10
            },
        },
    },
    ['police'] = {
        label = 'Cảnh Sát',
        type = 'leo',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Học viên',
                payment = 1500
            },
            [1] = {
                name = 'Tân Binh',
                payment = 2500
            },

            [2] = {
                name = 'Hạ Sĩ',
                payment = 3250
            },

            [3] = {
                name = 'Trung Sĩ',
                payment = 3300
            },

            [4] = {
                name = 'Thượng sĩ',
                payment = 3350
            },

            [5] = {
                name = 'Thiếu úy',
                payment = 3400
            },

            [6] = {
                name = 'Thượng úy',
                payment = 3450
            },

            [7] = {
                name = 'Đại úy',
                payment = 3500
            },

            [8] = {
                name = 'Thiếu tá',
                payment = 3550
            },

            [9] = {
                name = 'Trung tá',
                payment = 3600
            },

            [10] = {
                name = 'Đại tá',
                payment = 3900
            },

            [11] = {
                name = 'Thư Ký',
                isboss = true,
                payment = 4100
            },

            [12] = {
                name = 'Đồn phó',
                isboss = true,
                payment = 4200
            },

            [13] = {
                name = 'Đồn trưởng',
                isboss = true,
                payment = 4300
            },

            [14] = {
                name = 'Thống đốc',
                isboss = true,
                bankAuth = false,
                payment = 0
            },
           

        },
    },

    ['toathichinh'] = {
        label = 'Tòa Thị chính',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Thực tập EMS',
                payment = 0
            },

            [1] = {
                name = 'Thực tập PD',
                payment = 0
            },

            [2] = {
                name = 'Nhân viên TTC',
                payment = 0
            },

            [3] = {
                name = 'Nhân viên Cấp cao',
                payment = 0
            },
            [4] = {
                name = 'Quán lý TTC',
                isboss = true,
                payment = 0
            },
            
            [5] = {
                name = 'Thống đốc',
                isboss = true,
                bankAuth = true,
                payment = 0
            },
        },
    },

    ['bcso'] = {
        label = 'Tòa thị chính',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Officer',
                payment = 75
            },
            [2] = {
                name = 'Sergeant',
                payment = 100
            },
            [3] = {
                name = 'Lieutenant',
                payment = 125
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },

    ['doxe'] = {
        label = 'Độ xe',
        type = 'doxe',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Học việc',
                payment = 50
            },
            [1] = {
                name = 'Thợ phụ',
                payment = 100
            },
            [2] = {
                name = 'Thợ chính',
                payment = 200
            },
            [3] = {
                name = 'Quản lý',
                isboss = true,
                payment = 300
            },
            [4] = {
                name = 'Giám đốc',
                isboss = true,
                bankAuth = true,
                payment = 500
            },
            [5] = {
                name = 'Thống đốc',
                isboss = true,
                bankAuth = true,
                payment = 500
            },
        },
    },

    ['ambulance'] = {
        label = 'EMS',
        type = 'ems',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Thực Tập Sinh',
                payment = 2500
            },
            [1] = {
                name = 'Bác Sĩ',
                payment = 3200
            },
            [2] = {
                name = 'Bác Sĩ Trưởng',
                payment = 3300
            },
            [3] = {
                name = 'Phó Khoa',
                payment = 3500
            },
            [4] = {
                name = 'Trưởng Khoa',
                payment = 3700
            },
            [5] = {
                name = 'Thư ký',
                payment = 3800
            },
            [6] = {
                name = 'Quản lý bác sĩ',
                payment = 3900
            },
            [7] = {
                name = 'Trợ lý Giám đốc',
                isboss = true,
                payment = 4100
            },
            [8] = {
                name = 'Phó Giám đốc',
                isboss = true,
                payment = 4200
            },
            [9] = {
                name = 'Giám Đốc',
                isboss = true,
                payment = 4300
            },
            [10] = {
                name = 'Thống đốc',
                isboss = true,
                bankAuth = false,
                payment = 0
            },
        },
    },

    ['banveso'] = {
        label = 'Bán vé số',
        type = 'banveso',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Tập bán',
                payment = 0
            },
            [1] = {
                name = 'Nhân viên',
                payment = 0
            },
            [2] = {
                name = 'Quản lý',
                payment = 0
            },
            [3] = {
                name = 'Chủ đại lý',
                isboss = true,
                bankAuth = false,
                payment = 0
            },
        },
    },

    ['quannuoc'] = {
        label = 'Quán Nước',
        type = 'quannuoc',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Phụ bàn',
                payment = 200
            },
            [1] = {
                name = 'Bartender',
                payment = 250
            },
            [2] = {
                name = 'Quản lý',
                payment = 300
            },
            [3] = {
                name = 'Phó giám đốc',
                isboss = true,
                payment = 400
            },
            [4] = {
                name = 'Giám đốc',
                isboss = true,
                bankAuth = true,
                payment = 500
            },
        },
    },

    ['quanan'] = {
        label = 'Quán Ăn',
        type = 'quanan',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Phụ bàn',
                payment = 200
            },
            [1] = {
                name = 'Đầu Bếp',
                payment = 250
            },
            [2] = {
                name = 'Quản lý',
                payment = 300
            },
            [3] = {
                name = 'Phó giám đốc',
                isboss = true,
                payment = 400
            },
            [4] = {
                name = 'Giám đốc',
                isboss = true,
                bankAuth = true,
                payment = 500
            },
        },
    },


    ['cayxang'] = {
        label = 'Cây Xăng',
        type = 'cayxang',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Nhân viên',
                payment = 500
            },
            [1] = {
                name = 'Quản lý',
                payment = 1000
            },
            [2] = {
                name = 'Phó Giám đốc',
                payment = 1300
            },
            [3] = {
                name = 'Giám đốc',
                isboss = true,
                bankAuth = true,
                payment = 1500
            },
        },
    },



    ['realestate'] = {
        label = 'Bất Động Sản',
        type = 'realestate',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Thử Việc',
                payment = 500
            },
            [1] = {
                name = 'Nhân viên',
                payment = 750
            },
            [2] = {
                name = 'Nhân viên cao cấp',
                payment = 1000
            },
            [3] = {
                name = 'Phó giám đốc',
                payment = 1250
            },
            [4] = {
                name = 'Giám đốc',
                isboss = true,
                bankAuth = true,
                payment = 1500
            },
            [5] = {
                name = 'Thống đốc',
                isboss = true,
                bankAuth = true,
                payment = 1500
            },
        },
    },

    ['taxi'] = {
        label = 'Taxi',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Thử việc',
                payment = 15
            },
            [1] = {
                name = 'Tài xế',
                payment = 15
            },
            [2] = {
                name = 'Quản lý',
                payment = 15
            },
            [3] = {
                name = 'Phó giám đốc',
                isboss = true,
                bankAuth = true,
                payment = 15
            },
            [4] = {
                name = 'Giám đốc',
                isboss = true,
                bankAuth = true,
                payment = 15
            },
            [5] = {
                name = 'Thống đốc',
                isboss = true,
                bankAuth = true,
                payment = 15
            },
        },
    },

    ['bus'] = {
        label = 'Bus',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 50
            },
        },
    },

    ['cardealer'] = {
        label = 'Car Dealer',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Thử Việc',
                payment = 1000
            },
            [1] = {
                name = 'Nhân Viên',
                payment = 2000
            },
            [2] = {
                name = 'Quản Lý',
                payment = 2500
            },
            [3] = {
                name = 'Phó Giám Đốc',
                isboss = true,
                payment = 3000
            },
            [4] = {
                name = 'Giám Đốc',
                isboss = true,
                bankAuth = true,
                payment = 3500
            },
        },
    },

    ['luxurycar'] = {
        label = 'Luxury Car shop',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Thử Việc',
                payment = 1000
            },
            [1] = {
                name = 'Nhân Viên',
                payment = 2000
            },
            [2] = {
                name = 'Quản Lý',
                payment = 2500
            },
            [3] = {
                name = 'Phó Giám Đốc',
                isboss = true,
                payment = 3000
            },
            [4] = {
                name = 'Giám Đốc',
                isboss = true,
                bankAuth = true,
                payment = 3500
            },
        },
    },

    ['mechanic'] = {
        label = 'Sửa Xe',
        type = 'mechanic',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Thử việc',
                payment = 1000
            },
            [1] = {
                name = 'Thợ chính',
                payment = 2000
            },
            [2] = {
                name = 'Quản lý',
                payment = 2500
            },
            [3] = {
                name = 'Phó Giám Đốc',
                isboss = true,
                payment = 3000
            },
            [4] = {
                name = 'Giám Đốc',
                isboss = true,
                bankAuth = true,
                payment = 3500
            },
            [5] = {
                name = 'Thống đốc',
                isboss = true,
                bankAuth = true,
                payment = 2000
            },
        },
    },

    ['bar'] = {
        label = 'Quán Bar',
        type = 'bar',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Phụ bàn',
                payment = 200
            },

            [1] = {
                name = 'bartender',
                payment = 250
            },

            [2] = {
                name = 'DJ',
                payment = 350
            },

            [3] = {
                name = 'Quản lý',
                payment = 350
            },

            [4] = {
                name = 'Phó giám đốc',
                isboss = true,
                payment = 400
            },

            [5] = {
                name = 'Giám đốc',
                isboss = true,
                bankAuth = true,
                payment = 500
            },
        },
    },

    ['judge'] = {
        label = 'Honorary',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Judge',
                payment = 100
            },
        },
    },
    ['lawyer'] = {
        label = 'Law Firm',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Associate',
                payment = 50
            },
        },
    },
    ['reporter'] = {
        label = 'Reporter',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Journalist',
                payment = 50
            },
        },
    },
   ['vukhi'] = {
        label = 'Vũ khí',
        type = 'vukhi',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Nhân viên',
                payment = 200
            },
            [1] = {
                name = 'Nhân viên',
                payment = 250
            },
            [2] = {
                name = 'Quản lý',
                payment = 300
            },
            [3] = {
                name = 'Phó giám đốc',
                isboss = true,
                payment = 400
            },
            [4] = {
                name = 'Giám đốc',
                isboss = true,
                bankAuth = true,
                payment = 500
            },
        },
    },
    ['trucker'] = {
        label = 'Trucker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 50
            },
        },
    },
    ['tow'] = {
        label = 'Towing',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 50
            },
        },
    },
    ['garbage'] = {
        label = 'Garbage',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Collector',
                payment = 50
            },
        },
    },
    ['vineyard'] = {
        label = 'Vineyard',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Picker',
                payment = 50
            },
        },
    },
    ['hotdog'] = {
        label = 'Hotdog',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Sales',
                payment = 50
            },
        },
    },
}
