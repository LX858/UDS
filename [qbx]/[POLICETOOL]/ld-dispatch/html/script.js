//  _                             _                                  ___                        _     
// | |_   _ _ __  _ __  _   _  __| | _____   _____ ___  _ __ ___    ( _ )    _ ____      ____ _(_)___ 
// | | | | | '_ \| '_ \| | | |/ _` |/ _ \ \ / / __/ _ \| '_ ` _ \   / _ \/\ | '_ \ \ /\ / / _` | / __|
// | | |_| | | | | | | | |_| | (_| |  __/\ V / (_| (_) | | | | | | | (_>  < | |_) \ V  V / (_| | \__ \
// |_|\__,_|_| |_|_| |_|\__, |\__,_|\___| \_(_)___\___/|_| |_| |_|  \___/\/ | .__/ \_/\_/ \__,_|_|___/
//                      |___/                                               |_|                       

let dispatchcount = 0 
let personlist = []
let myunit = []
let myjob = "unemployed"

$(document).ready(function(){
    $("#overview").click(function(){
        $(".menus").css('display', 'none')
        $(".overview").css('display', 'flex')
        $("#text").html("Recent Alerts")
    })

    $(".xxxx").click(function(){
        $('.dispatchinputmenu').css('display', 'none')
    })

    $("#units").click(function(){
        reloadUnits()

        if(myunit) {
            if(myunit.unithead) {
                $("#createunit").html("Xóa đơn vị")
                $("#createunit").attr('act', 'delete')
            } else {
                $("#createunit").html("Leave Unit")
                $("#createunit").attr('act', 'leave')
            }
        } else {
            $("#createunit").attr('act', 'create')
            $("#createunit").html("Tạo đơn vị")
        }

        $(".menus").css('display', 'none')
        $(".units").css('display', 'flex')
        $("#text").html("Units")
    })

    $("#createunit").click(function(){
        let act = $(this).attr('act')
        if(act == "create") {
            personlist = []
            $('.eklenenkisiler').html("")
            // Reset input fields and validation
            $("#unitname").val("");
            $("#unitcallcode").val("");
            validateCreateUnitButton();
            $('.dispatchinputmenu').css('display', 'flex')
        } else if(act=="delete") {
            $.post("https://ld-dispatch/deleteUnit", JSON.stringify({}), function(x){
                reloadUnits()
                $("#createunit").attr('act', 'create')
                $("#createunit").html("Tạo đơn vị")
            });
        } else if(act=="leave") {
            $.post("https://ld-dispatch/leaveUnit", JSON.stringify({}), function(x){
                reloadUnits()
                $("#createunit").attr('act', 'create')
                $("#createunit").html("Tạo đơn vị")
            });
        }
    })

    $("#addperson").click(function(){
        let id = Number($("#personid").val())

        if (!personlist.includes(id)) {
            $.post("https://ld-dispatch/canAddtoUnit", JSON.stringify({id:id}), function(x){
                if(x == true) {
                    let rand = Math.floor(Math.random() * 142342340);
                    personlist.push(id)
                    $(".eklenenkisiler").append('<div class="kisi" personid="'+id+'" rand="'+rand+'">ID: '+id+'</div>')
                    $('.kisi[rand="'+rand+'"').click(function(){
                        $(this).remove()
                        personlist = personlist.filter(function(value) {
                            return value !== id;
                        });
                    })
                }
            });
        }
    })

    $("#createunitb").click(function(){
        // Prevent action if button is disabled
        if ($(this).hasClass("disabled") || $(this).prop("disabled")) {
            return false;
        }
        
        let name = $("#unitname").val()
        let callcode = $("#unitcallcode").val()
        $.post("https://ld-dispatch/createUnit", JSON.stringify({personlist:personlist, name:name, callcode:callcode}), function(x){
            $('.dispatchinputmenu').css('display', 'none')
            // Reset input fields and validation
            $("#unitname").val("");
            $("#unitcallcode").val("");
            validateCreateUnitButton();
            
            reloadUnits()
            $("#createunit").html("Xóa đơn vị")
            $("#createunit").attr('act', 'delete')
        });
    })

    $("#officers").click(function(){
        $.post("https://ld-dispatch/getPlayers", JSON.stringify({}), function(x){
            let html = ``
            for(let i = 0; i<x.length; i++) {
                html+= '<p>' + x[i].displayname + '</p>'
                let displayname = x[i].displayname
                let plyrs = x[i].officers
                console.log(JSON.stringify(plyrs))
                for(let z=0; z<plyrs.length; z++) {
                    html+= `
                        <div class="dispatch blue">
                            <div class="dispatch_head">
                                <div class="left">
                                    <i class="fa-solid fa-user-large"></i>
                                    <p>${plyrs[z].callsign}-${plyrs[z].name}</p>
                                </div>
                            </div>
                            <div class="dispatch_informations">
                                <div>
                                    <div class="dispatch_info">
                                        <i class="fa-solid fa-note-sticky"></i>
                                        <p>${(displayname).toLowerCase()}</p>
                                    </div>
                                </div>
                                <div>
                                    <div class="dispatch_info">
                                        <i class="fa-solid fa-id-badge"></i>
                                        <p>${plyrs[z].job.grade.name}</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    `
                }
            }

            $(".officers_lists").html(html)

            $(".menus").css('display', 'none')
            $(".officers").css('display', 'flex')
            $("#text").html("Officers")
        });
    })
    
    // Function to validate create unit button
    function validateCreateUnitButton() {
        const unitName = $("#unitname").val().trim();
        const unitCallCode = $("#unitcallcode").val().trim();
        const createButton = $("#createunitb");
        
        if (unitName === "" || unitCallCode === "") {
            createButton.addClass("disabled");
            createButton.prop("disabled", true);
        } else {
            createButton.removeClass("disabled");
            createButton.prop("disabled", false);
        }
    }
    
    // Initially disable the button
    validateCreateUnitButton();
    
    // Add event listeners to input fields
    $("#unitname, #unitcallcode").on("input keyup", function() {
        validateCreateUnitButton();
    });
})

