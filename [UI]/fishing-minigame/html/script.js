// =============================================
// 🎨 RANDOM THEME - Đổi màu mỗi lần chơi
// =============================================
const COLOR_THEMES = [
  { // 1. Ocean Blue — bar xanh nhạt, cá xanh đậm
    bgTop: '#a3d5ff', bgBottom: '#004080', outline: '#002244',
    barBg: 'rgba(100, 180, 255, 0.45)', barBorder: '#60b0ff',
    barActiveBg: 'rgba(100, 200, 255, 0.9)', barActiveGlow: '#60d0ff',
    fishBody: '#1a7fff', fishFin: '#005fcc', fishScale: '#003fa8'
  },
  { // 2. Deep Purple — bar tím nhạt, cá tím đậm
    bgTop: '#c9b1ff', bgBottom: '#1a0050', outline: '#0d0033',
    barBg: 'rgba(160, 100, 255, 0.45)', barBorder: '#9966ff',
    barActiveBg: 'rgba(170, 120, 255, 0.9)', barActiveGlow: '#bb88ff',
    fishBody: '#7722ff', fishFin: '#5500dd', fishScale: '#3300aa'
  },
  { // 3. Emerald Green — bar xanh lá nhạt, cá xanh lá đậm
    bgTop: '#a8f0c0', bgBottom: '#004d25', outline: '#002914',
    barBg: 'rgba(80, 200, 120, 0.45)', barBorder: '#40cc80',
    barActiveBg: 'rgba(80, 220, 130, 0.9)', barActiveGlow: '#60ee99',
    fishBody: '#00aa55', fishFin: '#008844', fishScale: '#006633'
  },
  { // 4. Sunset Orange — bar cam nhạt, cá cam đậm
    bgTop: '#ffd580', bgBottom: '#7a1f00', outline: '#4a0f00',
    barBg: 'rgba(255, 160, 60, 0.45)', barBorder: '#ff9933',
    barActiveBg: 'rgba(255, 180, 80, 0.9)', barActiveGlow: '#ffbb44',
    fishBody: '#e06600', fishFin: '#bb4400', fishScale: '#993300'
  },
  { // 5. Neon Cyan — bar cyan sáng, cá cyan đậm
    bgTop: '#00f5ff', bgBottom: '#003340', outline: '#001a20',
    barBg: 'rgba(0, 210, 230, 0.4)', barBorder: '#00e5ff',
    barActiveBg: 'rgba(0, 230, 250, 0.9)', barActiveGlow: '#00ffff',
    fishBody: '#009db5', fishFin: '#007a90', fishScale: '#005a6e'
  },
  { // 6. Rose Gold — bar hồng nhạt, cá hồng đậm
    bgTop: '#ffc8d8', bgBottom: '#5c0020', outline: '#3a0015',
    barBg: 'rgba(255, 100, 130, 0.45)', barBorder: '#ff7096',
    barActiveBg: 'rgba(255, 120, 150, 0.9)', barActiveGlow: '#ff88aa',
    fishBody: '#e0305a', fishFin: '#bb1540', fishScale: '#900030'
  },
  { // 7. Midnight Teal — bar teal sáng, cá teal đậm
    bgTop: '#66ffdd', bgBottom: '#00302a', outline: '#001a16',
    barBg: 'rgba(0, 180, 150, 0.45)', barBorder: '#00ccaa',
    barActiveBg: 'rgba(0, 200, 170, 0.9)', barActiveGlow: '#00ffdd',
    fishBody: '#00917a', fishFin: '#006e5c', fishScale: '#004d40'
  },
  { // 8. Lava Red — bar đỏ nhạt, cá đỏ đậm
    bgTop: '#ff8080', bgBottom: '#330000', outline: '#1a0000',
    barBg: 'rgba(220, 50, 50, 0.45)', barBorder: '#ff4444',
    barActiveBg: 'rgba(240, 60, 60, 0.9)', barActiveGlow: '#ff5555',
    fishBody: '#cc0000', fishFin: '#990000', fishScale: '#660000'
  },
  { // 9. Arctic Ice — bar trắng xanh, cá xanh băng đậm
    bgTop: '#e0f4ff', bgBottom: '#006699', outline: '#004466',
    barBg: 'rgba(180, 230, 255, 0.45)', barBorder: '#88ccee',
    barActiveBg: 'rgba(200, 240, 255, 0.9)', barActiveGlow: '#aaddff',
    fishBody: '#0077aa', fishFin: '#005588', fishScale: '#003366'
  },
  { // 10. Sakura Pink — bar hồng đào, cá hồng sâu
    bgTop: '#ffb3cc', bgBottom: '#661133', outline: '#440022',
    barBg: 'rgba(255, 140, 170, 0.45)', barBorder: '#ff80a0',
    barActiveBg: 'rgba(255, 160, 185, 0.9)', barActiveGlow: '#ff99bb',
    fishBody: '#cc2255', fishFin: '#aa0033', fishScale: '#880022'
  },
  { // 11. Golden Hour — bar vàng nhạt, cá vàng đậm
    bgTop: '#fff0a0', bgBottom: '#664400', outline: '#442200',
    barBg: 'rgba(255, 210, 60, 0.45)', barBorder: '#ffcc00',
    barActiveBg: 'rgba(255, 220, 80, 0.9)', barActiveGlow: '#ffdd33',
    fishBody: '#cc8800', fishFin: '#aa6600', fishScale: '#884400'
  },
  { // 12. Forest Moss — bar xanh rêu nhạt, cá xanh rêu đậm
    bgTop: '#c8e6a0', bgBottom: '#1a3300', outline: '#0d1a00',
    barBg: 'rgba(130, 190, 80, 0.45)', barBorder: '#88cc44',
    barActiveBg: 'rgba(150, 210, 90, 0.9)', barActiveGlow: '#aaee55',
    fishBody: '#4a8800', fishFin: '#336600', fishScale: '#224400'
  },
  { // 13. Indigo Night — bar chàm tím xanh, cá chàm đậm
    bgTop: '#9999ff', bgBottom: '#000033', outline: '#000022',
    barBg: 'rgba(80, 80, 220, 0.45)', barBorder: '#6666dd',
    barActiveBg: 'rgba(100, 100, 240, 0.9)', barActiveGlow: '#8888ff',
    fishBody: '#3333cc', fishFin: '#2222aa', fishScale: '#111188'
  },
  { // 14. Coral Reef — bar san hô nhạt, cá san hô đậm
    bgTop: '#ffccaa', bgBottom: '#7a2200', outline: '#4a1500',
    barBg: 'rgba(255, 140, 80, 0.45)', barBorder: '#ff9955',
    barActiveBg: 'rgba(255, 160, 100, 0.9)', barActiveGlow: '#ffaa66',
    fishBody: '#cc4400', fishFin: '#aa3300', fishScale: '#882200'
  },
  { // 15. Mint Breeze — bar xanh bạc hà, cá xanh bạc hà đậm
    bgTop: '#b3fff0', bgBottom: '#004d3d', outline: '#003328',
    barBg: 'rgba(60, 230, 190, 0.4)', barBorder: '#33ddbb',
    barActiveBg: 'rgba(80, 240, 200, 0.9)', barActiveGlow: '#55ffcc',
    fishBody: '#009977', fishFin: '#007755', fishScale: '#005533'
  },
  { // 16. Grape Dusk — bar tím nho, cá tím nho đậm
    bgTop: '#dda0dd', bgBottom: '#2d0050', outline: '#1a0033',
    barBg: 'rgba(180, 80, 180, 0.45)', barBorder: '#cc66cc',
    barActiveBg: 'rgba(200, 100, 200, 0.9)', barActiveGlow: '#dd88dd',
    fishBody: '#880088', fishFin: '#660066', fishScale: '#440044'
  },
  { // 17. Steel Blue — bar xám xanh thép, cá xám xanh đậm
    bgTop: '#b0c8e0', bgBottom: '#1a2d40', outline: '#0d1a26',
    barBg: 'rgba(90, 140, 190, 0.45)', barBorder: '#6699bb',
    barActiveBg: 'rgba(110, 160, 210, 0.9)', barActiveGlow: '#88bbdd',
    fishBody: '#336688', fishFin: '#224466', fishScale: '#112233'
  },
  { // 18. Amber Glow — bar hổ phách nhạt, cá hổ phách đậm
    bgTop: '#ffe0a0', bgBottom: '#5c3000', outline: '#3a1e00',
    barBg: 'rgba(255, 180, 60, 0.45)', barBorder: '#ffaa22',
    barActiveBg: 'rgba(255, 195, 80, 0.9)', barActiveGlow: '#ffcc44',
    fishBody: '#cc7700', fishFin: '#aa5500', fishScale: '#883300'
  },
  { // 19. Neon Lime — bar xanh lá neon, cá xanh lá đậm bão hòa
    bgTop: '#ccff66', bgBottom: '#1a3300', outline: '#0d1a00',
    barBg: 'rgba(150, 240, 50, 0.4)', barBorder: '#99ee22',
    barActiveBg: 'rgba(170, 255, 70, 0.9)', barActiveGlow: '#bbff44',
    fishBody: '#448800', fishFin: '#336600', fishScale: '#224400'
  },
  { // 20. Crimson Dusk — bar đỏ tươi nhạt, cá đỏ thẫm
    bgTop: '#ffaaaa', bgBottom: '#4d0000', outline: '#330000',
    barBg: 'rgba(220, 80, 80, 0.45)', barBorder: '#ee5555',
    barActiveBg: 'rgba(240, 100, 100, 0.9)', barActiveGlow: '#ff7777',
    fishBody: '#aa0022', fishFin: '#880011', fishScale: '#660000'
  }
];

