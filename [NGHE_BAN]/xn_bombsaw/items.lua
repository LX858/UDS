-- Thêm các dòng này vào file ox_inventory/data/items.lua

return {
    ['quabom'] = {
        label = 'Quả Bom',
        weight = 5000,
        stack = true,
        close = true,
        description = 'Một quả bom cũ, có thể cưa để lấy tài nguyên',
        client = {
            image = 'quabom.png',
        }
    },

    ['hoado'] = {
        label = 'Hoa Đỏ',
        weight = 100,
        stack = true,
        close = true,
        description = 'Một bông hoa đỏ',
        client = {
            image = 'hoado.png',
        }
    },
}
