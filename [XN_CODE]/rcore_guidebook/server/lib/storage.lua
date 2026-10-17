local gameName = GetGameName()
local categories = {}
local pages = {}
local points = {}

function getPoints()
    return points
end

function getPages()
    return pages
end

function ParseDataAttributesToTable(key, attributes, dataType)
    if attributes == nil or attributes == '' then
        return {}
    end

    local attr, _, err = json.decode(attributes)

    local label = dataType == DataTypes.CATEGORY and 'Category' or dataType == DataTypes.PAGE and 'Page' or 'Point'

    if err then
        dbg.error(
            '%s "%s" has error (see below) in `attributes` field. %s attributes will be ignored until fixed! Check database if the field is valid JSON.',
            label, key, label)
        dbg.error("Error: %s", err)

        return {}
    end

    return attr
end

function loadCategories()
    local categoryRaw = MySQL.Sync.fetchAll("SELECT * FROM rcore_guidebook_categories ORDER BY order_number DESC")
    if not next(categoryRaw) then
        return
    end

    categories = {}
    for _, categoryData in pairs(categoryRaw) do
        categoryData.attributes = ParseDataAttributesToTable(categoryData.key, categoryData.attributes,
            DataTypes.CATEGORY)
        categories[categoryData.key] = categoryData
    end
    return categories
end

function loadPageContent()
    local pagesRaw = MySQL.Sync.fetchAll("SELECT * FROM rcore_guidebook_pages")
    if not next(pagesRaw) then
        return
    end

    for _, pageData in pairs(pagesRaw) do
        pageData.attributes = ParseDataAttributesToTable(pageData.key, pageData.attributes, DataTypes.PAGE)
        pages[pageData.key] = pageData
    end
    return pages
end

function findAllOccurrences(s, pattern)
    local positions = {}
    local start = 1
    while true do
        local foundStart, foundEnd = string.find(s, pattern, start)
        if foundStart then
            table.insert(positions, foundStart)
            start = foundEnd + 1
        else
            break
        end
    end
    return positions
end

function searchPageContents(query, source)
    local SNIPPET_LENGTH = 70
    local ACCURACY_POINTS_CONTENT = 1
    local ACCURACY_POINTS_LABEL = 5

    local pages = getPages()

    local results = {}

    for _, pageData in pairs(pages) do
        local categoryKey = pageData.category_key

        if categories[categoryKey] == nil or categories[categoryKey].is_enabled == false or pageData.is_enabled == false then
            goto continue
        end

        local playerJob = {
            name = GetPlayersJobName(source),
            grade = GetPlayersJobGrade(source),
        }

        local isAdmin = Ace.Can(source, Permissions.OPEN_CONTROL)

        local hasCategoryPermission = HasPermission(categories[categoryKey].attributes, playerJob, isAdmin)

        if not hasCategoryPermission then
            goto continue
        end

        local hasPagePermission = HasPermission(pageData.attributes, playerJob, isAdmin)

        if not hasPagePermission then
            goto continue
        end

        local label = pageData.label
        local content = pageData.content

        local isMatchContent = content:lower():find(query:lower())
        local isMatchLabel = label:lower():find(query:lower())

        local accuracy = 0

        if isMatchContent ~= nil then
            -- Calling rcore_guidebook:getTextFromHTML without TriggerName on purpose
            -- to avoid people renaming script breaking the search
            TriggerEvent("rcore_guidebook:getTextFromHTML", content, function(html)
                local occurrences = findAllOccurrences(html:lower(), query:lower())

                local snippets = {}
                for _, v in pairs(occurrences) do
                    local start = v - math.floor(SNIPPET_LENGTH / 2)
                    local finish = v + math.floor(SNIPPET_LENGTH / 2)

                    if start < 0 then
                        start = 0
                    end

                    if finish > #html then
                        finish = #html
                    end

                    local snippet = html:sub(start, finish)

                    snippets[v] = snippet

                    accuracy = accuracy + ACCURACY_POINTS_CONTENT
                end

                if accuracy > 0 then
                    results[pageData.key] = {
                        key = pageData.key,
                        label = pageData.label,
                        content = snippets,
                        accuracy = accuracy,
                    }
                end
            end)
        end

        if isMatchLabel ~= nil then
            local currentAccuracy = results[pageData.key] and results[pageData.key].accuracy or 0
            results[pageData.key] = table.merge(results[pageData.key] or {}, {
                key = pageData.key,
                label = pageData.label,
                accuracy = currentAccuracy + ACCURACY_POINTS_LABEL,
            })
        end

        ::continue::
    end

    if not next(results) then
        return
    end

    local pages = {}
    for _, pageData in pairs(results) do
        pages[pageData.key] = {
            label = pageData.label,
            content = pageData.content,
            accuracy = pageData.accuracy,
        }
    end

    return pages
