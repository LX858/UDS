//console.log('[Admin] Script loading...');

let currentEditingHouse = null;

// Custom Alert Function
function showAlert(message, type = 'info') {
    const overlay = document.getElementById('customAlertOverlay');
    const messageEl = document.getElementById('alertMessage');
    const iconEl = document.getElementById('alertIcon');
    const button = document.getElementById('alertButton');

    if (!overlay || !messageEl || !iconEl || !button) {
        console.error('[Admin] Alert elements not found!');
        return;
    }

    // Set message and type
    messageEl.textContent = message;
    iconEl.className = 'alert-icon ' + type;

    // Show overlay
    overlay.classList.add('show');

    // Close on button click
    const closeHandler = () => {
        overlay.classList.remove('show');
        button.removeEventListener('click', closeHandler);
    };
    button.addEventListener('click', closeHandler);

    //console.log('[Admin] Alert shown:', type, message);
}

// Custom Confirm Function
function showConfirm(message, onConfirm) {
    const overlay = document.getElementById('customAlertOverlay');
    const messageEl = document.getElementById('alertMessage');
    const iconEl = document.getElementById('alertIcon');
    const buttonsContainer = document.getElementById('alertButton').parentElement;

    if (!overlay || !messageEl || !iconEl || !buttonsContainer) {
        console.error('[Admin] Confirm elements not found!');
        return;
    }

    // Set message and icon
    messageEl.textContent = message;
    iconEl.className = 'alert-icon error'; // Use warning icon

    // Replace single button with confirm buttons
    buttonsContainer.innerHTML = `
        <div class="confirm-buttons">
            <button class="confirm-btn no" id="confirmNo">Hủy</button>
            <button class="confirm-btn yes" id="confirmYes">Xác Nhận</button>
        </div>
    `;

    // Show overlay
    overlay.classList.add('show');

    // Handle confirm/cancel
    const yesBtn = document.getElementById('confirmYes');
    const noBtn = document.getElementById('confirmNo');

    const closeConfirm = (confirmed) => {
        overlay.classList.remove('show');
        // Restore original button
        buttonsContainer.innerHTML = '<button class="alert-button" id="alertButton">OK</button>';
        if (confirmed && onConfirm) {
            onConfirm();
        }
    };

    yesBtn.addEventListener('click', () => closeConfirm(true));
    noBtn.addEventListener('click', () => closeConfirm(false));

    //console.log('[Admin] Confirm shown:', message);
}

// Helper: Detect if running in iframe
const isInIframe = window !== window.parent;
//console.log('[Admin] Running in iframe:', isInIframe);

// Helper: Get parent resource name
function GetParentResourceName() {
    if (isInIframe) {
        // Forward to parent window which has the real NUI connection
        return 'qbx_housing';
    }
    return 'qbx_housing';
}

// Helper: Fetch wrapper for iframe
function nuiFetch(endpoint, data) {
    if (isInIframe) {
        // Forward request to parent window
        return new Promise((resolve) => {
            const requestId = Math.random().toString(36);
            
            window.addEventListener('message', function handler(event) {
                if (event.data.type === 'nuiResponse' && event.data.requestId === requestId) {
                    window.removeEventListener('message', handler);
                    // Return response directly, not wrapped in json()
                    resolve(event.data.response);
                }
            });
            
            window.parent.postMessage({
                type: 'nuiRequest',
                requestId: requestId,
                endpoint: endpoint,
                data: data
            }, '*');
        });
    } else {
        // Direct NUI fetch - return the JSON data directly
        return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        }).then(resp => resp.json());
    }
}

// EVENT LISTENERS
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openAdmin') {
        const container = document.getElementById('adminContainer');
        if (container) {
            container.style.display = 'flex';
            loadHousesList();
            
            // Auto-fill House ID sau khi UI hiển thị (async để không block)
            setTimeout(() => {
                const houseType = document.getElementById('houseType').value || 'slum';
                autoFillHouseId(houseType);
            }, 100);
        }
    } else if (data.action === 'closeAdmin') {
        const container = document.getElementById('adminContainer');
        if (container) {
            container.style.display = 'none';
        }
    } else if (data.action === 'setCoords') {
        setCoordinates(data.target, data.coords);
    }
});

