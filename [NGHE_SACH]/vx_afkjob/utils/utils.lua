if not IsDuplicityVersion() then
  function GenerateUUID()
    return string.format('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
      math.random(0, 0xffff), math.random(0, 0xffff),
      math.random(0, 0xffff),
      math.random(0, 0x0fff) + 0x4000,
      math.random(0, 0x3fff) + 0x8000,
      math.random(0, 0xffff), math.random(0, 0xffff), math.random(0, 0xffff)
    )
  end
else
  function GenerateUUID()
    return string.format('%04x%04x-%04x-%04x-%04x-%04x%04x%04x%s',
      math.random(0, 0xffff), math.random(0, 0xffff),
      math.random(0, 0xffff),
      math.random(0, 0x0fff) + 0x4000,
      math.random(0, 0x3fff) + 0x8000,
      math.random(0, 0xffff), math.random(0, 0xffff), math.random(0, 0xffff),
      os.microtime()
    )
  end
end