function applyRandomTheme() {
  const t = COLOR_THEMES[Math.floor(Math.random() * COLOR_THEMES.length)];
  const root = document.documentElement;
  root.style.setProperty('--theme-bg-top',      t.bgTop);
  root.style.setProperty('--theme-bg-bottom',   t.bgBottom);
  root.style.setProperty('--theme-outline',     t.outline);
  root.style.setProperty('--bar-bg',            t.barBg);
  root.style.setProperty('--bar-border',        t.barBorder);
  root.style.setProperty('--bar-active-bg',     t.barActiveBg);
  root.style.setProperty('--bar-active-border', t.barActiveGlow);
  root.style.setProperty('--bar-glow',          t.barActiveGlow);
  root.style.setProperty('--fish-body',         t.fishBody);
  root.style.setProperty('--fish-fin',          t.fishFin);
  root.style.setProperty('--fish-scale',        t.fishScale);
}

class FishingMinigame {

  constructor(settings = {}) {
    const defaults = {
      gravity: -0.1,
      lift: 0.1,
      maxBarSpeed: 2,
      fishMaxSpeed: 2,
      fishAccel: 0.08,
      fishDartChance: 0.02,  // Xác suất cú phóng đột ngột mỗi frame
      fishSineAmpMax: 1.0, // Biên độ tối đa của dao động triều
      fillRate: 0.12,      // Đồng bộ với config.global.fillRate
      drainRate: 0.08,     // Đồng bộ với config.global.drainRate
      bounceDamping: 0.85,
      stopThreshold: 0.05,
      startCatchPercent: 20,
      barHeightPercent: 25  // Đồng bộ với config.global.barHeightPercent
    };
    this.settings = { ...defaults, ...settings };

    this.greenBar = document.getElementById("green-bar");
    this.box = document.getElementById("fish-box");
    this.fishCircle = document.getElementById("fish-circle");
    this.catchFill = document.getElementById("catch-fill");

    this.greenBar.style.height = `${this.settings.barHeightPercent}%`;

    this.isMouseDown = false;
    this.barPosition = 0;
    this.barVelocity = 0;
    this.fishPos = 0;
    this.fishVel = 0;
    this.fishSineTime = 0;       // Biến thời gian cho dao động sine
    this.fishSineFreq = 0;       // Tần số dao động (thay đổi sau mỗi dart)
    this.fishSineAmp = 0;        // Biên độ dao động sine
    this.fishDartCooldown = 0;   // Cooldown tránh dart liên tiếp
    this.catchProgress = this.settings.startCatchPercent;
    this.gameActive = false;
    this.resolveResult = null;

    document.addEventListener("mousedown", () => this.isMouseDown = true);
    document.addEventListener("mouseup", () => this.isMouseDown = false);
    document.addEventListener("keydown", e => { if (e.key === "Escape") this.endGame(false); });
  }

