let config = {};
let selectedCharges = [];
let availableCharges = [];
let selectedOffenders = [];

// Search optimization
let searchCache = {};
let searchTimers = {};
let isSearching = false;

// Listen for NUI messages
window.addEventListener("message", (event) => {
  const data = event.data;

  if (data.action === "openMDT") {
    document
      .querySelector(".mdt-wrapper")
      .classList.add("active");
    config = data.config;
    // Ẩn tab Quản Lý Tạm Giam Logout nếu cấp bậc < 3
    const offlinePrisonTab =
      document.querySelector(
        '.nav-item[data-page="offline-prison"]',
      );
    if (offlinePrisonTab) {
      if (
        config.playerGrade &&
        config.playerGrade >= 3
      ) {
        offlinePrisonTab.style.display = "block";
      } else {
        offlinePrisonTab.style.display = "none";
      }
    }
    // Ẩn tab Quản Lý Mức Án nếu cấp bậc < 14
    const chargesTab = document.querySelector(
      '.nav-item[data-page="charges"]',
    );
    if (chargesTab) {
      const minGrade = config.minGradeForCharges || 14;
      if (
        config.playerGrade &&
        config.playerGrade >= minGrade
      ) {
        chargesTab.style.display = "block";
      } else {
        chargesTab.style.display = "none";
      }
    }
    // Cập nhật giá cấp CCCD
    const idCardPriceEl = document.getElementById(
      "idcard-price",
    );
    if (idCardPriceEl && config.idCardPrice) {
      idCardPriceEl.textContent =
        config.idCardPrice;
    }
    // Không tự động load records nữa - người dùng phải tìm kiếm
    initializeHandlerInfo();
    // Load charges ngay khi mở MDT để sẵn sàng chọn tội danh
    loadChargesForSelection();
    // Load danh sách cảnh sát online - CHỈ LOAD 1 LẦN DUY NHẤT
    loadOnlineOfficers();
  } else if (data.action === "closeMDT") {
    document
      .querySelector(".mdt-wrapper")
      .classList.remove("active");
  } else if (
    data.action === "openQuickFinalize"
  ) {
    config = data.config;
    openQuickFinalizeModal();
  } else if (data.action === "openTabletMenu") {
    config = data.config;
    showTabletMenu();
  }
});

// Close MDT
function closeMDT() {
  fetch(
    `https://${GetParentResourceName()}/close`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  );
}

// ESC key to close
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") {
    // Kiểm tra nếu tablet menu đang mở
    const tabletMenu = document.getElementById(
      "tablet-menu-overlay",
    );
    if (tabletMenu) {
      if (
        typeof window.closeTabletMenu ===
        "function"
      ) {
        window.closeTabletMenu();
      } else {
        // Fallback: xóa trực tiếp và gọi callback
        tabletMenu.remove();
        fetch(
          `https://${GetParentResourceName()}/closeTabletMenu`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({}),
          },
        );
      }
      return;
    }

    // Kiểm tra nếu modal chọn tội danh trong quick finalize đang mở
    const quickChargeSelectorModal =
      document.getElementById(
        "quick-charge-selector-modal",
      );
    if (
      quickChargeSelectorModal &&
      !quickChargeSelectorModal.classList.contains(
        "hidden",
      )
    ) {
      if (
        typeof closeQuickChargeSelector ===
        "function"
      ) {
        closeQuickChargeSelector();
      }
      return;
    }

    // Kiểm tra nếu quick finalize modal đang mở
    const quickModal = document.getElementById(
      "quick-finalize-modal",
    );
    if (
      quickModal &&
      quickModal.style.display !== "none" &&
      !quickModal.classList.contains("hidden")
    ) {
      if (
        typeof window.closeQuickFinalize ===
        "function"
      ) {
        window.closeQuickFinalize();
      } else if (
        typeof closeQuickFinalize === "function"
      ) {
        closeQuickFinalize();
      }
      return;
    }

    // Kiểm tra nếu modal chi tiết vụ án đang mở
    const recordDetailModal =
      document.getElementById(
        "record-detail-modal",
      );
    if (
      recordDetailModal &&
      !recordDetailModal.classList.contains(
        "hidden",
      )
    ) {
      if (
        typeof closeRecordDetail === "function"
      ) {
        closeRecordDetail();
      }
      return;
    }

    // Kiểm tra nếu modal chọn tội danh đang mở
    const chargeSelectorModal =
      document.getElementById(
        "charge-selector-modal",
      );
    if (
      chargeSelectorModal &&
      !chargeSelectorModal.classList.contains(
        "hidden",
      )
    ) {
      if (
        typeof closeChargeSelector === "function"
      ) {
        closeChargeSelector();
      }
      return;
    }

    // Nếu không có gì đặc biệt thì đóng MDT
    const mdtWrapper = document.querySelector(
      ".mdt-wrapper",
    );
    if (
      mdtWrapper &&
      mdtWrapper.classList.contains("active")
    ) {
      closeMDT();
    }
  }
});

// Navigation
document
  .querySelectorAll(".nav-item")
  .forEach((item) => {
    item.addEventListener("click", () => {
      const page = item.dataset.page;

      // Kiểm tra quyền truy cập trang offline-prison
      if (page === "offline-prison") {
        if (
          !config.playerGrade ||
          config.playerGrade < 3
        ) {
          fetch(
            `https://${GetParentResourceName()}/notify`,
            {
              method: "POST",
              headers: {
                "Content-Type":
                  "application/json",
              },
              body: JSON.stringify({
                message:
                  "Bạn cần cấp bậc 3 trở lên để truy cập chức năng này!",
                type: "error",
              }),
            },
          );
          return;
        }
      }

      // Kiểm tra quyền truy cập trang charges
      if (page === "charges") {
        if (
          !config.playerGrade ||
          config.playerGrade < 12
        ) {
          fetch(
            `https://${GetParentResourceName()}/notify`,
            {
              method: "POST",
              headers: {
                "Content-Type":
                  "application/json",
              },
              body: JSON.stringify({
                message:
                  "Bạn cần cấp bậc 14 trở lên để quản lý mức án!",
                type: "error",
              }),
            },
          );
          return;
        }
      }

      document
        .querySelectorAll(".nav-item")
        .forEach((i) =>
          i.classList.remove("active"),
        );
      item.classList.add("active");

      document
        .querySelectorAll(".page")
        .forEach((p) =>
          p.classList.add("hidden"),
        );
      document
        .getElementById(page + "-page")
        .classList.remove("hidden");

      if (page === "charges") {
        loadCharges();
      }

      if (page === "today-records") {
        loadTodayRecords();
      }

      if (page === "offline-prison") {
        loadOfflinePrisonHistory();
      }

      if (page === "vehicle-impound") {
        loadActiveImpounds();
      }

      if (page === "create") {
        resetCaseForm();
        initializeHandlerInfo();
        // Không cần load lại officers - đã load khi mở MDT
        // loadOnlineOfficers();
        loadChargesForSelection();
      }
    });
  });

// Initialize Handler Info
function initializeHandlerInfo() {
  fetch(
    `https://${GetParentResourceName()}/getCurrentOfficer`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  )
    .then((r) => r.json())
    .then((officer) => {
      document.getElementById(
        "handler-name",
      ).value =
        `${officer.name} - ${officer.rank}`;
      document.getElementById(
        "handler-id",
      ).value = officer.citizenid;
      document.getElementById(
        "handler-rank",
      ).value = officer.rank;
    });
}

// Load Online Officers
function loadOnlineOfficers() {
  fetch(
    `https://${GetParentResourceName()}/getOnlineOfficers`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  )
    .then((r) => r.json())
    .then((officers) => {
      const list = document.getElementById(
        "officers-list",
      );
      list.innerHTML = officers
        .map(
          (o) => `
            <div class="officer-checkbox">
                <input type="checkbox" id="officer-${o.citizenid}" value="${o.citizenid}" data-name="${o.name}" data-rank="${o.rank}">
                <label for="officer-${o.citizenid}" style="cursor: pointer;">${o.name} - ${o.rank}</label>
            </div>
        `,
        )
        .join("");
    });
}

// Search Offender
function searchOffender() {
  const pid = document.getElementById(
    "offender-id",
  ).value;
  if (!pid) {
    showError("Vui lòng nhập PID");
    return;
  }

  const timeoutId = setTimeout(() => {
    showError(
      "Không tìm thấy người chơi với PID này (có thể offline)",
    );
  }, 5000);

  fetch(
    `https://${GetParentResourceName()}/getPlayerInfo`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        pid: parseInt(pid),
      }),
    },
  )
    .then((r) => r.json())
    .then((response) => {
      clearTimeout(timeoutId);
      if (response.success && response.data) {
        const player = response.data;
        // Check if already added
        if (
          selectedOffenders.some(
            (o) =>
              o.citizenid === player.citizenid,
          )
        ) {
          showError(
            "Tội phạm này đã được thêm vào danh sách",
          );
          return;
        }
        // Add to list
        selectedOffenders.push(player);
        renderSelectedOffenders();
        document.getElementById(
          "offender-id",
        ).value = "";
        showSuccess(`Đã thêm: ${player.name}`);
      } else {
        showError(
          response.error ||
            "Không tìm thấy người chơi",
        );
      }
    })
    .catch(() => {
      clearTimeout(timeoutId);
      showError("Lỗi khi tìm kiếm người chơi");
    });
}

// Load Charges for Selection
function loadChargesForSelection() {
  fetch(
    `https://${GetParentResourceName()}/getCharges`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  )
    .then((r) => r.json())
    .then((charges) => {
      availableCharges = charges;
    });
}

// Open Charge Selector
function openChargeSelector() {
  if (availableCharges.length === 0) {
    showError(
      "Chưa có mức án nào. Vui lòng tạo mức án trước.",
    );
    return;
  }

  const modal = document.getElementById(
    "charge-selector-modal",
  );
  const overlay = document.getElementById(
    "modal-overlay",
  );
  const list = document.getElementById(
    "charge-selector-list",
  );

  list.innerHTML = availableCharges
    .map(
      (charge) => `
        <div class="charge-select-item" onclick="addCharge(${charge.id}, '${charge.charge_name.replace(/'/g, "\\'")}', ${charge.fine_min}, ${charge.fine_max}, ${charge.jail_min}, ${charge.jail_max})">
            <div style="font-weight: 600; margin-bottom: 5px;">${charge.charge_name}</div>
            <div style="font-size: 12px; color: #94a3b8;">
                💰 $${charge.fine_min.toLocaleString()} - $${charge.fine_max.toLocaleString()} | 
                🔒 ${charge.jail_min} - ${charge.jail_max} bãi
            </div>
        </div>
    `,
    )
    .join("");

  modal.classList.remove("hidden");
  overlay.classList.remove("hidden");
}

