Locales = {}

function _(str, ...)
	local lang = AK4Y.Locale or AK4Y.Language or "vi"
	local locale = Locales[lang]

	if not locale then
		if Locales["vi"] then
			locale = Locales["vi"]
		elseif Locales["en"] then
			locale = Locales["en"]
		end
	end

	if locale and locale[str] then
		return string.format(locale[str], ...)
	elseif Locales["vi"] and Locales["vi"][str] then
		return string.format(Locales["vi"][str], ...)
	elseif Locales["en"] and Locales["en"][str] then
		return string.format(Locales["en"][str], ...)
	else
		return str
	end
end

function _U(str, ...)
	return _(str, ...):gsub("^%l", string.upper)
end
