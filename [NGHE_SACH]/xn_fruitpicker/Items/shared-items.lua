return {
	orange = {
		label = 'Orange',
		weight = 150,
		stack = true,
		close = true,
		description = 'Fresh orange fruit',
		client = {
			image = 'orange.png',
		}
	},

	fruit_basket = {
		label = 'Fruit Basket',
		weight = 2000,
		stack = false,
		close = true,
		description = 'A basket for collecting fruits',
		durability = 100, -- Initial durability
		degrade = 0, -- No auto-degrade, handled manually
		client = {
			image = 'fruit_basket.png',
		}
	},
}