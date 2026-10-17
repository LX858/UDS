-- =========================================================================
-- CÂU LỆNH SQL: CHỈ LẤY NHỮNG CITIZENID SỞ HỮU TỪ 7/9 MẪU XE TRỞ LÊN
-- =========================================================================

SELECT 
    pv.citizenid,
    CONCAT(
        COALESCE(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')), ''), ' ',
        COALESCE(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')), '')
    ) AS player_name,
    COUNT(DISTINCT LOWER(pv.vehicle)) AS unique_owned_out_of_9,
    GROUP_CONCAT(CONCAT(pv.vehicle, ' (', pv.plate, ')') SEPARATOR ', ') AS full_vehicles_list
FROM player_vehicles pv
LEFT JOIN players p ON pv.citizenid = p.citizenid
WHERE LOWER(pv.vehicle) IN (
    'r2f2fgtr34',
    'r2f2fgts',
    'r2f2fs2000',
    'r2f2fmle7',
    'fnfrx7',
    'chargerf8',
    'r2f2fmk4',
    'fnfmits',
    'godz95gsx'
)
GROUP BY pv.citizenid, player_name
HAVING COUNT(DISTINCT LOWER(pv.vehicle)) >= 7
ORDER BY unique_owned_out_of_9 DESC;
