module.exports = {
  data: {
    name: "command",
    description: "Execute a command on the server",
    options: [
      {
        name: "name",
        description: "The command name",
        type: ApplicationCommandOptionType.String,
        required: true,
      },
      {
        name: "args",
        description: "Command arguments",
        type: ApplicationCommandOptionType.String,
        required: false,
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;

    const name = interaction.options.getString("name").replace(" ", "");
    const args = interaction.options.getString("args");

    setImmediate(() => {
      if (args) {
        ExecuteCommand(`${name} ${args}`);
      } else {
        ExecuteCommand(`${name}`);
      }
    });

    interaction.reply({
      content: `Executing command: ${name} ${args || ""}`,
      ephemeral: true,
    });

    client.utils.log.info(interaction, false);
  },
};
