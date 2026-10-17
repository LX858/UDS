// Used when the player creates a report ingame
async function CreateReportChannel(reportData, discordID, name) {
  const guild = await client.guilds.cache.get(client.GUILD_ID);

  let userID;
  if (discordID) {
    const id = discordID.replace("discord:", "");
    userID = await guild.members.fetch(id);
    if (!userID) throw new Error("User not found");
  }

  // Create a channel with the corrected syntax for options
  const newChannel = await client.guild.channels.create({
    name: `Report - ${name}`,
    type: ChannelType.GuildText,
    parent: client.ReportsCategoryID,
  });

  const embed = new EmbedBuilder();

  const message = reportData?.messages[0]?.message;

  embed.setTitle(client.Locale("PlayerMessage"));
  embed.setDescription(message);
  embed.setColor("Blue");
  embed.setTimestamp();
  embed.addFields([
    {
      name: client.Locale("By"),
      value: name,
    },
    {
      name: client.Locale("From"),
      value: client.Locale("FromValue"),
    },
  ]);

  newChannel.send({
    embeds: [embed],
  });

  try {
    // Add player to the report
    if (userID) {
      newChannel.permissionOverwrites.create(userID, {
        ViewChannel: true,
      });
    }
    // Add STAFF to the report
    for (const group of client.config.Permissions) {
      const role = await guild.roles.fetch(group.role_id);
      if (!role) continue;
      newChannel.permissionOverwrites.create(role.id, {
        ViewChannel: true,
      });
    }
    // Return channel id

    return newChannel.id;
  } catch (e) {
    console.error("Failed to create channel", e);
  }
}

async function ReplyToReportOnDiscord(channelID, content, source, name) {
  try {
    const channel = await client.channels.fetch(channelID);
    if (!channel) throw new Error("Channel not found");

    const embed = new EmbedBuilder();

    embed.setTitle(
      source === "admin"
        ? client.Locale("StaffMessage")
        : client.Locale("PlayerMessage")
    );
    embed.setDescription(content.message);
    embed.setColor(source === "admin" ? "Red" : "Blue");
    embed.setTimestamp();
    embed.addFields([
      {
        name: client.Locale("By"),
        value: name,
      },
      {
        name: client.Locale("From"),
        value: client.Locale("FromValue"),
      },
    ]);

    await channel.send({
      embeds: [embed],
    });
  } catch (e) {
    console.error("Failed to reply to ticket", e);
  }
}

async function LoadReports() {
  try {
    const result = await LoadResourceFile(
      "LuxuAdmin",
      "./database/reports.json"
    );
    const reports = await JSON.parse(result);
    return reports;
  } catch (e) {
    console.error("Error Loading reports from LuxuAdmin", e);
  }
}

function SaveReports(reports) {
  try {
    SaveResourceFile(
      GetCurrentResourceName(),
      "./database/reports.json",
      JSON.stringify(reports),
      -1
    );
  } catch (e) {
    console.error("Error saving reports", e);
  }
}
/**
 * Handles a message received by the bot and sends it to the appropriate report channel.
 * @param {Object} message - The message object received by the bot.
 * @returns {void} - This function does not return anything.
 */
async function handleMessage(message) {
  const content = message.content;
  const channeldID = message.channel.id;
  const author_discordID = message.author.id;
  /*  */
  const reports = await LoadReports();
  if (!reports) return;
  const report = reports.find((r) => r.discord_channel === channeldID);
  if (!report) return;

  if (`${author_discordID}` === report.discordID.replace("discord:", "")) {
    /* Create Report Message as player */
    client.globalExports(
      "LuxuAdmin",
      "SendMessageToReport",
      report.id,
      content,
      "player"
    );
  } else {
    /* Create Report Message as staff */
    client.globalExports(
      "LuxuAdmin",
      "SendMessageToReport",
      report.id,
      content,
      "admin"
    );
  }
}

/**
 * Gets player information from a report.
 * @async
 * @param {Object} report - The report object containing player information.
 * @param {string} report.license - The license of the player.
 * @param {string} report.playerName - The name of the player.
 * @returns {Object} An object containing player information.
 * @returns {string} returns.name - The name of the player.
 * @returns {string} returns.license - The license of the player.
 * @returns {string} returns.status - The status of the player, either "online" or "offline".
 * @returns {Object} returns.id - The id of the player if the player is online, otherwise null.
 */
async function GetPlayerInfoFromReport(report) {
  const license = report.license;
  const name = report.player_name;

  // check if player is online
  const player_list = await exports[ResourceName].GetPlayers();

  let playerID;
  for (const player of player_list) {
    const playerLicense = GetPlayerIdentifierByType(player, "license");
    if (playerLicense === license) {
      playerID = player;
      break;
    }
  }

  if (!playerID) return { name, license, status: "offline" };

  return { name, license, status: "online", id: playerID };
}

async function DeleteReportChannelFromDiscord(channelID) {
  try {
    const guild = await client.guilds.cache.get(client.GUILD_ID);
    const channel = await guild.channels.fetch(channelID);
    if (!channel) throw new Error("Channel not found");
    channel.send({
      content: client.Locale("ClosingReportSuccess"),
    });
    setTimeout(() => channel.delete(), 5000);
  } catch (e) {
    console.error("Failed to delete report channel", e);
  }
}

exports("CreateReportChannel", CreateReportChannel);
exports("ReplyToReportOnDiscord", ReplyToReportOnDiscord);
exports("DeleteReportChannelFromDiscord", DeleteReportChannelFromDiscord);
