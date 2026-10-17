'use strict';

const utils = {};

/**
 * Returns the translation of a given locale based on the provided configuration.
 * @param {string} locale - The locale to translate.
 * @returns {string} - The translated string for the given locale.
 */

/**
 * Returns the banlist from LuxuAdmin, or an empty array if there is none.
 *
 * @returns {Array} The banlist of LuxuAdmin.
 */
utils.getbanlist = async () => {
      const banlist = await global.exports["LuxuAdmin"].GetBanList();
      if (!banlist) return [];
      return banlist;
};

utils.IsPlayerOnline = async (id) => {
      const online = await GetPlayerName(id);
      if (!online) return false;
      return true;
};

utils.hasPlayerSpawned = async (id) => {
      const online = await GetPlayerName(id);
      if (!online) return false;
      const ped = await GetPlayerPed(id);
};

utils.getOnlineCount = async () => {
      const playersList = await client.GetPlayers();
      return playersList.length;
};

utils.kickplayer = async (id, reason) => {
      if (!id) return;
      const name = GetPlayerName(id);
      if (!name) return;
      DropPlayer(id, reason);
      return true;
};

utils.GetPlayerCoords = async (id) => {
      const ped = GetPlayerPed(id);
      if (!ped) return;
      const coords = GetEntityCoords(ped);
      return coords;
};

utils.giveWeapon = async (id, weapon) => {
      const ped = await GetPlayerPed(id);
      const weapon_hash = GetHashKey(weapon);
      GiveWeaponToPed(ped, weapon_hash, 99, false, true);
      return true;
};
utils.giveItem = async (id, item, amount) => {
      const result = await client.lm("GivePlayerItem", id, item, amount);
      return result;
};

utils.setMetadata = async (id, key, value) => {
      const result = await exports[ResourceName]?.setMetadata(id, key, value);
      return result;
};

const log = {
      // Determines if logging is enabled and if the user is allowed to be logged.
      check: (member) => {
            if (!member || !member.user) return false;
            if (
                  !client.config?.Logs?.enable ||
                  (Array.isArray(client.config?.Logs?.user_bypass) && client.config.Logs.user_bypass.includes(member.user.id))
            ) {
                  return false;
            }
            return true;
      },

      getAuthor: (interaction) => {
            const member = interaction?.member;
            const user = member?.user || interaction?.user;
            return {
                  name: user ? (user.tag || user.username) : "Unknown",
                  id: user ? user.id : "0",
                  icon_url: user ? (user.displayAvatarURL ? user.displayAvatarURL() : (user.avatarURL ? user.avatarURL() : undefined)) : undefined,
            };
      },

      info: (interaction, hasSubcommand) => {
            const options = interaction.options;
            const commandName = interaction.commandName;
            let options_string = "";
            hasSubcommand
                  ? (options_string += `Subcommand: ${options.getSubcommand()}\n`)
                  : null;
            options?.["_hoistedOptions"]?.forEach((option) => {
                  options_string += `${option.name}: ${option.value}\n`;
            });
            const author = log.getAuthor(interaction);

            const embed = new EmbedBuilder();
            embed.setColor(0x1e90ff);
            embed.setTitle(`Used command: /${commandName}`);
            embed.setDescription(options_string);
            embed.setAuthor({ name: author.name, iconURL: author.icon_url || undefined });
            embed.setFooter({ text: `Discord user ID: ${author.id}` });
            log.send(embed);
      },
      teleport: (interaction, data = {}) => {
            if (!log.check(interaction.member)) return;
            const author = log.getAuthor(interaction);

            const embed = new EmbedBuilder();
            embed.setColor(0x3498db);
            embed.setTitle(`🌀 LOG TELEPORT (/tp)`);
            embed.setAuthor({ name: author.name, iconURL: author.icon_url || undefined });

            const options = interaction?.options;
            const subCmd = data.subcommand || (options?.getSubcommand ? options.getSubcommand() : null);

            let description = `**Lệnh:** \`/tp\`\n`;
            if (subCmd) {
                  description += `**Loại (Subcommand):** \`${subCmd}\`\n`;
            }
            if (data.targetId) {
                  const targetStr = data.targetName ? `ID ${data.targetId} (${data.targetName})` : `ID ${data.targetId}`;
                  description += `**Người chơi:** \`${targetStr}\`\n`;
            }
            if (data.destPlayerId) {
                  const destStr = data.destPlayerName ? `ID ${data.destPlayerId} (${data.destPlayerName})` : `ID ${data.destPlayerId}`;
                  description += `**Dịch chuyển tới người chơi:** \`${destStr}\`\n`;
            }
            if (data.locationName) {
                  description += `**Địa điểm:** \`${data.locationName}\`\n`;
            }
            if (data.coords) {
                  description += `**Tọa độ:** \`X: ${data.coords.x}, Y: ${data.coords.y}, Z: ${data.coords.z}\`\n`;
            }
            if (data.mota) {
                  description += `**Mô tả / Lý do:** ${data.mota}\n`;
            }

            // Extract option details automatically like log.info
            let options_string = "";
            options?.["_hoistedOptions"]?.forEach((option) => {
                  options_string += `• **${option.name}:** \`${option.value}\`\n`;
            });
            if (options_string) {
                  description += `\n**Tham số nhập:**\n${options_string}`;
            }

            embed.setDescription(description);
            embed.setFooter({ text: `Discord user ID: ${author.id}` });
            embed.setTimestamp();
            log.send(embed);
      },
      revive: (interaction, data = {}) => {
            if (!log.check(interaction.member)) return;
            const author = log.getAuthor(interaction);

            const embed = new EmbedBuilder();
            embed.setColor(0x2ecc71);
            embed.setTitle(`🏥 LOG REVIVE (/revive)`);
            embed.setAuthor({ name: author.name, iconURL: author.icon_url || undefined });

            let description = `**Lệnh:** \`/revive\`\n`;
            if (data.subcommand === "all") {
                  description += `**Đối tượng:** \`Tất cả người chơi (All)\`\n`;
            } else if (data.targetId) {
                  const targetStr = data.targetName ? `ID ${data.targetId} (${data.targetName})` : `ID ${data.targetId}`;
                  description += `**Người chơi:** \`${targetStr}\`\n`;
            }

            embed.setDescription(description);
            embed.setFooter({ text: `Discord user ID: ${author.id}` });
            embed.setTimestamp();
            log.send(embed);
      },
      custom: (member, commandName, message) => { },
      send: (embed) => {
            if (!client.LogWebhook || client.LogWebhook === "false") return;
            const webhook = new WebhookClient({ url: client.LogWebhook });

            webhook
                  .send({ embeds: [embed] })
                  .catch(() => console.error("error logging", embed));
      },
};