// Close Charge Selector
function closeChargeSelector() {
  document
    .getElementById("charge-selector-modal")
    .classList.add("hidden");
  document
    .getElementById("modal-overlay")
    .classList.add("hidden");
}

// Add Charge
function addCharge(
  id,
  name,
  fineMin,
  fineMax,
  jailMin,
  jailMax,
) {
  if (selectedCharges.some((c) => c.id === id)) {
    showError("Tội danh này đã được chọn");
    return;
  }

  selectedCharges.push({
    id: id,
    name: name,
    fineMin: fineMin,
    fineMax: fineMax,
    jailMin: jailMin,
    jailMax: jailMax,
    selectedFine: null,
    selectedJail: null,
  });

  renderSelectedCharges();
  closeChargeSelector();
}

// Remove Charge
function removeCharge(index) {
  selectedCharges.splice(index, 1);
  renderSelectedCharges();
}

// Select Fine
function selectChargeFine(index, type) {
  const charge = selectedCharges[index];
  charge.selectedFine =
    type === "min"
      ? charge.fineMin
      : charge.fineMax;
  renderSelectedCharges();
}

// Select Jail
function selectChargeJail(index, type) {
  const charge = selectedCharges[index];
  charge.selectedJail =
    type === "min"
      ? charge.jailMin
      : charge.jailMax;
  renderSelectedCharges();
}

// Render Selected Offenders
function renderSelectedOffenders() {
  const container = document.getElementById(
    "offenders-list",
  );

  if (selectedOffenders.length === 0) {
    container.innerHTML =
      '<p style="color: #94a3b8; text-align: center; padding: 10px;">Chưa có tội phạm nào</p>';
    return;
  }

  container.innerHTML = selectedOffenders
    .map(
      (offender, index) => `
        <div style="background: rgba(40, 40, 50, 0.9); border: 2px solid #3b82f6; border-radius: 8px; padding: 12px; margin-bottom: 10px; display: flex; justify-content: space-between; align-items: center;">
            <div>
                <div style="font-weight: 600; color: #3b82f6;">${offender.name}</div>
                <div style="font-size: 12px; color: #94a3b8;">PID: ${offender.pid}</div>
            </div>
            <button class="remove-charge-btn" onclick="removeOffender(${index})" style="margin: 0;">✕ Xóa</button>
        </div>
    `,
    )
    .join("");
}

// Remove Offender
function removeOffender(index) {
  selectedOffenders.splice(index, 1);
  renderSelectedOffenders();
}

// Render Selected Charges
function renderSelectedCharges() {
  const container = document.getElementById(
    "selected-charges-list",
  );

  if (selectedCharges.length === 0) {
    container.innerHTML =
      '<p style="color: #94a3b8; text-align: center;">Chưa có tội danh nào được chọn</p>';
    return;
  }

  container.innerHTML = selectedCharges
    .map(
      (charge, index) => `
        <div class="selected-charge-card">
            <div class="selected-charge-header">
                <div class="selected-charge-title">${index + 1}. ${charge.name}</div>
                <button class="remove-charge-btn" onclick="removeCharge(${index})">✕ Xóa</button>
            </div>
            
            <div class="penalty-row">
                <div class="penalty-label">💰 Mức phạt:</div>
                <div class="penalty-buttons">
                    <button class="penalty-btn ${charge.selectedFine === charge.fineMin ? "active" : ""}" 
                            onclick="selectChargeFine(${index}, 'min')">
                        $${charge.fineMin.toLocaleString()}
                    </button>
                    <button class="penalty-btn ${charge.selectedFine === charge.fineMax ? "active" : ""}" 
                            onclick="selectChargeFine(${index}, 'max')">
                        $${charge.fineMax.toLocaleString()}
                    </button>
                </div>
            </div>
            
            <div class="penalty-row">
                <div class="penalty-label">⏱️ Thời gian tù:</div>
                <div class="penalty-buttons">
                    <button class="penalty-btn jail ${charge.selectedJail === charge.jailMin ? "active" : ""}" 
                            onclick="selectChargeJail(${index}, 'min')">
                        ${charge.jailMin} bãi
                    </button>
                    <button class="penalty-btn jail ${charge.selectedJail === charge.jailMax ? "active" : ""}" 
                            onclick="selectChargeJail(${index}, 'max')">
                        ${charge.jailMax} bãi
                    </button>
                </div>
            </div>
        </div>
    `,
    )
    .join("");
}

// Finalize Case
function finalizeCase() {
  // Validate
  const notes =
    document.getElementById("case-notes").value;

  if (selectedOffenders.length === 0) {
    showError("Vui lòng thêm ít nhất 1 tội phạm");
    return;
  }

  if (selectedCharges.length === 0) {
    showError("Vui lòng chọn ít nhất 1 tội danh");
    return;
  }

  // Check if all charges have penalties selected
  for (let charge of selectedCharges) {
    if (
      charge.selectedFine === null ||
      charge.selectedJail === null
    ) {
      showError(
        `Vui lòng chọn mức án cho tội "${charge.name}"`,
      );
      return;
    }
  }

  // Get selected officers
  const selectedOfficers = [];
  document
    .querySelectorAll(
      '#officers-list input[type="checkbox"]:checked',
    )
    .forEach((cb) => {
      selectedOfficers.push({
        citizenid: cb.value,
        name: cb.dataset.name,
        rank: cb.dataset.rank,
      });
    });

  // VALIDATION: BẮT BUỘC CHỌN ÍT NHẤT 1 CẢNH SÁT THAM GIA
  if (selectedOfficers.length === 0) {
    showError(
      "Vui lòng chọn ít nhất 1 cảnh sát tham gia vụ án",
    );
    return;
  }

  // Calculate totals
  const totalFine = selectedCharges.reduce(
    (sum, c) => sum + c.selectedFine,
    0,
  );
  const totalJailTime = selectedCharges.reduce(
    (sum, c) => sum + c.selectedJail,
    0,
  );

  // Prepare data
  const caseData = {
    handler: {
      citizenid:
        document.getElementById("handler-id")
          .value,
      name: document
        .getElementById("handler-name")
        .value.split(" - ")[0],
      rank: document.getElementById(
        "handler-rank",
      ).value,
    },
    officers: selectedOfficers,
    offenders: selectedOffenders.map((o) => ({
      name: o.name,
      citizenid: o.citizenid,
      pid: o.pid,
    })),
    charges: selectedCharges.map((c) => ({
      id: c.id,
      name: c.name,
      selectedFine: c.selectedFine,
      selectedJail: c.selectedJail,
    })),
    totalFine: totalFine,
    totalJailTime: totalJailTime,
    notes: notes,
  };

  fetch(
    `https://${GetParentResourceName()}/finalizeCase`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(caseData),
    },
  )
    .then((r) => r.json())
    .then((result) => {
      if (result.success) {
        showSuccess("Kết án thành công!");
        resetCaseForm();
        loadRecords();
      } else {
        showError(
          result.message || "Có lỗi xảy ra",
        );
      }
    });
}

// Reset Case Form
function resetCaseForm() {
  document.getElementById("offender-id").value =
    "";
  document.getElementById("case-notes").value =
    "";
  selectedCharges = [];
  selectedOffenders = [];
  renderSelectedCharges();
  renderSelectedOffenders();
  document
    .querySelectorAll(
      '#officers-list input[type="checkbox"]',
    )
    .forEach((cb) => (cb.checked = false));
}

// Load Records
function loadRecords() {
  // Clear cache
  searchCache = {};

  const list = document.getElementById(
    "records-list",
  );
  list.innerHTML =
    '<p style="color: #3b82f6; text-align: center; padding: 40px;">🔄 Đang tải...</p>';

  fetch(
    `https://${GetParentResourceName()}/getRecords`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  )
    .then((r) => r.json())
    .then((records) => {
      displayRecords(records);
    })
    .catch(() => {
      list.innerHTML =
        '<p style="color: #ef4444; text-align: center; padding: 40px;">❌ Lỗi khi tải dữ liệu</p>';
    });
}

// Load Today Records
function loadTodayRecords() {
  const list = document.getElementById(
    "today-records-list",
  );
  list.innerHTML =
    '<p style="color: #3b82f6; text-align: center; padding: 40px;">🔄 Đang tải...</p>';

  fetch(
    `https://${GetParentResourceName()}/getTodayRecords`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  )
    .then((r) => r.json())
    .then((records) => {
      if (!records || records.length === 0) {
        list.innerHTML =
          '<p style="color: #94a3b8; text-align: center; padding: 40px;">📭 Chưa có hồ sơ vụ án nào trong ngày hôm nay</p>';
        return;
      }

      list.innerHTML = records
        .map(
          (r) => `
            <div class="record-item" data-record-id="${r.id}" style="cursor: pointer; transition: all 0.3s;" onmouseover="this.style.background='rgba(50,50,60,0.9)'" onmouseout="this.style.background='rgba(40,40,50,0.9)'">
                <div class="record-title">${r.title}</div>
                <div class="record-meta">
                    Xử lý bởi: ${r.handler_officer_name} | 
                    Ngày tạo: ${new Date(r.created_date).toLocaleString("vi-VN")}
                </div>
                <div style="font-size: 12px; color: #3b82f6; margin-top: 8px;">👁️ Click để xem chi tiết</div>
            </div>
        `,
        )
        .join("");

      // Thêm event listener cho mỗi record
      list
        .querySelectorAll(".record-item")
        .forEach((item) => {
          item.addEventListener(
            "click",
            function () {
              const recordId = parseInt(
                this.getAttribute(
                  "data-record-id",
                ),
              );
              viewRecordDetail(recordId);
            },
          );
        });
    })
    .catch((err) => {
      list.innerHTML =
        '<p style="color: #ef4444; text-align: center; padding: 40px;">❌ Lỗi khi tải dữ liệu</p>';
    });
}