end

function loadPointContent()
    local pointsRaw = MySQL.Sync.fetchAll("SELECT * FROM rcore_guidebook_points")
    if not next(pointsRaw) then
        return
    end

    local biggerDistance = Config.HelpPointRenderDistance
    for _, pointData in pairs(pointsRaw) do
        pointData.position = json.decode(pointData.position)
        pointData.color = json.decode(pointData.color)
        pointData.marker_color = json.decode(pointData.marker_color)
        pointData.marker_size = json.decode(pointData.marker_size)
        pointData.marker_rotation = json.decode(pointData.marker_rotation or '{x: 0, y: 0, z: 0}')

        if gameName == GameType.FIVEM then
            --Need to fix types from db
            pointData.marker_type = tonumber(pointData.marker_type)
            pointData.blip_sprite = tonumber(pointData.blip_sprite)
        end

        if biggerDistance < pointData.draw_distance then
            biggerDistance = pointData.draw_distance
            dbg.debug("Found point with %s draw distance extending near point distance from %s", biggerDistance,
                Config.HelpPointRenderDistance)
            Config.HelpPointRenderDistance = biggerDistance
        end

        pointData.attributes = ParseDataAttributesToTable(pointData.key, pointData.attributes, DataTypes.POINT)

        points[pointData.key] = pointData
    end

    dbg.debug('Loaded %s points', table.len(points))
    return points
end

function updateCategory(categoryKey, label, orderNumber, isEnabled, isExpandable, attributes)
    local updateRows = MySQL.Sync.execute(
        "UPDATE `rcore_guidebook_categories` SET `label`=@label, `is_enabled`=@isEnabled, `order_number`=@orderNumber, `default_expand`=@isExpandable, `attributes`=@attributes WHERE `key`=@key",
        {
            ['label'] = label,
            ['isEnabled'] = isEnabled,
            ['orderNumber'] = orderNumber,
            ['isExpandable'] = isExpandable,
            ['key'] = categoryKey,
            ['attributes'] = attributes,
        })

    if updateRows then
        categories[categoryKey].label = label
        categories[categoryKey].order_number = orderNumber
        categories[categoryKey].is_enabled = isEnabled
        categories[categoryKey].default_expand = isExpandable
        categories[categoryKey].attributes = ParseDataAttributesToTable(categoryKey, attributes, DataTypes.CATEGORY)

        return true
    end

    return false
end

function createCategory(categoryKey, label, orderNumber, isEnabled, isExpandable, attributes)
    local id = MySQL.Sync.insert(
        "INSERT INTO `rcore_guidebook_categories` (`label`, `key`, `order_number`, `is_enabled`, `default_expand`, `attributes`) VALUES (@label, @key, @orderNumber, @isEnabled, @isExpandable, @attributes)",
        {
            ['label'] = label,
            ['isEnabled'] = isEnabled,
            ['orderNumber'] = orderNumber,
            ['isExpandable'] = isExpandable,
            ['key'] = categoryKey,
            ['attributes'] = attributes,
        })

    if id then
        categories[categoryKey] = {
            id = id,
            label = label,
            key = categoryKey,
            order_number = orderNumber,
            is_enabled = isEnabled,
            default_expand = isExpandable,
            attributes = ParseDataAttributesToTable(categoryKey, attributes, DataTypes.CATEGORY)
        }

        return id
    end

    return false
