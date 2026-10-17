Locales = {}

Locales.vi = {
    -- Target labels
    buy_shop = 'Mua hàng',
    access_stash = 'Kho hàng',
    sell_to_player = 'Bán hàng cho người này',
    open_shop_menu = 'Xem menu',
    toggle_duty = 'Bắt đầu / Kết thúc ca',
    duty_on = 'Bạn đã bắt đầu ca làm việc!',
    duty_off = 'Bạn đã kết thúc ca làm việc!',
    
    -- Notifications
    stash_deposit_only = 'Kho này chỉ cho phép cất đồ vào, không thể lấy đồ ra!',
    stash_grade_required = 'Bạn cần chức vụ cấp %s trở lên để lấy đồ ra khỏi kho!',
    stash_cannot_swap = 'Kho này chỉ cho phép cất đồ vào ô trống, không thể đổi lấy đồ ra!',
    item_not_allowed = 'Vật phẩm "%s" không được phép bán trong cửa hàng này!',
    item_added_to_shop = 'Đã thêm %s vào cửa hàng với giá %s$',
    stash_info = 'Kho: %s slots, %skg tối đa',
    employee_online = 'Đang có nhân viên online tại %s!\nHãy liên hệ với nhân viên để trao đổi, mua bán.',
    employee_count_online = 'Đang có %d nhân viên online tại %s!\nHãy liên hệ với nhân viên để trao đổi, mua bán.',
    shop_closed_employee_online = 'Cửa hàng đóng cửa khi có nhân viên làm việc!',
    
    -- Employee selling feature
    select_item_to_sell = 'Chọn vật phẩm muốn bán',
    enter_quantity = 'Nhập số lượng',
    quantity = 'Số lượng',
    confirm = 'Xác nhận',
    cancel = 'Hủy',
    sell_offer_title = 'Đề xuất mua hàng',
    sell_offer_description = 'Nhân viên %s (%s) đang đề xuất bán cho bạn %d %s với giá %s$. Bạn có đồng ý mua không?',
    accept = 'Đồng ý',
    decline = 'Từ chối',
    sale_success = 'Giao dịch thành công! Đã bán %d %s với giá %s$',
    sale_success_commission = 'Giao dịch thành công! Đã bán %d %s với giá %s$ (Nhận %s$ hoa hồng)',
    purchase_success = 'Mua hàng thành công! Đã mua %d %s với giá %s$',
    sale_cancelled = 'Khách hàng đã từ chối giao dịch',
    purchase_cancelled = 'Bạn đã từ chối giao dịch',
    not_enough_stock = 'Không đủ hàng trong kho! Còn lại: %d',
    not_enough_money = 'Khách hàng không đủ tiền để mua!',
    buyer_not_enough_money = 'Bạn không đủ tiền để mua! Cần: %s$',
    invalid_quantity = 'Số lượng không hợp lệ!',
    no_items_in_shop = 'Không có vật phẩm nào để bán!',
    waiting_response = 'Đang chờ phản hồi từ khách hàng...',
    customer_offline = 'Khách hàng đã offline!',
    
    -- Order system
    new_order_received = 'Có đơn hàng mới!',
    order_placed_success = 'Đặt hàng thành công! Nhân viên sẽ xử lý đơn hàng của bạn.',
    no_items_available = 'Không có sản phẩm nào có sẵn!',
    your_order_cancelled = 'Đơn hàng của bạn đã bị hủy!',
    your_order_completed = 'Đơn hàng của bạn đã hoàn thành! Cảm ơn bạn đã mua hàng.',
    order_completed_success = 'Đơn hàng hoàn thành! Đã thu %s$',
    order_owned_by_another = 'Đơn hàng này đã được nhân viên khác xác nhận!',
    customer_not_enough_money = 'Khách hàng không đủ tiền!',
    
    -- Crafting system
    crafting_progress = 'Đang chế biến %s...',
    crafting_cancelled = 'Đã hủy chế biến!',
    craft_success = 'Chế biến thành công! Nhận được %d %s',
    craft_failed = 'Chế biến thất bại!',
    not_enough_ingredients = 'Không đủ nguyên liệu!',
    not_enough_ingredient = 'Thiếu %s! Cần: %d, Có: %d',
    wrong_job = 'Bạn không có quyền sử dụng!',
    error_occurred = 'Đã xảy ra lỗi!',
    
    -- Shop labels (thêm label mới ở đây khi tạo shop mới)
    default_shop = 'Cửa hàng',
    bar_shop = 'QUÁN BAR DS',
    quannuoc = 'Quán nước út sổ',
    police_shop = 'Quán Bar Cảnh Sát',
    mechanic_shop = 'Cửa Hàng Sửa Xe',
    ambulance_shop = 'Hiệu Thuốc',
    restaurant_shop = 'Nhà hàng',
    cafe_shop = 'Quán Cafe',
    bakery_shop = 'Tiệm Bánh',
    burgershot_shop = 'Burger Shot',
    pizzathis_shop = 'Pizza This',
    
    -- Debug messages (có thể tắt trong production)
    debug_item_from_payload = 'DEBUG: Lấy item từ payload.fromSlot',
    debug_no_item_info = 'DEBUG: Không thể lấy thông tin item từ payload',
    debug_price_set = 'DEBUG: Đã set giá %s cho item %s ở slot %s',
    debug_shop = 'DEBUG: Shop = %s',
    debug_item_name = 'DEBUG: Item name = %s',
    debug_available_items = 'DEBUG: Available items = %s',
    debug_item_price = 'DEBUG: Item price = %s',
    debug_stash_config = 'DEBUG: Tạo stash %s với %s slots, %skg',
}