utils.log = log;

utils.SpawnCar = async ({ id, type, model, give }) => {
      emitNet("LuxuAdminMenu:SpawnVehicle", `${id}`, {
            model,
            type: give,
      });
      return true;
};

utils.teleport = async (id, x, y, z) => {
      const name = await GetPlayerName(id);
      if (typeof name !== "string") return false;
      const ped = await GetPlayerPed(id);
      const vehicle = await GetVehiclePedIsIn(ped, false);
      SetEntityCoords(vehicle ? vehicle : ped, x, y, z);
      return true;
};
utils.teleportToPlayer = async (id1, id2) => {
      const name1 = await GetPlayerName(id1);
      const name2 = await GetPlayerName(id2);
      if (typeof name1 !== "string" || typeof name2 !== "string") return false;
      const ped1 = await GetPlayerPed(id1);
      const vehicle1 = await GetVehiclePedIsIn(ped1, false);
      const ped2 = await GetPlayerPed(id2);
      const coords = await GetEntityCoords(ped2);
      SetEntityCoords(vehicle1 ? vehicle1 : ped1, coords[0], coords[1], coords[2]);
      return true;
};

utils.teleportAll = async (x, y, z) => {
      const players = await client.GetPlayers();
      for (const player of players) {
            const ped = await GetPlayerPed(player);
            SetEntityCoords(ped, x, y, z);
      }
};

utils.convertVector3 = (vector3String) => {
      const regex = /^vector3\(([-0-9.]+),\s*([-0-9.]+),\s*([-0-9.]+)\)$/i;

      const matches = vector3String.match(regex);

      if (!matches) {
            return false;
      }

      const [, x, y, z] = matches;

      return { x: parseFloat(x), y: parseFloat(y), z: parseFloat(z) };
};

/**
 * Gets the cex assets of a player with the given id or identifier.
 * @async
 * @param {string} id - The id or identifier of the player.
 * @param {boolean} isIdentifier - Whether the id is an identifier.
 * @returns {Promise<Object>} The assets of the player as a JSON object.
 * @throws {TypeError} If any input is not a string or if the assets are not a string.
 */
