module.exports = {
  data: {
    name: "money",
    description: "Manage player money accounts",
    options: [
      {
        name: "modify",
        description: "The player server ID",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
          {
            name: "account",
            description: "The account to modify",
            type: ApplicationCommandOptionType.String,
            required: true,
            choices: GetMoneyAccounts(),
          },
          {
            name: "operation",
            description: "The operation to perform",
            type: ApplicationCommandOptionType.String,
            required: true,
            choices: [
              {
                name: client.Locale("Add"),
                value: "add",
              },
              {
                name: client.Locale("Remove"),
                value: "remove",
              },
              {
                name: client.Locale("Set"),
                value: "set",
              },
            ],
          },
          {
            name: "amount",
            description: "The amount to modify",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
        ],
      },
      {
        name: "check",
        description: "Check the players accounts",
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
    const id = interaction.options.getNumber("id");

    const subCommand = interaction.options.getSubcommand();
    if (subCommand === "modify") {
      const operation = interaction.options.getString("operation");
      const account = interaction.options.getString("account");
      const amount = interaction.options.getNumber("amount");

      const result = await client.lm(
        "SetAccountMoney",
        id,
        account,
        operation,
        amount
      );
      if (result) {
        interaction.reply({
          content: `${client.Locale("PlayerMoneyChanged")}`,
          ephemeral: true,
        });
        client.utils.log.info(interaction, true);
      } else {
        interaction.reply({
          content: `${client.Locale("AccountNotFound")}`,
          ephemeral: true,
        });
      }
    } else if (subCommand === "check") {
      const accounts = await client.lm("GetPlayerAccounts", id);
      if (!accounts) {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
        return;
      }
      const list = accounts.map((account) => {
        return {
          name: account.name,
          value: `${account.money}`,
        };
      });

      const data = {
        title: `${client.Locale("PlayerMoneyAccounts")}`,
        description: `${client.Locale("PlayerMoneyAccountsDesc")}`,
        maxPerPage: 3,
      };

      client.utils.embedBuilder(list, interaction, data);
    }
  },
};
function GetMoneyAccounts() {
  const list = Object.values(client.config?.Accounts).map((acc) => {
    return {
      name: acc,
      value: acc,
    };
  });
  return list;
}
