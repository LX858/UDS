module.exports = {
  data: {
    name: "ban",
    description: client.Locale("ShowsBanlist"),
    options: [
      {
        name: "identifier-type",
        description: "The player identifier type",
        type: ApplicationCommandOptionType.String,
        required: true,
        choices: [
          {
            name: "server ID",
            value: "svid",
          },
          {
            name: "identifier | e.g (license:43214141)",
            value: "license",
          },
        ],
      },
      {
        name: "identifier",
        description: client.Locale("ChosenIdentifier"),
        type: ApplicationCommandOptionType.String,
        required: true,
      },
      {
        name: "reason",
        description: client.Locale("BanReason"),
        type: ApplicationCommandOptionType.String,
        required: true,
      },
      {
        name: "duration",
        description: `${client.Locale(
          "DurationOfTheBanCanBe"
        )} 1 y | 1M | 1w | 1d | 1h | 1m | 1s || Example: 1d`,
        type: ApplicationCommandOptionType.String,
        required: true,
      },
    ],
  },
  async execute(client, interaction) {
    const authorName = interaction.member.user.tag;
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    try {
      const identifierType = interaction.options.getString("identifier-type");
      const identifier = interaction.options.getString("identifier");
      const reason = interaction.options.getString("reason");
      const duration = parseDuration(interaction.options.getString("duration")); // ms;

      const expiration = Math.round(duration / 1000);

      if (identifierType == "svid") {
        const id = Number(identifier);
        const isOnline = await client.utils.IsPlayerOnline(id);
        if (!isOnline) {
          interaction.reply({
            content: client.Locale("PlayerNotFound"),
            ephemeral: true,
          });
          return;
        }
        const license = await client.utils.GetPlayerLicense(id);
        const playerName = await client.utils.GetPlayerName(id);

        client.globalExports(
          "LuxuAdmin",
          "ManualBan",
          license,
          reason,
          expiration,
          authorName,
          playerName
        );

        if (playerName) {
          setImmediate(() => {
            DropPlayer(id.toString(), reason);
          });
        }

        const embed = new EmbedBuilder()
          .setColor("Green")
          .setTitle(client.Locale("PlayerBanned"))
          .addFields(
            {
              name: client.Locale("License"),
              value: license,
            },
            {
              name: client.Locale("Reason"),
              value: reason,
            },
            {
              name: client.Locale("Expires"),
              value: new Date(duration).toLocaleString(),
            }
          );

        interaction.reply({
          embeds: [embed],
          ephemeral: true,
        });
      } else {
        client.globalExports(
          "LuxuAdmin",
          "ManualBan",
          identifier,
          reason,
          expiration,
          authorName,
          "Unknown"
        );

        const embed = new EmbedBuilder()
          .setColor("Green")
          .setTitle(client.Locale("PlayerBanned"))
          .addFields(
            {
              name: client.Locale("License"),
              value: identifier,
            },
            {
              name: client.Locale("Reason"),
              value: reason,
            },
            {
              name: client.Locale("Expires"),
              value: new Date(duration).toLocaleString(),
            }
          );

        interaction.reply({
          embeds: [embed],
          ephemeral: true,
        });
      }

      client.utils?.log.info(interaction, false);
    } catch (e) {
      console.error("Error banning player", e);
    }
  },
};

/**
 * Parses a duration string into a Date object.
 *
 * @param {string} durationString - The duration string to parse.
 * @returns {Date} The date that is the given duration from now.
 */
function parseDuration(durationString) {
  const durationRegex = /(\d+)\s*([yMwdhms])/g;
  let match = durationRegex.exec(durationString);
  let totalMilliseconds = 0;

  while (match !== null) {
    const [, amountString, unit] = match;
    const amount = parseInt(amountString);

    switch (unit) {
      case "y":
        totalMilliseconds += amount * 365 * 24 * 60 * 60 * 1000;
        break;
      case "M":
        totalMilliseconds += amount * 30 * 24 * 60 * 60 * 1000;
        break;
      case "w":
        totalMilliseconds += amount * 7 * 24 * 60 * 60 * 1000;
        break;
      case "d":
        totalMilliseconds += amount * 24 * 60 * 60 * 1000;
        break;
      case "h":
        totalMilliseconds += amount * 60 * 60 * 1000;
        break;
      case "m":
        totalMilliseconds += amount * 60 * 1000;
        break;
      case "s":
        totalMilliseconds += amount * 1000;
        break;
      default:
        throw new Error("Invalid duration string");
    }

    match = durationRegex.exec(durationString);
  }

  return new Date(Date.now() + totalMilliseconds).getTime();
}
