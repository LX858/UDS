function GetPlayerIdentifierArray(src) {
  let identifiers = [];
  for (let i = 0; i < GetNumPlayerIdentifiers(src); i++) {
    const identifier = GetPlayerIdentifier(src, i);

    identifiers.push(identifier);
  }
  return identifiers;
}

on("playerConnecting", async (name, setKickReason, deferrals) => {
  // whitelist
  if (Config?.Whitelist?.enable) {
    deferrals.defer();

    const identifiers = await GetPlayerIdentifierArray(global.source);
    const allowed_identifiers = Config?.Whitelist?.user_bypass;

    const canEnter = await identifiers.some((identifier) => {
      return allowed_identifiers.includes(identifier);
    });
    if (!canEnter) {
      CancelEvent();
      setKickReason("You are not whitelisted");
    } else {
      deferrals.done();
    }

    // discord checker
  } else if (Config?.DiscordChecker?.enabled) {
    deferrals.defer();

    let discord;
    for (let i = 0; i < GetNumPlayerIdentifiers(source); i++) {
      const identifier = GetPlayerIdentifier(source, i);
      if (
        Config?.DiscordChecker?.whitelisted_identifiers.includes(identifier)
      ) {
        deferrals.done();
        return;
      }
      if (identifier.includes("discord:")) {
        discord = identifier.replace("discord:", "");
      }
    }
    if (!discord) {
      CancelEvent();
      setKickReason(client.locale("DiscordAccountNotFound"));
    }
    let guild = client.guilds.cache.get(client.GUILD_ID);
    const members = await guild.members.fetch();

    if (members.has(discord)) {
      deferrals.done();
    } else {
      CancelEvent();
      setKickReason(client.locale("DiscordNotConnectToServer"));
    }
  }
});
