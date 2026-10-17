Config = {}

Config.DMVSchool = {
    vector4(224.01, -1385.96, 30.52, 251.35)
}

Config.Language = "vi"

Config.SpeedMultiplier = 3.6 -- 3.6 for kmh, 2.236936 for mph

Config.MarkerSettings = {
    type = 1, -- 1 = vòng tròn nổi, 2 = mũi tên, 20 = vòng tròn dưới đất
    size = vector3(3.0, 3.0, 1.0),
    color = vector3(0, 255, 0), -- RGB: Xanh lá
    rotate = false,
    dump = false
}

Config.PuntiMinimi = 5 -- Minimum points to pass the theory test

-- Theory result images
Config.ResultImages = {
    pass = 'https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/success.jpg',  -- Link ảnh thi đậu
    fail = 'https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/fail.jpg'   -- Link ảnh thi rớt
}

-- ATTENTION: Modifying the id after a user has already obtained a license causes them to be lost
Config.License = {
    {
        label = 'Bằng A',
        id = 'license_bike',
        img = 'bike.png',
        pricing = {
            theory = 1000,      -- Giá thi lý thuyết
            practice = 2000,   -- Giá thi thực hành
            reissue = 5000      -- Giá cấp lại bằng
        },
        practiceTimeLimit = 300, -- Thời gian thi (giây) - 5 phút
        maxErrors = 3, -- Số lỗi tối đa cho phép (4 lỗi = thất bại)
        maxSpeed = 60, -- Tốc độ tối đa (km/h)
        vehicle = {
            model = 'faggio',
            coords = vector3(231.2591, -1392.982, 30.50785),
            heading = 144.40260314941,
            plate = "DMV1"
        }
    },
    {
        label = 'Bằng B',
        id = 'license_car',
        img = 'car.png',
        pricing = {
            theory = 2000,      -- Giá thi lý thuyết
            practice = 4000,   -- Giá thi thực hành
            reissue = 10000      -- Giá cấp lại bằng
        },
        practiceTimeLimit = 480, -- Thời gian thi (giây) - 8 phút
        maxErrors = 4, -- Số lỗi tối đa cho phép (5 lỗi = thất bại)
        maxSpeed = 80, -- Tốc độ tối đa (km/h)
        vehicle = {
            model = 'blista',
            coords = vector3(231.2591, -1392.982, 30.50785),
            heading = 144.40260314941,
            plate = "DMV1"
        }
    },
    {
        label = 'Bằng C',
        id = 'license_truck',
        img = 'truck.png',
        pricing = {
            theory = 6000,     -- Giá thi lý thuyết
            practice = 10000,   -- Giá thi thực hành
            reissue = 15000      -- Giá cấp lại bằng
        },
        practiceTimeLimit = 600, -- Thời gian thi (giây) - 10 phút
        maxErrors = 5, -- Số lỗi tối đa cho phép (6 lỗi = thất bại)
        maxSpeed = 70, -- Tốc độ tối đa (km/h)
        vehicle = {
            model = 'pounder',
            coords = vector3(245.74, -1398.34, 30.52),
            heading = 84.47,
            plate = "DMV1"
        }
    }
}

Config.PracticeCoords = {
    [1] = {
        {
            coordinate = vector3(227.1181, -1399.691, 30.1),
            speedLimit = 50
        },
        {
            coordinate = vector3(183.7479, -1394.595, 29.05295),
            speedLimit = 50
        },
        {
            coordinate = vector3(210.3608, -1327.127, 29.16619),
            speedLimit = 50
        },
        {
            coordinate = vector3(217.6466, -1145.248, 29.3349),
            speedLimit = 50
        },
        {
            coordinate = vector3(83.13854, -1136.699, 29.15778),
            speedLimit = 50
        },
        {
            coordinate = vector3(55.52874, -1248.127, 29.34311),
            speedLimit = 50
        },
        {
            coordinate = vector3(82.69904, -1338.678, 29.3447),
            speedLimit = 50
        },
        {
            coordinate = vector3(131.4893, -1387.581, 29.28993),
            speedLimit = 50
        },
        {
            coordinate = vector3(220.603, -1445.61, 29.24681),
            speedLimit = 50
        },
        {
            coordinate = vector3(242.2584, -1536.136, 29.24705),
            speedLimit = 50
        },
        {
            coordinate = vector3(301.6448, -1523.68, 29.34156),
            speedLimit = 50
        },
        {
            coordinate = vector3(256.1726, -1445.458, 29.24207),
            speedLimit = 50
        },
        {
            coordinate = vector3(233.427, -1397.215, 30.5071),
            speedLimit = 50
        },
    }
}


