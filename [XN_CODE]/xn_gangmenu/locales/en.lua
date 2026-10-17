local Translations = {
    headers = {
        ['bsm'] = 'Boss Menu - ',
    },
    body = {
        ['manage'] = 'Manage Employees',
        ['managed'] = 'Check your Employees List',
        ['hire'] = 'Hire Employees',
        ['hired'] = 'Hire Nearby Civilians',
        ['storage'] = 'Storage Access',
        ['storaged'] = 'Open Storage',
        ['outfits'] = 'Outfits',
        ['outfitsd'] = 'See Saved Outfits',
        ['money'] = 'Money Management',
        ['moneyd'] = 'Check your Company Balance',
        ['mempl'] = 'Manage Employees - ',
        ['mngpl'] = 'Manage ',
        ['grade'] = 'Grade: ',
        ['fireemp'] = 'Fire Employee',
        ['hireemp'] = 'Hire Employees - ',
        ['cid'] = 'Citizen ID: ',
        ['balance'] = 'Balance: $',
        ['deposit'] = 'Deposit',
        ['depositd'] = 'Deposit Money into account',
        ['withdraw'] = 'Withdraw',
        ['withdrawd'] = 'Withdraw Money from account',
        ['depositm'] = 'Deposit Money <br> Available Balance: $',
        ['withdrawm'] = 'Withdraw Money <br> Available Balance: $',
        ['submit'] = 'Confirm',
        ['amount'] = 'Amount',
        ['return'] = 'Return',
        ['exit'] = 'Return',
    },
    drawtext = {
        ['label'] = '[E] Open Job Management',
    },
    target = {
        ['label'] = 'Boss Menu',
    },
    headersgang = {
        ['bsm'] = 'Quản Lý Xã Đoàn - ',
    },
    bodygang = {
        ['manage'] = 'Quản Lý Thành Viên Xã Đoàn',
        ['managed'] = 'Tuyển hoặc Khai trừ thành viên',
        ['hire'] = 'Tuyển Thành Viên',
        ['hired'] = 'Tuyển thành viên xã đoàn',
        ['storage'] = 'Kho Xã Đoàn',
        ['storaged'] = 'Mở Kho Xã Đoàn',
        ['outfits'] = 'Trang phục',
        ['outfitsd'] = 'Đổi trang phục',
        ['money'] = 'Quản Lý Quỹ Xã Đoàn',
        ['moneyd'] = 'Kiểm tra số dư quỹ xã đoàn',
        ['mempl'] = 'Quản Lý Thành Viên - ',
        ['mngpl'] = 'Quản lý ',
        ['grade'] = 'Chức vụ: ',
        ['fireemp'] = 'Khai trừ',
        ['hireemp'] = 'Tuyển Thành Viên - ',
        ['cid'] = 'Citizen ID: ',
        ['balance'] = 'Số dư: $',
        ['deposit'] = 'Nạp tiền',
        ['depositd'] = 'Nạp tiền vào quỹ xã đoàn',
        ['withdraw'] = 'Rút tiền',
        ['withdrawd'] = 'Rút tiền từ quỹ xã đoàn',
        ['depositm'] = 'Nạp Tiền <br> Số dư hiện tại: $',
        ['withdrawm'] = 'Rút Tiền <br> Số dư hiện tại: $',
        ['submit'] = 'Xác nhận',
        ['amount'] = 'Số lượng',
        ['return'] = 'Quay lại',
        ['exit'] = 'Thoát',
    },
    drawtextgang = {
        ['label'] = '[E] Mở Quản Lý Xã Đoàn',
    },
    targetgang = {
        ['label'] = 'Menu Xã Đoàn',
    }
}

Locale = Locale or {}
Locale.__index = Locale

function Locale:new(opts)
    local obj = setmetatable({}, self)
    obj.phrases = opts and opts.phrases or {}
    return obj
end

function Locale:t(key, subs)
    if not key then return '' end
    local keys = {}
    for k in string.gmatch(key, "[^.]+") do
        keys[#keys + 1] = k
    end

    local current = self.phrases
    for _, k in ipairs(keys) do
        if type(current) == "table" and current[k] ~= nil then
            current = current[k]
        else
            return key
        end
    end

    local phrase = tostring(current)
    if subs and type(subs) == "table" then
        for k, v in pairs(subs) do
            phrase = string.gsub(phrase, "%%{" .. k .. "}", tostring(v))
        end
    end
    return phrase
end

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