function addDispatch(x) {
    dispatchcount=dispatchcount+1
    let dispatchid = dispatchcount

    let alerts = ``
    let alertdetails = x.values || []
    for(let i = 0; i<alertdetails.length; i++) {
        alerts+= `
            <div class="dispatch_info">
                <i class="${alertdetails[i].icon}"></i>
                <p>${alertdetails[i].text}</p>
            </div>
        `
    }

    let alerts2 = ``
    let alertdetails2 = x.valuestwo || []
    for(let j = 0; j<alertdetails2.length; j++) {
        alerts2+= `
            <div class="dispatch_info">
                <i class="${alertdetails2[j].icon}"></i>
                <p>${alertdetails2[j].text}</p>
            </div>
        `
    }

    let html = `
        <div class="dispatch red revealdispatch animate-in slide-in-from-right-12 mr-2 fill-mode-both fade-in-0 duration-700" dispatchid="${dispatchid}">
            <div class="dispatch_head">
                <div class="left">
                    <i class="fa-solid fa-bullhorn"></i>
                    <p>${x.title}</p>
                </div>
                <div class="right">
                    <div>${x.code}</div>
                    <div>${x.dispatchnumber}</div>
                </div>
            </div>
            <div class="dispatch_informations">
                <div>
                    ${alerts}
                </div>
                <div>
                     <div class="dispatch_info">
                        <i class="fa-solid fa-clock"></i>
                        <p>in a few seconds</p>
                    </div>
                      ${alerts2}
                </div>
            </div>
        </div>
    `

    $(".dispatchs").prepend(html)
    setTimeout(() => {
        $('.revealdispatch[dispatchid="'+dispatchid+'"]').removeClass('animate-in slide-in-from-right fade-in duration-500').addClass("animate-out fade-out duration-700");
        setTimeout(() => {
            $('.revealdispatch[dispatchid="'+dispatchid+'"]').remove(); 
        }, 700);
    }, 7000);
}