// Load Offline Prison History
function loadOfflinePrisonHistory() {
  const list = document.getElementById(
    "offline-prison-list",
  );
  list.innerHTML =
    '<p style="color: #3b82f6; text-align: center; padding: 40px;">🔄 Đang tải...</p>';

  fetch(
    `https://${GetParentResourceName()}/getOfflinePrisonHistory`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  )
    .then((r) => r.json())
    .then((result) => {
      if (
        !result.success ||
        !result.data ||
        result.data.length === 0
      ) {
        list.innerHTML =
          '<p style="color: #94a3b8; text-align: center; padding: 40px;">📭 Chưa có hồ sơ tạm giam logout nào</p>';
        return;
      }

      const records = result.data;

      list.innerHTML = records
        .map((r) => {
          const isActive = r.status === "active";
          const statusColor = isActive
            ? "#f59e0b"
            : "#10b981";
          const statusIcon = isActive
            ? "🔒"
            : "✅";
          const statusText = isActive
            ? "Đang tạm giam"
            : "Đã thả";

          return `
                <div class="record-item" style="border-left: 3px solid ${statusColor};">
                    <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 10px;">
                        <div class="record-title" style="flex: 1;">
                            ${statusIcon} ${r.offender_name} (PID: ${r.offender_pid})
                        </div>
                        <span style="background: ${statusColor}; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600; white-space: nowrap; margin-left: 10px;">
                            ${statusText}
                        </span>
                    </div>
                    
                    <div class="record-meta" style="margin-bottom: 8px;">
                        👮 Người xử lý: ${r.punisher_name} (${r.punisher_rank || "Officer"})
                    </div>
                    
                    <div style="background: rgba(30,30,40,0.5); padding: 10px; border-radius: 6px; margin-top: 10px;">
                        <div style="color: #94a3b8; font-size: 13px; margin-bottom: 5px;">📝 Lý do:</div>
                        <div style="color: white; font-size: 14px;">${r.reason}</div>
                    </div>
                    
                    <div style="margin-top: 10px; font-size: 12px; color: #64748b;">
                        ⏰ Tạo lúc: ${new Date(r.created_date).toLocaleString("vi-VN")}
                        ${r.released_date ? `<br>✅ Thả lúc: ${new Date(r.released_date).toLocaleString("vi-VN")}` : ""}
                        ${r.released_by_name ? `<br>👤 Người thả: ${r.released_by_name}` : ""}
                    </div>
                </div>
            `;
        })
        .join("");
    })
    .catch((err) => {
      console.error(
        "[OFFLINE PRISON] Error:",
        err,
      );
      list.innerHTML =
        '<p style="color: #ef4444; text-align: center; padding: 40px;">❌ Lỗi khi tải dữ liệu</p>';
    });
}

// Add Offline Prison
function addOfflinePrison() {
  const offenderPid = document.getElementById(
    "prison-offender-pid",
  ).value;
  const reason = document.getElementById(
    "prison-reason",
  ).value;

  if (!offenderPid) {
    showError("Vui lòng nhập PID tội phạm");
    return;
  }

  if (!reason || reason.trim() === "") {
    showError("Vui lòng nhập lý do tạm giam");
    return;
  }

  fetch(
    `https://${GetParentResourceName()}/addOfflinePrison`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        offenderPid: offenderPid,
        reason: reason,
      }),
    },
  )
    .then((r) => r.json())
    .then((result) => {
      if (result.success) {
        showSuccess("✅ Đã tạm giam thành công!");
        document.getElementById(
          "prison-offender-pid",
        ).value = "";
        document.getElementById(
          "prison-reason",
        ).value = "";
        loadOfflinePrisonHistory();
      } else {
        showError(
          result.message || "Lỗi khi tạm giam",
        );
      }
    })
    .catch((err) => {
      console.error(
        "[OFFLINE PRISON] Add error:",
        err,
      );
      showError("Lỗi khi tạm giam");
    });
}

// Release Offline Prison
function releaseOfflinePrison() {
  const offenderPid = document.getElementById(
    "release-offender-pid",
  ).value;

  if (!offenderPid) {
    showError(
      "Vui lòng nhập PID tội phạm cần thả",
    );
    return;
  }

  fetch(
    `https://${GetParentResourceName()}/releaseOfflinePrison`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        offenderPid: offenderPid,
      }),
    },
  )
    .then((r) => r.json())
    .then((result) => {
      if (result.success) {
        showSuccess(
          "✅ Đã thả tạm giam thành công!",
        );
        document.getElementById(
          "release-offender-pid",
        ).value = "";
        loadOfflinePrisonHistory();
      } else {
        showError(
          result.message ||
            "Lỗi khi thả tạm giam",
        );
      }
    })
    .catch((err) => {
      console.error(
        "[OFFLINE PRISON] Release error:",
        err,
      );
      showError("Lỗi khi thả tạm giam");
    });
}

// Quick Release Prisoner (from create page)
function quickReleasePrisoner() {
  const offenderPid = document.getElementById(
    "quick-release-pid",
  ).value;

  if (!offenderPid) {
    showError(
      "Vui lòng nhập PID tội phạm cần thả",
    );
    return;
  }

  fetch(
    `https://${GetParentResourceName()}/cancelPrison`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        pid: parseInt(offenderPid),
      }),
    },
  )
    .then((r) => r.json())
    .then((result) => {
      if (result.success) {
        showSuccess("✅ Đã thả tù thành công!");
        document.getElementById(
          "quick-release-pid",
        ).value = "";
      } else {
        showError(
          result.message || "Lỗi khi thả tù",
        );
      }
    })
    .catch((err) => {
      showError("Lỗi khi thả tù");
    });
}

// Search Offline Prison by PID
function searchOfflinePrison() {
  const pid = document.getElementById(
    "search-prison-pid",
  ).value;

  if (!pid) {
    showError("Vui lòng nhập PID để tìm kiếm");
    return;
  }

  const list = document.getElementById(
    "offline-prison-list",
  );
  list.innerHTML =
    '<p style="color: #3b82f6; text-align: center; padding: 40px;">🔄 Đang tìm kiếm...</p>';

  fetch(
    `https://${GetParentResourceName()}/searchOfflinePrison`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        pid: pid,
      }),
    },
  )
    .then((r) => r.json())
    .then((result) => {
      if (
        !result.success ||
        !result.data ||
        result.data.length === 0
      ) {
        list.innerHTML =
          '<p style="color: #94a3b8; text-align: center; padding: 40px;">📭 Không tìm thấy hồ sơ tạm giam nào</p>';
        return;
      }

      const records = result.data;

      list.innerHTML = records
        .map((r) => {
          const isActive = r.status === "active";
          const statusColor = isActive
            ? "#f59e0b"
            : "#10b981";
          const statusIcon = isActive
            ? "🔒"
            : "✅";
          const statusText = isActive
            ? "Đang tạm giam"
            : "Đã thả";

          return `
                <div class="record-item" style="border-left: 3px solid ${statusColor};">
                    <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 10px;">
                        <div class="record-title" style="flex: 1;">
                            ${statusIcon} ${r.offender_name} (PID: ${r.offender_pid})
                        </div>
                        <span style="background: ${statusColor}; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600; white-space: nowrap; margin-left: 10px;">
                            ${statusText}
                        </span>
                    </div>
                    
                    <div class="record-meta" style="margin-bottom: 8px;">
                        👮 Người xử lý: ${r.punisher_name} (${r.punisher_rank || "Officer"})
                    </div>
                    
                    <div style="background: rgba(30,30,40,0.5); padding: 10px; border-radius: 6px; margin-top: 10px;">
                        <div style="color: #94a3b8; font-size: 13px; margin-bottom: 5px;">📝 Lý do:</div>
                        <div style="color: white; font-size: 14px;">${r.reason}</div>
                    </div>
                    
                    <div style="margin-top: 10px; font-size: 12px; color: #64748b;">
                        ⏰ Tạo lúc: ${new Date(r.created_date).toLocaleString("vi-VN")}
                        ${r.released_date ? `<br>✅ Thả lúc: ${new Date(r.released_date).toLocaleString("vi-VN")}` : ""}
                        ${r.released_by_name ? `<br>👤 Người thả: ${r.released_by_name}` : ""}
                    </div>
                </div>
            `;
        })
        .join("");

      showSuccess(
        `Tìm thấy ${records.length} hồ sơ`,
      );
    })
    .catch((err) => {
      console.error(
        "[OFFLINE PRISON] Search error:",
        err,
      );
      list.innerHTML =
        '<p style="color: #ef4444; text-align: center; padding: 40px;">❌ Lỗi khi tìm kiếm</p>';
    });
}

// Search Records by Handler PID
function searchRecordsByHandler() {
  const pid = document.getElementById(
    "search-handler-pid",
  ).value;
  if (!pid) {
    showError("Vui lòng nhập PID người xử lý");
    return;
  }

  // Prevent spam
  if (isSearching) {
    showError(
      "Vui lòng chờ tìm kiếm trước kết thúc",
    );
    return;
  }

  // Check cache (30 seconds)
  const cacheKey = "handler_" + pid;
  const cached = searchCache[cacheKey];
  if (
    cached &&
    Date.now() - cached.timestamp < 30000
  ) {
    displayRecords(cached.data);
    showSuccess(
      `Tìm thấy ${cached.data.length} hồ sơ (cached)`,
    );
    return;
  }

  // Show loading
  isSearching = true;
  const list = document.getElementById(
    "records-list",
  );
  list.innerHTML =
    '<p style="color: #3b82f6; text-align: center; padding: 40px;">🔍 Đang tìm kiếm...</p>';

  fetch(
    `https://${GetParentResourceName()}/searchRecordsByHandler`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        pid: parseInt(pid),
      }),
    },
  )
    .then((r) => r.json())
    .then((records) => {
      isSearching = false;

      // Check for null or invalid response
      if (!records || !Array.isArray(records)) {
        records = [];
      }

      // Cache results
      searchCache[cacheKey] = {
        data: records,
        timestamp: Date.now(),
      };

      if (records.length === 0) {
        showError(
          "Không tìm thấy hồ sơ nào của người xử lý này",
        );
      } else {
        showSuccess(
          `Tìm thấy ${records.length} hồ sơ`,
        );
      }
      displayRecords(records);
    })
    .catch(() => {
      isSearching = false;
      list.innerHTML =
        '<p style="color: #ef4444; text-align: center; padding: 40px;">❌ Lỗi khi tìm kiếm</p>';
    });
}

