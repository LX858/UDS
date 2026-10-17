module.exports = {
  data: {
    name: "unban",
    description: client.Locale("UnBanPlayer"),
    options: [
      {
        name: "identifier",
        description: "The chosen identifier",
        type: ApplicationCommandOptionType.String,
        required: true,
      },
    ],
  },
  async execute(client, interaction) {
    const authorName = interaction.member.user.tag;
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;

    const identifier = interaction.options.getString("identifier");
    try {
      const result = await client.globalExports(
        "LuxuAdmin",
        "RemoveBanByLicense",
        identifier,
        authorName
      );
      if (result) {
        interaction.reply({
          content: `${client.Locale("UnBanPlayerSuccess")}`,
          ephemeral: true,
        });
        client.utils?.log.info(interaction, false);
      } else {
        interaction.reply({
          content: `${client.Locale("UnBanPlayerFailed")}`,
          ephemeral: true,
        });
      }
    } catch (e) {
      console.error("Error banning player", e);
    }
  },
};