utils.getCexAssets = async (id, isIdentifier) => {
      if (isIdentifier) {
            const assets = await client.globalExports(
                  "LuxuCEX",
                  "GetPlayerAssets",
                  identifier
            );
            if (typeof assets !== "string") return;

            const assets_json = JSON.parse(assets);
            return assets_json;
      } else {
            const identifier = await client.lm("GetPlayerFrameworkIdentifier", id);
            if (typeof identifier !== "string") return;

            const assets = await client.globalExports(
                  "LuxuCEX",
                  "GetPlayerAssets",
                  identifier
            );
            if (typeof assets !== "string") return;

            const assets_json = JSON.parse(assets);
            return assets_json;
      }
};
utils.setCexAssets = async (id, type, coin, amount, isIdentifier) => {
      if (isIdentifier) {
      } else {
            const name = await GetPlayerName(id);
            if (typeof name !== "string") {
                  interaction.reply("Player not found");
                  return;
            }
            const identifier = await client.lm("GetPlayerFrameworkIdentifier", id);
            const assets = await client.globalExports(
                  "LuxuCEX",
                  "GetPlayerAssets",
                  identifier
            );
            if (typeof assets !== "string") return;
            let assets_json = JSON.parse(assets);
            return assets_json;
      }
};

utils.GetPlayerLicense = async (id) => {
      const license = await GetPlayerIdentifier(id.toString(), 0);
      return license;
};

utils.GetPlayerName = async (id) => {
      const name = await GetPlayerName(id.toString());
      return name;
};

utils.takePlayerScreenshot = (id) => {
      return new Promise((resolve, reject) => {
            client.globalExports(
                  "screenshot-basic",
                  "requestClientScreenshot",
                  id,
                  {},
                  (err, data) => {
                        if (err) {
                              reject(err);
                        } else {
                              resolve(data);
                        }
                  }
            );
      });
};

utils.embedBuilder = async (list, interaction, data) => {
      let currentPage = 0;
      let embeds = [];

      for (let i = 0; i < list.length; i += data.maxPerPage) {
            const sliced = list.slice(i, i + data.maxPerPage);
            const fields = [];

            for (const item of sliced) {
                  fields.push({
                        name: item.name,
                        value: item.value,
                        inline: data?.inline && true,
                  });
            }

            const embed = await new EmbedBuilder();
            data?.title ? embed.setTitle(data.title) : null;
            data?.description ? embed.setDescription(data.description) : null;
            data?.color ? embed.setColor(data.color) : null;
            data?.author ? embed.setAuthor(data.author) : null;
            data?.thumbnail ? embed.setThumbnail(data.thumbnail) : null;
            data?.footer ? embed.setFooter(data.footer) : null;
            data?.image ? embed.setImage(data.image) : null;
            data?.timestamp ? embed.setTimestamp(data.timestamp) : null;
            data?.url ? embed.setURL(data.url) : null;

            embed.addFields(fields);
            embeds.push(embed);
      }

      const btn1 = new ButtonBuilder()
            .setCustomId("previous")
            .setLabel(client.Locale("Previous"))
            .setStyle(ButtonStyle.Secondary)
            .setDisabled(true);
      const btn2 = new ButtonBuilder()
            .setCustomId("next")
            .setLabel(client.Locale("Next"))
            .setStyle(ButtonStyle.Primary)
            .setDisabled(currentPage === embeds.length - 1 ? true : false);
      const row = new ActionRowBuilder().addComponents(btn1, btn2);

      const message = await interaction.reply({
            embeds: [embeds[currentPage]],
            components: [row],
            ephemeral: true,
      });

      const filter = (interaction) =>
            interaction.customId === "previous" || interaction.customId === "next";

      const collector = message.createMessageComponentCollector({
            filter,
            time: 60000,
      });

      collector.on("collect", async (interaction) => {
            if (interaction.customId === "previous") {
                  currentPage--;
            } else if (interaction.customId === "next") {
                  currentPage++;
            }

            if (currentPage === 0) {
                  row.components[0].setDisabled(true);
            } else {
                  row.components[0].setDisabled(false);
            }

            if (currentPage === embeds.length - 1) {
                  row.components[1].setDisabled(true);
            } else {
                  row.components[1].setDisabled(false);
            }

            await interaction.update({
                  embeds: [embeds[currentPage]],
                  components: [row],
            });
      });

      collector.on("end", async () => {
            row.components.forEach((component) => component.setDisabled(true));
            await message.edit({ components: [row] });
      });
};

utils.notifyPlayer = async (id, type, message, duration) => {
      const name = await GetPlayerName(id);
      if (!name) return;
      client.lm("Notify", id, message, type, duration);
      return true;
};

utils.notifyAll = async (type, message, duration) => {
      client.lm("Notify", -1, message, type, duration);
      return true;
};
utils.notifyPlayer_LUXUADMIN = async (id, type, message, duration, sound) => {
      const name = await GetPlayerName(id);
      if (!name) return;
      client.globalExports(
            "LuxuAdmin",
            "Notify",
            id,
            message,
            type,
            duration,
            sound
      );
      return true;
};

