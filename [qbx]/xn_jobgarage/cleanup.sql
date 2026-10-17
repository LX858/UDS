-- Cleanup script to remove old hash-based vehicle data
-- Run this ONCE to clean up old data before using the fixed version

DELETE FROM job_vehicles;

-- After running this, players will need to take out vehicles again
-- The new system will save vehicle names (strings) instead of hashes (numbers)
