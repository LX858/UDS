var timerInterval = null;
var hideTimeout = null;
var eKeyPressed = false;
var slotPosition = 0;
var currPosition = 1;

function startGame(difficulty) {
    if (hideTimeout) {
        clearTimeout(hideTimeout);
        hideTimeout = null;
    }
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }
    var hackingContainer = document.querySelector('.hacking-container');
    var movingSquare = document.querySelector('.moving-square');
    var buttonPress = document.querySelector('.button-press');
    var squareSlot = document.querySelector('.square-slot');
    hackingContainer.style.display = 'flex'
    movingSquare.style.background = "radial-gradient(circle, rgb(0, 255, 200), rgb(0, 174, 130))";
    movingSquare.style.boxShadow = "0 0 5px 0px rgb(16, 239, 191)";
    movingSquare.style.marginLeft = "1%";
    buttonPress.style.background = 'radial-gradient(circle, rgb(0, 183, 140), rgb(0, 81, 61))';
    squareSlot.style.setProperty('--background-gradient', 'radial-gradient(circle, rgb(0, 255, 200), rgb(0, 174, 130))');
    eKeyPressed = false;
    currPosition = 0;
    randomizeSquareSlot();

    // Map difficulty to speed/interval
    var diff = 'medium';
    if (difficulty) {
        var dStr = String(difficulty).toLowerCase().trim();
        if (dStr === 'easy' || dStr === 'dễ' || dStr === '1' || dStr === 'de') {
            diff = 'easy';
        } else if (dStr === 'hard' || dStr === 'khó' || dStr === '3' || dStr === 'kho') {
            diff = 'hard';
        }
    }

    var speed = 25; // default medium
    if (diff === 'easy') {
        speed = 50;
    } else if (diff === 'hard') {
        speed = 12;
    }

    // Dynamically set CSS transition duration to match the speed (in seconds)
    movingSquare.style.transition = "margin-left " + (speed / 1000) + "s linear, scale 0.3s ease-in-out";

    tick(speed);
}

function checkWin() {
    var movingSquare = document.querySelector('.moving-square');
    var squareSlot = document.querySelector('.square-slot');
    var buttonPress = document.querySelector('.button-press');
    if (timerInterval) {
        clearInterval(timerInterval);
    }
    if (slotPosition - 2.6 <= currPosition && currPosition <= slotPosition + 2.6) {
        movingSquare.style.scale = '1.2';
        setTimeout(function () {
            movingSquare.style.scale = '1';
        }, 300);
        return true;
    }
    movingSquare.style.background = "radial-gradient(circle, rgb(255, 85, 76), rgba(132, 32, 32, 0.894))";
    movingSquare.style.boxShadow = "0 0 5px 0px rgb(255, 0, 0)";
    buttonPress.style.background = "radial-gradient(circle, rgb(255, 85, 76), rgba(132, 32, 32, 0.894))";
    squareSlot.style.setProperty('--background-gradient', 'radial-gradient(circle, rgb(255, 85, 76), rgba(132, 32, 32, 0.894))');
    return false;
}

function tick(speed) {
    var movingSquare = document.querySelector('.moving-square');
    timerInterval = setInterval(function () {
        movingSquare.style.marginLeft = "".concat(currPosition, "%");
        currPosition += 1;
        if (currPosition > Math.min(slotPosition + 7, 94)) {
            if (timerInterval) {
                clearInterval(timerInterval);
            }
            handleKeyPress(new KeyboardEvent('keydown', { key: 'E' }));
        }
    }, speed);
}

function handleKeyPress(event) {
    if (!eKeyPressed && (event.key.toLowerCase() === 'e')) {
        eKeyPressed = true;
        var won = checkWin();
        var resourceName = "five-repairkit";
        try {
            if (typeof GetParentResourceName !== 'undefined') {
                resourceName = GetParentResourceName();
            }
        } catch (e) {}

        fetch(`https://${resourceName}/GetResult`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify(won)
        }).catch(function(err) {
            console.log("Post result failed: not running inside FiveM NUI?");
        });

        hideTimeout = setTimeout(function () {
            var hackingContainer = document.querySelector('.hacking-container');
            hackingContainer.style.display = 'none';
            hideTimeout = null;
        }, 1000);
    }
}
function randomizeSquareSlot() {
    var squareSlot = document.querySelector('.square-slot');
    slotPosition = Math.floor(Math.random() * (90 - 40) + 40);
    squareSlot.style.marginLeft = "".concat(slotPosition, "%");
    squareSlot.style.display = "flex";
}

document.addEventListener('keydown', handleKeyPress);

window.addEventListener('message', (event) => {
    if (event.data.type === 'start') {
        startGame(event.data.difficulty);
    }
});