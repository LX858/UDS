-- Hàm loại bỏ khoảng trắng thừa đầu và cuối chuỗi
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Hàm kiểm tra tính hợp lệ của Tên/Họ
local function validateName(name)
    if not name or trim(name) == "" then
        return nil, "Không được bỏ trống."
    end
    local cleanName = trim(name)
    
    -- Kiểm tra độ dài (sử dụng utf8.len để hỗ trợ tiếng Việt có dấu chính xác)
    local utf8Len = utf8.len(cleanName)
    if not utf8Len or utf8Len < Config.MinLength or utf8Len > Config.MaxLength then
        return nil, string.format("Độ dài phải từ %d đến %d ký tự.", Config.MinLength, Config.MaxLength)
    end

    -- Kiểm tra nếu không cho phép chữ số
    if not Config.AllowNumbers and string.match(cleanName, "%d") then
        return nil, "Không được chứa chữ số."
    end

    -- Kiểm tra nếu không cho phép ký tự đặc biệt (chỉ cho phép chữ và khoảng trắng)
    -- Sử dụng pattern kiểm tra xem có chứa ký tự đặc biệt/ký tự điều khiển không
    if not Config.AllowSpecialChars and string.match(cleanName, '[%c%p]') then
        return nil, "Không được chứa ký tự đặc biệt."
    end

    return cleanName, nil
end

-- Đăng ký sự kiện sử dụng item từ Server gửi về
RegisterNetEvent('thedoiten:client:useItem', function()
    local defaultFirstname = ""
    local defaultLastname = ""
    local errFirstname = nil
    local errLastname = nil
    local firstname, lastname

    while true do
        local firstnameDesc = Config.Lang.input_description
        if errFirstname then
            firstnameDesc = "⚠️ Lỗi: " .. errFirstname
        end

        local lastnameDesc = Config.Lang.input_description
        if errLastname then
            lastnameDesc = "⚠️ Lỗi: " .. errLastname
        end

        -- 1. Hiển thị Dialog nhập tên mới
        local input = lib.inputDialog(Config.Lang.input_title, {
            { 
                type = 'input', 
                label = Config.Lang.input_firstname, 
                placeholder = Config.Lang.input_firstname_placeholder, 
                description = firstnameDesc,
                required = true,
                min = Config.MinLength,
                max = Config.MaxLength,
                default = defaultFirstname ~= "" and defaultFirstname or nil
            },
            { 
                type = 'input', 
                label = Config.Lang.input_lastname, 
                placeholder = Config.Lang.input_lastname_placeholder, 
                description = lastnameDesc,
                required = true,
                min = Config.MinLength,
                max = Config.MaxLength,
                default = defaultLastname ~= "" and defaultLastname or nil
            }
        })

        -- Nếu người chơi tắt Dialog hoặc không nhập
        if not input then 
            lib.notify({
                description = Config.Lang.rename_cancelled,
                type = 'info'
            })
            return 
        end

        defaultFirstname = input[1] or ""
        defaultLastname = input[2] or ""

        local validFirstname, err1 = validateName(defaultFirstname)
        local validLastname, err2 = validateName(defaultLastname)

        if validFirstname and validLastname then
            firstname = validFirstname
            lastname = validLastname
            break
        else
            errFirstname = err1
            errLastname = err2
        end
    end

    -- 2. Hiển thị cảnh báo xác nhận đổi tên
    local alert = lib.alertDialog({
        header = Config.Lang.confirm_title,
        content = Config.Lang.confirm_desc,
        centered = true,
        cancel = true,
        labels = {
            confirm = Config.Lang.confirm_yes,
            cancel = Config.Lang.confirm_no
        }
    })

    -- Nếu chọn "Đồng Ý"
    if alert == 'confirm' then
        -- Gọi callback đồng bộ lên server để xử lý cơ sở dữ liệu và trừ item
        local success, msg = lib.callback.await('thedoiten:server:renamePlayer', false, firstname, lastname)

        if success then
            -- 3. Đổi tên thành công, hiển thị Alert yêu cầu "động đất" (relog)
            lib.alertDialog({
                header = Config.Lang.success_title,
                content = Config.Lang.success_desc,
                centered = true,
                cancel = false,
                labels = {
                    confirm = Config.Lang.success_ok
                }
            })
        else
            -- Báo lỗi nếu server phản hồi thất bại
            lib.notify({
                description = msg or Config.Lang.db_error,
                type = 'error'
            })
        end
    else
        lib.notify({
            description = Config.Lang.rename_cancelled,
            type = 'info'
        })
    end
end)