// ESC KEY TO CLOSE
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        const modal = document.getElementById('editModal');
        const container = document.getElementById('adminContainer');
        
        // Close modal first if open
        if (modal && modal.style.display === 'flex') {
            modal.style.display = 'none';
            return;
        }
        
        // Close admin UI if container is visible
        if (container && container.style.display === 'flex') {
            container.style.display = 'none';
            nuiFetch('closeAdmin', {});
            // Stop propagation to prevent housing UI ESC handler
            event.stopPropagation();
            event.preventDefault();
        }
    }
});

// TAB SWITCHING
document.querySelectorAll('.tab-button').forEach(button => {
    button.addEventListener('click', function() {
        if (this.classList.contains('close-btn')) return;
        
        const tabName = this.getAttribute('data-tab');
        
        // Remove active from all tabs
        document.querySelectorAll('.tab-button').forEach(btn => btn.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
        
        // Add active to clicked tab
        this.classList.add('active');
        document.getElementById(tabName + 'Tab').classList.add('active');
        
        if (tabName === 'manage') {
            loadHousesList();
        }
    });
});

// CLOSE ADMIN
document.getElementById('closeAdmin').addEventListener('click', function() {
    const container = document.getElementById('adminContainer');
    if (container) {
        container.style.display = 'none';
    }
    
    // Call closeAdmin callback
    nuiFetch('closeAdmin', {});
});

// GET COORDS BUTTONS
document.querySelectorAll('.get-coords-btn').forEach(button => {
    button.addEventListener('click', function() {
        const target = this.getAttribute('data-target');
        const originalText = this.textContent;
        
        // Visual feedback
        this.textContent = '⏳ Đang lấy...';
        this.disabled = true;
        
        nuiFetch('getCoords', { target: target }).then(() => {
            // Reset button sau 1 giây
            setTimeout(() => {
                this.textContent = '✓ Đã lấy!';
                setTimeout(() => {
                    this.textContent = originalText;
                    this.disabled = false;
                }, 1000);
            }, 100);
        });
    });
});

// PARSE VEC3/VEC4 STRING - Phân tích chuỗi vec3(x,y,z) hoặc vec4(x,y,z,h)
function parseVecString(vecStr) {
    if (!vecStr || typeof vecStr !== 'string') return null;
    
    // Remove spaces and match vec3(...) or vec4(...)
    const cleaned = vecStr.trim().replace(/\s/g, '');
    const match = cleaned.match(/vec[34]\(([^)]+)\)/);
    
    if (!match) {
        // Try parsing raw numbers: "100, 200, 300" or "100, 200, 300, 45"
        const rawMatch = cleaned.match(/^(-?\d+\.?\d*),(-?\d+\.?\d*),(-?\d+\.?\d*)(?:,(-?\d+\.?\d*))?$/);
        if (rawMatch) {
            return {
                x: parseFloat(rawMatch[1]),
                y: parseFloat(rawMatch[2]),
                z: parseFloat(rawMatch[3]),
                h: rawMatch[4] ? parseFloat(rawMatch[4]) : undefined
            };
        }
        return null;
    }
    
    const values = match[1].split(',').map(v => parseFloat(v.trim()));
    
    if (values.length === 3) {
        return { x: values[0], y: values[1], z: values[2] };
    } else if (values.length === 4) {
        return { x: values[0], y: values[1], z: values[2], h: values[3] };
    }
    
    return null;
}

// FORMAT COORDS TO VEC STRING
function formatVecString(x, y, z, h) {
    // Kiểm tra null/undefined cho x, y, z
    if (x === null || x === undefined || y === null || y === undefined || z === null || z === undefined) {
        return '';
    }
    
    if (h !== undefined && h !== null) {
        return `vec4(${x.toFixed(2)}, ${y.toFixed(2)}, ${z.toFixed(2)}, ${h.toFixed(2)})`;
    }
    return `vec3(${x.toFixed(2)}, ${y.toFixed(2)}, ${z.toFixed(2)})`;
}

// SET COORDINATES - Lấy vec3 một lần fill vào input duy nhất
function setCoordinates(target, coords) {
    const input = document.querySelector(`[data-coord="${target}"]`);
    
    if (input) {
        input.value = formatVecString(coords.x, coords.y, coords.z, coords.h);
        
        // Visual feedback - highlight input briefly
        input.style.backgroundColor = '#4a90e244';
        setTimeout(() => {
            input.style.backgroundColor = '';
        }, 500);
    }
    
    //console.log(`✓ Đã lấy: ${formatVecString(coords.x, coords.y, coords.z, coords.h)}`);
}

// RESET FORM
// Check if DOM is already loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeEventListeners);
} else {
    // DOM already loaded, run immediately
    //console.log('[Admin] DOM already loaded, initializing immediately...');
    initializeEventListeners();
}

