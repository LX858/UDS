--[[
    Cảm ơn bạn đã sử dụng script của chúng tôi. Chúng tôi rất vui khi có bạn ở đây.
    Nếu bạn cần giúp đỡ, bạn có thể tham gia máy chủ Discord của chúng tôi.
    https://discord.gg/zppUXj4JRm
]]

DreamLocales['en'] = {
    ['NotifyHeader'] = 'Bãi giữ xe cảnh sát',

    ['GlobalVehicle'] = {
        ['ImpoundTarget'] = {
            ['Name'] = 'Tạm giữ phương tiện',
            ['Dialog'] = {
                ['Title'] = '🚓 Tạm giữ phương tiện',
                ['Model'] = 'Mẫu xe',
                ['Plate'] = 'Biển số',
                ['Officer'] = 'Cảnh sát',
                ['Duration'] = 'Thời gian giữ',
                ['Offence'] = 'Lý do vi phạm',
                ['OffencePlaceholder'] = 'Chọn lý do vi phạm',
                ['Fine'] = 'Tiền phạt',
                ['Note'] = 'Ghi chú thêm',
                ['NeedUnlock'] = 'Cần được mở khóa trước tại LSPD',
            },
            ['Notify'] = {
                ['ImpoundSuccess'] = 'Phương tiện %s đã bị tạm giữ thành công.',
                ['ImpoundInfo'] = 'Phương tiện của bạn %s đã bị cảnh sát tạm giữ.',
                ['ImpoundFail'] = {
                    ['WrongIdentifer'] = 'Không thể tạm giữ phương tiện %s.',
                    ['NoOwner'] = 'Phương tiện %s không có chủ sở hữu.',
                }
            }
        }
    },
    ['LocalEntity'] = {
        ['ImpoundStation'] = {
            ['Name'] = 'Bãi giữ xe cảnh sát',
            ['Menu'] = {
                ['Title'] = '🚓 Bãi giữ xe cảnh sát',
                ['PoliceVehicleDesc'] = 'Chủ xe phải đến lấy lại phương tiện',
                ['PoliceVehicleUnlockDesc'] = 'Nhấn để mở khóa phương tiện',
                ['VehicleDesc'] = 'Nhấn để lấy xe ra',
                ['VehicleUnlockDesc'] = 'Cần cảnh sát mở khóa phương tiện',
            },
            ['VehicleMetadata'] = {
                ['Status'] = '🚨 Trạng thái',
                ['Owner'] = '🤵 Chủ sở hữu',
                ['Officer'] = '👮 Cảnh sát',
                ['Modell'] = '🚗 Mẫu xe',
                ['Plate'] = '🔢 Biển số',
                ['Offence'] = '⚖️ Vi phạm',
                ['Fine'] = '💰 Tiền phạt',
                ['Duration'] = '⏳ Thời gian giữ',
                ['Note'] = '📝 Ghi chú',
            },
            ['Notify'] = {
                ['NoImpoundVehicles'] = 'Không có phương tiện nào đang bị tạm giữ',
                ['PoliceVehicleUnlockSuccess'] = 'Phương tiện đã được mở khóa thành công',
                ['ImpoundVehicleInvalid'] = 'Phương tiện tạm giữ không hợp lệ',
                ['ImpoundVehicleUnlockInfo'] = 'Phương tiện của bạn %s đã được cảnh sát mở khóa',
                ['ImpoundVehicleDuration'] = 'Bạn cần chờ đến %s để lấy xe ra',
                ['ImpoundNotEnoughMoney'] = 'Bạn không đủ tiền để lấy xe ra',
                ['ImpoundVehicleParkOut'] = 'Phương tiện đã được lấy ra',
            }
        }
    }
}
