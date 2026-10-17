$("#boxgin").hide();
window.onload = function(e) {
    window.addEventListener('message', function(event) {
        let data = event.data
        switch(data.action) {
            case "open":
                DanhSach(data);
            break;
            case "open_modal":
                OpenModal(data);
            break;
        }
    })
    
} 

// Show danh sách order
DanhSach = function(data) {
    $("#boxgin").css("display", "block");
}
OpenModal = function(data) {
    $("#modal").css("display", "block");
    // console.log(data.id_pl);
    var AddProduct = '<div class="idplay" data-id="'+data.id_pl+'"><div class="khungtrog">['+data.id_pl+'] '+data.name_pl+'</div></div>';
    $('.showid').append(AddProduct);
}
  
// Nhận 
$(document).on('click', '.idplay', function(e) {
    e.preventDefault();
    data_id = $(this).data("id");
    $("#boxgin").hide();
    $("#modal").hide();
    $(".showid").html('');
    $.post(`http://nl_hotcut/hoantat`, JSON.stringify({
        id_member: data_id,
        solan: $("#solan").val(),
    }));
    $("#solan").val("");
});

// Nhận 
$(document).on('click', '#gui', function(e) {
    e.preventDefault();
    var solan = $("#solan").val();
    if(solan>0) {
        $.post(`http://nl_hotcut/gui`, JSON.stringify({
        }));
    }
});

//Nút ESC đóng tab
$(document).on('keydown', function() {
    switch(event.keyCode) {
        case 27: // ESC
        $("#boxgin").hide();
        $("#modal").hide();
        $(".showid").html('');
        $("#solan").val("");
        $.post("http://nl_hotcut/tat", JSON.stringify({
        }));
        break;
    }
});
