$(function() {
    window.addEventListener('message', function(event) {
        var type = event.data.type;
        var data = event.data;
        if (type === 'showUI') {
           showTextUi(data)
        } else if (type === 'hideUI') {
           hideTextUi()
        } else if (type == 'showNotify') {
           showNotify(event.data.data)
        } else if(type == 'NotifyV2'){
            Notify(event.data.data)
        }
    });
});

var notifyCount = 0;

showTextUi = function(data) {
    if(data.icon === undefined){
        data.icon = 'fa-solid fa-hand'
    } else if(data.icon == 'target'){
        data.icon = 'fa-solid fa-eye'
    }
    let notify = `
    <div class="textuiContainer">
        <div class="leftBar">
            <i class="${data.icon}"></i>
        </div>
        <div class="leftright">
            <h1>${data.string}</h1>
        </div>
    </div>`;

    $(".text").html(notify);

    let container = $('.textuiContainer');

    container.css("right", "-300px");
    container.animate({ "right": "2vh" }, 350);
};

hideTextUi = function() {
    const notifyElement = $('.textuiContainer');

    // Sola kayarak kaybolan animasyon
    notifyElement.animate({ "right": "-300px" }, 350, function() {
        $(this).remove();
    });
}

showNotify = function(data) {
    notifyCount++;

    var color = '#fff';
    var type = 'info';
    var time = 3;
    var icon = 'circle-info'

    if(data.type == 'error'){
        color = '#FE4E4E';
        title = data.type;
        icon = 'error'
    } else if (data.type == 'success'){
        color = '#26CB90';
        icon = 'check_circle'
        title = data.type
    } else if (data.type == 'info'){
        color = '#42D3E7';
        icon = 'info'
        title = data.type
    }

    if (data.color){
        color = data.color  
    };

    if(data.time){
        time = data.time
    }

    let notify = `   
    <div id="notify-${notifyCount}" class="Bunlar w3-animate-right">
        <div class="LeftBoar">
            <span class="material-symbols-outlined" style="color: ${color};">
                ${icon}
            </span>
        </div>
        <div class="RightBoar">
            <h1 style="color: ${color}">${data.title}</h1>
            <p>${data.text}</p>
        </div>
    </div>`;

    $(".NotifyPart").append(notify);
    $(`#notify-${notifyCount}`).css("right", "-300px");
    $(`#notify-${notifyCount}`).animate({ "right": "0" }, 350);

    const notifyElement = $(`#notify-${notifyCount}`);
    const timeoutId = setTimeout(function() {
        notifyElement.animate({ "right": "-300px" }, 350, function() {
            $(this).remove();
        });
    }, 1000 * time);

    notifyElement.find(".closeButton").on("click", function() {
        clearTimeout(timeoutId);
        notifyElement.animate({ "right": "-300px" }, 350, function() {
            $(this).remove();
        });
    });

    const notifyContainers = $(".Bunlar");
    $(".NotifyPart").empty(); // Önce tüm bildirimleri temizle

    for (let i = notifyContainers.length - 1; i >= 0; i--) {
        $(".NotifyPart").append(notifyContainers[i]);
    }

    var audio = document.getElementById("notificationSound");
    audio.play();
}
