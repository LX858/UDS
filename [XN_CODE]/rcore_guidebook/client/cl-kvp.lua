function StorePageScaleToKvp(scaleValue)
  StoreKVPValue("pageScale", scaleValue)
end

-- Get stored page scale from KVP storage
function GetStoredPageScale()
  local storedScale = GetKVPValue("pageScale")
  return storedScale or 1.0
end