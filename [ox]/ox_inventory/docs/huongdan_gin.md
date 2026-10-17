Nút xóa vật phẩm (thêm vào client.lua + modules/inventory/server.lua)

---Tắt cái này để dùng súng trên xe

---add dan va phu kien server chiem dong

-- Gin Edit
check cop chinh chu 
tat Glovebox

--- balo
client.lua , server.lua
Kiểm tra slot cấm (6-21)
tim Inventory.AddItem 
add duoi metadata = assertMetadata(metadata)
-- Danh sách các item được phép vào slot 6-21
local allowedItems = {
    -- Các item quần áo
    ['cloth_outfit'] = true, ['cloth_torso'] = true, ['cloth_tshirt'] = true,
    ['cloth_arms'] = true, ['cloth_pants'] = true, ['cloth_shoes'] = true,
    ['cloth_decals'] = true, ['cloth_ears'] = true, ['cloth_mask'] = true,
    ['cloth_bproof'] = true, ['cloth_chain'] = true, ['cloth_bags'] = true,
    ['cloth_glasses'] = true, ['cloth_watches'] = true, ['cloth_bracelets'] = true,
    ['cloth_helmet'] = true, ['clothes'] = true,
}
-- Kiểm tra slot cấm (6-21) nếu item không nằm trong danh sách cho phép
if slot and slot >= 6 and slot <= 21 and not allowedItems[item.name] then
    return false, 'restricted_slot'
end

-- Nếu slot được chỉ định và không nằm trong vùng cấm
if slot then
    local slotData = inv.items[slot]
    slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)

    if not slotData or (item.stack and slotData.name == item.name and table.matches(slotData.metadata, slotMetadata)) then
        toSlot = slot
    end
end

-- Tìm slot trống nếu chưa có slot được chỉ định
if not toSlot then
    local items = inv.items
    slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)

    for i = 1, inv.slots do
        -- Bỏ qua các slot từ 6 đến 21 khi tìm slot trống
        if i < 6 or i > 21 then
            local slotData = items[i]

            if item.stack and slotData ~= nil and slotData.name == item.name and table.matches(slotData.metadata, slotMetadata) then
                toSlot = i
                break
            elseif not item.stack and not slotData then
                if not toSlot then toSlot = {} end

                toSlot[#toSlot + 1] = { slot = i, count = slotCount, metadata = slotMetadata }

                if count == slotCount then
                    break
                end

                count -= 1
                slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)
            elseif not toSlot and not slotData then
                toSlot = i
            end
        end
    end
end

tim ox_inventory:buyItem
add duoi if fromData then
-- Danh sách các item được phép vào slot 6-21
local allowedItems = {
    -- Các item quần áo
    ['cloth_outfit'] = true, ['cloth_torso'] = true, ['cloth_tshirt'] = true,
    ['cloth_arms'] = true, ['cloth_pants'] = true, ['cloth_shoes'] = true,
    ['cloth_decals'] = true, ['cloth_ears'] = true, ['cloth_mask'] = true,
    ['cloth_bproof'] = true, ['cloth_chain'] = true, ['cloth_bags'] = true,
    ['cloth_glasses'] = true, ['cloth_watches'] = true, ['cloth_bracelets'] = true,
    ['cloth_helmet'] = true, ['clothes'] = true,
}

-- Kiểm tra slot cấm (6-21) nếu item không nằm trong danh sách cho phép
if data.toSlot and data.toSlot >= 6 and data.toSlot <= 21 and not allowedItems[fromData.name] then
    return false, false, { type = 'error', description = 'Không thể mua vật phẩm vào slot này' }
end

them file script/gin.js

sua lai
\web\src\components\inventory\InventoryGrid.tsx

<div className="inventory-grid-container" ref={containerRef}>
    <div className='RegularSlots'>
        {inventory.items.slice(0, 5).map((item, index) => (
            <InventorySlot
            key={`${inventory.type}-${inventory.id}-${item.slot}`}
            item={item}
            ref={index === (page + 1) * PAGE_SIZE - 1 ? ref : null}
            inventoryType={inventory.type}
            inventoryGroups={inventory.groups}
            inventoryId={inventory.id}
            />
        ))}
        </div>
    <div className="RegularSlots-2">
        {inventory.items?.length >= 22 && (
            <div className="iconWrapper-bag">
            <i className="fa-solid fa-backpack"></i>
            </div>
        )}
        {inventory.items?.slice(21, 150).map((item, index) => (
            <InventorySlot
            key={`${inventory.type}-${inventory.id}-${item.slot}`}
            item={item}
            ref={index === (page + 1) * PAGE_SIZE - 1 ? ref : null}
            inventoryType={inventory.type}
            inventoryGroups={inventory.groups}
            inventoryId={inventory.id}
            />
        ))}
    </div>
</div>

web\src\components\inventory\InventoryGridRight.tsx
tim inventory-grid-container thay lai 
<div className="inventory-grid-container" ref={containerRef}>
    <div className='Gin_Chon_BQ'>
        <>
        {displayedItems.slice(0, (page + 1) * PAGE_SIZE).map((item, index) => (
            <InventorySlot
            key={`${inventory.type}-${inventory.id}-${item.slot}`}
            item={item}
            ref={index === (page + 1) * PAGE_SIZE - 1 ? ref : null}
            inventoryType={inventory.type}
            inventoryGroups={inventory.groups}
            inventoryId={inventory.id}
            image={item.name ? getItemUrl(item as SlotWithItem) : ''}
            />
        ))}
        </>
    </div>
</div>

thay lai code css o duong dan
them file script/style.css

them vao trong <head></head>
<link href="https://kit-pro.fontawesome.com/releases/v6.6.0/css/pro.min.css" rel="stylesheet">
<script src="https://code.jquery.com/jquery-3.5.1.js" integrity="sha256-QWo7LDvxbWT2tbbQ97B53yJnYU3WhH/C8ycbRAkjPDc=" crossorigin="anonymous"></script>
<script type="module" crossorigin src="./assets/gin.js"></script>
Copy file trong script/gin.js vao trong assets roi bo code nay vao file  build/index.html