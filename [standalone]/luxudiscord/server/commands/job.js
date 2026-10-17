module.exports = {
  data: {
    name: "job",
    description: "Change or check a player's job",
    options: [
      {
        name: "check",
        description: "Check the players current bucket",
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
      {
        name: "set",
        description: "Change the players current bucket",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
          {
            name: "job-name",
            description: "The job name",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
          {
            name: "job-level",
            description: "The job level/grade, if you don't know, just put 0",
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
    const id = interaction.options.getNumber("id");
    const subCommand = interaction.options.getSubcommand();

    const isOnline = await client.utils.IsPlayerOnline(id);
    if (!isOnline) {
      interaction.reply({
        content: `${client.Locale("PlayerNotFound")}`,
        ephemeral: true,
      });
      return;
    }

    const playerObj = await client.lm("GetPlayerObject", id);
    if (!playerObj) {
      interaction.reply({
        content: `${client.Locale("PlayerNotFound")}`,
        ephemeral: true,
      });
      return;
    }

    const resourceName = client.ResourceName;
    const data = await client.globalExports(
      resourceName,
      "GetPlayerJob",
      playerObj
    );

    const currentJob = data.name;

    if (subCommand === "check") {
      interaction.reply({
        content: `Player ${id} current job: ${currentJob}`,
        ephemeral: true,
      });
    } else if (subCommand === "set") {
      const newJob = interaction.options.getString("job-name");
      const newLevel = interaction.options.getNumber("job-level");
      const result = await client.globalExports(
        resourceName,
        "SetPlayerJob",
        playerObj,
        newJob,
        newLevel
      );

      if (result) {
        interaction.reply({
          content: `Player ${id} job changed from ${currentJob} to ${newJob}`,
          ephemeral: true,
        });
      } else {
        interaction.reply({
          content: `Failed updating player job`,
          ephemeral: true,
        });
      }

      client.utils.log.info(interaction, true);
    }
  },
};
