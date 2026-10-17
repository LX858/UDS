local postsPerPage = 10

BaseCallback("yellowPages:getPosts", function(source, phoneNumber, page, filters)
    if not page then
        page = 0
    end
    
    local params = {}
    local whereConditions = {}
    
    if filters then
        if filters.search then
            whereConditions[#whereConditions + 1] = "(title LIKE ? OR description LIKE ?)"
            params[#params + 1] = "%" .. filters.search .. "%"
            params[#params + 1] = "%" .. filters.search .. "%"
            
            if not filters.from then
                whereConditions[#whereConditions + 1] = "OR phone_number LIKE ?"
                params[#params + 1] = "%" .. filters.search .. "%"
            end
        end
        
        if filters.from then
            local condition = ""
            if #whereConditions > 0 then
                condition = "AND "
            end
            condition = condition .. "phone_number = ?"
            whereConditions[#whereConditions + 1] = condition
            params[#params + 1] = filters.from
        end
    end
    
    local query = [[
        SELECT
            id,
            phone_number AS `number`,
            title,
            description,
            attachment,
            price,
            `timestamp`
        FROM
            phone_yellow_pages_posts
        {WHERE}
        ORDER BY
            `timestamp` DESC
        LIMIT ?, ?
    ]]
    
    local whereClause = ""
    if #whereConditions > 0 then
        whereClause = "WHERE " .. table.concat(whereConditions, " ")
    end
    
    query = query:gsub("{WHERE}", whereClause)
    
    params[#params + 1] = (page or 0) * postsPerPage
    params[#params + 1] = postsPerPage
    
    return MySQL.query.await(query, params)
end)

BaseCallback("yellowPages:createPost", function(source, phoneNumber, postData)
    if not postData or not postData.title or not postData.description then
        return false
    end
    
    if ContainsBlacklistedWord(source, "Pages", postData.title) or ContainsBlacklistedWord(source, "Pages", postData.description) then
        return false
    end
    
    local postId = MySQL.insert.await("INSERT INTO phone_yellow_pages_posts (phone_number, title, description, attachment, price) VALUES (@number, @title, @description, @attachment, @price)", {
        ["@number"] = phoneNumber,
        ["@title"] = postData.title,
        ["@description"] = postData.description,
        ["@attachment"] = postData.attachment,
        ["@price"] = tonumber(postData.price)
    })
    
    if not postId then
        return false
    end
    
    postData.id = postId
    postData.number = phoneNumber
    
    TriggerClientEvent("phone:yellowPages:newPost", -1, postData)
    TriggerEvent("lb-phone:pages:newPost", postData)
    
    Log("YellowPages", source, "info", L("BACKEND.LOGS.YELLOWPAGES_NEW_TITLE"), L("BACKEND.LOGS.YELLOWPAGES_NEW_DESCRIPTION", {
        title = postData.title,
        description = postData.description,
        attachment = postData.attachment or "",
        id = postData.id
    }))
    
    return postId
end)

BaseCallback("yellowPages:deletePost", function(source, phoneNumber, postId)
    local isAdmin = IsAdmin(source)
    local deleteQuery = "DELETE FROM phone_yellow_pages_posts WHERE id = @id"
    
    if not isAdmin then
        deleteQuery = deleteQuery .. " AND phone_number = @number"
    end
    
    local success = MySQL.update.await(deleteQuery, {
        ["@id"] = postId,
        ["@number"] = phoneNumber
    }) > 0
    
    if success then
        Log("YellowPages", source, "error", L("BACKEND.LOGS.YELLOWPAGES_DELETED"), ("**ID**: %s"):format(postId))
    end
    
    return true
end)