  startGame() {
    this.barPosition = 0;
    this.barVelocity = 0;
    this.greenBar.style.bottom = "0px";

    this.fishPos = (this.box.offsetHeight - this.fishCircle.offsetHeight) / 2;
    this.fishVel = 0;
    this.fishSineTime = Math.random() * Math.PI * 2;  // Phase ngẫu nhiên ban đầu
    this.fishSineFreq = 0.02 + Math.random() * 0.03;  // 0.02–0.05 rad/frame
    this.fishSineAmp  = Math.min(0.3 + Math.random() * 0.4, this.settings.fishSineAmpMax);  // 0.3–0.7 px/frame (giới hạn bởi fishSineAmpMax)
    this.fishDartCooldown = 0;
    this.fishCircle.style.top = `${this.fishPos}px`;

    this.catchProgress = this.settings.startCatchPercent;
    this.catchFill.style.height = `${this.catchProgress}%`;

    this.isMouseDown = false;
    this.gameActive = true;
    this.loop();
  }

  endGame(success) {
    if (this.gameActive) {
      // Gửi kết quả về Lua client trước khi đóng UI
      fetch(`https://${GetParentResourceName()}/fishingResult`, { 
        method: "POST", 
        body: JSON.stringify({ success: success }) 
      });
    }
    
    if (this.resolveResult) {
      this.resolveResult(success);
      this.resolveResult = null;
    }
    this.gameActive = false;
    document.body.classList.remove("active");
    fetch(`https://${GetParentResourceName()}/closeNui`, { method: "POST" });
  }

  showUi() {
    applyRandomTheme();
    document.body.classList.add("active");
    this.startGame();
  }

