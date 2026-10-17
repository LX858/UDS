

BaseCallback("maps:getSavedLocations", function(source, phoneNumber)
    local locations = MySQL.query.await("SELECT id, `name`, x_pos, y_pos FROM phone_maps_locations WHERE phone_number = ? ORDER BY `name` ASC", {
        phoneNumber
    })
    
    for i = 1, #locations do
        local location = locations[i]
        local formattedLocation = {}
        formattedLocation.id = location.id
        formattedLocation.name = location.name
        formattedLocation.position = {
            location.y_pos,
            location.x_pos
        }
        locations[i] = formattedLocation
    end
    
    return locations
end, {})

BaseCallback("maps:addLocation", function(source, phoneNumber, name, xPos, yPos)
    return MySQL.insert.await("INSERT INTO phone_maps_locations (phone_number, `name`, x_pos, y_pos) VALUES (?, ?, ?, ?)", {
        phoneNumber,
        name,
        xPos,
        yPos
    })
end)

BaseCallback("maps:renameLocation", function(source, phoneNumber, locationId, newName)
    return MySQL.update.await("UPDATE phone_maps_locations SET `name` = ? WHERE id = ? AND phone_number = ?", {
        newName,
        locationId,
        phoneNumber
    }) > 0
end)

BaseCallback("maps:removeLocation", function(source, phoneNumber, locationId)
    return MySQL.update.await("DELETE FROM phone_maps_locations WHERE id = ? AND phone_number = ?", {
        locationId,
        phoneNumber
    }) > 0
end)
