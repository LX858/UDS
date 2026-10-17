module.exports = {
  data: {
    name: "remove-vip-coins",
    description: "Remove vip shop coins",
    options: [
      {
        name: "id",
        description: "The player server ID",
        type: ApplicationCommandOptionType.Number,
        required: true,
      },
      {
        name: "amount",
        description: "amount",
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

    const amount = interaction.options.getNumber("amount");

    setImmediate(() => {
      const success = global.exports["LuxuVipShop"].UpdateCoinBalance(
        id,
        amount,
        "remove"
      );

      if (success) {
        interaction.reply({
          content: `Successfully removed ${amount} vip shop coins to player with ID: ${id}`,
          ephemeral: true,
        });
      } else {
        interaction.reply({
          content: `Failed to remove vip shop coins to player with ID: ${id}`,
          ephemeral: true,
        });
      }
    });
  },
};
