-- Items for ox_inventory - MT Workshops
-- Tất cả items cần thiết cho hệ thống cosmetics

return {
    -- Paint & Cosmetics Items
    ['mechspray'] = {
        label = 'Sơn xe',
        weight = 500,
        stack = true,
        close = true,
        description = 'Dùng để sơn xe với nhiều màu khác nhau',
        client = {
            image = 'mechspray.png',
        }
    },

    ['cosmetics'] = {
        label = 'Đồ trang trí xe',
        weight = 200,
        stack = true,
        close = true,
        description = 'Các phụ kiện trang trí cho xe',
        client = {
            image = 'cosmetics.png',
        }
    },

    ['neon_custom'] = {
        label = 'Bóng đèn gầm',
        weight = 300,
        stack = true,
        close = true,
        description = 'Bóng đèn LED gầm xe với nhiều màu sắc',
        client = {
            image = 'neon_custom.png',
        }
    },

    -- Wheels & Rims
    ['car_wheel'] = {
        label = 'Mâm xe',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Mâm xe chất lượng cao cho nhiều loại xe',
        client = {
            image = 'car_wheel.png',
        }
    },

    -- Body Parts
    ['spoiler'] = {
        label = 'Cánh gió',
        weight = 800,
        stack = true,
        close = true,
        description = 'Cánh gió thể thao cho xe',
        client = {
            image = 'spoiler.png',
        }
    },

    ['front_bumper'] = {
        label = 'Cản trước',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Cản trước thể thao',
        client = {
            image = 'front_bumper.png',
        }
    },

    ['rear_bumper'] = {
        label = 'Cản sau',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Cản sau thể thao',
        client = {
            image = 'rear_bumper.png',
        }
    },

    ['skirtcar'] = {
        label = 'Ốp hông',
        weight = 600,
        stack = true,
        close = true,
        description = 'Ốp hông thể thao cho xe',
        client = {
            image = 'skirtcar.png',
        }
    },

    ['exhaust'] = {
        label = 'Ống xả',
        weight = 1200,
        stack = true,
        close = true,
        description = 'Ống xả thể thao, tăng hiệu suất',
        client = {
            image = 'exhaust.png',
        }
    },

    ['car_hood'] = {
        label = 'Nắp capo',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Nắp capo carbon fiber',
        client = {
            image = 'car_hood.png',
        }
    },

    -- Interior Items
    ['horn'] = {
        label = 'Còi xe',
        weight = 100,
        stack = true,
        close = true,
        description = 'Còi xe với nhiều âm thanh khác nhau',
        client = {
            image = 'horn.png',
        }
    },

    ['internals'] = {
        label = 'Phụ kiện nội thất',
        weight = 300,
        stack = true,
        close = true,
        description = 'Các phụ kiện trang trí nội thất xe',
        client = {
            image = 'internals.png',
        }
    },

    ['seats'] = {
        label = 'Ghế xe',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Ghế thể thao chất lượng cao',
        client = {
            image = 'seats.png',
        }
    },

    -- Engine & Performance
    ['engine_block'] = {
        label = 'Khối động cơ',
        weight = 5000,
        stack = true,
        close = true,
        description = 'Khối động cơ hiệu suất cao',
        client = {
            image = 'engine_block.png',
        }
    },

    -- Plates & Livery
    ['vanity_plate'] = {
        label = 'Biển số trang trí',
        weight = 50,
        stack = true,
        close = true,
        description = 'Biển số tùy chỉnh',
        client = {
            image = 'vanity_plate.png',
        }
    },

    ['livery'] = {
        label = 'Tem dán',
        weight = 100,
        stack = true,
        close = true,
        description = 'Tem dán trang trí cho xe',
        client = {
            image = 'livery.png',
        }
    },

    -- Repair Items
    ['phutung'] = {
        label = 'Phụ tùng động cơ',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Phụ tùng dùng để sửa động cơ xe',
        client = {
            image = 'phutung.png',
        }
    },

    ['thanvo'] = {
        label = 'Phụ tùng thân vỏ',
        weight = 800,
        stack = true,
        close = true,
        description = 'Phụ tùng dùng để sửa thân vỏ xe',
        client = {
            image = 'thanvo.png',
        }
    },

    ['bolauxe'] = {
        label = 'Bộ lau xe',
        weight = 200,
        stack = true,
        close = true,
        description = 'Dùng để rửa xe',
        client = {
            image = 'bolauxe.png',
        }
    },

    ['phutungdacbiet'] = {
        label = 'Phụ tùng xe đặc biệt',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Phụ tùng chuyên dùng để sửa xe công an, xe bác sĩ và các xe đặc biệt khác',
        client = {
            image = 'phutungdacbiet.png',
        }
    },

    -- Tuner Items
    ['tuner_pad'] = {
        label = 'Máy tính độ xe',
        weight = 300,
        stack = false,
        close = true,
        description = 'Máy tính chuyên dụng để xem và chỉnh sửa phụ tùng xe',
        client = {
            image = 'tuner_pad.png',
        }
    },

    -- Discount Vouchers / Phiếu giảm giá
    ['phieu_giam_gia_10'] = {
        label = 'Phiếu giảm giá 10%',
        weight = 10,
        stack = true,
        close = true,
        description = 'Phiếu giảm giá 10% khi thanh toán hóa đơn sửa xe',
        client = {
            image = 'coupon.png',
        }
    },

    ['phieu_giam_gia_20'] = {
        label = 'Phiếu giảm giá 20%',
        weight = 10,
        stack = true,
        close = true,
        description = 'Phiếu giảm giá 20% khi thanh toán hóa đơn sửa xe',
        client = {
            image = 'coupon.png',
        }
    },

    ['phieu_giam_gia_30'] = {
        label = 'Phiếu giảm giá 30%',
        weight = 10,
        stack = true,
        close = true,
        description = 'Phiếu giảm giá 30% khi thanh toán hóa đơn sửa xe',
        client = {
            image = 'coupon.png',
        }
    },

    ['phieu_giam_gia_50'] = {
        label = 'Phiếu giảm giá 50%',
        weight = 10,
        stack = true,
        close = true,
        description = 'Phiếu giảm giá 50% khi thanh toán hóa đơn sửa xe',
        client = {
            image = 'coupon.png',
        }
    },
}
