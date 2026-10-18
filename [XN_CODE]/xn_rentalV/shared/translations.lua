local brandOverrides = {
  en = {
    brand = "ALLGAMERS",
    title = "THUÊ XE & VI VU",
    creator = "QUẢN LÝ TRẠM",
    capsule_side = "Vị trí khoang xe",
    side_right = "Bên phải quầy",
    side_left = "Bên trái quầy",
    interact = "Thuê xe",
    bring_scooter = "Đưa xe bạn đã thuê đến gần trạm.",
    strip_hint = "Màu của trạm gần nhất sẽ áp dụng cho dải đèn chung.",
  },
  bs = {
    brand = "ALLGAMERS",
    title = "Vault Rental",
    creator = "VAULT LAB",
    capsule_side = "Pozicija vaulta",
    side_right = "Desno od šaltera",
    side_left = "Lijevo od šaltera",
    interact = "Koristi rental tablet",
    bring_scooter = "Dovezi iznajmljeni auto blizu stanice.",
    strip_hint = "Boja najbliže stanice vrijedi za zajedničke teksture.",
  },
  de = {
    brand = "ALLGAMERS",
    title = "Vault Rental",
    creator = "VAULT LAB",
    capsule_side = "Vault-Position",
    side_right = "Rechts vom Schalter",
    side_left = "Links vom Schalter",
    interact = "Miet-Tablet benutzen",
    bring_scooter = "Bringe das Mietfahrzeug zur Station.",
    strip_hint = "Die Farbe der nächsten Station gilt für gemeinsame Texturen.",
  },
}

for localeKey, entries in pairs(brandOverrides) do
  for key, value in pairs(entries) do
    ScootLocales[localeKey][key] = value
  end
end

local stationOverrides = {
  en = {
    station_version = "Kiểu trạm thuê",
    version_booth = "Quầy thuê xe",
    version_tablet = "Trụ máy tính bảng",
    version_booth_hint = "Quầy chi tiết với nhân viên và màn hình thuê xe.",
    version_tablet_hint = "Trụ đứng nhỏ gọn với màn hình thuê xe thực tế.",
    place_capsule = "Đặt khoang xe",
    capsule_step_hint = "Đặt và xoay khoang xe trước. Sau đó đặt quầy/máy thuê xe độc lập.",
    terminal_step_hint = "Chỉ di chuyển và xoay quầy/máy. Tránh vị trí khoang xe và trong phạm vi 20 mét.",
    confirm_capsule = "Xác nhận khoang · Tiếp theo",
    save_station = "Lưu toàn bộ trạm",
  },
  bs = {
    station_version = "Izgled rental stanice",
    version_booth = "Rental kućica",
    version_tablet = "Samostojeći tablet",
    version_booth_hint = "Detaljna kućica, NPC i rental ekran.",
    version_tablet_hint = "Kompaktno postolje s pravim DUI ekranom.",
    place_capsule = "Postavi vault",
    capsule_step_hint = "Prvo postavi i rotiraj vault. Zatim zasebno postavi kućicu ili tablet.",
    terminal_step_hint = "Pomjeraš i rotiraš samo kućicu/tablet. Ostavi prostor oko vaulta; najveća udaljenost je 20 metara.",
    confirm_capsule = "Potvrdi vault · Dalje",
    save_station = "Sačuvaj cijelu stanicu",
  },
  de = {
    station_version = "Mietstation wählen",
    version_booth = "Mietkabine",
    version_tablet = "Freistehendes Tablet",
    version_booth_hint = "Detaillierte Kabine mit Personal und Bildschirm.",
    version_tablet_hint = "Kompakter Ständer mit echtem DUI-Bildschirm.",
    place_capsule = "Vault platzieren",
    capsule_step_hint = "Zuerst den Vault platzieren und drehen, danach das Terminal separat.",
    terminal_step_hint = "Nur das Terminal wird bewegt. Vault freihalten; maximal 20 Meter Abstand.",
    confirm_capsule = "Vault bestätigen · Weiter",
    save_station = "Station speichern",
  },
}

for localeKey, entries in pairs(stationOverrides) do
  for key, value in pairs(entries) do
    ScootLocales[localeKey][key] = value
  end
end
