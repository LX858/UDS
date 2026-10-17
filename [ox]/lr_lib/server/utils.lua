---Get current Date
---@return {day:number,hour:number,month:number,year:number,min:number,sec:number,isdst:boolean,wday:number,yday:number}
function GetDate()
  local date = os.date("*t")
  ---@diagnostic disable-next-line: return-type-mismatch
  return date
end

-- exports["lr_lib"]:WsRegisterEventHander("onClientReady", function(...)
--   print("onClientReady", json.encode({...}), table.unpack({...}))
-- end)

function Copynof(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[Copynof(orig_key)] = Copynof(orig_value)
    end
  else -- number, string, boolean, etc
    if orig_type ~= 'function' then
      copy = orig
    end
  end
  return copy
end