end

function updatePage(pageKey, label, categoryKey, orderNumber, isEnabled, content, attributes)
    local change = MySQL.Sync.execute(
        'UPDATE `rcore_guidebook_pages` SET `label`=@label, `category_key`=@categoryKey, `order_number`=@orderNumber, `is_enabled`=@isEnabled, `content`=@content, `attributes`=@attributes WHERE `key`=@pageKey',
        {
            ['pageKey'] = pageKey,
            ['label'] = label,
            ['categoryKey'] = categoryKey,
            ['orderNumber'] = orderNumber,
            ['isEnabled'] = isEnabled,
            ['content'] = content,
            ['attributes'] = attributes,
        })

    if change then
        pages[pageKey].label = label
        pages[pageKey].category_key = categoryKey
        pages[pageKey].order_number = orderNumber
        pages[pageKey].is_enabled = isEnabled
        pages[pageKey].content = content
        pages[pageKey].attributes = ParseDataAttributesToTable(pageKey, attributes, DataTypes.PAGE)

        return true
    end

    return false
end

function createPage(pageKey, label, categoryKey, orderNumber, isEnabled, content, attributes)
    local id = MySQL.Sync.insert(
        'INSERT INTO `rcore_guidebook_pages` (`label`, `key`, `category_key`, `order_number`, `is_enabled`, `content`, `attributes`) VALUES (@label, @key, @categoryKey, @orderNumber, @isEnabled, @content, @attributes)',
        {
            ['key'] = pageKey,
            ['categoryKey'] = categoryKey,
            ['label'] = label,
            ['orderNumber'] = orderNumber,
            ['isEnabled'] = isEnabled,
            ['content'] = content,
            ['attributes'] = attributes,
        })

    if id then
        pages[pageKey] = {
            id = id,
            label = label,
            category_key = categoryKey,
            key = pageKey,
            order_number = orderNumber,
            is_enabled = isEnabled,
            content = content,
            attributes = ParseDataAttributesToTable(pageKey, attributes, DataTypes.PAGE)
        }

        return true
    end

    return false
end

function createPoint(args)
    local id = MySQL.Sync.insert(
        "INSERT INTO `rcore_guidebook_points` (`key`, `label`, `is_enabled`, `can_navigate`, `blip_sprite`, `blip_display_type`, `blip_size`, `blip_enabled`, `show_date`, `hide_date`, `content`, `help_key`, `draw_distance`, `position`, `color`, `size`, `blip_color`, `marker_enabled`, `marker_size`, `marker_draw_distance`, `marker_type`, `marker_color`, `is_rotation_enabled`, `marker_rotation`, `font`, `attributes`) VALUES (@key, @label, @isEnabled, @canNavigate, @blipSprite, @displayType, @blipSize, @blipEnabled, @showDate, @hideDate, @content, @helpKey, @drawDistance, @position, @color, @size, @blipColor, @marker_enabled, @marker_size, @marker_draw_distance, @marker_type, @marker_color, @is_rotation_enabled, @marker_rotation, @font, @attributes)",
        {
            ['key'] = args.key,
            ['label'] = args.label,
            ['isEnabled'] = args.is_enabled,
            ['is_rotation_enabled'] = args.is_rotation_enabled,
            ['marker_rotation'] = json.encode(args.marker_rotation),
            ['canNavigate'] = args.can_navigate,
            ['blipSprite'] = args.blip_sprite,
            ['displayType'] = args.blip_display_type,
            ['blipSize'] = args.blip_size,
            ['blipEnabled'] = args.blip_enabled or false,
            ['blipColor'] = args.blip_color,
            ['marker_enabled'] = args.marker_enabled,
            ['marker_size'] = json.encode(args.marker_size),
            ['marker_type'] = args.marker_type,
            ['marker_draw_distance'] = args.marker_draw_distance,
            ['marker_color'] = json.encode(args.marker_color),
            ['showDate'] = args.show_date,
            ['hideDate'] = args.hide_date,
            ['content'] = args.content,
            ['helpKey'] = args.help_key,
            ['drawDistance'] = args.draw_distance,
            ['position'] = json.encode(args.position),
            ['size'] = args.size,
            ['color'] = json.encode(args.color),
            ['font'] = args.font or 0,
            ['attributes'] = args.attributes,
        })

    if id then
        points[args.key] = {
            id = id,
            key = args.key,
            label = args.label,
            is_enabled = args.is_enabled,
            is_rotation_enabled = args.is_rotation_enabled,
            marker_rotation = args.marker_rotation,
            can_navigate = args.can_navigate,
            blip_sprite = args.blip_sprite,
            blip_display_type = args.blip_display_type,
            blip_size = args.blip_size,
            blip_color = args.blip_color,
            blip_enabled = args.blip_enabled,
            marker_enabled = args.marker_enabled,
            marker_size = args.marker_size,
            marker_type = args.marker_type,
            marker_draw_distance = args.marker_draw_distance,
            marker_color = args.marker_color,
            show_date = args.show_date,
            hide_date = args.hide_date,
            content = args.content,
            help_key = args.help_key,
            draw_distance = args.draw_distance,
            position = args.position,
            color = args.color,
            size = args.size,
            font = args.font or 0,
            attributes = ParseDataAttributesToTable(args.key, args.attributes, DataTypes.POINT),
        }

        return true
    end

    return false
