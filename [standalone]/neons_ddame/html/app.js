
$(function () {
	window.addEventListener('message', function (event) {
		var data = event.data;
        var dmg = event.data.mg;
        var x = event.data.x;
        var y = event.data.y;
        var color = event.data.color;
		if (data.action === "dmg") {
            // console.log(x, y);
            $(`#container`).append(`
                <span id="dmg" style="left: ${x}%; bottom: ${y}%; color: ${color}";>${dmg}</span>
            `)
        }
	})
})