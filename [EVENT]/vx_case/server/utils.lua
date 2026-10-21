function Response(isSuccess, message, data)
  if not isSuccess then
    return {
      status = "error",
      message = message
    }
  end
  return {
    status = "success",
    data = data,
    message = message
  }
end

---@param collectionName string
---@param gender 0|1
---@param componentType "component"|"prop"
---@param componentId number
---@param drawableId number
---@param textureId number
---@return string
function GetItemlabel(collectionName, gender, componentType, componentId, drawableId, textureId)
  local label = ""
  local _gender = gender == 0 and "nam" or "nữ"
  if componentType == "component" then
    label = string.format("%s %s %s-%s %s", componentLabel[componentId], _gender,
      drawableId,
      textureId, collectionName)
  elseif componentType == "prop" then
    label = string.format("%s %s %s-%s %s", propLabel[componentId], _gender,
      drawableId,
      textureId, collectionName)
  end
  return label
end
