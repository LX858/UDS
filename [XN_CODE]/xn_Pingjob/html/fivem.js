
const FiveM = {
  eventHandler : {},
  send : function (action, data, callback) {
    "use strict";
    action= action || ""
    data = data || {};
    callback = callback || function() {}
    GetParentResourceName = GetParentResourceName || function() {return "localhost"}
    $.post(`http://${GetParentResourceName()}/${action}`, JSON.stringify(data), (d) => callback(d));
  }, 
  get: function (action, callback)  {
    "use strict";
    
    if (!this.eventHandler[action]) this.eventHandler[action] = []
    this.eventHandler[action].push(callback)
  },
  trigger: function(action, data) {
    "use strict";
    data = data || {}
    data.action = action
    if (FiveM.eventHandler[action]) 
      for (let i = 0; i <  FiveM.eventHandler[action].length; i++) 
        setTimeout(FiveM.eventHandler[action][i](data), 0);
  }
  
}

  
  
$(document).ready(() => {
  _updateSize()

  $(window).resize(function() {
    _updateSize();
  });

    window.addEventListener("message", function(event) {
      let data = event.data
      if (typeof(data) == "string") 
        data = JSON.parse(data)
      let action = data.action
      FiveM.trigger(action, data)
    })  
});

  
function _updateSize() {
  $("[--css-size='true']").each(async (i,d) => {
        let div = $(d)
        await new Promise((done) => div.ready(() => done()))
        let width = div.width()
        let height = div.height()
        div.css("--width", width + "px")
        div.css("--height", height + "px")
    })
}