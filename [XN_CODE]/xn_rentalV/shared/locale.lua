function ScootT(key, ...)
  local locale = ScootLocales[ScootConfig.locale]
  if not locale then
    locale = ScootLocales.en
  end

  local text = locale[key]
  if not text then
    text = ScootLocales.en[key]
    if not text then
      text = key
    end
  end

  if select("#", ...) > 0 then
    local formatted = text:format(...)
    if formatted then
      return formatted
    end
  end

  return text
end

function ScootTranslations()
  local result = {}
  for key in pairs(ScootLocales.en) do
    result[key] = ScootT(key)
  end
  return result
end
