module.exports = {
  data: {
    name: "reportinfo",
    description: "Gets information about this report",
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;

    const channelID = interaction.channel.id;

    try {
      const reports = await LoadReports();

      const report = await reports.find((r) => r.discord_channel === channelID);

      if (!report) {
        interaction.reply({
          content: `${client.Locale("ThisIsNotAReportChannel")}`,
          ephemeral: true,
        });
        return;
      }

      const playerInfo = await client.GetPlayerInfoFromReport(report);

      const embed = new EmbedBuilder();
      embed.setTitle(`${client.Locale("ReportInfo")}`);
      embed.addFields([
        {
          name: client.Locale("name"),
          value: playerInfo.name,
        },
        {
          name: client.Locale("license"),
          value: playerInfo.license,
        },
        {
          name: client.Locale("status"),
          value: client.Locale(playerInfo.status),
        },
        {
          name: client.Locale("id"),
          value: `${playerInfo.id}` || "null",
        },
      ]);

      interaction.reply({
        embeds: [embed],
        ephemeral: true,
      });
    } catch (e) {
      console.error("Error getting report info", e);
    }
  },
};