// Search Records by Offender PID (30 days)
function searchRecordsByOffender() {
  const pid = document.getElementById(
    "search-offender-pid",
  ).value;
  if (!pid) {
    showError("Vui lòng nhập PID tội phạm");
    return;
  }

  // Prevent spam
  if (isSearching) {
    showError(
      "Vui lòng chờ tìm kiếm trước kết thúc",
    );
    return;
  }

  // Check cache (30 seconds)
  const cacheKey = "offender_" + pid;
  const cached = searchCache[cacheKey];
  if (
    cached &&
    Date.now() - cached.timestamp < 30000
  ) {
    displayRecords(cached.data);
    showSuccess(
      `Tìm thấy ${cached.data.length} án tích (cached)`,
    );
    return;
  }

  // Show loading
  isSearching = true;
  const list = document.getElementById(
    "records-list",
  );
  list.innerHTML =
    '<p style="color: #10b981; text-align: center; padding: 40px;">🔍 Đang tìm kiếm án tích...</p>';

  fetch(
    `https://${GetParentResourceName()}/searchRecordsByOffender`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        pid: parseInt(pid),
      }),
    },
  )
    .then((r) => r.json())
    .then((records) => {
      isSearching = false;

      // Check for null or invalid response
      if (!records || !Array.isArray(records)) {
        records = [];
      }

      // Cache results
      searchCache[cacheKey] = {
        data: records,
        timestamp: Date.now(),
      };

      if (records.length === 0) {
        showError(
          "Không tìm thấy án tích nào trong 30 ngày",
        );
      } else {
        showSuccess(
          `Tìm thấy ${records.length} án tích trong 30 ngày`,
        );
      }
      displayRecords(records);
    })
    .catch(() => {
      isSearching = false;
      list.innerHTML =
        '<p style="color: #ef4444; text-align: center; padding: 40px;">❌ Lỗi khi tìm kiếm</p>';
    });
}

// Display Records Helper
function displayRecords(records) {
  const list = document.getElementById(
    "records-list",
  );

  if (
    !records ||
    !Array.isArray(records) ||
    records.length === 0
  ) {
    list.innerHTML =
      '<p style="color: #ef4444; text-align: center; padding: 40px;">❌ Không tìm thấy kết quả nào</p>';
    return;
  }

  list.innerHTML = records
    .map(
      (r) => `
        <div class="record-item" data-record-id="${r.id}" style="cursor: pointer; transition: all 0.3s;" onmouseover="this.style.background='rgba(50,50,60,0.9)'" onmouseout="this.style.background='rgba(40,40,50,0.9)'">
            <div class="record-title">${r.title}</div>
            <div class="record-meta">
                Xử lý bởi: ${r.handler_officer_name} | 
                Ngày tạo: ${new Date(r.created_date).toLocaleString("vi-VN")}
            </div>
            <div style="font-size: 12px; color: #3b82f6; margin-top: 8px;">👁️ Click để xem chi tiết</div>
        </div>
    `,
    )
    .join("");

  // Thêm event listener cho mỗi record
  list
    .querySelectorAll(".record-item")
    .forEach((item) => {
      item.addEventListener("click", function () {
        const recordId = parseInt(
          this.getAttribute("data-record-id"),
        );
        viewRecordDetail(recordId);
      });
    });
}

// View Record Detail
function viewRecordDetail(recordId) {
  console.log(
    "[VIEW DETAIL] Opening detail for record ID:",
    recordId,
  );
  const modal = document.getElementById(
    "record-detail-modal",
  );
  const content = document.getElementById(
    "record-detail-content",
  );

  modal.classList.remove("hidden");
  content.innerHTML =
    '<p style="color: #3b82f6; text-align: center; padding: 40px;">🔄 Đang tải chi tiết...</p>';

  fetch(
    `https://${GetParentResourceName()}/getRecordDetail`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        recordId: recordId,
      }),
    },
  )
    .then((r) => r.json())
    .then((detail) => {
      console.log(
        "[VIEW DETAIL] Got detail:",
        detail,
      );

      if (!detail || !detail.record) {
        content.innerHTML =
          '<p style="color: #ef4444; text-align: center;">❌ Không tìm thấy thông tin vụ án</p>';
        return;
      }

      const record = detail.record;
      const offenders = detail.offenders || [];
      const charges = detail.charges || [];
      const officers = detail.officers || [];

      // Calculate totals
      const totalFine = charges.reduce(
        (sum, c) => sum + (c.fine_amount || 0),
        0,
      );
      const totalJail = charges.reduce(
        (sum, c) => sum + (c.jail_time || 0),
        0,
      );

      content.innerHTML = `
            <div style="margin-bottom: 20px; padding: 15px; background: rgba(59, 130, 246, 0.1); border-left: 4px solid #3b82f6; border-radius: 6px;">
                <h3 style="color: #3b82f6; margin: 0 0 10px 0;">${record.title}</h3>
                <div style="color: #94a3b8; font-size: 14px;">
                    <p style="margin: 5px 0;">👮 Người xử lý: ${record.handler_officer_name} - ${record.handler_officer_rank}</p>
                    <p style="margin: 5px 0;">📅 Ngày tạo: ${new Date(record.created_date).toLocaleString("vi-VN")}</p>
                    <p style="margin: 5px 0;">📊 Trạng thái: <span style="color: ${record.status === "closed" ? "#10b981" : "#f59e0b"}; font-weight: 600;">${record.status === "closed" ? "Đã đóng" : "Đang mở"}</span></p>
                </div>
            </div>
            
            ${
              officers.length > 0
                ? `
            <div style="margin-bottom: 20px;">
                <h4 style="color: #3b82f6; margin-bottom: 10px;">👥 Cảnh Sát Tham Gia (${officers.length})</h4>
                <div style="display: flex; flex-wrap: wrap; gap: 10px;">
                    ${officers
                      .map(
                        (o) => `
                        <div style="background: rgba(59, 130, 246, 0.1); border: 1px solid rgba(59, 130, 246, 0.3); padding: 10px 15px; border-radius: 6px; font-size: 13px;">
                            <div style="color: #3b82f6; font-weight: 600;">${o.officer_name}</div>
                            <div style="color: #94a3b8; font-size: 12px;">${o.officer_rank}</div>
                        </div>
                    `,
                      )
                      .join("")}
                </div>
            </div>
            `
                : ""
            }
            
            ${
              offenders.length > 0
                ? `
            <div style="margin-bottom: 20px;">
                <h4 style="color: #ef4444; margin-bottom: 10px;">🎯 Tội Phạm (${offenders.length})</h4>
                ${offenders
                  .map(
                    (off) => `
                    <div style="background: rgba(239, 68, 68, 0.1); border: 1px solid rgba(239, 68, 68, 0.3); padding: 15px; border-radius: 8px; margin-bottom: 10px;">
                        <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 8px;">
                            <div>
                                <div style="font-weight: 600; color: #ef4444; font-size: 16px;">${off.offender_name}</div>
                                <div style="font-size: 13px; color: #94a3b8; margin-top: 3px;">PID: ${off.offender_pid}</div>
                            </div>
                            <div style="text-align: right;">
                                <div style="color: #10b981; font-weight: 600;">💰 $${(off.total_fine || 0).toLocaleString()}</div>
                                <div style="color: #f59e0b; font-weight: 600;">⏱️ ${off.total_jail || 0} bãi</div>
                            </div>
                        </div>
                        ${off.charges ? `<div style="font-size: 12px; color: #cbd5e1; margin-top: 8px; padding-top: 8px; border-top: 1px solid rgba(239, 68, 68, 0.2);">📋 Tội: ${off.charges}</div>` : ""}
                    </div>
                `,
                  )
                  .join("")}
            </div>
            `
                : ""
            }
            
            ${
              charges.length > 0
                ? `
            <div style="margin-bottom: 20px;">
                <h4 style="color: #f59e0b; margin-bottom: 10px;">⚖️ Chi Tiết Tội Danh & Hình Phạt (${charges.length} tội)</h4>
                <div style="max-height: 300px; overflow-y: auto; padding-right: 5px;">
                    ${charges
                      .map(
                        (charge, index) => `
                        <div style="background: rgba(245, 158, 11, 0.1); border: 1px solid rgba(245, 158, 11, 0.3); padding: 12px; border-radius: 8px; margin-bottom: 8px;">
                            <div style="display: flex; justify-content: space-between; align-items: center;">
                                <div style="flex: 1;">
                                    <div style="font-weight: 600; color: #f59e0b; margin-bottom: 5px;">${index + 1}. ${charge.charge_name}</div>
                                    <div style="font-size: 12px; color: #94a3b8;">Áp dụng cho: ${charge.offender_name}</div>
                                </div>
                                <div style="display: flex; gap: 15px; font-size: 13px;">
                                    <span style="color: #10b981; font-weight: 600;">💰 $${charge.fine_amount ? charge.fine_amount.toLocaleString() : "0"}</span>
                                    <span style="color: #f59e0b; font-weight: 600;">⏱️ ${charge.jail_time || 0} bãi</span>
                                </div>
                            </div>
                        </div>
                    `,
                      )
                      .join("")}
                </div>
                
                <div style="background: linear-gradient(135deg, rgba(59, 130, 246, 0.2), rgba(16, 185, 129, 0.2)); border: 2px solid #3b82f6; padding: 15px; border-radius: 8px; margin-top: 15px;">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: #3b82f6; font-weight: 700; font-size: 18px;">📊 TỔNG CỘNG:</span>
                        <div style="display: flex; gap: 20px;">
                            <span style="color: #10b981; font-weight: 700; font-size: 18px;">💰 $${totalFine.toLocaleString()}</span>
                            <span style="color: #f59e0b; font-weight: 700; font-size: 18px;">⏱️ ${totalJail} bãi</span>
                        </div>
                    </div>
                </div>
            </div>
            `
                : '<p style="color: #94a3b8; text-align: center; padding: 20px;">Chưa có thông tin tội danh</p>'
            }
            
            ${
              record.description
                ? `
            <div style="margin-bottom: 20px;">
                <h4 style="color: #94a3b8; margin-bottom: 10px;">📝 Chi Tiết Vụ Việc</h4>
                <div style="background: rgba(40,40,50,0.8); border: 1px solid rgba(148, 163, 184, 0.2); padding: 15px; border-radius: 8px; color: #e2e8f0; white-space: pre-wrap; line-height: 1.6;">
                    ${record.description}
                </div>
            </div>
            `
                : '<div style="background: rgba(148, 163, 184, 0.1); padding: 12px; border-radius: 6px; color: #94a3b8; text-align: center; font-size: 13px; margin-bottom: 20px;">📝 Không có ghi chú chi tiết vụ việc</div>'
            }
        `;
    })
    .catch((err) => {
      console.error("[VIEW DETAIL] Error:", err);
      content.innerHTML =
        '<p style="color: #ef4444; text-align: center;">❌ Lỗi khi tải chi tiết vụ án</p>';
    });
}

