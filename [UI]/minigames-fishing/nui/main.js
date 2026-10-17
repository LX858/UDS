const fish = document.getElementById("fish");
const floater = document.getElementById("floater");
const progressBar = document.getElementById("progress-bar");
const instruction = document.getElementById("instruction");

let fishPos = 0;
let fishSpeed = 2;
let baseSpeed = 2;
let floaterPos = 170;
let floaterSpeed = 0;
let holding = false;
let progress = 0;
let gameActive = false;
let gameTimeout = null;
let lastDirectionChange = 0; // Thời điểm cuối cùng mà cá đổi hướng
let directionChangeCooldown = randomBetween(2000, 3000); // Cooldown giữa các lần đổi hướng
let nextDirectionChangeTime = 0; // Thời điểm tiếp theo cá sẽ đổi hướng
let fishMovementPattern = 0; // Mẫu chuyển động (0: thẳng, 1: zigzag, 2: ngắt quãng)
let zigzagCounter = 0; // Đếm thời gian cho mẫu zigzag

// Thêm biến cho random phím
let currentKey = 'Space';
let possibleKeys = ['A','C', 'D', 'E', 'H', 'I', 'J', 'N', 'O', 'Q', 'R', 'S', 'U', 'V', 'W', 'Y', 'Z', 'Space'];

// Thời gian cho minigame - random từ 10-18 giây
let minigameTime = Math.floor(Math.random() * 8000) + 10000;

// Hàm tạo số ngẫu nhiên trong khoảng
function randomBetween(min, max) {
  return Math.random() * (max - min) + min;
}

// Hàm để chọn ngẫu nhiên phím mới
function setRandomKey() {
  // Chọn ngẫu nhiên một phím từ danh sách
  currentKey = possibleKeys[Math.floor(Math.random() * possibleKeys.length)];
  
  // Cập nhật hướng dẫn
  updateInstructionText();
}

// Cập nhật text hướng dẫn
function updateInstructionText() {
  const displayKey = currentKey === 'Space' ? 'SPACE' : currentKey;
  instruction.innerHTML = `Cá sẽ di chuyển theo nhiều mẫu khác nhau. Nhấn phím <span class="key-highlight">[${displayKey}]</span> để theo dõi cá!`;
}

// Cập nhật mẫu chuyển động của cá
function updateFishMovementPattern() {
  fishMovementPattern = Math.floor(Math.random() * 3); // 0, 1, or 2
  // Reset các biến liên quan đến mẫu chuyển động
  zigzagCounter = 0;
  
  // Giữ nguyên tốc độ ban đầu
  baseSpeed = randomBetween(1.5 , 2);
  fishSpeed = fishSpeed < 0 ? -baseSpeed : baseSpeed;
  
  // Đặt thời gian đổi hướng tiếp theo
  setNextDirectionChangeTime();
}

// Đặt thời gian đổi hướng tiếp theo
function setNextDirectionChangeTime() {
  let minTime, maxTime;
  
  // Tùy chỉnh thời gian dựa trên mẫu chuyển động
  if (fishMovementPattern === 0) { // Thẳng - đổi hướng chậm hơn
    minTime = 2000;
    maxTime = 3500;
  } else if (fishMovementPattern === 1) { // Zigzag - đổi hướng nhanh hơn
    minTime = 300;
    maxTime = 700;
  } else { // Ngắt quãng - không đoán trước được
    minTime = 500;
    maxTime = 2000;
  }
  
  // Lưu thời điểm đổi hướng tiếp theo
  nextDirectionChangeTime = Date.now() + randomBetween(minTime, maxTime);
}

// Hàm để cá đổi hướng theo mẫu và thời gian
function handleFishMovement(currentTime) {
  // Nếu chưa đến thời gian đổi hướng
  if (currentTime < nextDirectionChangeTime) {
    // Xử lý mẫu zigzag
    if (fishMovementPattern === 1) {
      zigzagCounter += 1;
      if (zigzagCounter > 15) { // Đổi hướng sau mỗi 15 khung hình trong mẫu zigzag
        fishSpeed *= -1;
        zigzagCounter = 0;
      }
    }
    return;
  }
  
  // Đã đến thời gian đổi hướng
  if (fishMovementPattern === 2) { // Mẫu ngắt quãng - dừng đột ngột
    if (Math.random() < 0.3) { // 30% cơ hội dừng lại
      fishSpeed = 0;
      // Dừng trong thời gian ngắn
      setTimeout(() => {
        if (gameActive) {
          // Tiếp tục di chuyển với tốc độ và hướng ngẫu nhiên
          fishSpeed = Math.random() < 0.5 ? baseSpeed : -baseSpeed;
        }
      }, randomBetween(200, 500));
    } else {
      fishSpeed *= -1;
    }
  } else {
    // Đổi hướng cho các mẫu khác
    fishSpeed *= -1;
  }
  
  // Thêm hiệu ứng nhấp nháy khi cá đổi hướng
  fish.style.filter = "brightness(1.5)";
  setTimeout(() => {
    fish.style.filter = "none";
  }, 100);
  
  // Đặt thời điểm đổi hướng tiếp theo
  setNextDirectionChangeTime();
}

