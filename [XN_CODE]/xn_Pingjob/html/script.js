
var queueNews = 0
var currentNews = 0
var isShow
var isMenuOpen = false
var activePingCount = 0

var noti_sound = CreateSound("./noti.mp3", 0.3)

function UpdateBellHud() {
    $("#ping-count").text(activePingCount)
    if (activePingCount > 0 && !isMenuOpen) {
        $(".ping-bell-hud").removeClass('hidden')
    } else {
        $(".ping-bell-hud").addClass('hidden')
    }
}

$(document).ready(() => {
    $("body").show()


    FiveM.get("display_ping", (data) => {
        if (data.isShow)
            $(".crime-call-hud").removeClass('hidden')
        else
            $(".crime-call-hud").addClass('hidden')
    })

    $(".crime-call-hud .list .service").click((e) => {
        let service = $(e.target).attr("id")
        FiveM.send("call_service", { job: service })
    })

    FiveM.get("display_menu", (data) => {
        const jobAssets = {
            ambulance: {
                bg: 'https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/medicalallstars.webp'
            }
        };
    
        const assets = jobAssets[data.JobCheck];
        isMenuOpen = !!data.isShow;
        if (data.isShow) {
            $(".crime-menu-hud").removeClass('hidden');
            if (assets && assets.bg) {
                $('.crime-menu-hud').css('background-image', `url(${assets.bg})`);
            }
        } else {
            $(".crime-menu-hud").addClass('hidden');
        }
        UpdateBellHud()
    })

    FiveM.get("update_menu", (data) => {
        RenderMenu(data.job, data.playerId, data.list)
        activePingCount = (data.list && Array.isArray(data.list)) ? data.list.length : 0
        UpdateBellHud()
    })


    $(".crime-menu-hud").on("click", "#gps", (e) => {
        let id = $(e.target).closest('.item').data("caller")
        FiveM.send("gps_service", { id: id })
    })

    $(".crime-menu-hud").on("click", "#accept", (e) => {
        let id = $(e.target).closest('.item').data("caller")
        FiveM.send("accept_service", { id: id })
    })


    $(".crime-menu-hud").on("click", "#cancel", (e) => {
        let id = $(e.target).closest('.item').data("caller")
        FiveM.send("cancel_service", { id: id })
    })


    $(".crime-menu-hud").on("click", "#pull", (e) => {
        let id = $(e.target).closest('.item').data("caller")
        FiveM.send("pull_service", { id: id })
    })

    $(".crime-menu-hud").on("click", "#delete", (e) => {
        let id = $(e.target).closest('.item').data("caller")
        FiveM.send("delete_service", { id: id })
    })

    $(".crime-menu-hud").on("click", "#reset-bucket", (e) => {
        let id = $(e.target).closest('.item').data("caller")
        FiveM.send("reset_bucket", { id: id })
    })

    FiveM.get("ping_sound", () => noti_sound.play())

    // Nhận message từ Lua để copy vào clipboard  
    FiveM.get("copy_to_clipboard", (data) => {
        if (data.text) {
            navigator.clipboard.writeText(data.text).catch(() => {
                // Fallback
                let textArea = document.createElement("textarea")
                textArea.value = data.text
                document.body.appendChild(textArea)
                textArea.focus()
                textArea.select()
                document.execCommand('copy')
                document.body.removeChild(textArea)
            })
        }
    })


    FiveM.get("display_blacklist", (data) => {
        if (data.isShow)
            $(".crime-blacklist-hud").removeClass('hidden')
        else
            $(".crime-blacklist-hud").addClass('hidden')
    })

    FiveM.get("update_blacklist", (data) => {
        RenderBlacklist(data.job, data.list)
    })


    $(".crime-blacklist-hud").on("click", "#new", (e) => {
        FiveM.send("new_blacklist")
    })



    $(".crime-blacklist-hud").on("click", "#edit", (e) => {
        let player = $(e.target).closest('.item').data("player")
        let name = $(e.target).closest('.item').data("name")

        FiveM.send("edit_blacklist", { player: player, name: name })
    })


    $(".crime-blacklist-hud").on("click", "#delete", (e) => {
        let player = $(e.target).closest('.item').data("player")
        FiveM.send("delete_blacklist", { player: player })
    })


    $(document).keydown(function (e) {
        if (e.which == 27) {
            FiveM.send("close")
        }
    })
})


