local Locales = {}

Locales['vi'] = {
    -- Menu
    ['reputation_title'] = 'Thông Tin Uy Tín',
    ['character_name'] = 'Tên nhân vật',
    ['reputation_points'] = 'Điểm uy tín',
    ['close_menu'] = 'Đóng',
    
    -- Notifications
    ['reputation_decreased'] = 'Điểm uy tín của bạn đã giảm %s điểm! Còn lại: %s/100',
    ['combat_forbidden_zone'] = 'Bạn bị trừ điểm uy tín vì đánh nhau trong khu vực cấm!',
    ['vehicle_ramming_penalty'] = 'Bạn bị trừ điểm uy tín vì đâm xe vào người chơi khác!',
    ['reputation_low'] = 'Cảnh báo: Điểm uy tín của bạn đang rất thấp!',
    
    -- Commands
    ['reputation_check'] = 'Kiểm tra điểm uy tín của bạn',
    
    -- Reputation check request
    ['check_request_title'] = 'Yêu Cầu Kiểm Tra Thông Tin',
    ['check_request_content'] = '%s muốn kiểm tra thông tin của bạn. Bạn có đồng ý không?',
    ['check_request_accept'] = 'Đồng ý',
    ['check_request_decline'] = 'Từ chối',
    ['check_waiting'] = 'Đang chờ xác nhận',
    ['check_declined'] = 'Người chơi đã từ chối yêu cầu kiểm tra thông tin!',
    ['check_accepted'] = 'Đã chia sẻ thông tin uy tín',
    
    -- Prison Trash Collection
    ['pick_trash_bag'] = 'Nhặt túi rác',
    ['place_trash_bag'] = 'Đặt túi rác vào thùng',
    ['bag_already_taken'] = 'Túi rác này đã được nhặt!',
    ['bag_already_in_hand'] = 'Bạn đã cầm một túi rác rồi!',
    ['trash_collected'] = 'Đã thu gom túi rác! Thời gian tù giảm 1 phút.',
    ['no_bag_in_hand'] = 'Bạn không có túi rác để đặt!',
    ['too_far_from_bin'] = 'Bạn quá xa thùng rác!',
}

if lib then
    lib.locale = Locales['vi']
end

return Locales
