Config = {}

-- Tên item được sử dụng (phải trùng khớp với khai báo trong ox_inventory/qb-core items list)
Config.ItemName = 'thedoithongtin'

-- Cấu hình giới hạn tên nhân vật
Config.MinLength = 2  -- Độ dài tối thiểu của Tên/Họ
Config.MaxLength = 15 -- Độ dài tối đa của Tên/Họ

--Kiểm tra ký tự đặc biệt (chỉ cho phép chữ và khoảng trắng)
Config.AllowNumbers = true
Config.AllowSpecialChars = false

-- Ngôn ngữ và thông báo hiển thị
Config.Lang = {
    -- Client UI
    input_title = "Thẻ Đổi Tên Nhân Vật",
    input_firstname = "Họ (First Name)",
    input_firstname_placeholder = "Nhập tên mới của bạn...",
    input_description = "Tên không được có ký tự đặc biệt, Trên 2 chữ số",
    input_lastname = "Tên (Last Name)",
    input_lastname_placeholder = "Nhập họ mới của bạn...",
    
    confirm_title = "Xác nhận đổi tên",
    confirm_desc = "Bạn có chắc chắn muốn đổi tên này? Hành động này sẽ tiêu hao 1 Thẻ Đổi Tên.",
    confirm_yes = "Đồng Ý",
    confirm_no = "Hủy Bỏ",
    
    success_title = "Đổi tên thành công",
    success_desc = "Bạn cần phải động đất để nhận tên mới.",
    success_ok = "OK",

    -- Notifications
    invalid_input = "Tên và Họ không hợp lệ (phải từ %d đến %d ký tự, không chứa ký tự đặc biệt).",
    no_item = "Bạn không có Thẻ Đổi Tên!",
    db_error = "Đã xảy ra lỗi khi lưu thông tin vào cơ sở dữ liệu.",
    rename_cancelled = "Đã hủy bỏ đổi tên."
}