// Close Record Detail
function closeRecordDetail() {
  console.log("[VIEW DETAIL] Closing modal");
  document
    .getElementById("record-detail-modal")
    .classList.add("hidden");
}

// Search Players
function searchPlayers() {
  const term = document.getElementById(
    "search-input",
  ).value;
  if (!term) {
    showError("Vui lòng nhập từ khóa tìm kiếm");
    return;
  }

  fetch(
    `https://${GetParentResourceName()}/searchPlayers`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ searchTerm: term }),
    },
  )
    .then((r) => r.json())
    .then((results) => {
      const container = document.getElementById(
        "search-results",
      );

      if (results.length === 0) {
        container.innerHTML =
          '<p style="padding: 15px; color: #94a3b8;">Không tìm thấy kết quả</p>';
        container.classList.remove("hidden");
        return;
      }

      container.innerHTML = results
        .map(
          (p) => `
            <div class="search-result-item">
                <div style="font-weight: 600;">${p.name}</div>
                <div style="font-size: 12px; color: #94a3b8;">
                    PID: ${p.pid} | Citizen ID: ${p.citizenid}
                </div>
            </div>
        `,
        )
        .join("");
      container.classList.remove("hidden");
    });
}

// Load Charges
function loadCharges() {
  const list = document.getElementById(
    "charges-list",
  );
  list.innerHTML =
    '<p style="color: #3b82f6; text-align: center;">🔄 Đang tải...</p>';

  fetch(
    `https://${GetParentResourceName()}/getCharges`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  )
    .then((r) => r.json())
    .then((charges) => {
      if (!charges || charges.length === 0) {
        list.innerHTML =
          '<p style="color: #94a3b8;">Chưa có mức án nào</p>';
        return;
      }

      list.innerHTML = charges
        .map(
          (c) => {
            const chargeTypeLabel = c.charge_type === 'vehicle_impound' ? '🚗 Giam xe' : '🚔 Tội phạm';
            const chargeTypeColor = c.charge_type === 'vehicle_impound' ? '#f59e0b' : '#3b82f6';
            
            let detailsHtml = '';
            
            if (c.charge_type === 'vehicle_impound') {
              detailsHtml = `<span>💰 Phạt tiền: $${c.fine_min.toLocaleString()}</span>`;
            } else {
              detailsHtml = `<span>💰 Phạt tiền: $${c.fine_min.toLocaleString()} - $${c.fine_max.toLocaleString()}</span>
                            <span>🔒 Tù: ${c.jail_min} - ${c.jail_max} bãi</span>`;
            }
            
            return `
            <div class="charge-item">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px;">
                    <div class="charge-name">${c.charge_name}</div>
                    <span style="background: ${chargeTypeColor}33; color: ${chargeTypeColor}; padding: 3px 8px; border-radius: 4px; font-size: 11px; font-weight: 600;">${chargeTypeLabel}</span>
                </div>
                <div class="charge-details">
                    ${detailsHtml}
                </div>
                <div style="font-size: 12px; color: #94a3b8; margin-top: 5px;">
                    Tạo bởi: ${c.created_by_name} | ${new Date(c.created_date).toLocaleString("vi-VN")}
                </div>
                <div class="charge-actions">
                    <button class="btn btn-small btn-edit" data-charge='${JSON.stringify(c)}' data-action="edit">✏️ Sửa</button>
                    <button class="btn btn-small btn-danger" data-charge-id="${c.id}" data-action="delete">🗑️ Xóa</button>
                </div>
            </div>
        `;
          }
        )
        .join("");

      // Gắn event listeners cho tất cả các nút
      list
        .querySelectorAll(
          'button[data-action="delete"]',
        )
        .forEach((btn) => {
          btn.addEventListener(
            "click",
            function (e) {
              console.log(
                "[DELETE CLICK] Button clicked!",
              );
              const chargeId = parseInt(
                this.getAttribute(
                  "data-charge-id",
                ),
              );
              console.log(
                "[DELETE CLICK] Charge ID:",
                chargeId,
              );
              deleteChargeNew(chargeId, this);
            },
          );
        });

      list
        .querySelectorAll(
          'button[data-action="edit"]',
        )
        .forEach((btn) => {
          btn.addEventListener(
            "click",
            function (e) {
              const charge = JSON.parse(this.getAttribute('data-charge'));
              editCharge(charge);
            },
          );
        });
    })
    .catch((err) => {
      console.error("[LOAD CHARGES] ERROR:", err);
      list.innerHTML =
        '<p style="color: #ef4444; text-align: center;">❌ Lỗi khi tải mức án</p>';
    });
}

