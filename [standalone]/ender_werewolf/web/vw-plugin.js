const plugin = require('tailwindcss/plugin');

// Viewport width conversion (base: 1920px)
const vwConverter = px => `${((px / 1920) * 100).toFixed(3)}vw`;

// Generate VW-based spacing scale
const generateVwSpacing = () => {
  const spacingValues = {
    0: '0',
    0.5: `${vwConverter(2)} /* 2px */`,
    1: `${vwConverter(4)} /* 4px */`,
    1.5: `${vwConverter(6)} /* 6px */`,
    2: `${vwConverter(8)} /* 8px */`,
    2.5: `${vwConverter(10)} /* 10px */`,
    3: `${vwConverter(12)} /* 12px */`,
    3.5: `${vwConverter(14)} /* 14px */`,
    4: `${vwConverter(16)} /* 16px */`,
    5: `${vwConverter(20)} /* 20px */`,
    6: `${vwConverter(24)} /* 24px */`,
    7: `${vwConverter(28)} /* 28px */`,
    8: `${vwConverter(32)} /* 32px */`,
    9: `${vwConverter(36)} /* 36px */`,
    10: `${vwConverter(40)} /* 40px */`,
    11: `${vwConverter(44)} /* 44px */`,
    12: `${vwConverter(48)} /* 48px */`,
    14: `${vwConverter(56)} /* 56px */`,
    16: `${vwConverter(64)} /* 64px */`,
    20: `${vwConverter(80)} /* 80px */`,
    24: `${vwConverter(96)} /* 96px */`,
    28: `${vwConverter(112)} /* 112px */`,
    32: `${vwConverter(128)} /* 128px */`,
    36: `${vwConverter(144)} /* 144px */`,
    40: `${vwConverter(160)} /* 160px */`,
    44: `${vwConverter(176)} /* 176px */`,
    48: `${vwConverter(192)} /* 192px */`,
    52: `${vwConverter(208)} /* 208px */`,
    56: `${vwConverter(224)} /* 224px */`,
    60: `${vwConverter(240)} /* 240px */`,
    64: `${vwConverter(256)} /* 256px */`,
    72: `${vwConverter(288)} /* 288px */`,
    80: `${vwConverter(320)} /* 320px */`,
    96: `${vwConverter(384)} /* 384px */`,
  };
  return spacingValues;
};

// Generate VW-based font sizes
const generateVwFontSizes = () => {
  return {
    xs: [
      `${vwConverter(12)} /* 12px */`,
      {lineHeight: `${vwConverter(16)} /* 16px */`},
    ],
    sm: [
      `${vwConverter(14)} /* 14px */`,
      {lineHeight: `${vwConverter(20)} /* 20px */`},
    ],
    base: [
      `${vwConverter(16)} /* 16px */`,
      {lineHeight: `${vwConverter(24)} /* 24px */`},
    ],
    lg: [
      `${vwConverter(18)} /* 18px */`,
      {lineHeight: `${vwConverter(28)} /* 28px */`},
    ],
    xl: [
      `${vwConverter(20)} /* 20px */`,
      {lineHeight: `${vwConverter(28)} /* 28px */`},
    ],
    '2xl': [
      `${vwConverter(24)} /* 24px */`,
      {lineHeight: `${vwConverter(32)} /* 32px */`},
    ],
    '3xl': [
      `${vwConverter(30)} /* 30px */`,
      {lineHeight: `${vwConverter(36)} /* 36px */`},
    ],
    '4xl': [
      `${vwConverter(36)} /* 36px */`,
      {lineHeight: `${vwConverter(40)} /* 40px */`},
    ],
    '5xl': [`${vwConverter(48)} /* 48px */`, {lineHeight: '1'}],
    '6xl': [`${vwConverter(60)} /* 60px */`, {lineHeight: '1'}],
    '7xl': [`${vwConverter(72)} /* 72px */`, {lineHeight: '1'}],
    '8xl': [`${vwConverter(96)} /* 96px */`, {lineHeight: '1'}],
    '9xl': [`${vwConverter(128)} /* 128px */`, {lineHeight: '1'}],
  };
};

// Generate VW-based width sizing
const generateVwWidthSizing = () => {
  const spacing = generateVwSpacing();
  return {
    ...spacing,
    auto: 'auto',
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
    fit: 'fit-content',
  };
};

// Generate VW-based height sizing
const generateVwHeightSizing = () => {
  const spacing = generateVwSpacing();
  return {
    ...spacing,
    auto: 'auto',
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
    fit: 'fit-content',
  };
};

// Generate VW-based border radius
const generateVwBorderRadius = () => {
  return {
    none: '0',
    sm: `${vwConverter(2)} /* 2px */`,
    DEFAULT: `${vwConverter(4)} /* 4px */`,
    md: `${vwConverter(6)} /* 6px */`,
    lg: `${vwConverter(8)} /* 8px */`,
    xl: `${vwConverter(12)} /* 12px */`,
    '2xl': `${vwConverter(16)} /* 16px */`,
    '3xl': `${vwConverter(24)} /* 24px */`,
    full: '9999px',
  };
};

// Generate VW-based border width
const generateVwBorderWidth = () => {
  return {
    0: '0',
    DEFAULT: `${vwConverter(1)} /* 1px */`,
    2: `${vwConverter(2)} /* 2px */`,
    4: `${vwConverter(4)} /* 4px */`,
    8: `${vwConverter(8)} /* 8px */`,
  };
};

const vwPlugin = plugin(
  function ({addBase, theme}) {
    // Override default theme values
    const vwSpacing = generateVwSpacing();
    const vwFontSizes = generateVwFontSizes();
    const vwWidthSizing = generateVwWidthSizing();
    const vwHeightSizing = generateVwHeightSizing();

    // You can add custom base styles here if needed
    addBase({
      html: {
        fontSize: vwConverter(16), // Base font size in vw
      },
    });
  },
  {
    theme: {
      spacing: generateVwSpacing(),
      fontSize: generateVwFontSizes(),
      width: generateVwWidthSizing(),
      height: generateVwHeightSizing(),
      maxWidth: generateVwWidthSizing(),
      maxHeight: generateVwHeightSizing(),
      minWidth: generateVwWidthSizing(),
      minHeight: generateVwHeightSizing(),
      extend: {
        borderRadius: generateVwBorderRadius(),
        borderWidth: generateVwBorderWidth(),
      },
    },
  }
);

module.exports = vwPlugin;
