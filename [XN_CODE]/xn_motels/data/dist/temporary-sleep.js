(function () {
  var currentData = null;
  var isSubmitting = false;

  function money(value) {
    return "$" + Number(value || 0).toLocaleString();
  }

  function hasActiveRoom(data) {
    return !!(data && (data.myRoom || (Array.isArray(data.myRooms) && data.myRooms.length > 0)));
  }

  function shouldShow(data) {
    return !!(data && data.ownerData && data.ownerData.canTemporarySleep && !hasActiveRoom(data));
  }

  function removeTemporarySleepEntry() {
    var existing = document.getElementById("temporary-sleep-entry");
    if (existing) existing.remove();
  }

  function renderTemporarySleepEntry() {
    if (!shouldShow(currentData)) {
      removeTemporarySleepEntry();
      return;
    }

    var main = document.querySelector("#root main");
    if (!main) return;

    var existing = document.getElementById("temporary-sleep-entry");
    if (existing && existing.dataset.motel === currentData.motelId) return;
    removeTemporarySleepEntry();

    var price = currentData.ownerData.temporarySleepPrice || 2000;
    var share = currentData.ownerData.temporarySleepHotelShare || 1200;

    var wrapper = document.createElement("div");
    wrapper.id = "temporary-sleep-entry";
    wrapper.dataset.motel = currentData.motelId || "";
    wrapper.style.cssText = [
      "margin:18px 28px 0",
      "padding:16px 18px",
      "border:1px solid rgba(0,240,255,.28)",
      "border-left:4px solid var(--accent-cyan,#00f0ff)",
      "border-radius:4px",
      "background:linear-gradient(135deg,rgba(14,17,23,.96),rgba(8,9,13,.96))",
      "display:flex",
      "align-items:center",
      "justify-content:space-between",
      "gap:14px",
      "box-shadow:0 6px 20px rgba(0,0,0,.55)"
    ].join(";");

    var info = document.createElement("div");
    info.style.cssText = "display:flex;flex-direction:column;gap:5px;min-width:0;";
    info.innerHTML =
      '<strong style="color:#fff;font-family:Montserrat,sans-serif;font-size:15px;text-transform:uppercase;letter-spacing:.5px;">' +
      '<i class="fa-solid fa-bed" style="color:var(--accent-cyan,#00f0ff);margin-right:7px;"></i>Thuê chỗ ngủ tạm thời</strong>' +
      '<span style="color:var(--text-secondary,#cbd5e1);font-size:12.5px;line-height:1.35;">' +
      "Không có chủ/nhân viên online. Giá " + money(price) + " / 1 lần, khách sạn nhận " + money(share) + "." +
      "</span>";

    var button = document.createElement("button");
    button.type = "button";
    button.style.cssText = [
      "pointer-events:auto",
      "border:1px solid rgba(0,240,255,.45)",
      "border-radius:4px",
      "background:linear-gradient(135deg,#00f0ff,#0072ff)",
      "color:#020617",
      "font-family:Montserrat,sans-serif",
      "font-weight:800",
      "font-size:12px",
      "text-transform:uppercase",
      "padding:10px 14px",
      "min-width:142px",
      "cursor:pointer"
    ].join(";");
    button.innerHTML = '<i class="fa-solid fa-moon" style="margin-right:6px;"></i>Thuê ' + money(price);
    button.onclick = function () {
      if (isSubmitting || !currentData) return;
      isSubmitting = true;
      button.disabled = true;
      button.style.opacity = ".65";
      button.textContent = "Đang thuê...";

      fetch("https://" + (currentData.resourceName || "xn_motels") + "/rentTemporarySleep", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          motel: currentData.motelId,
          paymentMethod: "money"
        })
      })
        .then(function (response) { return response.json(); })
        .finally(function () {
          isSubmitting = false;
          button.disabled = false;
          button.style.opacity = "";
          button.innerHTML = '<i class="fa-solid fa-moon" style="margin-right:6px;"></i>Thuê ' + money(price);
        });
    };

    wrapper.appendChild(info);
    wrapper.appendChild(button);
    main.insertBefore(wrapper, main.firstChild);
  }

  window.addEventListener("message", function (event) {
    if (!event.data) return;
    if (event.data.type === "closeUI") {
      currentData = null;
      removeTemporarySleepEntry();
      return;
    }
    if (event.data.type !== "openUI") return;
    currentData = event.data;
    setTimeout(renderTemporarySleepEntry, 0);
    setTimeout(renderTemporarySleepEntry, 100);
    setTimeout(renderTemporarySleepEntry, 300);
  });

  new MutationObserver(function () {
    if (currentData) renderTemporarySleepEntry();
  }).observe(document.documentElement, { childList: true, subtree: true });
})();