// Charge Form Submit
document
  .getElementById("charge-form")
  .addEventListener("submit", (e) => {
    e.preventDefault();

    const id =
      document.getElementById("charge-id").value;
    const chargeType = document.getElementById("charge-type").value;
    
    let fine_min, fine_max;
    if (chargeType === 'vehicle_impound') {
      const singleFine = parseInt(document.getElementById("fine-amount-single").value);
      fine_min = singleFine;
      fine_max = singleFine;
    } else {
      fine_min = parseInt(document.getElementById("fine-amount-min").value);
      fine_max = parseInt(document.getElementById("fine-amount-max").value);
    }
    
    const data = {
      id: id || null,
      charge_name: document.getElementById(
        "charge-name",
      ).value,
      charge_type: chargeType,
      fine_amount_min: fine_min,
      fine_amount_max: fine_max,
      jail_time_min: chargeType === 'criminal' ? parseInt(
        document.getElementById("jail-time-min")
          .value,
      ) : 0,
      jail_time_max: chargeType === 'criminal' ? parseInt(
        document.getElementById("jail-time-max")
          .value,
      ) : 0,
      impound_duration: 0, // Không sử dụng nữa, để mặc định 0
    };

    const endpoint = id
      ? "updateCharge"
      : "createCharge";

    fetch(
      `https://${GetParentResourceName()}/${endpoint}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      },
    )
      .then((r) => r.json())
      .then((result) => {
        if (result && result.success) {
          showSuccess(
            id
              ? "Cập nhật thành công!"
              : "Tạo mức án thành công!",
          );
          document
            .getElementById("charge-form")
            .reset();
          document.getElementById(
            "charge-id",
          ).value = "";
          document.getElementById(
            "submit-charge-btn",
          ).textContent = "✓ Tạo Mức Án";
          document.getElementById(
            "cancel-edit-btn",
          ).style.display = "none";
          loadCharges();
          loadChargesForSelection();
        } else {
          showError(
            result.message || "Có lỗi xảy ra",
          );
        }
      })
      .catch((err) => {
        console.error(
          "Charge form submit error:",
          err,
        );
        showError("Lỗi khi gửi form");
      });
  });

// Edit Charge
function editCharge(charge) {
  if (!charge) return;

  document.getElementById("charge-id").value = charge.id;
  document.getElementById("charge-name").value = charge.charge_name;
  document.getElementById("charge-type").value = charge.charge_type || 'criminal';
  
  // Populate fine amount fields based on type
  if (charge.charge_type === 'vehicle_impound') {
    document.getElementById("fine-amount-single").value = charge.fine_amount_min || charge.fine_min;
  } else {
    document.getElementById("fine-amount-min").value = charge.fine_amount_min || charge.fine_min;
    document.getElementById("fine-amount-max").value = charge.fine_amount_max || charge.fine_max;
  }
  
  document.getElementById("jail-time-min").value = charge.jail_time_min || charge.jail_min || 0;
  document.getElementById("jail-time-max").value = charge.jail_time_max || charge.jail_max || 0;
  
  // Toggle fields based on type
  toggleChargeFields();
  
  document.getElementById("submit-charge-btn").textContent = "✓ Cập Nhật";
  document.getElementById("cancel-edit-btn").style.display = "inline-block";
}

// Cancel Edit Charge
function cancelEditCharge() {
  document.getElementById("charge-form").reset();
  document.getElementById("charge-id").value = "";
  document.getElementById("charge-type").value = "criminal";
  document.getElementById("submit-charge-btn").textContent = "✓ Tạo Mức Án";
  document.getElementById("cancel-edit-btn").style.display = "none";
  toggleChargeFields();
}

// Toggle charge fields based on type
function toggleChargeFields() {
  const chargeType = document.getElementById("charge-type").value;
  const jailTimeGroup = document.getElementById("jail-time-group");
  const fineMinMaxGroup = document.getElementById("fine-amount-minmax-group");
  const fineSingleGroup = document.getElementById("fine-amount-single-group");
  const jailTimeMin = document.getElementById("jail-time-min");
  const jailTimeMax = document.getElementById("jail-time-max");
  const fineMin = document.getElementById("fine-amount-min");
  const fineMax = document.getElementById("fine-amount-max");
  const fineSingle = document.getElementById("fine-amount-single");
  
  if (chargeType === 'vehicle_impound') {
    // Giam xe: Chỉ 1 input tiền phạt, ẩn jail time
    fineMinMaxGroup.style.display = 'none';
    fineSingleGroup.style.display = 'block';
    jailTimeGroup.style.display = 'none';
    
    // Clear required cho hidden fields
    fineMin.required = false;
    fineMax.required = false;
    jailTimeMin.required = false;
    jailTimeMax.required = false;
    
    // Set required cho visible fields
    fineSingle.required = true;
    
    // Reset giá trị hidden fields
    jailTimeMin.value = 0;
    jailTimeMax.value = 0;
  } else {
    // Tội phạm: Min/max tiền phạt, hiện jail time
    fineMinMaxGroup.style.display = 'block';
    fineSingleGroup.style.display = 'none';
    jailTimeGroup.style.display = 'block';
    
    // Clear required cho hidden fields
    fineSingle.required = false;
    
    // Set required cho visible fields
    fineMin.required = true;
    fineMax.required = true;
    jailTimeMin.required = true;
    jailTimeMax.required = true;
  }
}

// Delete Charge - NEW VERSION with proper button handling
function deleteChargeNew(id, buttonElement) {
  console.log(
    "[DELETE] ========== START DELETE ==========",
  );
  console.log("[DELETE] Charge ID:", id);
  console.log(
    "[DELETE] Button element:",
    buttonElement,
  );

  // XÓA confirm() VÌ NÓ LÀM TREO UI TRONG CEF/NUI
  // if (!confirm('Bạn có chắc muốn xóa mức án này?')) {
  //     console.log('[DELETE] User cancelled');
  //     return;
  // }

  console.log(
    "[DELETE] Proceeding without confirm...",
  );

  // Disable nút xóa tạm thời để tránh spam click
  if (buttonElement) {
    buttonElement.disabled = true;
    buttonElement.textContent = "⏳ Đang xóa...";
    buttonElement.style.opacity = "0.5";
    buttonElement.style.cursor = "not-allowed";
    console.log("[DELETE] Button disabled");
  }

  console.log(
    "[DELETE] Creating timeout promise (10s)...",
  );
  // Tạo timeout promise để tránh treo UI
  const timeoutPromise = new Promise(
    (_, reject) => {
      setTimeout(() => {
        console.log(
          "[DELETE] TIMEOUT! 10 seconds passed",
        );
        reject(
          new Error(
            "Timeout: Quá 10 giây không có phản hồi",
          ),
        );
      }, 10000);
    },
  );

  console.log(
    "[DELETE] Sending fetch request...",
  );
  const fetchPromise = fetch(
    `https://${GetParentResourceName()}/deleteCharge`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ id: id }),
    },
  )
    .then((r) => {
      console.log(
        "[DELETE] Got response, status:",
        r.status,
        "ok:",
        r.ok,
      );
      if (!r.ok)
        throw new Error(
          "Server error: " + r.status,
        );
      return r.json();
    })
    .then((data) => {
      console.log(
        "[DELETE] Parsed JSON response:",
        data,
      );
      return data;
    });

  console.log("[DELETE] Racing promises...");
  // Race giữa fetch và timeout
  Promise.race([fetchPromise, timeoutPromise])
    .then((result) => {
      console.log(
        "[DELETE] Promise resolved with result:",
        result,
      );
      if (result && result.success) {
        console.log(
          "[DELETE] Success! Showing notification...",
        );
        showSuccess("Đã xóa mức án thành công!");
        console.log(
          "[DELETE] Reloading charges list...",
        );
        // Tải lại danh sách ngay lập tức
        loadCharges();
        // Cập nhật cache cho tạo án
        console.log(
          "[DELETE] Reloading charges for selection...",
        );
        loadChargesForSelection();
        console.log(
          "[DELETE] ========== DELETE COMPLETE ==========",
        );
      } else {
        console.log(
          "[DELETE] Failed with message:",
          result.message,
        );
        showError(
          result.message ||
            "Có lỗi xảy ra khi xóa",
        );
        if (buttonElement) {
          buttonElement.disabled = false;
          buttonElement.textContent = "🗑️ Xóa";
          buttonElement.style.opacity = "1";
          buttonElement.style.cursor = "pointer";
          console.log(
            "[DELETE] Button re-enabled",
          );
        }
      }
    })
    .catch((err) => {
      console.error(
        "[DELETE] ERROR caught:",
        err,
      );
      console.error(
        "[DELETE] Error stack:",
        err.stack,
      );
      showError(
        err.message ||
          "Lỗi kết nối khi xóa mức án",
      );
      if (buttonElement) {
        buttonElement.disabled = false;
        buttonElement.textContent = "🗑️ Xóa";
        buttonElement.style.opacity = "1";
        buttonElement.style.cursor = "pointer";
        console.log(
          "[DELETE] Button re-enabled after error",
        );
      }
      console.log(
        "[DELETE] ========== DELETE FAILED ==========",
      );
    });

  console.log(
    "[DELETE] Function returned, waiting for async operations...",
  );
}

// Delete Charge - OLD VERSION (keep for backward compatibility)
function deleteCharge(id) {
  console.warn(
    "[DELETE] WARNING: Using old deleteCharge function",
  );
  console.log(
    "[DELETE] ID:",
    id,
    "event:",
    event,
  );
  const btn = event ? event.target : null;
  console.log(
    "[DELETE] Button from event.target:",
    btn,
  );
  deleteChargeNew(id, btn);
}

// Show Error
// Show Error
function showError(message) {
  fetch(
    `https://${GetParentResourceName()}/notify`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: message,
        type: "error",
      }),
    },
  );
}

// Show Success
function showSuccess(message) {
  fetch(
    `https://${GetParentResourceName()}/notify`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: message,
        type: "success",
      }),
    },
  );
}

// Get Parent Resource Name
function GetParentResourceName() {
  return "mini-mdt";
}

// ============= QUICK FINALIZE (KẾT ÁN NHANH) =============
let quickSelectedCharges = [];
let quickSelectedOffenders = [];

function openQuickFinalizeModal() {
  const modal = document.getElementById(
    "quick-finalize-modal",
  );

  if (!modal) {
    return;
  }

  modal.classList.remove("hidden");
  modal.style.display = "flex";

  // Reset form
  quickSelectedCharges = [];
  quickSelectedOffenders = [];
  document.getElementById(
    "quick-offender-id",
  ).value = "";
  document.getElementById(
    "quick-case-notes",
  ).value = "";
  document.getElementById(
    "quick-offenders-list",
  ).innerHTML = "";
  document.getElementById(
    "quick-selected-charges-list",
  ).innerHTML = "";

  // Load handler info
  fetch(
    `https://${GetParentResourceName()}/getCurrentOfficer`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  )
    .then((r) => r.json())
    .then((officer) => {
      document.getElementById(
        "quick-handler-name",
      ).value =
        `${officer.name} - ${officer.rank}`;
      document.getElementById(
        "quick-handler-id",
      ).value = officer.citizenid;
    })
    .catch((err) => {
      console.error(
        "[QUICK FINALIZE] Error loading handler:",
        err,
      );
    });

  // Load online officers
  loadQuickOnlineOfficers();

  // Load charges
  loadQuickChargesForSelection();
}

function closeQuickFinalize() {
  const modal = document.getElementById(
    "quick-finalize-modal",
  );
  modal.classList.add("hidden");
  modal.style.display = "none"; // Force display none

  // Clear checkboxes
  document
    .querySelectorAll(
      '#quick-officers-list input[type="checkbox"]',
    )
    .forEach((cb) => (cb.checked = false));

  fetch(
    `https://${GetParentResourceName()}/closeQuick`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  );
}

function loadQuickOnlineOfficers() {
  fetch(
    `https://${GetParentResourceName()}/getOnlineOfficers`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  )
    .then((r) => r.json())
    .then((officers) => {
      const list = document.getElementById(
        "quick-officers-list",
      );
      if (officers && officers.length > 0) {
        list.innerHTML = officers
          .map(
            (o) => `
                <div class="officer-checkbox" style="margin-bottom: 8px;">
                    <input type="checkbox" id="quick-officer-${o.citizenid}" value="${o.citizenid}" data-name="${o.name}" data-rank="${o.rank}">
                    <label for="quick-officer-${o.citizenid}" style="cursor: pointer;">👮 ${o.name} - ${o.rank}</label>
                </div>
            `,
          )
          .join("");
      } else {
        list.innerHTML =
          '<p style="color: #64748b; font-size: 13px;">Không có cảnh sát online khác</p>';
      }
    });
}

function searchQuickOffender() {
  const pid = document.getElementById(
    "quick-offender-id",
  ).value;
  if (!pid) {
    showError("Vui lòng nhập PID tội phạm");
    return;
  }

  fetch(
    `https://${GetParentResourceName()}/getPlayerInfo`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        pid: parseInt(pid),
      }),
    },
  )
    .then((r) => r.json())
    .then((response) => {
      if (response.success && response.data) {
        const player = response.data;
        if (
          !quickSelectedOffenders.find(
            (o) =>
              o.citizenid === player.citizenid,
          )
        ) {
          quickSelectedOffenders.push(player);
          displayQuickOffenders();
          document.getElementById(
            "quick-offender-id",
          ).value = "";
        } else {
          showError("Tội phạm này đã được thêm");
        }
      } else {
        showError(
          response.error ||
            "Không tìm thấy người chơi",
        );
      }
    })
    .catch(() => {
      showError("Lỗi khi tìm kiếm người chơi");
    });
}

function displayQuickOffenders() {
  const list = document.getElementById(
    "quick-offenders-list",
  );
  list.innerHTML = quickSelectedOffenders
    .map(
      (o) => `
        <div style="background: rgba(239, 68, 68, 0.1); border-left: 3px solid #ef4444; padding: 10px; border-radius: 6px; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;">
            <div>
                <div style="color: white; font-weight: 600; font-size: 13px;">${o.name}</div>
                <div style="color: #94a3b8; font-size: 11px;">PID: ${o.pid}</div>
            </div>
            <button onclick="removeQuickOffender('${o.citizenid}')" style="background: rgba(239, 68, 68, 0.2); color: #ef4444; border: 1px solid #ef4444; border-radius: 4px; padding: 4px 8px; cursor: pointer; font-size: 11px; font-weight: 600;">✕</button>
        </div>
    `,
    )
    .join("");
}

function removeQuickOffender(citizenid) {
  quickSelectedOffenders =
    quickSelectedOffenders.filter(
      (o) => o.citizenid !== citizenid,
    );
  displayQuickOffenders();
}

