module.exports = {
      data: {
            name: "price",
            description: "Get the price of a cryptocurrency",
            options: [
                  {
                        name: "id",
                        description: "the coin id",
                        type: ApplicationCommandOptionType.String,
                        required: true,
                  },
            ],
      },
      async execute(client, interaction) {
            const hasPerm = await client.checkPermission(interaction, this.data.name);
            if (!hasPerm) return;
            const id = interaction.options.getString("id").toLowerCase();
            const coin = client.coins.find((coin) => {
                  if (
                        coin.value.toLowerCase() === id ||
                        coin.name.toLowerCase() === id ||
                        coin.symbol.toLowerCase() === id
                  )
                        return true;
            });
            if (!coin) {
                  interaction.reply({
                        content: `${client.Locale("CoinNotFound")}`,
                  });
                  return;
            }
            try {
                  const coinID = coin.value;
                  const result = await axios.get(
                        `https://api.coingecko.com/api/v3/coins/${coinID}`
                  );

                  const data = result?.data;

                  if (data) {
                        const colors = {
                              green: 5763719,
                              red: 15548997,
                        };
                        const date = new Date();
                        const date_string = `${date.getDate()}-${date.getMonth()}-${date.getFullYear()}`;
                        const time = `${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`;
                        const coin = {
                              name: data.name,
                              symbol: data.symbol,
                              value: this.formatCurrency(data.market_data.current_price.usd),
                              image: data.image.large,
                              "24h_change": data.market_data.price_change_percentage_24h,
                              "30d_change": data.market_data.price_change_percentage_30d,
                        };

                        const embed = new EmbedBuilder()
                              .setTitle(`${coin.name}`)
                              .setThumbnail(coin.image)
                              .setDescription(
                                    coin["24h_change"] > 0
                                          ? `${coin.name} is up in the last 24 hours.`
                                          : `${coin.name} is down in the last 24 hours.`
                              )
                              .setColor(coin["24h_change"] > 0 ? colors.green : colors.red)
                              .addFields(
                                    { name: "Symbol", value: coin.symbol },
                                    {
                                          name: "Current Price",
                                          value: coin.value,
                                    },
                                    {
                                          name: "24h change",
                                          value: `${coin["24h_change"].toFixed(2)}%`,
                                    },
                                    {
                                          name: "30d change",
                                          value: `${coin["30d_change"].toFixed(2)}%`,
                                    }
                              )
                              .setFooter({
                                    text: `Date: ${date_string} | Time: ${time}`,
                              });
                        //
                        interaction.reply({
                              embeds: [embed],
                        });
                  } else {
                        interaction.reply({
                              content: `${client.Locale("CoinNotFound")}`,
                        });
                  }
            } catch (e) {
                  console.error(e);
            }
      },
      formatCurrency: (value) => {
            return new Intl.NumberFormat("en-US", {
                  style: "currency",
                  maximumFractionDigits: 8,
                  currency: "USD",
            }).format(value);
      },
};