function initializeEventListeners() {
    //console.log('[Admin] Initializing event listeners...');
    
    // CREATE HOUSE BUTTON
    const createHouseBtn = document.getElementById('createHouseBtn');
    //console.log('[Admin] createHouseBtn found:', !!createHouseBtn);
    
    if (createHouseBtn) {
        createHouseBtn.addEventListener('click', function() {
            //console.log('[Admin] Create house button clicked');
            
            // Clear previous errors
            document.querySelectorAll('.vec-input, #houseId').forEach(input => {
                input.style.border = '';
                input.removeAttribute('title');
            });
            
            let hasError = false;
            const emptyFields = [];
            
            // Helper function để validate và highlight input
            const validateInput = (selector, fieldName, isVec = true) => {
                const input = document.querySelector(selector);
                if (!input) {
                    console.warn('[Admin] Input not found:', selector);
                    return null;
                }
                
                const value = input.value.trim();
                if (!value) {
                    input.style.border = '2px solid #ff4444';
                    input.setAttribute('title', '⚠️ Thiếu nội dung: ' + fieldName);
                    emptyFields.push(fieldName);
                    hasError = true;
                    return null;
                }
                
                if (isVec) {
                    const parsed = parseVecString(value);
                    if (!parsed) {
                        input.style.border = '2px solid #ff4444';
                        input.setAttribute('title', '⚠️ Sai format: ' + fieldName + '\nVD: vec3(x, y, z) hoặc vec4(x, y, z, h)');
                        emptyFields.push(fieldName + ' (sai format)');
                        hasError = true;
                        return null;
                    }
                    return parsed;
                }
                
                return value;
            };
            
            // Validate House ID
            const houseId = validateInput('#houseId', 'House ID', false);
            if (houseId && houseId.length < 3) {
                const input = document.getElementById('houseId');
                input.style.border = '2px solid #ff4444';
                input.setAttribute('title', '⚠️ House ID phải có ít nhất 3 ký tự');
                emptyFields.push('House ID (quá ngắn)');
                hasError = true;
            }
            
            // Validate all coords
            const doorCoords = validateInput('[data-coord="door"]', 'Cửa nhà (Door)');
            const interiorCoords = validateInput('[data-coord="interior"]', 'Nội thất (Interior)');
            const storageCoords = validateInput('[data-coord="storage"]', 'Kho đồ (Storage)');
            const juicerCoords = validateInput('[data-coord="juicer"]', 'Máy xay sinh tố (Juicer)');
            const packagingCoords = validateInput('[data-coord="packaging"]', 'Đóng thùng hàng (Packaging)');
            const exitCoords = validateInput('[data-coord="exit"]', 'Lối ra (Exit)');
            const garageCoords = validateInput('[data-coord="garage"]', 'Gara cất xe (Garage)');
            const spawnCoords = validateInput('[data-coord="spawn"]', 'Spawn xe (Spawn)');
            
            // Bed coords - OPTIONAL (có thể để trống)
            const bedInput = document.querySelector('[data-coord="bed"]');
            let bedCoords = null;
            if (bedInput && bedInput.value.trim()) {
                bedCoords = parseVecString(bedInput.value.trim());
                if (!bedCoords) {
                    bedInput.style.border = '2px solid #ff4444';
                    bedInput.setAttribute('title', '⚠️ Sai format: Giường ngủ\nVD: vec3(x, y, z) hoặc để trống');
                    emptyFields.push('Giường ngủ (sai format)');
                    hasError = true;
                }
            }
            
            // Validate spawn có heading
            if (spawnCoords && !spawnCoords.h) {
                const input = document.querySelector('[data-coord="spawn"]');
                input.style.border = '2px solid #ff4444';
                input.setAttribute('title', '⚠️ Spawn coords phải có heading!\nVD: vec4(x, y, z, heading)');
                emptyFields.push('Spawn (thiếu heading)');
                hasError = true;
            }
            
            // Nếu có lỗi, hiển thị thông báo và DỪNG LẠI
            if (hasError) {
                console.warn('[Admin] Validation failed:', emptyFields);
                showAlert('❌ Vui lòng kiểm tra lại các ô bị highlight đỏ:\n\n' + emptyFields.join('\n'), 'error');
                return; // DỪNG - KHÔNG GỌI nuiFetch
            }
            
            //console.log('[Admin] Validation passed, creating house...');
            
            // Get price (optional)
            const priceInput = document.getElementById('housePrice');
            const price = priceInput && priceInput.value.trim() ? parseInt(priceInput.value) : null;
            
            const gangInput = document.getElementById('houseGang');
            const gangVal = gangInput && gangInput.value.trim() ? gangInput.value.trim() : null;

            const houseData = {
                id: houseId,
                type: document.getElementById('houseType').value,
                price: price, // null = use Config.HouseTypes price
                gang: gangVal,
                door: doorCoords,
                interior: interiorCoords,
                storage: storageCoords,
                juicer: juicerCoords,
                packaging: packagingCoords,
                exit: exitCoords,
                garage: garageCoords,
                spawn: spawnCoords,
                bed: bedCoords // Có thể null nếu không nhập
            };
            
            //console.log('[Admin] Creating house:', houseData);
            
            nuiFetch('createHouse', houseData)
                .then(data => {
                    //console.log('[Admin] Create response:', data);
                    //console.log('[Admin] Response success value:', data.success, typeof data.success);
                    //console.log('[Admin] Full response:', JSON.stringify(data));
                    if (data.success) {
                        // Reset form trước
                        resetCreateForm();
                        
                        // Gọi closeAdmin và ĐỢI nó hoàn thành
                        //console.log('[Admin] Closing admin UI...');
                        return nuiFetch('closeAdmin', {}).then(() => {
                            // Sau khi closeAdmin hoàn thành, ẨN UI
                            //console.log('[Admin] Admin closed, hiding UI...');
                            document.getElementById('adminContainer').style.display = 'none';
                            
                            // Alert sau khi đã close hoàn toàn
                            setTimeout(() => {
                                showAlert('✓ Tạo nhà thành công: ' + houseId + '\n\nNhà đã được khởi tạo!', 'success');
                            }, 100);
                        });
                    } else {
                        showAlert('❌ Lỗi: ' + (data.message || 'Không xác định'), 'error');
                    }
                })
                .catch(err => {
                    console.error('[Admin] Create error:', err);
                    showAlert('❌ Lỗi khi tạo nhà!', 'error');
                });
        });
    } else {
        console.error('[Admin] createHouseBtn not found in DOM!');
    }
    
    // Reset form button
    const resetBtn = document.getElementById('resetFormBtn');
    if (resetBtn) {
        resetBtn.addEventListener('click', resetCreateForm);
    }
    
    // AUTO-FILL HOUSE ID khi chọn loại nhà
    const houseTypeSelect = document.getElementById('houseType');
    if (houseTypeSelect) {
        houseTypeSelect.addEventListener('change', function() {
            const selectedType = this.value;
            autoFillHouseId(selectedType);
        });
    }
    
    // AUTO-CLEAR ERROR BORDERS khi user gõ vào input
    document.querySelectorAll('.vec-input, #houseId').forEach(input => {
        input.addEventListener('input', function() {
            // Clear border đỏ và tooltip khi user bắt đầu gõ
            this.style.border = '';
            this.removeAttribute('title');
        });
    });
    
    //console.log('[Admin] Event listeners registered successfully');
}