function addDispatchtoMenu(x) {
    $(".recentdispatchs").html("")
    $(".activecalls").html("")
    for(let i = 0; i<x.length; i++) {
        if(!x[i].jobs.includes(myjob)) { return }

        let alerts = ``
        let alertdetails = x[i].values || []
        for(let j = 0; j<alertdetails.length; j++) {
            alerts+= `
                <div class="dispatch_info">
                    <i class="${alertdetails[j].icon}"></i>
                    <p>${alertdetails[j].text}</p>
                </div>
            `
        }
    
        let alerts2 = ``
        let alertdetails2 = x[i].valuestwo || []
        for(let k = 0; k<alertdetails2.length; k++) {
            alerts2+= `
                <div class="dispatch_info">
                    <i class="${alertdetails2[k].icon}"></i>
                    <p>${alertdetails2[k].text}</p>
                </div>
            `
        }
        let rand = Math.floor(Math.random() * 142342340);

        let color = "red";
        let hover = `
             <div class="hover_button" act="active" rand="${rand}">
                        <i class="fa-solid fa-plus"></i>
            </div>
        `
        if(x[i].active) {
            color = "blue"
            hover = ""
        }

        let html = `
            <div class="dispatch menudispatch ${color}" rand="${rand}">
                <div class="hover" style="display:none;">
                    <div class="hover_button" act="location" rand="${rand}">
                        <i class="fa-solid fa-location-dot"></i>
                    </div>
                    ${hover}
                </div>
                <div class="dispatch_head">
                    <div class="left">
                        <i class="fa-solid fa-bullhorn"></i>
                        <p>${x[i].title}</p>
                    </div>
                    <div class="right">
                        <div>${x[i].code}</div>
                        <div>${x[i].dispatchnumber}</div>
                    </div>
                </div>
                <div class="dispatch_informations">
                    <div>
                        ${alerts}
                    </div>
                    <div>
                        <div class="dispatch_info">
                            <i class="fa-solid fa-clock"></i>
                            <p>${zamanHesapla(x[i].date)}</p>
                        </div>
                        ${alerts2}
                    </div>
                </div>
            </div>
        `

        if(!x[i].active) {
            $(".recentdispatchs").prepend(html)
        } else {
            $(".activecalls").prepend(html)
        }

        $(".menudispatch[rand='"+rand+"']").hover(
            function() {
                $(this).children('.hover').css('display', 'flex');
            }, 
            function() {
                $(this).children('.hover').css('display', 'none');
            }
        );

        $(".hover_button[rand='"+rand+"']").click(function(){
            if($(this).attr('act') == "location") {
                $.post("https://ld-dispatch/setLocation", JSON.stringify({id:Number(x[i].dispatchnumber)}), function(callback){
                    
                });
            } else {
                $.post("https://ld-dispatch/setActive", JSON.stringify({id:Number(x[i].dispatchnumber)}), function(callback){

                });
            }
        })


    }
}

function addActiveCall(x) {
    let html = `
    <div class="dispatch blue">
        <div class="dispatch_head">
            <div class="left">
                <i class="fa-solid fa-bullhorn"></i>
                <p>Gun shots reported</p>
            </div>
            <div class="right">
                <div>10-71A</div>
                <div>785</div>
            </div>
        </div>
        <div class="dispatch_informations">
            <div>
                <div class="dispatch_info">
                    <i class="fa-solid fa-earth-americas"></i>
                    <p>Hawick Ave Meteor St</p>
                </div>
                <div class="dispatch_info">
                    <i class="fa-solid fa-bars-staggered"></i>
                    <p>Priotry 1</p>
                </div>
            </div>
            <div>
                <div class="dispatch_info">
                    <i class="fa-solid fa-clock"></i>
                    <p>in a few seconds</p>
                </div>
                <div class="dispatch_info">
                    <i class="fa-solid fa-walkie-talkie"></i>
                    <p>1</p>
                </div>
            </div>
        </div>
    </div>
`
$(".activecalls").prepend(html)
}