function RenderMenu(job, id, list) {
    $(".crime-menu-hud .title").html(`Dịch vụ ${job}`)

    $(".crime-menu-hud .body").empty()

    list = list.sort((a, b) => a.distance - b.distance).sort((a, b) => b.time - a.time)

    list.forEach(d => {
        let citizenDisplay = d.citizenId && d.citizenId !== "N/A" 
            ? d.citizenId
            : "N/A";
            
        let bucketNum = (d.bucket !== undefined && d.bucket !== null) ? Number(d.bucket) : 0;
        let bucketContent = bucketNum !== 0
            ? `<span class="bucket-val warning">${bucketNum}</span><button id="reset-bucket" type="button" class="btn-reset-bucket" title="Đưa về Bucket 0"><i class="fa-solid fa-arrows-rotate"></i></button>`
            : `<span class="bucket-val">${bucketNum}</span>`;

        let div = $(`
    <div class="item ${d.blacklist ? "blacklist" : ""}">
      <div class="col">${d.callerName}</div>
      <div class="col">${citizenDisplay}</div>
      <div class="col col-bucket">${bucketContent}</div>
      <div class="col">${d.accepterName}</div>
      <div class="col">${d.blacklist ? DateFormat(d.blacklist) : "Không"}</div>
      <div class="col" id="timer">${TimeString(d.time)}</div>
      <div class="col">${Math.floor(d.distance * 10) / 10}m</div>
      <div class="col">${(d.accepterId == -1) ? `<button id="accept" type="button" class="btn btn-outline-success">Nhận</button>`
                : ((d.accepterId == id) ? `<button id="cancel" type="button" class="btn btn-outline-warning">Hủy Nhận</button>` : ``)
            }</div>
      <div class="col"><button id="gps" type="button" class="btn btn-outline-info">GPS</button></div>
      <div class="col"><button id="pull" type="button" class="btn btn-outline-warning">Kéo Xác</button></div>
      <div class="col"><button id="delete" type="button" class="btn btn-outline-danger">Xóa</button></div>
    </div>
    `)

        div.data("caller", d.callerId)
        div.data("citizen", d.citizenId)
        div.data("bucket", bucketNum)
        $(".crime-menu-hud .body").append(div)

        let timer = d.time
        let tick = setInterval(() => {
            timer++;
            div.find("#timer").html(TimeString(timer))

            if ($(".crime-menu-hud").hasClass("hidden") || div.is(":hidden"))
                clearInterval(tick)
        }, 1000)
    });
}



function RenderBlacklist(job, list) {
    $(".crime-blacklist-hud .title").html(`Danh sách blacklist ${job}`)
    $(".crime-blacklist-hud .body").empty()

    list.forEach(d => {
        let div = $(`
    <div class="item">
      <div class="col">${d.name}</div>
      <div class="col">${d.blacklister}</div>
      <div class="col">${DateFormat(d.time)}</div>
      <div class="col">${d.reason}</div>
      <div class="col"><button id="edit" type="button" class="btn btn-outline-warning">Chỉnh sửa</button></div>
      <div class="col"><button id="delete" type="button" class="btn btn-outline-danger">Xóa</button></div>
    </div>
    `)


        div.data("player", d.identifier)
        div.data("name", d.name)
        // div.data("reason", d.reason)

        $(".crime-blacklist-hud .body").append(div)
    });
}



function TimeString(countdown) {
    let minute = Math.floor(countdown / 60)
    let second = countdown - minute * 60

    let time = `${second} Giây`
    if (countdown >= 60) {
        time = `${minute} Phút ${time}`
    }

    return time
}


function DateFormat(timestamp) {
    let time = new Date(timestamp)
    return `${time.getHours().toString().padStart(2, "0")}:${time.getMinutes().toString().padStart(2, "0")} ${time.getDate().toString().padStart(2, "0")}/${(time.getMonth() + 1).toString().padStart(2, "0")}`
}

function CreateSound(file, volume) {
    let obj = {}

    obj.sound = new Audio(file);
    obj.sound.volume = volume
    obj.play = function () {
        obj.sound.currentTime = 0;
        obj.sound.volume = volume;
        obj.sound.play();
    }
    obj.stop = function () {
        obj.sound.pause();
        obj.sound.currentTime = 0;
        obj.sound.volume = volume;
    }
    return obj
}
