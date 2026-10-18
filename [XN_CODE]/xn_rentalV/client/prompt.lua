ScootPrompt = {}

local config = ScootConfig
local currentText = nil
local currentKey = nil

function buildInteractionHint()
  local promptConfig = config.prompt or {}
  local accent = promptConfig.accent
  if not accent then
    if config.ui and config.ui.accent then
      accent = config.ui.accent
    elseif config.display and config.display.accent then
      accent = config.display.accent
    else
      accent = "#00e5b4"
    end
  end

  return {
    action = "interactionHint",
    text = currentText or false,
    key = currentKey or false,
    title = promptConfig.title or "VAULT RENTAL",
    scale = promptConfig.scale or 1,
    accent = accent,
  }
end

function ScootPrompt.show(text, key)
  if currentText == text and currentKey == key then
    return
  end

  currentText = text
  currentKey = key
  SendNUIMessage(buildInteractionHint())
end

function ScootPrompt.hide()
  if not currentText then
    return
  end

  currentText = nil
  currentKey = nil
  SendNUIMessage({
    action = "interactionHint",
    text = false,
  })
end

function ScootPrompt.toast(data)
  local accent = "#00e5b4"
  if config.ui and config.ui.accent then
    accent = config.ui.accent
  end

  SendNUIMessage({
    action = "toast",
    description = data.description or "",
    type = data.type or "inform",
    accent = accent,
  })
end

RegisterNUICallback("interactionHintReady", function(_, cb)
  cb({ ok = true })
  if currentText then
    SendNUIMessage(buildInteractionHint())
  end
end)