$(document).keyup(function(e) {
    if (e.key === "Escape") {
        if ($('.dispatchinputmenu').css('display') == 'flex') {
            $('.dispatchinputmenu').css('display', 'none')
        } else {
            $.post('https://ld-dispatch/closeMenu');
            $(".dispatchmenu").css('display', 'none')
        }
    }
});

window.addEventListener("message", function (event) {
    if(event.data.action == "openMenu") {
        myjob = event.data.myjob
        myunit = event.data.unit
        $(".dispatchmenu").css('display', 'flex')
        addDispatchtoMenu(event.data.data)
    } else if(event.data.action == "addispatch") {
        addDispatch(event.data.data)
    }
});

function reloadUnits() {
    $.post("https://ld-dispatch/getUnits", JSON.stringify({}), function(x){
        let html = ``
        for(let i = 0; i<x.length; i++) {
            html+= '<p>' + x[i].displayname + '</p>'
            let units = x[i].jobunits
            console.log(JSON.stringify(units))
            for(let z=0; z<units.length; z++) {
                
                let officers = units[z].officer || []
                let officerlist = []
                for(let j = 0; j<officers.length; j++) {
                    officerlist += `
                        <div class="dispatch_info">
                            <i class="fa-solid fa-id-badge"></i>
                            <p>${officers[j].callsign + "-" + officers[j].name}</p>
                        </div>
                    `
                    
                }

                html+= `
                    <div class="dispatch blue">
                        <div class="dispatch_head">
                            <div class="left">
                                <i class="fa-solid fa-user-large"></i>
                                <p>${units[z].name}</p>
                            </div>
                        </div>
                        <div class="dispatch_informations">
                            <div>
                                ${officerlist}
                                <div class="dispatch_info">
                                    <i class="fa-solid fa-note-sticky"></i>
                                    <p>${units[z].callname}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                `
            }
        }

        $(".unitslist").html(html)
    });
}

function zamanHesapla(time) {
    var luaTimeStr = time;
    var luaTime = new Date(luaTimeStr);
    var currentTime = new Date();
    var elapsedTime = currentTime - luaTime;
    var seconds = Math.floor(elapsedTime / 1000);
    var minutes = Math.floor(elapsedTime / (1000 * 60));
    var hours = Math.floor(elapsedTime / (1000 * 60 * 60));
    var days = Math.floor(elapsedTime / (1000 * 60 * 60 * 24));
    var elapsedTimeStr = "";
    if (seconds < 10) {
        elapsedTimeStr = "in a few seconds";
    } else if (days >= 1) {
        if (days === 1) {
            elapsedTimeStr = "1 days ago";
        } else {
            elapsedTimeStr = days + " days ago";
        }
    } else if (hours >= 1) {
        if (hours === 1) {
            elapsedTimeStr = "1 hours ago";
        } else {
            elapsedTimeStr = hours + " hours ago";
        }
    } else if (minutes >= 1) {
        if (minutes === 1) {
            elapsedTimeStr = "1 minutes ago";
        } else {
            elapsedTimeStr = minutes + " minutes ago";
        }
    } else {
        elapsedTimeStr = seconds + " seconds ago";
    }
    return elapsedTimeStr
}

//  _                             _                                  ___                        _     
// | |_   _ _ __  _ __  _   _  __| | _____   _____ ___  _ __ ___    ( _ )    _ ____      ____ _(_)___ 
// | | | | | '_ \| '_ \| | | |/ _` |/ _ \ \ / / __/ _ \| '_ ` _ \   / _ \/\ | '_ \ \ /\ / / _` | / __|
// | | |_| | | | | | | | |_| | (_| |  __/\ V / (_| (_) | | | | | | | (_>  < | |_) \ V  V / (_| | \__ \
// |_|\__,_|_| |_|_| |_|\__, |\__,_|\___| \_(_)___\___/|_| |_| |_|  \___/\/ | .__/ \_/\_/ \__,_|_|___/
//                      |___/                                               |_|