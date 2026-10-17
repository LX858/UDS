module.exports = {
  data: {
    name: "close",
    description: "Closes this ticket",
    options: [
      {
        name: "reason",
        description: "Close reason",
        type: ApplicationCommandOptionType.String,
        required: true,
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    const reason = interaction.options.getString("reason");
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

      const reportID = report.id;

      const result = await client.globalExports(
        "LuxuAdmin",
        "CloseReport",
        reportID,
        reason
      );

      if (result) {
        interaction.reply({
          content: `${client.Locale("ClosingReportSuccess")}`,
          ephemeral: true,
        });
        /* LogMessages(interaction.channel, () => {
          setTimeout(() => {
            interaction.channel.delete();
          }, 5000);
        }); */
        setTimeout(() => {
          interaction.channel.delete();
        }, 5000);

        client.utils?.log.info(interaction, false);
      } else {
        interaction.reply({
          content: `${client.Locale("ClosingReportFailed")}`,
          ephemeral: true,
        });
      }
    } catch (e) {
      console.error("Error closing report", e);
    }
  },
};

// work in progress
/* async function LogMessages(channel, cb) {
  const messages = await channel.messages.fetch();
  messages.forEach((m) => {
    console.log(m);
  });

  if (typeof cb === "function") cb();
}
 */