-- Câu hỏi theo từng loại bằng: license_bike (Bằng A), license_car (Bằng B), license_truck (Bằng C)
Config.Question = {
    ['license_bike'] = { -- Bằng A - Xe máy
        {
            label = "Khi trời mưa to, đường trơn như bôi mỡ, bạn nên:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: C (cầu nguyện không thay được phanh)",
            options = {
                { label = "A. Chạy nhanh cho mau tới", correct = false },
                { label = "B. Thả tay lái cho 'nghệ'", correct = false },
                { label = "C. Giảm tốc độ và giữ khoảng cách", correct = true },
                { label = "D. Cầu trời khấn Phật", correct = false }
            }
        },
        {
            label = "Thấy đèn vàng nhấp nháy ở ngã tư, bạn phải:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (đèn vàng không phải đèn xanh nha bạn ơi)",
            options = {
                { label = "A. Tăng tốc vượt cho kịp", correct = false },
                { label = "B. Dừng lại quan sát rồi đi", correct = true },
                { label = "C. Bấm còi inh ỏi rồi lao thẳng", correct = false },
                { label = "D. Nhắm mắt lại rồi cầu may", correct = false }
            }
        },
        {
            label = "Xe máy của bạn bị hết xăng giữa đường, bạn nên:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (khóc giải quyết được gì đâu bạn)",
            options = {
                { label = "A. Ngồi khóc giữa đường", correct = false },
                { label = "B. Để xe giữa đường rồi đi mua xăng", correct = false },
                { label = "C. Gọi điện than phiền với bạn bè", correct = false },
                { label = "D. Đẩy xe vào lề đường an toàn", correct = true }
            }
        },
        {
            label = "Khi vượt xe khác trên đường, bạn cần:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (vượt kiểu F1 thì ở nhà chơi game đi)",
            options = {
                { label = "A. Bấm còi inh ỏi cho oai", correct = false },
                { label = "B. Quan sát, báo hiệu và vượt an toàn", correct = true },
                { label = "C. Lao thẳng không cần nhìn", correct = false },
                { label = "D. Vừa vượt vừa nhắn tin", correct = false }
            }
        },
        {
            label = "Biển báo hình tam giác viền đỏ, giữa có hình chữ 'Dốc xuống nguy hiểm' nghĩa là:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            options = {
                { label = "A. Giảm tốc độ, cẩn thận khi xuống dốc", correct = true },
                { label = "B. Chỗ này để đua xe", correct = false },
                { label = "C. Tăng ga cho xe nhanh hơn", correct = false },
                { label = "D. Tắt máy lao xuống cho phê", correct = false }
            }
        },
        {
            label = "Khi dừng xe chờ đèn đỏ, bạn nên:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: A (vạch trắng có vẽ để cho đẹp đâu)",
            options = {
                { label = "A. Dừng ngay vạch trắng", correct = true },
                { label = "B. Vượt qua vạch một tí cho đỡ chờ", correct = false },
                { label = "C. Dừng giữa đường cho oai", correct = false },
                { label = "D. Vẫn chạy nếu không có ai", correct = false }
            }
        },
        {
            label = "Khi chở người ngồi sau xe máy, bạn cần:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (mũ bảo hiểm quan trọng hơn mũ lưỡi trai)",
            options = {
                { label = "A. Bắt người ngồi sau bịt mắt", correct = false },
                { label = "B. Chạy nhanh cho kịp giờ", correct = false },
                { label = "C. Đảm bảo cả hai đều đội mũ bảo hiểm", correct = true },
                { label = "D. Bắt người sau tự bám lấy", correct = false }
            }
        },
        {
            label = "Khi xe máy bị trượt bánh, bạn nên:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (bình tĩnh mới sống được bạn ơi)",
            options = {
                { label = "A. Hét lên cho đã căng thẳng", correct = false },
                { label = "B. Giữ thăng bằng, không phanh gấp", correct = true },
                { label = "C. Nhảy ra khỏi xe ngay", correct = false },
                { label = "D. Đạp phanh hết cỡ", correct = false }
            }
        },
        {
            label = "Thấy biển báo 'Cấm rẽ trái', bạn phải:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (biển báo không phải để trang trí)",
            options = {
                { label = "A. Rẽ trái nếu không có CSGT", correct = false },
                { label = "B. Rẽ trái rồi chạy thật nhanh", correct = false },
                { label = "C. Tuân thủ, tìm đường khác", correct = true },
                { label = "D. Tranh luận với biển báo", correct = false }
            }
        },
        {
            label = "Khi đi vào đường hầm, bạn cần:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (đây không phải rạp hát để hét)",
            options = {
                { label = "A. Bật đèn chiếu sáng và giảm tốc độ", correct = true },
                { label = "B. Tắt đèn cho tiết kiệm điện", correct = false },
                { label = "C. Tăng tốc để qua nhanh", correct = false },
                { label = "D. Hét lên nghe tiếng vang", correct = false }
            }
        }
    },
    ['license_car'] = { -- Bằng B - Ô tô
        {
            label = "Khi trời mưa to, tầm nhìn hạn chế, bạn nên:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (về nhà sớm nhưng không còn mạng thì ý nghĩa gì)",
            options = {
                { label = "A. Tăng tốc độ để về nhà sớm", correct = false },
                { label = "B. Giảm tốc, bật đèn và giữ khoảng cách", correct = true },
                { label = "C. Đóng mắt lái cho may mắn", correct = false },
                { label = "D. Vừa lái vừa livestream", correct = false }
            }
        },
        {
            label = "Khi xe ô tô của bạn bị nổ lốp trên đường cao tốc, bạn nên:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (phanh gấp là bay luôn đó)",
            options = {
                { label = "A. Đạp phanh gấp ngay lập tức", correct = false },
                { label = "B. Tăng tốc để thoát khỏi đoạn đường", correct = false },
                { label = "C. Nhảy ra khỏi xe", correct = false },
                { label = "D. Giữ chặt vô lăng, giảm tốc từ từ", correct = true }
            }
        },
        {
            label = "Thấy xe cứu thương có còi hú, bạn phải:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (đây không phải Fast & Furious)",
            options = {
                { label = "A. Tăng tốc đua với xe cứu thương", correct = false },
                { label = "B. Nhường đường và tránh sang", correct = true },
                { label = "C. Chặn đường để xem gì vui", correct = false },
                { label = "D. Bấm còi đáp lễ", correct = false }
            }
        },
        {
            label = "Khi đi qua khu vực trường học, bạn phải:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (trẻ con nó không biết sợ xe đâu bạn)",
            options = {
                { label = "A. Chạy bình thường không cần giảm tốc", correct = false },
                { label = "B. Bấm còi liên tục để cảnh báo", correct = false },
                { label = "C. Tăng tốc để qua nhanh", correct = false },
                { label = "D. Giảm tốc độ xuống dưới 30km/h", correct = true }
            }
        },
        {
            label = "Khi nhập làn cao tốc từ đường nhánh, bạn cần:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (nhập làn kiểu F1 thì tai nạn liền)",
            options = {
                { label = "A. Lao thẳng vào không cần nhìn", correct = false },
                { label = "B. Tăng tốc phù hợp, quan sát và nhập làn an toàn", correct = true },
                { label = "C. Dừng xe chờ không có xe mới vào", correct = false },
                { label = "D. Nhập làn chậm rãi 20km/h", correct = false }
            }
        },
        {
            label = "Thấy đèn đỏ nhưng không có xe, bạn nên:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (camera nó không ngủ đâu bạn)",
            options = {
                { label = "A. Vượt đèn đỏ vì không ai thấy", correct = false },
                { label = "B. Dừng và chờ đèn xanh", correct = true },
                { label = "C. Chạy chậm qua cho an toàn", correct = false },
                { label = "D. Xem điện thoại chờ đèn xanh", correct = false }
            }
        },
        {
            label = "Khi vào cua gấp trên đường núi, bạn phải:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (drift để ngắm cảnh hả bạn)",
            options = {
                { label = "A. Tăng tốc để drift đẹp", correct = false },
                { label = "B. Nhắm mắt và đi thẳng", correct = false },
                { label = "C. Giảm tốc độ, bấm còi báo hiệu", correct = true },
                { label = "D. Thả tay lái xem sao", correct = false }
            }
        },
        {
            label = "Khi thắt dây an toàn, bạn cần:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: A (dây an toàn là bạn thân nhất khi đi xe)",
            options = {
                { label = "A. Thắt qua vai và hông chắc chắn", correct = true },
                { label = "B. Thắt cho có, không cần kéo chặt", correct = false },
                { label = "C. Để phía sau ghế cho thoải mái", correct = false },
                { label = "D. Không cần thắt nếu đi gần", correct = false }
            }
        },
        {
            label = "Thấy biển 'Hết cấm vượt', nghĩa là:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: A (nhưng vượt cũng phải có não nhé)",
            options = {
                { label = "A. Được phép vượt an toàn", correct = true },
                { label = "B. Vẫn cấm vượt", correct = false },
                { label = "C. Vượt bừa cũng được", correct = false },
                { label = "D. Biển báo trêu người", correct = false }
            }
        },
        {
            label = "Khi phanh xe bị mất phanh đột ngột, bạn nên:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (hét to giải quyết được gì bạn ơi)",
            options = {
                { label = "A. Hét to 'Ối giời ơi!'", correct = false },
                { label = "B. Sử dụng phanh tay và giảm số", correct = true },
                { label = "C. Nhảy ra khỏi xe đang chạy", correct = false },
                { label = "D. Tắt máy và cầu nguyện", correct = false }
            }
        }
    },
    ['license_truck'] = { -- Bằng C - Xe tải
        {
            label = "Khi lái xe tải nặng xuống dốc dài, bạn cần:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (xuống dốc như tên lửa thì gặp tổ tiên sớm)",
            options = {
                { label = "A. Tăng tốc cho nhanh xuống", correct = false },
                { label = "B. Sử dụng phanh engine và phanh tay", correct = true },
                { label = "C. Tắt máy lao xuống cho tự nhiên", correct = false },
                { label = "D. Ngủ một giấc cho khỏe", correct = false }
            }
        },
        {
            label = "Khi chở hàng quá khổ, quá tải, bạn có được phép:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (luật nó có để cho vui đâu bạn)",
            options = {
                { label = "A. Được, nếu không ai biết", correct = false },
                { label = "B. Không được, vi phạm luật giao thông", correct = true },
                { label = "C. Được, nếu đi ban đêm", correct = false },
                { label = "D. Được, nếu đưa tiền CSGT", correct = false }
            }
        },
        {
            label = "Trước khi khởi hành với xe tải, bạn phải:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: A (cầu trời không bằng kiểm tra xe)",
            options = {
                { label = "A. Kiểm tra phanh, đèn, lốp xe kỹ càng", correct = true },
                { label = "B. Lên xe chạy luôn cho nhanh", correct = false },
                { label = "C. Chỉ cần nổ máy là đủ", correct = false },
                { label = "D. Cầu trời phù hộ là được", correct = false }
            }
        },
        {
            label = "Khi rẽ phải với xe tải dài, bạn cần chú ý:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (đuôi xe tải quét như đuôi khủng long đó)",
            options = {
                { label = "A. Rẽ gấp cho nhanh", correct = false },
                { label = "B. Khoảng quét của đuôi xe và xe sau", correct = true },
                { label = "C. Không cần quan sát", correct = false },
                { label = "D. Thả tay lái để xe tự rẽ", correct = false }
            }
        },
        {
            label = "Khi lùi xe tải không có người hướng dẫn, bạn phải:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (lùi xe tải không phải lùi xe đạp)",
            options = {
                { label = "A. Lùi nhanh cho xong việc", correct = false },
                { label = "B. Quan sát kỹ cả 2 gương và phía sau", correct = true },
                { label = "C. Nhắm mắt lùi thôi", correct = false },
                { label = "D. Nhờ người đi đường chỉ huy", correct = false }
            }
        },
        {
            label = "Khi chở hàng dễ cháy nổ, bạn cần:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (hút thuốc thì nổ tung luôn nhé)",
            options = {
                { label = "A. Hút thuốc trong xe cho tỉnh táo", correct = false },
                { label = "B. Chạy nhanh để giảm rủi ro", correct = false },
                { label = "C. Giấu hàng đi cho khỏi sợ", correct = false },
                { label = "D. Gắn biển cảnh báo và tuân thủ quy định", correct = true }
            }
        },
        {
            label = "Khi phanh xe tải trên đường trơn, bạn nên:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (phanh gấp là đảm bảo trượt dài)",
            options = {
                { label = "A. Đạp phanh hết cỡ", correct = false },
                { label = "B. Không phanh để xe tự dừng", correct = false },
                { label = "C. Phanh nhẹ từng nhịp, tránh phanh gấp", correct = true },
                { label = "D. Rẽ sang trái cho nhanh dừng", correct = false }
            }
        },
        {
            label = "Độ cao tối đa của hàng hóa trên xe tải là:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (cao như tháp Eiffel thì cấm luôn)",
            options = {
                { label = "A. Càng cao càng tốt", correct = false },
                { label = "B. Theo quy định của luật giao thông", correct = true },
                { label = "C. Chỗ nào vừa là được", correct = false },
                { label = "D. Không có quy định cụ thể", correct = false }
            }
        },
        {
            label = "Khi xe tải bị mất lái ở tốc độ cao, bạn cần:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: B (hét thì chỉ tốn hơi thôi bạn ơi)",
            options = {
                { label = "A. Hét lên thật to", correct = false },
                { label = "B. Giảm tốc từ từ, giữ thăng bằng", correct = true },
                { label = "C. Đạp phanh gấp ngay", correct = false },
                { label = "D. Nhảy ra khỏi xe", correct = false }
            }
        },
        {
            label = "Khi đỗ xe tải trên dốc, bạn phải:",
            image = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/background.jpg",
            correctExplanation = "👉 Đáp án đúng: A (trôi xuống đè người thì tội lắm)",
            options = {
                { label = "A. Kéo phanh tay và chèn bánh xe", correct = true },
                { label = "B. Chỉ cần tắt máy là đủ", correct = false },
                { label = "C. Không cần làm gì", correct = false },
                { label = "D. Để xe tự trôi xuống", correct = false }
            }
        }
    }
}

