module.exports = {
  data: {
    name: "txid",
    description: "Check a tebex transaction id",
    options: [
      {
        name: "transaction",
        description: "The transaction id | e.g tbx-52012223a241419z-b8c764",
        type: ApplicationCommandOptionType.String,
        required: true,
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    const transaction = await interaction.options.getString("transaction");
    try {
      const result = await axios.get(
        `https://plugin.tebex.io/payments/${transaction}`,
        {
          headers: {
            "X-Tebex-Secret": client.TEBEX_SECRET,
          },
        }
      );
      const data = result.data;
      const date = new Date(data.date).toLocaleDateString();
      const player = data?.player;

      const fields = data?.packages?.map((p) => {
        return { name: p.name, value: `Quantity: ${p.quantity}` };
      });

      const embed = new EmbedBuilder().setTitle(
        `Transaction ID: ${transaction}`
      );
      embed.setDescription(
        `**Status**: ${data.status}\n**Date**: ${date}\n**Player**: ${
          player?.name
        }\n**Notes**: ${
          data.notes.lenght > 0 ? JSON.stringify(data.notes) : "None"
        }\n**Packages** 👇`
      );
      embed.addFields(fields);

      interaction.reply({
        embeds: [embed],
        ephemeral: true,
      });
    } catch (e) {
      console.error("Error getting transaction info", e);
      interaction.reply({
        content: client.Locale("TransactionNotFound"),
      });
    }
  },
};
