
local query = {
    getAllCharactersQuery =
    'SELECT citizenid, cid, charinfo, money, job, position FROM players WHERE license = ? OR license = ? ORDER BY cid',
    getCharacterCountQuery = 'SELECT COUNT(*) FROM players WHERE license = ? OR license = ?',
    deleteCharacterQuery = 'SELECT license FROM players WHERE citizenid = ? LIMIT 1',
    tebexSlotsQuery =
    'SELECT COALESCE(SUM(slots_count), 0) FROM ronin_slots WHERE (license = ? OR license = ?) AND claim = 1'
}

return query
