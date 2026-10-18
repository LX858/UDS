Capsule = {}

Capsule.contract = json.decode(LoadResourceFile(GetCurrentResourceName(), "data/asset-contract.json"))
Capsule.curves = json.decode(LoadResourceFile(GetCurrentResourceName(), "data/curves_right.json"))

function Capsule.variant(side)
  return Capsule.contract.variants[side or "right"]
end

function Capsule.world(frame, forward, right, up)
  local headingRad = math.rad(frame.heading or 0)
  return vector3(
    frame.coords.x + math.cos(headingRad) * forward - math.sin(headingRad) * right,
    frame.coords.y + math.sin(headingRad) * forward + math.cos(headingRad) * right,
    frame.coords.z + (up or 0)
  )
end

function Capsule.localPoint(frame, worldPos)
  local headingRad = math.rad(frame.heading or 0)
  local dx = worldPos.x - frame.coords.x
  local dy = worldPos.y - frame.coords.y
  return vector3(
    math.cos(headingRad) * dx + math.sin(headingRad) * dy,
    -math.sin(headingRad) * dx + math.cos(headingRad) * dy,
    worldPos.z - frame.coords.z
  )
end

function Capsule.bay(frame, worldPos, padding)
  local localPos = Capsule.localPoint(frame, worldPos)
  local variant = Capsule.variant(frame.side)
  if not padding then
    padding = 0
  end
  return math.abs(localPos.x - variant.capsuleCenter[1]) < (1.85 + padding)
end

function Capsule.terminalFrame(location)
  if not location.terminal then
    return location
  end

  local terminal = location.terminal
  if location.version == "tablet" then
    return {
      coords = terminal.coords,
      heading = terminal.heading,
      side = "right",
    }
  end

  local worldPos = Capsule.world(terminal, -2.35, -0.4, 0)
  return {
    coords = {
      x = worldPos.x,
      y = worldPos.y,
      z = worldPos.z,
    },
    heading = terminal.heading,
    side = "right",
  }
end

function Capsule.screen(location)
  if location.terminal and location.version == "tablet" then
    return 0, 0.081, 1.6
  end

  local frame = Capsule.terminalFrame(location)
  local x
  if frame.side == "left" then
    x = -3.1133204
  else
    x = 1.5866793
  end
  return x, 1.652, 1.6
end

function Capsule.service(location)
  local frame = Capsule.terminalFrame(location)
  if location.terminal and location.version == "tablet" then
    return Capsule.world(frame, 0, 1.0, 1.2)
  end

  local variant = Capsule.variant(frame.side)
  return Capsule.world(frame, variant.kioskCenter[1], 3.5, 1.2)
end

function Capsule.defaultTerminal(frame)
  local variant = Capsule.variant(frame.side)
  local worldPos = Capsule.world(frame, variant.kioskCenter[1], 0.4, 0)
  return {
    coords = {
      x = worldPos.x,
      y = worldPos.y,
      z = worldPos.z,
    },
    heading = frame.heading or 0,
  }
end

function Capsule.terminalModel(location)
  if not location.terminal then
    return Capsule.variant(location.side).kiosk
  end
  if location.version == "tablet" then
    return "ninelabs_capsule_tablet"
  end
  return "ninelabs_capsule_booth"
end

function Capsule.terminalClear(location)
  if not location.terminal then
    return true
  end

  local isTablet = location.version == "tablet"
  local probe = Capsule.world(location.terminal, 0, isTablet and 0 or 0.95, 0)
  probe = vector3(probe.x, probe.y, location.coords.z)

  local blocked = Capsule.vehicleInBay(
    location,
    probe,
    location.terminal.heading,
    isTablet and 0.7 or 3.2,
    isTablet and 0.56 or 4.78,
    2.3,
    3.7
  )
  return not blocked
end

function Capsule.vehicleInBay(frame, worldPos, heading, halfWidth, halfLength, bayHalfX, bayHalfY)
  local localPos = Capsule.localPoint(frame, worldPos)
  local capsuleCenter = Capsule.variant(frame.side).capsuleCenter

  if localPos.z <= -3 or localPos.z >= 4 then
    return false
  end

  local dx = localPos.x - capsuleCenter[1]
  local relativeHeading = math.rad((heading or 0) - (frame.heading or 0))
  local cosH = math.cos(relativeHeading)
  local sinH = math.sin(relativeHeading)
  local absCos = math.abs(cosH)
  local absSin = math.abs(sinH)

  local limitX = bayHalfX or 1.85
  local extentX = (halfWidth or 2.3) / 2 + 0.15
  local extentY = (halfLength or 5.6) / 2 + 0.15

  return math.abs(dx) < (limitX + absCos * extentX + absSin * extentY)
end

function Capsule.frame(anim, delta)
  if not anim then
    return 0
  end
  return math.min(anim.target, anim.frame + math.max(0, delta) * 0.03)
end

ScootAssets = {
  model = "ninelabs_capsule_kiosk_right",
  animDict = "ninelabs_capsule_anim_right",
  animClip = "capsule_cycle",
}
