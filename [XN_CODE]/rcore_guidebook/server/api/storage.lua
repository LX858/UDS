-- This function is necessary only when updating from v1 to v2
-- You can turn this on/off by adding `Config.UpdateDatabaseStructure = false` to config.lua
function updateDatabaseStructure()
    if Config.UpdateDatabaseStructure == false then return end

    dbg.debug('Checking database structure...')

    local tables = {
        'rcore_guidebook_categories',
        'rcore_guidebook_pages',
        'rcore_guidebook_points',
    }

    for _, table in ipairs(tables) do
        local result = MySQL.Sync.fetchAll('SHOW COLUMNS FROM `' .. table .. '` LIKE "attributes"')

        if #result == 0 then
            dbg.debug('Updating structure of table "%s"', table)
            MySQL.Sync.execute("ALTER TABLE `" .. table .. "` ADD COLUMN `attributes` LONGTEXT NOT NULL;")
        end
    end

    dbg.debug('Database structure is up to date')

    Config.UpdateDatabaseStructure = false
end

-- Default database
local function insertCategoriesDatabase()
    -- create table rcore_guidebook_categories
    MySQL.Sync.execute([[
        create table rcore_guidebook_categories
        (
            id             int auto_increment,
            label          VARCHAR(255) not null,
            `key`          VARCHAR(255) not null,
            order_number   int default 1 null,
            is_enabled     tinyint(1) default 1 null,
            default_expand tinyint(1) default 1 null,
            attributes     LONGTEXT not null,
            constraint rcore_guidebook_categories_pk
                primary key (id)
        );
    ]], {})

    MySQL.Sync.execute([[
        create unique index rcore_guidebook_categories_key_uindex
            on rcore_guidebook_categories (`key`);
    ]], {})

    -- insert default data
    MySQL.Sync.execute([[
        INSERT INTO rcore_guidebook_categories (label, `key`, order_number, is_enabled, default_expand, attributes)
        VALUES ('Home', 'home', 1, 1, 1, '{}');
    ]], {})

    -- convert to utf8mb4
    MySQL.Sync.execute([[
        ALTER TABLE rcore_guidebook_categories CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
    ]], {})
end

local function insertPagesDatabase()
    -- create table rcore_guidebook_pages
    MySQL.Sync.execute([[
        create table rcore_guidebook_pages
        (
            id           int auto_increment,
            label        varchar(255) not null,
            `key`        varchar(255) not null,
            category_key varchar(255) not null,
            order_number int default 1 null,
            is_enabled   tinyint(1) default 1 null,
            content      LONGTEXT null,
            attributes   LONGTEXT not null,
            constraint rcore_guidebook_pages_pk
                primary key (id)
        );
    ]], {})

    MySQL.Sync.execute([[
        create unique index rcore_guidebook_pages_key_uindex
            on rcore_guidebook_pages (`key`);
    ]], {})

    MySQL.Sync.execute([[
        INSERT INTO rcore_guidebook_pages (label, `key`, category_key, order_number, is_enabled, content, attributes)
        VALUES ('Welcome', 'welcome', 'home', 1, 1, '<h2>Welcome to this server :)</h2>
        <p>This is the demo page of rcore_guidebook resource.</p>
        <p>You can change all this with the administration command if you have the rights to do.<br /><br /></p>
        <p>If you need any help contact us on our discord <a href="https://discord.gg/F28PfsY">https://discord.gg/F28PfsY</a></p>', '{}');
    ]], {})


    MySQL.Sync.execute([[
        ALTER TABLE rcore_guidebook_pages CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
    ]], {})
end

local function insertPointsDatabase()
    -- create table rcore_guidebook_points
    MySQL.Sync.execute([[
        create table rcore_guidebook_points
        (
            id                int auto_increment,
            `key`             varchar(50)                           not null,
            label             varchar(255) null,
            is_enabled        tinyint(1) default 1 not null,
            can_navigate      tinyint(1) default 1 not null,
            blip_sprite       varchar(255) null,
            blip_color        int null,
            blip_display_type int          default 4                null,
            blip_size              float        default 1.0              null,
            blip_enabled      tinyint(1) default 1 not null,
            marker_enabled      tinyint(1) default 1 not null,
            marker_size varchar(255) null,
            marker_draw_distance int null,
            marker_type varchar(255) null,
            marker_color varchar(255) null,
            show_date         timestamp null,
            hide_date         timestamp null,
            content           TEXT null,
            help_key          varchar(255) null,
            draw_distance     int null,
            position          varchar(255) default "vector3(0,0,0)" not null,
            size float default 1.0 null,
            color varchar(255) null,
            is_rotation_enabled tinyint(1) default 1 null,
            marker_rotation varchar(255) default '{"x":0.0,"y":0.0,"z":0.0}' null,
            font tinyint(1) default 0 null,
            attributes     LONGTEXT not null,
            constraint rcore_guidebook_points_pk
                primary key (id)
        );
    ]], {})
    MySQL.Sync.execute([[
        create unique index rcore_guidebook_points_key_uindex
            on rcore_guidebook_points (`key`);
    ]], {})

    MySQL.Sync.execute([[
        ALTER TABLE rcore_guidebook_points CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
    ]], {})
end

function insertDatabaseSafely()
    dbg.info('Started inserting default database tables and data.')
    dbg.info('Checking if data already exists.')
    local result = {}

    for _, v in pairs(MySQL.Sync.fetchAll([[ SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() ]], {})) do
        result[v.TABLE_NAME] = true
    end

    if not result['rcore_guidebook_categories'] then
        dbg.info('Inserting rcore_guidebook_categories table to database')
        insertCategoriesDatabase()
    end

    if not result['rcore_guidebook_pages'] then
        dbg.info('Inserting rcore_guidebook_pages table to database')
        insertPagesDatabase()
    end

    if not result['rcore_guidebook_points'] then
        dbg.info('Inserting rcore_guidebook_points table to database')
        insertPointsDatabase()
    end

    dbg.info('Finished inserting default database tables and data.')
end