end

function updatePoint(args)
    local id = MySQL.Sync.execute(
        "UPDATE `rcore_guidebook_points`  SET `label`=@label, `is_enabled`=@isEnabled, `is_rotation_enabled`=@is_rotation_enabled, `marker_rotation`=@marker_rotation,  `can_navigate`=@canNavigate, `blip_sprite`=@blipSprite, `blip_display_type`=@displayType, `blip_size`=@blipSize, `blip_enabled`=@blipEnabled, `show_date`=@showDate, `hide_date`=@hideDate, `content`=@content, `help_key`=@helpKey, `draw_distance`=@drawDistance, `position`=@position, `size`=@size, `color`=@color, blip_color=@blipColor, `marker_enabled`=@marker_enabled, `marker_size`=@marker_size, `marker_draw_distance`=@marker_draw_distance, `marker_type`=@marker_type, `marker_color`=@marker_color, `font`=@font, `attributes`=@attributes WHERE `key`=@key",
        {
            ['key'] = args.key,
            ['label'] = args.label,
            ['isEnabled'] = args.is_enabled,
            ['is_rotation_enabled'] = args.is_rotation_enabled,
            ['marker_rotation'] = json.encode(args.marker_rotation),
            ['canNavigate'] = args.can_navigate,
            ['blipSprite'] = args.blip_sprite,
            ['displayType'] = args.blip_display_type,
            ['blipColor'] = args.blip_color,
            ['blipSize'] = args.blip_size,
            ['blipEnabled'] = args.blip_enabled,
            ['marker_enabled'] = args.marker_enabled,
            ['marker_size'] = json.encode(args.marker_size),
            ['marker_draw_distance'] = args.marker_draw_distance,
            ['marker_type'] = args.marker_type,
            ['marker_color'] = json.encode(args.marker_color),
            ['showDate'] = args.show_date,
            ['hideDate'] = args.hide_date,
            ['content'] = args.content,
            ['helpKey'] = args.help_key,
            ['drawDistance'] = args.draw_distance,
            ['position'] = json.encode(args.position),
            ['size'] = args.size,
            ['color'] = json.encode(args.color),
            ['font'] = args.font or 0,
            ['attributes'] = args.attributes,
        })

    if id then
        points[args.key] = {
            id = id,
            key = args.key,
            label = args.label,
            is_enabled = args.is_enabled,
            is_rotation_enabled = args.is_rotation_enabled,
            marker_rotation = args.marker_rotation,
            can_navigate = args.can_navigate,
            blip_sprite = args.blip_sprite,
            blip_display_type = args.blip_display_type,
            blip_size = args.blip_size,
            blip_color = args.blip_color,
            blip_enabled = args.blip_enabled,
            marker_enabled = args.marker_enabled,
            marker_size = args.marker_size,
            marker_draw_distance = args.marker_draw_distance,
            marker_type = args.marker_type,
            marker_color = args.marker_color,
            show_date = args.show_date,
            hide_date = args.hide_date,
            content = args.content,
            help_key = args.help_key,
            draw_distance = args.draw_distance,
            position = args.position,
            color = args.color,
            size = args.size,
            font = args.font or 0,
            attributes = ParseDataAttributesToTable(args.key, args.attributes, DataTypes.POINT),
        }

        return true
    end

    return false