// Function tự động điền House ID dựa trên số thứ tự cao nhất
function autoFillHouseId(houseType) {
    nuiFetch('getHousesList', {})
        .then(data => {
            if (!data.houses || data.houses.length === 0) {
                // Không có nhà nào, bắt đầu từ 1
                document.getElementById('houseId').value = houseType + '_1';
                return;
            }
            
            // Filter houses theo type
            const housesOfType = data.houses.filter(h => h.type === houseType);
            
            if (housesOfType.length === 0) {
                // Không có nhà loại này, bắt đầu từ 1
                document.getElementById('houseId').value = houseType + '_1';
                return;
            }
            
            // Tìm số thứ tự cao nhất
            let maxNumber = 0;
            const regex = new RegExp(`^${houseType}_(\\d+)$`);
            
            housesOfType.forEach(house => {
                const match = house.id.match(regex);
                if (match) {
                    const num = parseInt(match[1], 10);
                    if (num > maxNumber) {
                        maxNumber = num;
                    }
                }
            });
            
            // Điền số tiếp theo
            const nextNumber = maxNumber + 1;
            document.getElementById('houseId').value = houseType + '_' + nextNumber;
            //console.log(`[Admin] Auto-filled House ID: ${houseType}_${nextNumber}`);
        })
        .catch(err => {
            console.error('[Admin] Error auto-filling house ID:', err);
        });
}

