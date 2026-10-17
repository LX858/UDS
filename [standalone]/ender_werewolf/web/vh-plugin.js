const plugin = require('tailwindcss/plugin')

// Viewport height conversion (base: 1080px)
const vhConverter = (px) => `${((px / 1080) * 100).toFixed(3)}vh`

// Generate VH-based spacing scale
const generateVhSpacing = () => {
	const spacingValues = {
		0: '0',
		0.5: `${vhConverter(2)} /* 2px */`,
		1: `${vhConverter(4)} /* 4px */`,
		1.5: `${vhConverter(6)} /* 6px */`,
		2: `${vhConverter(8)} /* 8px */`,
		2.5: `${vhConverter(10)} /* 10px */`,
		3: `${vhConverter(12)} /* 12px */`,
		3.5: `${vhConverter(14)} /* 14px */`,
		4: `${vhConverter(16)} /* 16px */`,
		5: `${vhConverter(20)} /* 20px */`,
		6: `${vhConverter(24)} /* 24px */`,
		7: `${vhConverter(28)} /* 28px */`,
		8: `${vhConverter(32)} /* 32px */`,
		9: `${vhConverter(36)} /* 36px */`,
		10: `${vhConverter(40)} /* 40px */`,
		11: `${vhConverter(44)} /* 44px */`,
		12: `${vhConverter(48)} /* 48px */`,
		14: `${vhConverter(56)} /* 56px */`,
		16: `${vhConverter(64)} /* 64px */`,
		20: `${vhConverter(80)} /* 80px */`,
		24: `${vhConverter(96)} /* 96px */`,
		28: `${vhConverter(112)} /* 112px */`,
		32: `${vhConverter(128)} /* 128px */`,
		36: `${vhConverter(144)} /* 144px */`,
		40: `${vhConverter(160)} /* 160px */`,
		44: `${vhConverter(176)} /* 176px */`,
		48: `${vhConverter(192)} /* 192px */`,
		52: `${vhConverter(208)} /* 208px */`,
		56: `${vhConverter(224)} /* 224px */`,
		60: `${vhConverter(240)} /* 240px */`,
		64: `${vhConverter(256)} /* 256px */`,
		72: `${vhConverter(288)} /* 288px */`,
		80: `${vhConverter(320)} /* 320px */`,
		96: `${vhConverter(384)} /* 384px */`
	}
	return spacingValues
}

// Generate VH-based font sizes
const generateVhFontSizes = () => {
	return {
		xs: [`${vhConverter(12)} /* 12px */`, { lineHeight: `${vhConverter(16)} /* 16px */` }],
		sm: [`${vhConverter(14)} /* 14px */`, { lineHeight: `${vhConverter(20)} /* 20px */` }],
		base: [`${vhConverter(16)} /* 16px */`, { lineHeight: `${vhConverter(24)} /* 24px */` }],
		lg: [`${vhConverter(18)} /* 18px */`, { lineHeight: `${vhConverter(28)} /* 28px */` }],
		xl: [`${vhConverter(20)} /* 20px */`, { lineHeight: `${vhConverter(28)} /* 28px */` }],
		'2xl': [`${vhConverter(24)} /* 24px */`, { lineHeight: `${vhConverter(32)} /* 32px */` }],
		'3xl': [`${vhConverter(30)} /* 30px */`, { lineHeight: `${vhConverter(36)} /* 36px */` }],
		'4xl': [`${vhConverter(36)} /* 36px */`, { lineHeight: `${vhConverter(40)} /* 40px */` }],
		'5xl': [`${vhConverter(48)} /* 48px */`, { lineHeight: '1' }],
		'6xl': [`${vhConverter(60)} /* 60px */`, { lineHeight: '1' }],
		'7xl': [`${vhConverter(72)} /* 72px */`, { lineHeight: '1' }],
		'8xl': [`${vhConverter(96)} /* 96px */`, { lineHeight: '1' }],
		'9xl': [`${vhConverter(128)} /* 128px */`, { lineHeight: '1' }]
	}
}

