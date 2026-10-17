BaseCallback("notes:createNote", function(source, phoneNumber, title, content)
    return MySQL.insert.await("INSERT INTO phone_notes (phone_number, title, content) VALUES (?, ?, ?)", {
        phoneNumber,
        title,
        content
    })
end)

BaseCallback("notes:saveNote", function(source, phoneNumber, noteId, title, content)
    return MySQL.update.await("UPDATE phone_notes SET title = ?, content = ? WHERE id = ? AND phone_number = ?", {
        title,
        content,
        noteId,
        phoneNumber
    }) > 0
end)

BaseCallback("notes:removeNote", function(source, phoneNumber, noteId)
    return MySQL.update.await("DELETE FROM phone_notes WHERE id = ? AND phone_number = ?", {
        noteId,
        phoneNumber
    }) > 0
end)

BaseCallback("notes:getNotes", function(source, phoneNumber)
    return MySQL.query.await("SELECT id, title, content, `timestamp` FROM phone_notes WHERE phone_number = ?", {
        phoneNumber
    })
end)