function resetCreateForm() {
    const houseType = document.getElementById('houseType').value || 'slum';
    
    // Reset các vec input fields
    const coordFields = ['door', 'interior', 'storage', 'juicer', 'packaging', 'exit', 'garage', 'spawn'];
    coordFields.forEach(field => {
        const input = document.querySelector(`[data-coord="${field}"]`);
        if (input) {
            input.value = '';
        }
    });
    
    // Auto-fill house ID sau khi reset
    autoFillHouseId(houseType);
}

// LOAD HOUSES LIST
function loadHousesList() {
    //console.log('[Admin] Loading houses list...');
    nuiFetch('getHousesList', {})
        .then(data => {
            //console.log('[Admin] Houses list loaded:', data);
            const listContainer = document.getElementById('housesList');
            listContainer.innerHTML = '';
            
            if (!data.houses || data.houses.length === 0) {
                listContainer.innerHTML = '<p style="color: #888; text-align: center; padding: 40px;">Không có nhà nào trong database</p>';
                return;
            }
            
            data.houses.forEach(house => {
                const card = createHouseCard(house);
                listContainer.appendChild(card);
            });
        })
        .catch(err => {
            console.error('[Admin] Load houses error:', err);
        });
}

// CREATE HOUSE CARD
function createHouseCard(house) {
    const card = document.createElement('div');
    card.className = 'house-card';
    card.onclick = () => openEditModal(house);
    
    const typeLabels = {
        'slum': 'Ổ Chuột',
        'regular': 'Thường',
        'apartment': 'Chung Cư',
        'homestay': 'Homestay'
    };
    
    card.innerHTML = `
        <div class="house-card-header">
            <div class="house-card-id">${house.id}</div>
            <div class="house-card-type">${house.gang ? '🛡️ ' + house.gang : (typeLabels[house.type] || house.type)}</div>
        </div>
        <div class="house-card-info">
            <div><strong>Door:</strong> ${house.door_x.toFixed(1)}, ${house.door_y.toFixed(1)}, ${house.door_z.toFixed(1)}</div>
            ${house.owner_name ? `<div class="house-card-owner">Chủ: ${house.owner_name}</div>` : '<div style="color: #888;">Chưa có chủ</div>'}
            <div style="color: #666; font-size: 11px; margin-top: 5px;">Click để chỉnh sửa</div>
        </div>
    `;
    
    return card;
}

// OPEN EDIT MODAL
function openEditModal(house) {
    currentEditingHouse = house.id;
    document.getElementById('editHouseId').textContent = house.id;
    document.getElementById('editHouseType').value = house.type;
    
    // Helper function để set vec string vào inputs
    const setVecValue = (coordName, x, y, z, h) => {
        const input = document.querySelector(`[data-coord="${coordName}"]`);
        if (input) {
            // Skip nếu coords là null/undefined (dành cho optional fields như bed)
            if (x === null || x === undefined || y === null || y === undefined || z === null || z === undefined) {
                input.value = '';
            } else {
                // Bed coords luôn là vec4 (fallback heading = 0.0)
                if (coordName === 'edit_bed') {
                    input.value = formatVecString(x, y, z, h !== null && h !== undefined ? h : 0.0);
                } else {
                    input.value = formatVecString(x, y, z, h);
                }
            }
        }
    };
    
    // Set coords as vec strings
    setVecValue('edit_door', house.door_x, house.door_y, house.door_z);
    setVecValue('edit_interior', house.interior_x, house.interior_y, house.interior_z);
    setVecValue('edit_storage', house.storage_x, house.storage_y, house.storage_z);
    setVecValue('edit_juicer', house.juicer_x, house.juicer_y, house.juicer_z);
    setVecValue('edit_packaging', house.packaging_x, house.packaging_y, house.packaging_z);
    setVecValue('edit_exit', house.exit_x, house.exit_y, house.exit_z);
    setVecValue('edit_garage', house.garage_x, house.garage_y, house.garage_z);
    setVecValue('edit_spawn', house.spawn_x, house.spawn_y, house.spawn_z, house.spawn_h);
    setVecValue('edit_bed', house.bed_x, house.bed_y, house.bed_z, house.bed_w); // Bed coords (optional, vec4)
    
    // Set price (optional)
    document.getElementById('editHousePrice').value = house.price || '';
    
    // Set gang (optional)
    const editGangInput = document.getElementById('editHouseGang');
    if (editGangInput) {
        editGangInput.value = house.gang || '';
    }
    
    document.getElementById('editModal').style.display = 'flex';
}