// Di chuyển cá theo các mẫu chuyển động khác nhau
function moveFish() {
  if (!gameActive) return;

  // Xử lý chuyển động của cá
  handleFishMovement(Date.now());
  
  // Cập nhật vị trí cá
  fishPos += fishSpeed;
  
  // Giữ cá trong vùng hiển thị
  if (fishPos <= 0 || fishPos >= 350) {
    fishSpeed *= -1;
    fishPos = fishPos <= 0 ? 0 : 350;
    setNextDirectionChangeTime(); // Reset thời gian đổi hướng khi chạm biên
  }
  
  // Cập nhật vị trí hiển thị
  fish.style.top = fishPos + "px";
}

function moveFloater() {
  if (!gameActive) return;

  if (holding) {
    floaterSpeed = -4; // Khôi phục tốc độ ban đầu
  } else {
    floaterSpeed = 4; // Khôi phục tốc độ ban đầu
  }

  floaterPos += floaterSpeed;

  if (floaterPos < 0) floaterPos = 0;
  if (floaterPos > 340) floaterPos = 340;

  floater.style.top = floaterPos + "px";
}

function checkOverlap() {
  if (!gameActive) return;

  let fishTop = fishPos;
  let fishBottom = fishPos + 50;
  let floaterTop = floaterPos;
  let floaterBottom = floaterPos + 60;

  if (fishBottom > floaterTop && fishTop < floaterBottom) {
    // Khôi phục tốc độ tăng điểm ban đầu
    progress += 0.27;
    fish.style.filter = "drop-shadow(0 0 10px #0f0)";
  } else {
    // Khôi phục tốc độ giảm điểm ban đầu
    progress -= 0.3;
    fish.style.filter = "none";
  }

  if (progress > 100) progress = 100;
  if (progress < 0) progress = 0;

  progressBar.style.height = progress + "%";

  if (progress >= 100) {
    endGame(true);
  }
}

function endGame(success) {
  if (!gameActive) return;
  
  gameActive = false;
  fish.style.filter = "none";
  document.getElementById("game").style.display = "none";
  clearTimeout(gameTimeout);

  if (success) {
    // Hiện popup thành công
    const popup = document.getElementById("success-screen");
    popup.style.display = "flex";

    // Ẩn sau 1.5 giây
    setTimeout(() => {
      popup.style.display = "none";
    }, 1500);
  }

  // Gửi kết quả về script
  fetch(`https://${GetParentResourceName()}/minigameEnd`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify({ success })
  });
}

document.addEventListener("keydown", (e) => {
  if (gameActive) {
    if ((e.code === "Space" && currentKey === "Space") || 
        (e.code === "Key" + currentKey && currentKey !== "Space")) {
      holding = true;
    }
  }
});

document.addEventListener("keyup", (e) => {
  if (gameActive) {
    if ((e.code === "Space" && currentKey === "Space") || 
        (e.code === "Key" + currentKey && currentKey !== "Space")) {
      holding = false;
    }
  }
});

function gameLoop() {
  moveFish();
  moveFloater();
  checkOverlap();

  if (gameActive) {
    requestAnimationFrame(gameLoop);
  }
}

window.addEventListener('message', function(event) {
  console.log("Received message:", event.data);
  
  if (event.data.type === "show") {
    document.getElementById("game").style.display = "flex";
    gameActive = true;
    progress = 0;
    progressBar.style.height = "0%";
    fishPos = randomBetween(50, 300); // Vị trí cá bắt đầu ngẫu nhiên
    baseSpeed = 2;
    fishSpeed = Math.random() < 0.5 ? baseSpeed : -baseSpeed; // Hướng di chuyển ban đầu ngẫu nhiên
    floaterPos = 170;
    floater.style.top = floaterPos + "px";
    
    // Chọn mẫu chuyển động ngẫu nhiên ban đầu
    updateFishMovementPattern();
    
    // Khởi tạo phím ngẫu nhiên mới cho minigame này
    setRandomKey();
    
    // Đặt thời gian ngẫu nhiên cho minigame (10-18s)
    minigameTime = Math.floor(Math.random() * 8000) + 10000;
    
    // Đặt timeout cho minigame
    if (gameTimeout) clearTimeout(gameTimeout);
    gameTimeout = setTimeout(() => {
      if (gameActive) {
        endGame(false);
      }
    }, minigameTime);
    
    // Đặt interval để thay đổi mẫu chuyển động mỗi 2-4 giây
    let patternChangeInterval = setInterval(() => {
      if (!gameActive) {
        clearInterval(patternChangeInterval);
        return;
      }
      updateFishMovementPattern();
    }, randomBetween(2000, 4000));
    
    gameLoop();
  } else if (event.data.type === "hide") {
    endGame(false);
  }
});


