-- Test database connection and functionality
-- Run in server console: exec xn_pdtools testdb.lua

print("[xn_pdtools] Starting database test...")

-- Test QBCore database structure
local function testQBCoreDB()
    print("Testing QBCore database...")
    
    -- Check if oxmysql is available
    if not exports.oxmysql then
        print("ERROR: oxmysql not available!")
        return
    end
    
    -- Test connection with a simple query
    exports.oxmysql:execute('SELECT COUNT(*) as count FROM player_vehicles', {}, function(result)
        if result and result[1] then
            print("✅ QBCore database connected successfully!")
            print("Total vehicles in database: " .. result[1].count)
            
            -- Get sample data
            exports.oxmysql:execute('SELECT plate, citizenid, vehicle FROM player_vehicles LIMIT 5', {}, function(vehicles)
                print("--- Sample Vehicles ---")
                for i, vehicle in ipairs(vehicles) do
                    print(string.format("%d. Plate: %s | CitizenID: %s | Model: %s", 
                        i, vehicle.plate, vehicle.citizenid, vehicle.vehicle or "Unknown"))
                end
            end)
        else
            print("❌ Failed to connect to QBCore database")
        end
    end)
end

-- Test ESX database structure
local function testESXDB()
    print("Testing ESX database...")
    
    exports.oxmysql:execute('SELECT COUNT(*) as count FROM owned_vehicles', {}, function(result)
        if result and result[1] then
            print("✅ ESX database connected successfully!")
            print("Total vehicles in ESX database: " .. result[1].count)
            
            -- Get sample data
            exports.oxmysql:execute('SELECT plate, owner, vehicle FROM owned_vehicles LIMIT 5', {}, function(vehicles)
                print("--- Sample ESX Vehicles ---")
                for i, vehicle in ipairs(vehicles) do
                    print(string.format("%d. Plate: %s | Owner: %s | Model: %s", 
                        i, vehicle.plate, vehicle.owner, vehicle.vehicle or "Unknown"))
                end
            end)
        else
            print("❌ Failed to connect to ESX database")
        end
    end)
end

-- Test specific plate lookup
local function testPlateLookup(plate)
    plate = plate or "TEST123"
    print("Testing plate lookup for: " .. plate)
    
    -- QBCore test
    exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
        if result[1] then
            print("✅ Found in QBCore: " .. json.encode(result[1]))
            
            -- Get owner info
            exports.oxmysql:execute('SELECT * FROM players WHERE citizenid = ?', {result[1].citizenid}, function(players)
                if players[1] then
                    local charinfo = json.decode(players[1].charinfo)
                    print("Owner: " .. charinfo.firstname .. " " .. charinfo.lastname)
                end
            end)
        else
            print("❌ Not found in QBCore database for plate: " .. plate)
        end
    end)
    
    -- ESX test
    exports.oxmysql:execute('SELECT * FROM owned_vehicles WHERE plate = ?', {plate}, function(result)
        if result[1] then
            print("✅ Found in ESX: " .. json.encode(result[1]))
            
            -- Get owner info
            exports.oxmysql:execute('SELECT * FROM users WHERE identifier = ?', {result[1].owner}, function(users)
                if users[1] then
                    print("Owner: " .. users[1].firstname .. " " .. users[1].lastname)
                end
            end)
        else
            print("❌ Not found in ESX database for plate: " .. plate)
        end
    end)
end

-- Run tests
print("=" .. string.rep("=", 50))
print("XNPDTOOLS DATABASE TEST")
print("=" .. string.rep("=", 50))

testQBCoreDB()
Wait(2000)
testESXDB()
Wait(2000)
testPlateLookup("ABC123")

print("Database test completed!")
print("Check above for results...")