Config.Lang = {
    ['vi'] = {
        ['speed_error'] = "Bạn đang chạy quá nhanh, hãy giảm tốc độ!",
        ['open_dmv'] = "Nhấn ~INPUT_CONTEXT~ để mở trường dạy lái xe",
        ['dmv'] = " THI BẰNG LÁI XE",
        ['point'] = "ĐIỂM SỐ",
        ['error'] = "LỖI",
        ['ok'] = "Tiếp tục",
        ['start_theory'] = "Phần thi lý thuyết",
        ['theory_before'] = "Thi Thực Hành",
        ['start_practice'] = "Thi thực hành",
        ['reissue_license'] = "Cấp lại GPLX",
        ['test_passed'] = "Đã vượt qua bài thi!",
        ['already_done'] = "Đã hoàn thành!",
        ['theory_success'] = "Chúc mừng, bạn đã vượt qua bài thi lý thuyết, hãy quay lại sớm để thi thực hành!",
        ['theory_error'] = "Rất tiếc, bạn chưa vượt qua bài thi lý thuyết, đừng nản lòng, hãy quay lại chuẩn bị kỹ hơn và thử lại!",
        ['practice_success'] = "Chúc mừng, bạn đã vượt qua bài thi thực hành, bây giờ bạn đã có bằng lái xe!",
        ['practice_error'] = "Rất tiếc, bạn chưa vượt qua bài thi thực hành, đừng nản lòng, hãy quay lại chuẩn bị kỹ hơn và thử lại!",
        ['practice_fail_light'] = "Rớt sát sao quá bạn ơi! Lần sau cẩn thận một tí là đậu ngay! 😅",
        ['practice_fail_medium'] = "'Hung thần xa lộ' đã xuất hiện! Về nhà luyện thêm đi bạn ơi! 🚗💨",
        ['practice_fail_heavy'] = "Bạn lái xe như đang chơi GTA chế độ Chaos! Về xem lại bằng lý thuyết đi! 🎮💥",
        ['money_error'] = "Bạn không đủ tiền để làm bài thi này! Bạn còn thiếu %s€",
        ['reissue_notqualified'] = "Bạn phải thi đậu cả lý thuyết và thực hành mới được cấp lại bằng!",
        ['reissue_success'] = "Đã cấp lại bằng lái thành công!",
        ['reissue_error'] = "Bạn chưa có bằng lái này để cấp lại!",
        ['exam_title_bike'] = "ĐỀ THI BẰNG LÁI XE MÁY",
        ['exam_title_car'] = "ĐỀ THI BẰNG LÁI Ô TÔ",
        ['exam_title_truck'] = "ĐỀ THI BẰNG LÁI XE TẢI"
    }
}

-- Functions --

onCompleteTheory = function(license)
    TriggerServerEvent('ricky-dmv:givelicense', license) -- Give license to sql
end

onCompletePractice = function(license)
    TriggerServerEvent('ricky-dmv:givelicense', license) -- Give license to sql
end