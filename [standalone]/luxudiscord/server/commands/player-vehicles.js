module.exports = {
  data: {
    name: "player-vehicles",
    description: "Get all owned vehicles by a player",
    options: [
      {
        name: "id",
        description: "The player server ID",
        type: ApplicationCommandOptionType.Number,
        required: true,
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    const id = interaction.options.getNumber("id");

    const isPlayerOnline = await client.utils.IsPlayerOnline(id);

    if (!isPlayerOnline) {
      interaction.reply({
        content: `${client.Locale("PlayerNotFound")}`,
        ephemeral: true,
      });
      return;
    }

    const vehicles = await client.lm("GetOwnedVehicles", id);
    if (!vehicles || vehicles.length === 0) {
      interaction.reply({
        content: `${client.Locale("NoVehiclesFound")}`,
        ephemeral: true,
      });
      return;
    }

    const list = vehicles.map((vehicle) => {
      return {
        name: `Model: ${vehicle.vehicle}`,
        value: `Plate: ${vehicle.plate}`,
      };
    });

    const data = {
      title: `${client.Locale("PlayerVehicles")} ${id}`,
      description: `${client.Locale("TotalVehicles")}: ${
        vehicles.length
      }\n${client.Locale("PlayerVehiclesDesc")}`,
      maxPerPage: 5,
    };

    client.utils.embedBuilder(list, interaction, data);
  },
};
