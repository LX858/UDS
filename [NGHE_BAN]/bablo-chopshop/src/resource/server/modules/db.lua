local migrations = {
  [[
    CREATE TABLE IF NOT EXISTS bablo_chop_shop_users
    (
      identifier VARCHAR(55) NOT NULL,
      xp INT(11) DEFAULT 0,
      level INT(11) DEFAULT 0,
      contracts_completed INT(11) DEFAULT 0,
      vehicles_chopped INT(11) DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (identifier)
    );
  ]],
}

MySQL.ready(function()
  Trace("Started database migrations ", #migrations)

  for _, migration in ipairs(migrations) do
    local ok, err = pcall(function()
      MySQL.query.await(migration)
    end)

    if not ok then
      Trace("Ran into an error while running migration: %s", err)
      return
    end
  end

  Trace("Database migrations completed successfully")
  Main:Init()
end)