  updateGreenBar() {
    const boxHeight = this.box.offsetHeight;
    const barHeight = (this.settings.barHeightPercent / 100) * boxHeight;
    const maxY = boxHeight - barHeight;

    this.barVelocity += this.isMouseDown ? this.settings.lift : this.settings.gravity;
    this.barVelocity = Math.max(Math.min(this.barVelocity, this.settings.maxBarSpeed), -this.settings.maxBarSpeed);

    this.barPosition += this.barVelocity;

    if (this.barPosition < 0) {
      this.barPosition = 0;
      this.barVelocity *= -this.settings.bounceDamping;
      if (Math.abs(this.barVelocity) < this.settings.stopThreshold) this.barVelocity = 0;
    } else if (this.barPosition > maxY) {
      this.barPosition = maxY;
      this.barVelocity = 0;
    }

    this.greenBar.style.bottom = `${this.barPosition}px`;
  }

  updateFish() {
    const boxHeight = this.box.offsetHeight;
    const fishSize = this.fishCircle.offsetHeight;
    const maxPos = boxHeight - fishSize;
    const minPos = 0;

    // --- Cú DART đột ngột (fishDartChance) ---
    if (this.fishDartCooldown > 0) {
      this.fishDartCooldown--;
    } else if (Math.random() < this.settings.fishDartChance) {
      // Phóng mạnh về phía ngược chiều hiện tại, hoặc hướng hoàn toàn ngẫu nhiên
      const dartDir = Math.random() < 0.5 ? 1 : -1;
      const dartPower = this.settings.fishMaxSpeed * (0.7 + Math.random() * 0.6);
      this.fishVel = dartDir * dartPower;

      // Cập nhật sine sau dart — tần số & biên độ mới → phá vỡ nhịp cũ
      this.fishSineFreq = 0.02 + Math.random() * 0.05;
      this.fishSineAmp  = Math.min(0.4 + Math.random() * 0.6, this.settings.fishSineAmpMax);
      this.fishSineTime = Math.random() * Math.PI * 2;

      // Cooldown tránh dart dồn dập (~30-60 frame)
      this.fishDartCooldown = 30 + Math.floor(Math.random() * 30);
    }

    // --- Dao động Sine (tạo nhịp đảo triều) ---
    this.fishSineTime += this.fishSineFreq;
    const sineNudge = Math.sin(this.fishSineTime) * this.fishSineAmp;

    // --- Nhiễu ngẫu nhiên nhỏ (Brownian) ---
    const brownian = (Math.random() - 0.5) * this.settings.fishAccel;

    this.fishVel += sineNudge + brownian;

    // Clamp tốc độ
    this.fishVel = Math.max(
      Math.min(this.fishVel, this.settings.fishMaxSpeed),
      -this.settings.fishMaxSpeed
    );

    // Giảm dần một chút để không trôi mãi một hướng
    this.fishVel *= 0.96;

    this.fishPos += this.fishVel;
    if (this.fishPos < minPos || this.fishPos > maxPos) {
      this.fishPos = Math.max(Math.min(this.fishPos, maxPos), minPos);
      this.fishVel *= -0.6;  // Nảy mạnh hơn khi chạm tường
    }

    this.fishCircle.style.top = `${this.fishPos}px`;
  }

  updateCatchMeter() {
    const barRect = this.greenBar.getBoundingClientRect();
    const fishRect = this.fishCircle.getBoundingClientRect();
    const isOverlapping = !(barRect.bottom < fishRect.top || barRect.top > fishRect.bottom);

    this.catchProgress += isOverlapping ? this.settings.fillRate : -this.settings.drainRate;
    this.catchProgress = Math.max(0, Math.min(100, this.catchProgress));
    this.catchFill.style.height = `${this.catchProgress}%`;
    this.greenBar.classList.toggle("greener", isOverlapping);

    if (this.catchProgress >= 100 && this.gameActive) this.handleSuccess();
    if (this.catchProgress <= 0 && this.gameActive) this.handleFail();
  }

  loop() {
    if (!this.gameActive) return;
    this.updateGreenBar();
    this.updateFish();
    this.updateCatchMeter();
    requestAnimationFrame(() => this.loop());
  }

  handleSuccess() {
    this.endGame(true);
  }

  handleFail() {
    this.endGame(false);
  }

  startFromExport() {
    return new Promise(resolve => {
      this.resolveResult = resolve;
      this.showUi();
    });
  }
}

let fishingInstance = null;
window.startFishingMinigame = difficulty => {
  const settings = { ...config.global, ...config.difficulties[difficulty] };
  fishingInstance = new FishingMinigame(settings);
  return fishingInstance.startFromExport();
};
globalThis.StartFishing = difficulty => window.startFishingMinigame(difficulty);

window.addEventListener("message", event => {
  if (event.data.action === "startFishing") {
    fishingInstance = new FishingMinigame(event.data.difficultySettings);
    fishingInstance.startFromExport();
  }
});