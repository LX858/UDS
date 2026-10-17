module.exports = {
  data: {
    name: "cex",
    description: client.Locale("ManagePlayerCryptoAssets"),
    options: [
      {
        name: "server-id",
        description: client.Locale("ThePlayerOnlineServerID"),
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: client.Locale("TheChosenId"),
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
          {
            name: "type",
            description: client.Locale("TheTypeOfOperation"),
            type: ApplicationCommandOptionType.String,
            required: true,
            choices: [
              {
                name: client.Locale("Get"),
                value: "get",
              },
              {
                name: client.Locale("Set"),
                value: "set",
              },
              {
                name: client.Locale("Add"),
                value: "add",
              },
              {
                name: client.Locale("Remove"),
                value: "remove",
              },
            ],
          },
          {
            name: "coin",
            description: client.Locale("TheCoinSymbol"),
            type: ApplicationCommandOptionType.String,
            required: true,
          },
          {
            name: "amount",
            description: client.Locale("TheAmountOfCoins"),
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
        ],
      },
      {
        name: "identifier",
        description: "Identifier: QB | ESX",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: client.Locale("ThePlayerIdentifier"),
            type: ApplicationCommandOptionType.String,
            required: true,
          },
          {
            name: "type",
            description: client.Locale("TheTypeOfOperation"),
            type: ApplicationCommandOptionType.String,
            required: true,
            choices: [
              {
                name: client.Locale("Get"),
                value: "get",
              },
              {
                name: client.Locale("Set"),
                value: "set",
              },
              {
                name: client.Locale("Add"),
                value: "add",
              },
              {
                name: client.Locale("Remove"),
                value: "remove",
              },
            ],
          },
          {
            name: "coin",
            description: client.Locale("TheCoinSymbol"),
            type: ApplicationCommandOptionType.String,
            required: true,
          },
          {
            name: "amount",
            description: client.Locale("TheAmountOfCoins"),
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
    const type = interaction.options.getString("type");
    const coin = interaction.options.getString("coin").toUpperCase();
    const amount = interaction.options.getNumber("amount");

    const isIdentifier = subCommand === "identifier";

    const id = isIdentifier
      ? interaction.options.getString("id")
      : interaction.options.getNumber("id");

    if (type === "get") {
      const assets = await client.utils.getCexAssets(id, isIdentifier);

      if (!assets) {
        interaction.reply({
          content: client.Locale("PlayerNotFound"),
          ephemeral: true,
        });
        return;
      }

      let list;

      if (coin === "ALL" || coin === "EVERYTHING") {
        list = Object.keys(assets).map((key) => ({
          name: key,
          value: assets[key].toFixed(8),
        }));
      } else {
        const asset = assets[coin];
        if (typeof asset !== "number") {
          interaction.reply({
            content: client.Locale("AssetNotFound"),
            ephemeral: true,
          });
          return;
        }
        list = [
          {
            name: coin,
            value: assets[coin].toFixed(8) || 0,
          },
        ];
      }

      const data = {
        title: `Player ${id} CEX Assets`,
        description: client.Locale("AListOfPlayersCEXAssets"),
        color: 0x1e90ff,
        inline: true,
        maxPerPage: 3,
      };

      client.utils.embedBuilder(list, interaction, data);
    } else {
      const assets = await client.utils.setCexAssets(
        id,
        type,
        coin,
        amount,
        isIdentifier
      );

      if (!assets) {
        interaction.reply({
          content: client.Locale("PlayerAssetsNotFound"),
          ephemeral: true,
        });
        return;
      }

      if (coin === "all") {
      }
    }
  },
};