function openQuickChargeSelector() {
  document
    .getElementById("quick-charge-selector-modal")
    .classList.remove("hidden");
  document
    .getElementById("quick-modal-overlay")
    .classList.remove("hidden");
}

function closeQuickChargeSelector() {
  document
    .getElementById("quick-charge-selector-modal")
    .classList.add("hidden");
  document
    .getElementById("quick-modal-overlay")
    .classList.add("hidden");
}

function loadQuickChargesForSelection() {
  fetch(
    `https://${GetParentResourceName()}/getCharges`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  )
    .then((r) => r.json())
    .then((charges) => {
      const list = document.getElementById(
        "quick-charge-selector-list",
      );
      if (charges && charges.length > 0) {
        list.innerHTML = charges
          .map(
            (c) => `
                <div onclick="addQuickCharge(${c.id}, '${c.charge_name}', ${c.fine_min}, ${c.fine_max}, ${c.jail_min}, ${c.jail_max})" 
                     style="background: rgba(30,30,40,0.7); padding: 12px; border-radius: 6px; cursor: pointer; border: 1px solid rgba(100,100,120,0.3); transition: all 0.3s;"
                     onmouseover="this.style.background='rgba(59, 130, 246, 0.2)'; this.style.borderColor='#3b82f6'"
                     onmouseout="this.style.background='rgba(30,30,40,0.7)'; this.style.borderColor='rgba(100,100,120,0.3)'">
                    <div style="font-weight: 600; color: white; margin-bottom: 5px;">${c.charge_name}</div>
                    <div style="font-size: 13px; color: #94a3b8;">
                        💰 $${c.fine_min || 0} - $${c.fine_max || 0} | 
                        🔒 ${c.jail_min || 0} - ${c.jail_max || 0} bãi
                    </div>
                </div>
            `,
          )
          .join("");
      } else {
        list.innerHTML =
          '<p style="color: #94a3b8; text-align: center;">Chưa có mức án nào</p>';
      }
    });
}

function addQuickCharge(
  id,
  name,
  fineMin,
  fineMax,
  jailMin,
  jailMax,
) {
  if (
    quickSelectedCharges.find((c) => c.id === id)
  ) {
    showError("Tội danh này đã được chọn");
    return;
  }

  quickSelectedCharges.push({
    id: id,
    charge_name: name,
    fine_min: fineMin,
    fine_max: fineMax,
    jail_min: jailMin,
    jail_max: jailMax,
    selectedFine: null,
    selectedJail: null,
  });

  displayQuickSelectedCharges();
  closeQuickChargeSelector();
}

function displayQuickSelectedCharges() {
  const list = document.getElementById(
    "quick-selected-charges-list",
  );
  if (quickSelectedCharges.length === 0) {
    list.innerHTML =
      '<p style="color: #64748b; font-size: 13px;">Chưa chọn tội danh nào</p>';
    return;
  }

  list.innerHTML = quickSelectedCharges
    .map((c, index) => {
      const fineMin = c.fine_min || 0;
      const fineMax = c.fine_max || 0;
      const jailMin = c.jail_min || 0;
      const jailMax = c.jail_max || 0;

      return `
        <div style="background: rgba(59, 130, 246, 0.1); border-left: 3px solid #3b82f6; padding: 10px; border-radius: 6px; margin-bottom: 8px;">
            <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 8px;">
                <div style="font-weight: 600; color: white; font-size: 13px;">${c.charge_name}</div>
                <button onclick="removeQuickCharge(${index})" style="background: rgba(239, 68, 68, 0.2); color: #ef4444; border: 1px solid #ef4444; border-radius: 4px; padding: 2px 8px; cursor: pointer; font-size: 11px; font-weight: 600;">✕</button>
            </div>
            
            <div style="margin-bottom: 8px;">
                <div style="color: #94a3b8; font-size: 11px; margin-bottom: 4px;">💰 Tiền phạt ($)</div>
                <div style="display: flex; gap: 6px;">
                    <button onclick="selectQuickChargeFine(${index}, 'min')" style="flex: 1; background: ${c.selectedFine === fineMin ? "rgba(34, 197, 94, 0.4)" : "rgba(34, 197, 94, 0.15)"}; color: #22c55e; border: 1px solid ${c.selectedFine === fineMin ? "#22c55e" : "rgba(34, 197, 94, 0.3)"}; border-radius: 4px; padding: 6px; cursor: pointer; font-size: 11px; font-weight: 600; transition: all 0.2s;">
                        $${fineMin}
                    </button>
                    <button onclick="selectQuickChargeFine(${index}, 'max')" style="flex: 1; background: ${c.selectedFine === fineMax ? "rgba(239, 68, 68, 0.4)" : "rgba(239, 68, 68, 0.15)"}; color: #ef4444; border: 1px solid ${c.selectedFine === fineMax ? "#ef4444" : "rgba(239, 68, 68, 0.3)"}; border-radius: 4px; padding: 6px; cursor: pointer; font-size: 11px; font-weight: 600; transition: all 0.2s;">
                        $${fineMax}
                    </button>
                </div>
            </div>
            
            <div>
                <div style="color: #94a3b8; font-size: 11px; margin-bottom: 4px;">🔒 Thời gian (bãi)</div>
                <div style="display: flex; gap: 6px;">
                    <button onclick="selectQuickChargeJail(${index}, 'min')" style="flex: 1; background: ${c.selectedJail === jailMin ? "rgba(34, 197, 94, 0.4)" : "rgba(34, 197, 94, 0.15)"}; color: #22c55e; border: 1px solid ${c.selectedJail === jailMin ? "#22c55e" : "rgba(34, 197, 94, 0.3)"}; border-radius: 4px; padding: 6px; cursor: pointer; font-size: 11px; font-weight: 600; transition: all 0.2s;">
                        ${jailMin}
                    </button>
                    <button onclick="selectQuickChargeJail(${index}, 'max')" style="flex: 1; background: ${c.selectedJail === jailMax ? "rgba(239, 68, 68, 0.4)" : "rgba(239, 68, 68, 0.15)"}; color: #ef4444; border: 1px solid ${c.selectedJail === jailMax ? "#ef4444" : "rgba(239, 68, 68, 0.3)"}; border-radius: 4px; padding: 6px; cursor: pointer; font-size: 11px; font-weight: 600; transition: all 0.2s;">
                        ${jailMax}
                    </button>
                </div>
            </div>
        </div>
        `;
    })
    .join("");
}

function removeQuickCharge(index) {
  quickSelectedCharges.splice(index, 1);
  displayQuickSelectedCharges();
}

function selectQuickChargeFine(index, type) {
  const charge = quickSelectedCharges[index];
  const fineMin = charge.fine_min || 0;
  const fineMax = charge.fine_max || 0;

  charge.selectedFine =
    type === "min" ? fineMin : fineMax;

  displayQuickSelectedCharges();
}

function selectQuickChargeJail(index, type) {
  const charge = quickSelectedCharges[index];
  const jailMin = charge.jail_min || 0;
  const jailMax = charge.jail_max || 0;

  charge.selectedJail =
    type === "min" ? jailMin : jailMax;

  displayQuickSelectedCharges();
}

function submitQuickFinalize() {
  // Validate
  if (quickSelectedOffenders.length === 0) {
    showError(
      "Vui lòng thêm ít nhất một tội phạm",
    );
    return;
  }

  if (quickSelectedCharges.length === 0) {
    showError(
      "Vui lòng chọn ít nhất một tội danh",
    );
    return;
  }

  // Check if all charges have penalties selected
  for (let charge of quickSelectedCharges) {
    if (
      charge.selectedFine === null ||
      charge.selectedJail === null
    ) {
      showError(
        `Vui lòng chọn mức án cho tội "${charge.charge_name}"`,
      );
      return;
    }
  }

  const handlerName = document.getElementById(
    "quick-handler-name",
  ).value;
  const handlerCitizenid =
    document.getElementById(
      "quick-handler-id",
    ).value;
  const notes = document.getElementById(
    "quick-case-notes",
  ).value;

  // Get selected officers from checkboxes BEFORE validation
  const selectedOfficers = [];
  document
    .querySelectorAll(
      '#quick-officers-list input[type="checkbox"]:checked',
    )
    .forEach((cb) => {
      selectedOfficers.push({
        citizenid: cb.value,
        name: cb.dataset.name,
        rank: cb.dataset.rank,
      });
    });

  // VALIDATION: Check if at least one officer is selected
  if (selectedOfficers.length === 0) {
    showError(
      "Vui lòng chọn ít nhất một cảnh sát tham gia vụ án",
    );
    return;
  }

  // Calculate totals
  let totalFine = 0;
  let totalJailTime = 0;

  const formattedCharges =
    quickSelectedCharges.map((c) => {
      totalFine += parseInt(c.selectedFine) || 0;
      totalJailTime +=
        parseInt(c.selectedJail) || 0;

      return {
        id: c.id,
        name: c.charge_name,
        selectedFine:
          parseInt(c.selectedFine) || 0,
        selectedJail:
          parseInt(c.selectedJail) || 0,
      };
    });

  // Prepare finalize data (same structure as finalizeCase)
  const finalizeData = {
    handler: {
      citizenid: handlerCitizenid,
      name: handlerName.split(" - ")[0], // Remove rank from display
      rank:
        handlerName.split(" - ")[1] || "Officer",
    },
    offenders: quickSelectedOffenders.map(
      (o) => ({
        citizenid: o.citizenid,
        name: o.name,
        pid: o.pid,
      }),
    ),
    charges: formattedCharges,
    officers: selectedOfficers,
    totalFine: totalFine,
    totalJailTime: totalJailTime,
    notes: notes || "Kết án nhanh - Mini MDT",
  };

  // Submit via quickFinalize (NOT finalizeCase to avoid double execution)
  fetch(
    `https://${GetParentResourceName()}/quickFinalize`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(finalizeData),
    },
  )
    .then((r) => r.json())
    .then((result) => {
      if (result.success) {
        showSuccess(
          "✅ Kết án thành công! Tội phạm đã được xử lý.",
        );
        closeQuickFinalize();
      } else {
        showError(
          result.message || "Lỗi khi kết án",
        );
      }
    })
    .catch((err) => {
      console.error(
        "[QUICK FINALIZE] Error:",
        err,
      );
      showError("Lỗi khi kết án");
    });
}
// Filter charges in main UI
function filterCharges() {
  const searchTerm = document
    .getElementById("charge-search")
    .value.toLowerCase();
  const chargeItems = document.querySelectorAll(
    "#charge-selector-list > div",
  );

  chargeItems.forEach((item) => {
    const chargeName =
      item.textContent.toLowerCase();
    if (chargeName.includes(searchTerm)) {
      item.style.display = "";
    } else {
      item.style.display = "none";
    }
  });
}

