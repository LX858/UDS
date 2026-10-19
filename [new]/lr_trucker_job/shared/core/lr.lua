LR = LR or {}

LR.VERSION = "2.0.0"

function LR.extend(target, source)
  target = target or {}
  source = source or {}

  for key, value in pairs(source) do
    target[key] = value
  end

  return target
end

function LR.shallowCopy(source)
  local target = {}
  for key, value in pairs(source or {}) do
    target[key] = value
  end
  return target
end

function LR.assertName(name, label)
  if type(name) ~= "string" or name == "" then
    error((label or "name") .. " must be a non-empty string")
  end
end