end

function deletePage(pageKey)
    local changed = MySQL.Sync.execute('DELETE FROM `rcore_guidebook_pages` WHERE `key`=@key LIMIT 1', {
        ['key'] = pageKey
    })

    pages[pageKey] = nil

    return changed ~= 0
end

function deletePoint(pointKey)
    local changed = MySQL.Sync.execute('DELETE FROM `rcore_guidebook_points` WHERE `key`=@key LIMIT 1', {
        ['key'] = pointKey
    })

    points[pointKey] = nil

    return changed ~= 0
end

function deleteCategory(categoryKey)
    local changed = MySQL.Sync.execute('DELETE FROM `rcore_guidebook_categories` WHERE `key`=@key', {
        ['key'] = categoryKey
    })

    categories[categoryKey] = nil

    MySQL.Sync.execute('DELETE FROM `rcore_guidebook_pages` WHERE `category_key`=@key', {
        ['key'] = categoryKey
    })

    --We need to load next page content
    loadPageContent()

    return changed ~= 0
end

function formatFrontendData()
    if categories == nil or pages == nil then
        dbg.critical("Pages or categories is empty!")
        return
    end

    local categoryPageMap = {}
    local firstPage = true
    local firstPageContent = nil
    for pageKey, pageData in pairs(pages) do
        local lazyPageData = deepCopy(pageData)
        lazyPageData.content = nil

        if categoryPageMap[lazyPageData.category_key] == nil then
            categoryPageMap[lazyPageData.category_key] = {}
        end

        categoryPageMap[lazyPageData.category_key][#categoryPageMap[lazyPageData.category_key] + 1] = lazyPageData
    end

    local notIndexCategories = table.values(categories)
    table.sort(notIndexCategories, function(a, b) return a.order_number < b.order_number end)
    for _, categoryData in ipairs(notIndexCategories) do
        local categoryKey = categoryData.key
        local categoryPages = table.values(categoryPageMap[categoryKey] or {})
        table.sort(categoryPages, function(a, b) return a.order_number < b.order_number end)

        categoryData.pages = categoryPages or {}

        if firstPage == true then
            local firstPageData = categoryData.pages[1]
            if firstPageData == nil then
                firstPageContent = nil
            else
                firstPageContent = pages[firstPageData.key] or nil
            end
        end

        if firstPageContent and categoryData.is_enabled then
            firstPage = false
        end
    end

    return {
        categories = categories,
        firstPage = firstPageContent
    }
end

function getCategory(categoryKey)
    if categories == nil then
        dbg.critical('Trying to get category %s but categories data is nil! NOT-LOADED!', categoryKey)
        return
    end

    return categories[categoryKey]
end

function getPage(pageKey)
    if pages == nil then
        dbg.critical('Trying to get page %s but pages data is nil! NOT-LOADED!', pageKey)
        return
    end

    return pages[pageKey]
end

function getPoint(pointKey)
    if points == nil then
        dbg.critical('Trying to get point %s but pages data is nil! NOT-LOADED!', pointKey)
        return
    end

    return points[pointKey]
end
