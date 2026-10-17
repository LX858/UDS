MissedPrice = MissedPrice or {}

MissedPrice.MAX_CLAIMS_HARD = 31 

function MissedPrice.NormalizeMultiplier(raw)
	local m = tonumber(raw)
	if not m or m < 1 then
		return 1
	end
	if m > 100 then
		return 100
	end
	return m
end

function MissedPrice.ClampMaxClaims(raw, daysInMonth)
	local maxDays = math.max(1, math.min(MissedPrice.MAX_CLAIMS_HARD, math.floor(tonumber(daysInMonth) or MissedPrice.MAX_CLAIMS_HARD)))
	local n = math.max(0, math.floor(tonumber(raw) or 0))
	if n > maxDays then
		return maxDays
	end
	return n
end

function MissedPrice.ForIndex(basePrice, multiplier, claimIndex)
	basePrice = math.max(0, math.floor(tonumber(basePrice) or 0))
	multiplier = MissedPrice.NormalizeMultiplier(multiplier)
	claimIndex = math.max(0, math.min(MissedPrice.MAX_CLAIMS_HARD, math.floor(tonumber(claimIndex) or 0)))
	local price = basePrice * (1 + (multiplier - 1) * claimIndex)
	return math.max(0, math.floor(price + 0.5))
end

function MissedPrice.Preview(basePrice, multiplier, maxClaims)
	maxClaims = MissedPrice.ClampMaxClaims(maxClaims, MissedPrice.MAX_CLAIMS_HARD)
	local list = {}
	for i = 0, maxClaims - 1 do
		list[#list + 1] = {
			claim = i + 1,
			price = MissedPrice.ForIndex(basePrice, multiplier, i),
		}
	end
	return list
end
