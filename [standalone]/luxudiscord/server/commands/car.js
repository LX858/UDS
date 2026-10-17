module.exports = {
  data: {
    name: "car",
    description: "Kicks a player",
    options: [
      {
        name: "spawn",
        description: "Spawns a car for the player",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },

          {
            name: "model",
            description: "The model of the car",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
        ],
      },
      {
        name: "give",
        description: "Give vehicle to the player",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },

          {
            name: "model",
            description: "The model of the car",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
        ],
      },
      {
        name: "delete",
        description: "Deletes a players car",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
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

    const Subcommand = interaction.options.getSubcommand();
    const id = interaction.options.getNumber("id");

    const isOnline = await client.utils.IsPlayerOnline(id);
    if (!isOnline) {
      interaction.reply({
        content: `${client.Locale("PlayerNotFound")}`,
        ephemeral: true,
      });
      return;
    }

    if (Subcommand === "spawn") {
      const model = interaction.options.getString("model");
      const result = client.utils.SpawnPlayerCar(id, model);
      if (result) {
        interaction.reply({
          content: `${client.Locale("CarSpawnedSuccess")}`,
          ephemeral: true,
        });
        client.utils?.log.info(interaction, true);
      }
    } else if (Subcommand === "give") {
      const model = interaction.options.getString("model");

      const result = client.utils.GivePlayerCar(id, model);
      if (result) {
        interaction.reply({
          content: `${client.Locale("CarGivenSuccess")}`,
          ephemeral: true,
        });
        client.utils?.log.info(interaction, true);
      }
    } else if (Subcommand === "delete") {
      const result = await client.utils.DeletePlayerCar(id);
      if (result) {
        interaction.reply({
          content: `${client.Locale("CarDeletedSuccess")}`,
          ephemeral: true,
        });
        client.utils?.log.info(interaction, true);
      } else {
        interaction.reply({
          content: `${client.Locale("PlayerWasNotInCar")}`,
          ephemeral: true,
        });
      }
    }
  },
};