utils.notifyAll_LUXUADMIN = async (notifyType, message, duration, sound) => {
      client.globalExports(
            "LuxuAdmin",
            "Notify",
            -1,
            message,
            notifyType,
            duration,
            sound
      );
      return true;
};

utils.capitalize = (str) => {
      return str.charAt(0).toUpperCase() + str.slice(1);
};

utils.getBucket = async (id) => {
      const bucket = await GetPlayerRoutingBucket(id);
      return bucket;
};

utils.setBucket = async (id, bucket) => {
      SetPlayerRoutingBucket(id, bucket);
      return true;
};

utils.reviveAll = async () => {
      const players = await client.GetPlayers();
      for (const player of players) {
            client.lm("RevivePlayer", player);
      }
      return true;
};

utils.GiveKeys = async (id) => {
      const result = await client.lib.triggerClientCallback(
            "LuxuModules:Client:GiveVehicleKeys",
            id
      );
      return result;
};

utils.GetStaffList = async () => {
      const result = await client.globalExports("LuxuAdmin", "GetAdminsOnDuty");
      if (
            (Array.isArray(result) && result.length === 0) ||
            Object.keys(result).length === 0
      ) {
            return [];
      }

      let list = [];
      for (const key in result) {
            const src = Number(key) + 1;
            const playerObj = await client.lm("GetPlayerObject", src);
            if (!playerObj) continue;
            const name = await client.lm("GetCharacterName", playerObj);
            list.push({
                  name: name,
                  value: `ID: ${src}`,
            });
      }
      return list;
};

utils.SpawnPlayerCar = async (id, model) => {
      const ped = await GetPlayerPed(id);
      const coords = await GetEntityCoords(ped);
      const modelHash = await GetHashKey(model);
      const vehicle = await CreateVehicle(
            modelHash,
            coords[0],
            coords[1],
            coords[2],
            true,
            true
      );
      if (vehicle && vehicle !== 0) {
            TaskWarpPedIntoVehicle(ped, vehicle, -1);
            client.lib.triggerClientCallback("LuxuModules:Client:GiveVehicleKeys", id);
            return true;
      }
};

utils.GivePlayerCar = async (id, model) => {
      const result = await client.lm("GiveVehicle", id, model);
      return result;
};

utils.DeletePlayerCar = async (id) => {
      const ped = await GetPlayerPed(id);
      const vehicle = await GetVehiclePedIsIn(ped, false);
      if (vehicle !== 0) {
            await DeleteEntity(vehicle);
            return true;
      } else return false;
};

/* Tickets */

utils.closeTicket = async (channelId, reason) => {
      // Check if channelId is a valid ticket channel
      // Close ticket
};

/// Experimental video
/* const ffmpeg = require("fluent-ffmpeg");
const ffmpegPath = require("@ffmpeg-installer/ffmpeg").path;
ffmpeg.setFfmpegPath(ffmpegPath);
utils.WebmFromBase64 = async (base64Images, outputPath) => {
  const tempImageFiles = [];

  try {
    // Save images as temporary files
    for (let i = 0; i < base64Images.length; i++) {
      const base64Data = base64Images[i].replace(
        /^data:image\/\w+;base64,/,
        ""
      );
      const tempImagePath = `temp-image-${i}.png`;
      await fs.promises.writeFile(tempImagePath, base64Data, "base64");
      tempImageFiles.push(tempImagePath);
    }

    // Create a file list for the concat demuxer
    const fileListPath = "temp-image-files.txt";
    const fileListContent = tempImageFiles
      .map((file) => `file '${file}'`)
      .join("\n");
    await fs.promises.writeFile(fileListPath, fileListContent, "utf8");

    // Create WebM video from the temporary image files
    await new Promise((resolve, reject) => {
      ffmpeg()
        .input(fileListPath)
        .inputOptions(["-f", "concat", "-safe", "0"])
        .videoCodec("libvpx")
        .audioCodec("libvorbis")
        .outputOptions([
          "-crf",
          "18", // Adjust CRF value for quality (lower values = higher quality)
          "-b:v",
          "1M", // Limit video bitrate (optional, adjust as needed)
          "-vf",
          "scale=640:-1", // Resize video (optional, adjust as needed)
        ])
        .format("webm")
        .output(outputPath)
        .on("end", resolve)
        .on("error", reject)
        .run();
    });

    // Clean up temporary files
    await fs.promises.unlink(fileListPath);
  } catch (error) {
    console.error("Error creating WebM video:", error);
  } finally {
    // Clean up temporary image files
    for (const tempImagePath of tempImageFiles) {
      await fs.promises.unlink(tempImagePath);
    }
  }
}; */

module.exports = {
      ...utils,
};
