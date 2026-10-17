/**
 * @typedef {Object} UserData
 * @property {string} name - The FiveM name.
 * @property {string} characterName - The character's name.
 * @property {string} identifier - The unique identifier.
 * @property {Object} job - The job information.
 * @property {Array} accounts - The user's accounts.
 * @property {number} bucket - The bucket number.
 * @property {Array} identifiers - The array of identifiers.
 */

// Use the UserData type for a function parameter,

module.exports = {
  data: {
    name: "player",
    description: "Show detailed information about a player",
    options: [
      {
        name: "info",
        description: "Get info about a player",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The ID of the player",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
        ],
      },
      {
        name: "coords",
        description: "Get coords of a player",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The ID of the player",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
        ],
      },
    ],
  },

  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;

    const subCommand = interaction.options.getSubcommand();
    const id = interaction.options.getNumber("id");

    if (subCommand === "coords") {
      const coords = await client.utils.GetPlayerCoords(id);
      if (!coords) {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
        return;
      }
      interaction.reply({
        content: `vector3(${coords[0].toFixed(2)}, ${coords[1].toFixed(
          2
        )}, ${coords[2].toFixed(2)})`,
        ephemeral: true,
      });
    } else if (subCommand === "info") {
      const playerMug = await client.GetMugshot(id);
      if (!playerMug) {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
        return;
      }

      /** @type {UserData}  */
      const playerData = await client.lm("GetPlayerData", id);

      if (!playerData) {
        interaction.reply({
          content: `${client.Locale("PlayerNotSpawned")}`,
          ephemeral: true,
        });
        return;
      }

      if (typeof playerData === "string") {
        playerData = JSON.parse(playerData);
      }

      try {
        const bufferImage = new Buffer.from(playerMug.split(",")[1], "base64");
        const attachment = new AttachmentBuilder(bufferImage, {
          name: "mugshot.jpg",
        });

        const embed = new EmbedBuilder()
          .setTitle(`${client.Locale("PlayerInfo")}`)
          .setThumbnail("attachment://mugshot.jpg")
          .setColor("Blue")
          .addFields({
            name: "Server ID",
            value: `${id}`,
          });

        Object.keys(playerData).forEach((key) => {
          const value = playerData[key];
          if (key === "accounts") {
            for (const account of value) {
              embed.addFields({
                name: client.utils.capitalize(account.name),
                value: `${account.money}`,
                inline: true,
              });
            }
          } else if (key === "bucket") {
            embed.addFields({
              name: `Routing Bucket`,
              value: `${value}`,
            });
          } else if (key === "job") {
            embed.addFields({
              name: `Job: ${value.name}`,
              value: `Grade: ${value.grade}`,
            });
          } else if (key === "identifiers") {
            Object.values(value).forEach((identifier) => {
              embed.addFields({
                name: "Identifier",
                value: `${identifier}`,
                inline: true,
              });
            });
          } else {
            embed.addFields({
              name: client.utils.capitalize(key),
              value: `${value}`,
            });
          }
        });

        interaction.reply({
          embeds: [embed],
          ephemeral: true,
          files: [attachment],
        });
      } catch (e) {
        console.log("Error getting player data", e);
      }
    }
  },
};