// Filter charges in quick finalize
function filterQuickCharges() {
  const searchTerm = document
    .getElementById("quick-charge-search")
    .value.toLowerCase();
  const chargeItems = document.querySelectorAll(
    "#quick-charge-selector-list > div",
  );

  chargeItems.forEach((item) => {
    const chargeName =
      item.textContent.toLowerCase();
    if (chargeName.includes(searchTerm)) {
      item.style.display = "";
    } else {
      item.style.display = "none";
    }
  });
}

// Update Badge Photo
async function updateBadgePhoto() {
  const pid = document.getElementById(
    "badge-update-pid",
  ).value;
  const photoUrl = document.getElementById(
    "badge-photo-url",
  ).value;

  if (!pid || !photoUrl) {
    showError(
      "⚠️ Vui lòng nhập đầy đủ PID và link ảnh",
    );
    return;
  }

  // Validate URL
  try {
    new URL(photoUrl);
  } catch (e) {
    showError(
      "⚠️ Link ảnh không hợp lệ. Vui lòng nhập URL đúng định dạng",
    );
    return;
  }

  try {
    const response = await fetch(
      `https://${GetParentResourceName()}/updateBadgePhoto`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          pid: parseInt(pid),
          photoUrl: photoUrl,
        }),
      },
    );

    const result = await response.json();

    if (result.success) {
      showSuccess(
        "✅ Đã cập nhật ảnh thẻ thành công!",
      );
      // Clear inputs
      document.getElementById(
        "badge-update-pid",
      ).value = "";
      document.getElementById(
        "badge-photo-url",
      ).value = "";
    } else {
      showError(
        result.message ||
          "❌ Không thể cập nhật ảnh thẻ",
      );
    }
  } catch (error) {
    console.error("[BADGE PHOTO] Error:", error);
    showError("❌ Lỗi khi cập nhật ảnh thẻ");
  }
}

// ==================== Citizens Management ====================
async function issueCitizenID() {
  const pid = document.getElementById(
    "citizen-pid",
  ).value;

  if (!pid) {
    showError(
      "⚠️ Vui lòng nhập PID người cần cấp CCCD",
    );
    return;
  }

  const resultDiv = document.getElementById(
    "issue-result",
  );
  resultDiv.innerHTML =
    '<p style="color: #94a3b8; text-align: center;">⏳ Đang xử lý...</p>';

  try {
    const response = await fetch(
      `https://${GetParentResourceName()}/issueCitizenID`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          targetPid: parseInt(pid),
        }),
      },
    );

    const result = await response.json();

    if (result.success) {
      resultDiv.innerHTML = `
                <div style="background: rgba(16, 185, 129, 0.1); border-left: 4px solid #10b981; padding: 12px; border-radius: 6px;">
                    <p style="margin: 0; color: #10b981; font-weight: 600;">✅ ${result.message}</p>
                </div>
            `;
      document.getElementById(
        "citizen-pid",
      ).value = "";
    } else {
      resultDiv.innerHTML = `
                <div style="background: rgba(239, 68, 68, 0.1); border-left: 4px solid #ef4444; padding: 12px; border-radius: 6px;">
                    <p style="margin: 0; color: #ef4444; font-weight: 600;">❌ ${result.message}</p>
                </div>
            `;
    }
  } catch (error) {
    console.error("[ISSUE ID] Error:", error);
    resultDiv.innerHTML = `
            <div style="background: rgba(239, 68, 68, 0.1); border-left: 4px solid #ef4444; padding: 12px; border-radius: 6px;">
                <p style="margin: 0; color: #ef4444; font-weight: 600;">❌ Lỗi khi cấp CCCD</p>
            </div>
        `;
  }
}

// ==================== VEHICLE IMPOUND MANAGEMENT ====================

function renderImpoundList(items) {
  const container = document.getElementById("impound-list-container");
  if (!items || items.length === 0) {
    container.innerHTML = `<p style="color: #94a3b8; text-align: center; padding: 20px;">Không có dữ liệu xe tạm giam.</p>`;
    return;
  }

  const statusLabel = (s) => {
    // Convert sang number để xử lý safe
    const status = Number(s);
    if (status === 1) return `<span style="color:#10b981;font-weight:600;">✅ Đã chuộc xe</span>`;
    if (status === 2) return `<span style="color:#f59e0b;font-weight:600;">🔒 Đang giam</span>`;
    if (status === 3) return `<span style="color:#ef4444;font-weight:600;">🔑 Cần mở khóa</span>`;
    return `<span style="color:#94a3b8;">${s}</span>`;
  };

  const rows = items.map((r) => {
    // Format impound_date an toàn
    let impoundDateStr = "-";
    if (r.impound_date) {
      try {
        // Nếu là number (timestamp), nhân 1000 nếu cần
        let dateObj;
        if (typeof r.impound_date === 'number') {
          // Nếu timestamp < 10 tỷ thì đang ở giây, cần nhân 1000
          dateObj = new Date(r.impound_date < 10000000000 ? r.impound_date * 1000 : r.impound_date);
        } else if (typeof r.impound_date === 'string') {
          dateObj = new Date(r.impound_date);
        } else {
          dateObj = r.impound_date;
        }
        
        impoundDateStr = dateObj.toLocaleString("vi-VN", {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit'
        });
      } catch (e) {
        impoundDateStr = String(r.impound_date).substring(0, 16);
      }
    }
    
    return `
    <tr style="border-bottom: 1px solid rgba(255,255,255,0.05);">
      <td style="padding: 8px 10px; color: #f1f5f9; font-weight: 600;">${r.vehicle_plate || "-"}</td>
      <td style="padding: 8px 10px; color: #e2e8f0;">${r.vehicle_model || "-"}</td>
      <td style="padding: 8px 10px; color: #93c5fd;">${r.owner_name || "-"}<br><span style="font-size:11px;color:#64748b;">PID: ${r.owner_pid || "-"}</span></td>
      <td style="padding: 8px 10px; color: #c4b5fd;">${r.officer_name || "-"}<br><span style="font-size:11px;color:#64748b;">PID: ${r.officer_pid || "-"}</span></td>
      <td style="padding: 8px 10px; color: #fbbf24; max-width: 180px; word-break: break-word;">${r.offence || "-"}</td>
      <td style="padding: 8px 10px; color: #94a3b8; font-size: 12px;">${impoundDateStr}</td>
      <td style="padding: 8px 10px;">${statusLabel(r.status)}</td>
    </tr>
  `;
  }).join("");

  container.innerHTML = `
    <div style="overflow-x: auto;">
      <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
        <thead>
          <tr style="border-bottom: 1px solid rgba(255,255,255,0.15);">
            <th style="padding: 8px 10px; text-align: left; color: #64748b; font-weight: 600;">Biển số</th>
            <th style="padding: 8px 10px; text-align: left; color: #64748b; font-weight: 600;">Xe</th>
            <th style="padding: 8px 10px; text-align: left; color: #64748b; font-weight: 600;">Chủ xe</th>
            <th style="padding: 8px 10px; text-align: left; color: #64748b; font-weight: 600;">Cảnh sát</th>
            <th style="padding: 8px 10px; text-align: left; color: #64748b; font-weight: 600;">Vi phạm</th>
            <th style="padding: 8px 10px; text-align: left; color: #64748b; font-weight: 600;">Ngày giam</th>
            <th style="padding: 8px 10px; text-align: left; color: #64748b; font-weight: 600;">Trạng thái</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    </div>
  `;
}

async function loadActiveImpounds() {
  const container = document.getElementById("impound-list-container");
  container.innerHTML = `<p style="color: #94a3b8; text-align: center; padding: 20px;">Đang tải...</p>`;
  try {
    const resp = await fetch(`https://${GetParentResourceName()}/getActiveImpounds`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    });
    const result = await resp.json();
    renderImpoundList(result);
  } catch (e) {
    console.error("[IMPOUND] loadActiveImpounds error:", e);
    container.innerHTML = `<p style="color: #ef4444; text-align: center; padding: 20px;">❌ Lỗi khi tải dữ liệu.</p>`;
  }
}

async function searchImpoundByOwnerPID() {
  const pid = document.getElementById("impound-search-owner-pid").value.trim();
  if (!pid) return;
  const container = document.getElementById("impound-list-container");
  container.innerHTML = `<p style="color: #94a3b8; text-align: center; padding: 20px;">Đang tìm kiếm...</p>`;
  try {
    const resp = await fetch(`https://${GetParentResourceName()}/searchImpoundByOwnerPID`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ pid }),
    });
    const result = await resp.json();
    renderImpoundList(result);
  } catch (e) {
    console.error("[IMPOUND] searchImpoundByOwnerPID error:", e);
    container.innerHTML = `<p style="color: #ef4444; text-align: center; padding: 20px;">❌ Lỗi khi tìm kiếm.</p>`;
  }
}

async function searchImpoundByOfficerPID() {
  const pid = document.getElementById("impound-search-officer-pid").value.trim();
  if (!pid) return;
  const container = document.getElementById("impound-list-container");
  container.innerHTML = `<p style="color: #94a3b8; text-align: center; padding: 20px;">Đang tìm kiếm...</p>`;
  try {
    const resp = await fetch(`https://${GetParentResourceName()}/searchImpoundByOfficerPID`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ pid }),
    });
    const result = await resp.json();
    renderImpoundList(result);
  } catch (e) {
    console.error("[IMPOUND] searchImpoundByOfficerPID error:", e);
    container.innerHTML = `<p style="color: #ef4444; text-align: center; padding: 20px;">❌ Lỗi khi tìm kiếm.</p>`;
  }
}