// SAVE EDIT
// SAVE EDIT
document.getElementById('saveEditBtn').addEventListener('click', function() {
    // Helper function để lấy và parse vec string
    const getCoordFromVec = (coordName) => {
        const input = document.querySelector(`[data-coord="${coordName}"]`);
        if (!input || !input.value.trim()) return null;
        return parseVecString(input.value);
    };
    
    const doorCoords = getCoordFromVec('edit_door');
    const interiorCoords = getCoordFromVec('edit_interior');
    const storageCoords = getCoordFromVec('edit_storage');
    const juicerCoords = getCoordFromVec('edit_juicer');
    const packagingCoords = getCoordFromVec('edit_packaging');
    const exitCoords = getCoordFromVec('edit_exit');
    const garageCoords = getCoordFromVec('edit_garage');
    const spawnCoords = getCoordFromVec('edit_spawn');
    
    // Bed coords - OPTIONAL (để trống = xóa bed)
    const bedCoords = getCoordFromVec('edit_bed');
    
    // Validate
    if (!doorCoords || !interiorCoords || !storageCoords || !juicerCoords || !packagingCoords || !exitCoords || !garageCoords || !spawnCoords) {
        showAlert('Vui lòng điền đầy đủ tất cả coords!\nFormat: vec3(x, y, z) hoặc vec4(x, y, z, h)', 'error');
        return;
    }
    
    if (!spawnCoords.h) {
        showAlert('Spawn coords phải có heading! Dùng vec4(x, y, z, heading)', 'error');
        return;
    }
    
    // Get price (optional)
    const priceInput = document.getElementById('editHousePrice');
    const price = priceInput && priceInput.value.trim() ? parseInt(priceInput.value) : null;
    
    const editGangInput = document.getElementById('editHouseGang');
    const editGangVal = editGangInput && editGangInput.value.trim() ? editGangInput.value.trim() : null;

    const houseData = {
        id: currentEditingHouse,
        type: document.getElementById('editHouseType').value,
        price: price, // null = use Config.HouseTypes price
        gang: editGangVal,
        door: doorCoords,
        interior: interiorCoords,
        storage: storageCoords,
        juicer: juicerCoords,
        packaging: packagingCoords,
        exit: exitCoords,
        garage: garageCoords,
        spawn: spawnCoords,
        bed: bedCoords // Null = xóa bed
    };
    
    nuiFetch('updateHouse', houseData).then(data => {
        if (data.success) {
            showAlert('Cập nhật thành công!', 'success');
            document.getElementById('editModal').style.display = 'none';
            loadHousesList();
        } else {
            showAlert('Lỗi: ' + (data.message || 'Không xác định'), 'error');
        }
    });
});

// CANCEL EDIT
document.getElementById('cancelEditBtn').addEventListener('click', function() {
    document.getElementById('editModal').style.display = 'none';
});

// DELETE HOUSE
document.getElementById('deleteHouseBtn').addEventListener('click', function() {
    showConfirm('Bạn có chắc muốn XÓA nhà ' + currentEditingHouse + '?', () => {
        nuiFetch('deleteHouse', { id: currentEditingHouse }).then(data => {
            if (data.success) {
                showAlert('Xóa nhà thành công!', 'success');
                document.getElementById('editModal').style.display = 'none';
                loadHousesList();
            } else {
                showAlert('Lỗi: ' + (data.message || 'Không xác định'), 'error');
            }
        });
    });
});

// REFRESH LIST
document.getElementById('refreshList').addEventListener('click', loadHousesList);

// SEARCH
document.getElementById('searchHouse').addEventListener('input', function() {
    const searchTerm = this.value.toLowerCase();
    document.querySelectorAll('.house-card').forEach(card => {
        const text = card.textContent.toLowerCase();
        card.style.display = text.includes(searchTerm) ? 'block' : 'none';
    });
});

// ESC TO CLOSE
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        if (document.getElementById('editModal').style.display === 'flex') {
            document.getElementById('editModal').style.display = 'none';
        } else if (document.getElementById('adminContainer').style.display === 'flex') {
            document.getElementById('closeAdmin').click();
        }
    }
});

// CLOSE MODAL BUTTONS
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.close-modal').forEach(btn => {
        btn.addEventListener('click', function() {
            document.getElementById('editModal').style.display = 'none';
        });
    });
});

// Helper function to get resource name
function GetParentResourceName() {
    return 'qbx_housing';
}
