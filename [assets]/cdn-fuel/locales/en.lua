local Translations = {
    -- Fuel
    set_fuel_debug = "Đặt nhiên liệu thành:",
    cancelled = "Đã hủy.",
    not_enough_money = "Bạn không có đủ 💵!",
    not_enough_money_in_bank = "Bạn không có đủ 💵 trong tài khoản ngân hàng!",
    not_enough_money_in_cash = "Bạn không có đủ 💵 trong túi!",
    more_than_zero = "Bạn phải đổ nhiều hơn 0L!",
    emergency_shutoff_active = "Các máy bơm hiện đang tắt thông qua hệ thống ngắt khẩn cấp.",
    nozzle_cannot_reach = "Vòi bơm không thể với xa đến vậy!",
    station_no_fuel = "Trạm này đã hết nhiên liệu!",
    station_not_enough_fuel = "Trạm không có đủ nhiên liệu này!",
    show_input_key_special = "Nhấn [G] khi ở gần xe để đổ nhiên liệu!",
    tank_cannot_fit = "Bình nhiên liệu của bạn không thể chứa hết!",
    tank_already_full = "Xe của bạn đã đầy nhiên liệu!",
    need_electric_charger = "Tôi cần đến trạm sạc điện!",
    cannot_refuel_inside = "Bạn không thể đổ nhiên liệu từ bên trong xe!",
    
    -- 2.1.2 -- Reserves Pickup ---
    fuel_order_ready = "Đơn hàng nhiên liệu của bạn đã sẵn sàng để nhận! Hãy kiểm tra GPS để tìm điểm nhận!",
    draw_text_fuel_dropoff = "[E] Trả Xe Tải",
    fuel_pickup_success = "Kho dự trữ của bạn đã được đổ đầy thành: %sL",
    fuel_pickup_failed = "Ron Oil vừa giao nhiên liệu đến trạm của bạn!",
    trailer_too_far = "Rơ-moóc không được gắn với xe tải hoặc quá xa!",

    -- 2.1.0
    no_nozzle = "Bạn không có vòi bơm!",
    vehicle_is_damaged = "Xe quá hư hỏng để đổ nhiên liệu!",
    vehicle_too_far = "Bạn ở quá xa để đổ nhiên liệu cho xe này!",
    inside_vehicle = "Bạn không thể đổ nhiên liệu từ bên trong xe!",
    you_are_discount_eligible = "Nếu bạn làm nhiệm vụ, bạn có thể nhận được giảm giá "..Config.EmergencyServicesDiscount['discount'].."%!",
    no_fuel = "Không có nhiên liệu..",

    -- Electric
    electric_more_than_zero = "Bạn phải sạc nhiều hơn 0KW!",
    electric_vehicle_not_electric = "Xe của bạn không phải là xe điện!",
    electric_no_nozzle = "Xe của bạn không phải là xe điện!",

    -- Phone --
    electric_phone_header = "Trạm Sạc Điện",
    electric_phone_notification = "Tổng Chi Phí Điện: $",
    fuel_phone_header = "Trạm Xăng",
    phone_notification = "Tổng Chi Phí: $",
    phone_refund_payment_label = "Hoàn 💵 @ Trạm Xăng!",

    -- Stations
    station_per_liter = " / Lít!",
    station_already_owned = "Địa điểm này đã có chủ!",
    station_cannot_sell = "Bạn không thể bán địa điểm này!",
    station_sold_success = "Bạn đã bán thành công địa điểm này!",
    station_not_owner = "Bạn không sở hữu địa điểm này!",
    station_amount_invalid = "Số lượng không hợp lệ!",
    station_more_than_one = "Bạn phải mua nhiều hơn 1L!",
    station_price_too_high = "Giá này quá cao!",
    station_price_too_low = "Giá này quá thấp!",
    station_name_invalid = "Tên này không hợp lệ!",
    station_name_too_long = "Tên không thể dài hơn "..Config.NameChangeMaxChar.." ký tự.",
    station_name_too_short = "Tên phải dài hơn "..Config.NameChangeMinChar.." ký tự.",
    station_withdraw_too_much = "Bạn không thể rút nhiều hơn số 💵 trạm có!", 
    station_withdraw_too_little = "Bạn không thể rút ít hơn $1!",
    station_success_withdrew_1 = "Đã rút thành công $",
    station_success_withdrew_2 = " từ số dư của trạm này!", -- Leave the space @ the front!
    station_deposit_too_much = "Bạn không thể gửi nhiều hơn số 💵 bạn có!", 
    station_deposit_too_little = "Bạn không thể gửi ít hơn $1!",
    station_success_deposit_1 = "Đã gửi thành công $",
    station_success_deposit_2 = " vào số dư của trạm này!", -- Leave the space @ the front!
    station_cannot_afford_deposit = "Bạn không đủ khả năng gửi $",
    station_shutoff_success = "Đã thay đổi thành công trạng thái van ngắt cho địa điểm này!",
    station_fuel_price_success = "Đã thay đổi thành công giá nhiên liệu thành $",
    station_reserve_cannot_fit = "Kho dự trữ không thể chứa hết lượng này!",
    station_reserves_over_max =  "Bạn không thể mua số lượng này vì nó sẽ vượt quá số lượng tối đa "..Config.MaxFuelReserves.." Lít",
    station_name_change_success = "Đã thay đổi thành công tên thành: ", -- Leave the space @ the end!
    station_purchased_location_payment_label = "Đã mua một Địa Điểm Trạm Xăng: ",
    station_sold_location_payment_label = "Đã bán một Địa Điểm Trạm Xăng: ",
    station_withdraw_payment_label = "Đã rút 💵 từ Trạm Xăng. Địa điểm: ",
    station_deposit_payment_label = "Đã gửi 💵 vào Trạm Xăng. Địa điểm: ",
    -- All Progress Bars
    prog_refueling_vehicle = "Đang đổ nhiên liệu cho Xe..",
    prog_electric_charging = "Đang sạc..",
    prog_jerry_can_refuel = "Đang đổ đầy Can Xăng..",
    prog_syphoning = "Đang hút nhiên liệu..",

    -- Menus
    
    menu_header_cash = "💵 ngoài túi",
    menu_header_bank = "Ngân hàng",
    menu_header_close = "Hủy",
    menu_pay_with_cash = "Trả bằng 💵ngoài túi.  \nBạn có: 💵",
    menu_pay_with_bank = "Trả qua ngân hàng.", 
    menu_refuel_header = "Trạm Xăng",
    menu_refuel_accept = "Tôi muốn mua nhiên liệu.",
    menu_refuel_cancel = "Tôi không muốn nhiên liệu nữa.",
    menu_pay_label_1 = "Xăng @ ",
    menu_pay_label_2 = " / L",
    menu_header_jerry_can = "Can Xăng",
    menu_header_refuel_jerry_can = "Đổ Đầy Can Xăng",
    menu_header_refuel_vehicle = "Đổ Nhiên Liệu Cho Xe",

    menu_electric_cancel = "Tôi không muốn sạc xe nữa.",
    menu_electric_header = "Trạm Sạc Điện",
    menu_electric_accept = "Tôi muốn trả 💵 cho điện.",
    menu_electric_payment_label_1 = "Điện @ ",
    menu_electric_payment_label_2 = " / KW",


    -- Station Menus

    menu_ped_manage_location_header = "Quản Lý Địa Điểm Này",
    menu_ped_manage_location_footer = "Nếu bạn là chủ sở hữu, bạn có thể quản lý địa điểm này.",

    menu_ped_purchase_location_header = "Mua Địa Điểm Này",
    menu_ped_purchase_location_footer = "Nếu không ai sở hữu địa điểm này, bạn có thể mua nó.",

    menu_ped_emergency_shutoff_header = "Bật/Tắt Ngắt Khẩn Cấp",
    menu_ped_emergency_shutoff_footer = "Tắt nhiên liệu trong trường hợp khẩn cấp.   \n Các máy bơm hiện đang ",
    
    menu_ped_close_header = "Kết Thúc Cuộc Trò Chuyện",
    menu_ped_close_footer = "Tôi không muốn thảo luận gì thêm nữa.",

    menu_station_reserves_header = "Mua Dự Trữ cho ",
    menu_station_reserves_purchase_header = "Mua dự trữ với giá: $",
    menu_station_reserves_purchase_footer = "Vâng, tôi muốn mua dự trữ nhiên liệu với giá $",
    menu_station_reserves_cancel_footer = "Tôi không muốn mua thêm dự trữ nữa!",
    
    menu_purchase_station_header_1 = "Tổng chi phí sẽ là: $",
    menu_purchase_station_header_2 = " bao gồm thuế.",
    menu_purchase_station_confirm_header = "Xác nhận",
    menu_purchase_station_confirm_footer = "Tôi muốn mua địa điểm này với giá $",
    menu_purchase_station_cancel_footer = "Tôi không muốn mua địa điểm này nữa. Giá đó thật điên rồ!",

    menu_sell_station_header = "Bán ",
    menu_sell_station_header_accept = "Bán Trạm Xăng",
    menu_sell_station_footer_accept = "Vâng, tôi muốn bán địa điểm này với giá $",
    menu_sell_station_footer_close = "Tôi không có gì để thảo luận thêm nữa.",

    menu_manage_header = "Quản lý của ",
    menu_manage_reserves_header = "Dự Trữ Nhiên Liệu  \n",
    menu_manage_reserves_footer_1 =  " Lít trên tổng số ",
    menu_manage_reserves_footer_2 =  " Lít  \nBạn có thể mua thêm dự trữ bên dưới!",
    
    menu_manage_purchase_reserves_header = "Mua Thêm Nhiên Liệu Dự Trữ",
    menu_manage_purchase_reserves_footer = "Tôi muốn mua thêm dự trữ nhiên liệu với giá $",
    menu_manage_purchase_reserves_footer_2 = " / L!",

    menu_alter_fuel_price_header = "Thay Đổi Giá Nhiên Liệu",
    menu_alter_fuel_price_footer_1 = "Tôi muốn thay đổi giá nhiên liệu tại Trạm Xăng của tôi!  \nHiện tại, giá là $",
    
    menu_manage_company_funds_header = "Quản Lý Quỹ Công Ty",
    menu_manage_company_funds_footer = "Tôi muốn quản lý quỹ của địa điểm này.",
    menu_manage_company_funds_header_2 = "Quản Lý Quỹ của ",
    menu_manage_company_funds_withdraw_header = "Rút 💵",
    menu_manage_company_funds_withdraw_footer = "Rút 💵 từ tài khoản của Trạm.",
    menu_manage_company_funds_deposit_header = "Gửi 💵",
    menu_manage_company_funds_deposit_footer = "Gửi 💵 vào tài khoản của Trạm.",
    menu_manage_company_funds_return_header = "Quay Lại",
    menu_manage_company_funds_return_footer = "Tôi muốn thảo luận điều khác!",

    menu_manage_change_name_header = "Thay Đổi Tên Địa Điểm",
    menu_manage_change_name_footer = "Tôi muốn thay đổi tên địa điểm.",

    menu_manage_sell_station_footer = "Bán trạm xăng của bạn với giá $",

    menu_manage_close = "Tôi không có gì để thảo luận thêm nữa!", 

    -- Jerry Can Menus 
    menu_jerry_can_purchase_header = "Mua Can Xăng với giá $",
    menu_jerry_can_footer_full_gas = "Can Xăng của bạn đã đầy!",
    menu_jerry_can_footer_refuel_gas = "Đổ đầy Can Xăng của bạn!",
    menu_jerry_can_footer_use_gas = "Sử dụng xăng của bạn để đổ nhiên liệu cho xe!",
    menu_jerry_can_footer_no_gas = "Bạn không có xăng trong Can Xăng!",
    menu_jerry_can_footer_close = "Tôi không muốn một Can Xăng nữa.",
    menu_jerry_can_close = "Tôi không muốn sử dụng cái này nữa.",

    -- Syphon Kit Menus
    menu_syphon_kit_full = "Bộ Hút Xăng của bạn đã đầy! Nó chỉ chứa được " .. Config.SyphonKitCap .. "L!",
    menu_syphon_vehicle_empty = "Bình nhiên liệu của xe này đã cạn.",
    menu_syphon_allowed = "Lấy cắp nhiên liệu từ một nạn nhân không nghi ngờ!",
    menu_syphon_refuel = "Sử dụng xăng đã lấy cắp để đổ nhiên liệu cho xe!",
    menu_syphon_empty = "Sử dụng xăng đã lấy cắp để đổ nhiên liệu cho xe!",
    menu_syphon_cancel = "Tôi không muốn sử dụng cái này nữa. Tôi đã đổi mới!",
    menu_syphon_header = "Hút Xăng",
    menu_syphon_refuel_header = "Đổ Nhiên Liệu",


    -- Input --
    input_select_refuel_header = "Chọn lượng xăng cần đổ.",
    input_refuel_submit = "Đổ Nhiên Liệu Cho Xe",
    input_refuel_jerrycan_submit = "Đổ Đầy Can Xăng",
    input_max_fuel_footer_1 = "Lên đến ",
    input_max_fuel_footer_2 = "L xăng.",
    input_insert_nozzle = "Gắn Vòi Bơm", -- Used for Target as well!

    input_purchase_reserves_header_1 = "Mua Dự Trữ  \nGiá Hiện Tại: $",
    input_purchase_reserves_header_2 = Config.FuelReservesPrice .. " / Lít  \nDự Trữ Hiện Tại: ",
    input_purchase_reserves_header_3 = " Lít  \nChi Phí Đổ Đầy Dự Trữ: $",
    input_purchase_reserves_submit_text = "Mua Dự Trữ",
    input_purchase_reserves_text = 'Mua Dự Trữ Nhiên Liệu.',

    input_alter_fuel_price_header_1 = "Thay Đổi Giá Nhiên Liệu   \nGiá Hiện Tại: $",
    input_alter_fuel_price_header_2 = " / Lít",
    input_alter_fuel_price_submit_text = "Thay Đổi Giá Nhiên Liệu",

    input_change_name_header_1 = "Thay Đổi Tên ",
    input_change_name_header_2 = ".",
    input_change_name_submit_text = "Gửi Thay Đổi Tên",
    input_change_name_text = "Tên Mới..",

    input_withdraw_funds_header = "Rút 💵  \nSố Dư Hiện Tại: $",
    input_withdraw_submit_text = "Rút",
    input_withdraw_text = "Rút 💵",

    input_deposit_funds_header = "Gửi 💵  \nSố Dư Hiện Tại: $",
    input_deposit_submit_text = "Gửi",
    input_deposit_text = "Gửi 💵",

    -- Target
    grab_electric_nozzle = "Lấy Vòi Sạc Điện",
    insert_electric_nozzle = "Gắn Vòi Sạc Điện",
    grab_nozzle = "Lấy Vòi Bơm",
    return_nozzle = "Trả Vòi Bơm",
    grab_special_nozzle = "Lấy Vòi Bơm Đặc Biệt",
    return_special_nozzle = "Trả Vòi Bơm Đặc Biệt",
    buy_jerrycan = "Mua Can Xăng",
    station_talk_to_ped = "Thảo Luận Về Trạm Xăng",

    -- Jerry Can
    jerry_can_full = "Can Xăng của bạn đã đầy!",
    jerry_can_refuel = "Đổ đầy Can Xăng của bạn!",
    jerry_can_not_enough_fuel = "Can Xăng không có đủ nhiên liệu này!",
    jerry_can_not_fit_fuel = "Can Xăng không thể chứa nhiều nhiên liệu này!",
    jerry_can_success = "Đã đổ đầy Can Xăng thành công!",
    jerry_can_success_vehicle = "Đã đổ nhiên liệu cho xe bằng Can Xăng thành công!",
    jerry_can_payment_label = "Đã mua Can Xăng.",

    -- Syphoning
    syphon_success = "Đã hút xăng từ xe thành công!",
    syphon_success_vehicle = "Đã đổ nhiên liệu cho xe bằng Bộ Hút Xăng thành công!",
    syphon_electric_vehicle = "Xe này là xe điện!",
    syphon_no_syphon_kit = "Bạn cần thứ gì đó để hút xăng.",
    syphon_inside_vehicle = "Bạn không thể hút xăng từ bên trong xe!",
    syphon_more_than_zero = "Bạn phải lấy cắp nhiều hơn 0L!",
    syphon_kit_cannot_fit_1 = "Bạn không thể hút nhiều đến vậy, can của bạn không thể chứa hết! Bạn chỉ có thể chứa: ",
    syphon_kit_cannot_fit_2 = " Lít.",
    syphon_not_enough_gas = "Bạn không có đủ xăng để đổ nhiều đến vậy!",
    syphon_dispatch_string = "(10-90) - Trộm Xăng",
}
Lang = Locale:new({phrases = Translations, warnOnMissing = true})