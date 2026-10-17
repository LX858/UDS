module.exports = {
  data: {
    name: "plate",
    description: "Check vehicle plate",
    options: [
      {
        name: "check",
        description: "Check vehicle plate",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "plate",
            description: "The vehicle plate",
            type: ApplicationCommandOptionType.String,
            required: true,
            maxLength: 12,
          },
        ],
      },
      {
        name: "get",
        description: "Get a vehicle plate from the players server ID",
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

    const subCommand = interaction.options.getSubcommand();

    if (subCommand === "check") {
      const plate = interaction.options.getString("plate");

      const result = await client.lm("GetVehicleInfoByPlate", plate);

      if (!result) {
        interaction.reply({
          content: `${client.Locale("VehicleNotFound")}`,
          ephemeral: true,
        });
        return;
      }

      const { name, vehicle } = result;

      interaction.reply({
        content: `Owner: ${name}\nVehicle: ${vehicle}`,
        ephemeral: true,
      });
    } else if (subCommand === "get") {
      const id = interaction.options.getNumber("id");

      const isOnline = await client.utils.IsPlayerOnline(id);
      if (!isOnline) {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
        return;
      }
      const plate = await client.lib.triggerClientCallback(
        "LuxuModules:Client:GetVehiclePlate",
        id
      );

      if (plate) {
        interaction.reply({
          content: `${plate}`,
          ephemeral: true,
        });
      } else {
        interaction.reply({
          content: `${client.Locale("VehicleNotFound")}`,
          ephemeral: true,
        });
      }
    }
  },
};
