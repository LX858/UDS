$(function(){
    window.onload = (e) => {
        window.addEventListener("message", (event) => {
            var item = event.data;
            if(item !== undefined && item.type === "ui") {
                if (item.display) {
                    $('#container').show();
                    $('#aids')[0].play();
                    const audio = document.getElementById("aids");
                    audio.volume = 0.5; 
                } else{
                    $('#container').hide();
                    $('#aids')[0].pause();
                    const audio = document.getElementById("aids");
                    audio.volume = 0.5; 
                }
            }
        })
    }
})