// Generate VH-based width sizing
const generateVhWidthSizing = () => {
	const spacing = generateVhSpacing()
	return {
		...spacing,
		auto: 'auto',
		// Tailwind preset width keys (xs, sm, md, lg, xl, 2xl)
		xs: vhConverter(320), // 20rem
		sm: vhConverter(384), // 24rem
		md: vhConverter(448), // 28rem
		lg: vhConverter(512), // 32rem
		xl: vhConverter(576), // 36rem
		'2xl': vhConverter(672), // 42rem
		'1/2': '50%',
		'1/3': '33.333333%',
		'2/3': '66.666667%',
		'1/4': '25%',
		'2/4': '50%',
		'3/4': '75%',
		'1/5': '20%',
		'2/5': '40%',
		'3/5': '60%',
		'4/5': '80%',
		'1/6': '16.666667%',
		'2/6': '33.333333%',
		'3/6': '50%',
		'4/6': '66.666667%',
		'5/6': '83.333333%',
		'1/12': '8.333333%',
		'2/12': '16.666667%',
		'3/12': '25%',
		'4/12': '33.333333%',
		'5/12': '41.666667%',
		'6/12': '50%',
		'7/12': '58.333333%',
		'8/12': '66.666667%',
		'9/12': '75%',
		'10/12': '83.333333%',
		'11/12': '91.666667%',
		full: '100%',
		screen: '100vw',
		min: 'min-content',
		max: 'max-content',
		fit: 'fit-content'
	}
}

// Generate VH-based height sizing
const generateVhHeightSizing = () => {
	const spacing = generateVhSpacing()
	return {
		...spacing,
		auto: 'auto',
		// Tailwind preset height keys (xs, sm, md, lg, xl, 2xl)
		xs: vhConverter(320), // 20rem
		sm: vhConverter(384), // 24rem
		md: vhConverter(448), // 28rem
		lg: vhConverter(512), // 32rem
		xl: vhConverter(576), // 36rem
		'2xl': vhConverter(672), // 42rem
		'1/2': '50%',
		'1/3': '33.333333%',
		'2/3': '66.666667%',
		'1/4': '25%',
		'2/4': '50%',
		'3/4': '75%',
		'1/5': '20%',
		'2/5': '40%',
		'3/5': '60%',
		'4/5': '80%',
		'1/6': '16.666667%',
		'2/6': '33.333333%',
		'3/6': '50%',
		'4/6': '66.666667%',
		'5/6': '83.333333%',
		'1/12': '8.333333%',
		'2/12': '16.666667%',
		'3/12': '25%',
		'4/12': '33.333333%',
		'5/12': '41.666667%',
		'6/12': '50%',
		'7/12': '58.333333%',
		'8/12': '66.666667%',
		'9/12': '75%',
		'10/12': '83.333333%',
		'11/12': '91.666667%',
		full: '100%',
		screen: '100vh',
		min: 'min-content',
		max: 'max-content',
		fit: 'fit-content'
	}
}

// Generate VH-based border radius
const generateVhBorderRadius = () => {
	return {
		none: '0',
		sm: `${vhConverter(2)} /* 2px */`,
		DEFAULT: `${vhConverter(4)} /* 4px */`,
		md: `${vhConverter(6)} /* 6px */`,
		lg: `${vhConverter(8)} /* 8px */`,
		xl: `${vhConverter(12)} /* 12px */`,
		'2xl': `${vhConverter(16)} /* 16px */`,
		'3xl': `${vhConverter(24)} /* 24px */`,
		full: '9999px'
	}
}

// Generate VH-based border width
const generateVhBorderWidth = () => {
	return {
		0: '0',
		DEFAULT: `${vhConverter(1)} /* 1px */`,
		2: `${vhConverter(2)} /* 2px */`,
		4: `${vhConverter(4)} /* 4px */`,
		8: `${vhConverter(8)} /* 8px */`
	}
}

const vhPlugin = plugin(
	function ({ addBase, theme }) {
		// Override default theme values
		const vhSpacing = generateVhSpacing()
		const vhFontSizes = generateVhFontSizes()
		const vhWidthSizing = generateVhWidthSizing()
		const vhHeightSizing = generateVhHeightSizing()

		// You can add custom base styles here if needed
		addBase({
			html: {
				fontSize: vhConverter(16) // Base font size in vh
			}
		})
	},
	{
		theme: {
			spacing: generateVhSpacing(),
			fontSize: generateVhFontSizes(),
			width: generateVhWidthSizing(),
			height: generateVhHeightSizing(),
			maxWidth: generateVhWidthSizing(),
			maxHeight: generateVhHeightSizing(),
			minWidth: generateVhWidthSizing(),
			minHeight: generateVhHeightSizing(),
			extend: {
				borderRadius: generateVhBorderRadius(),
				borderWidth: generateVhBorderWidth(),
				minWidth: generateVhWidthSizing(),
				minHeight: generateVhHeightSizing(),
				maxWidth: generateVhWidthSizing(),
				maxHeight: generateVhHeightSizing()
			}
		}
	}
)

module.exports = vhPlugin
