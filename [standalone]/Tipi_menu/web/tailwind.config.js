/** @type {import('tailwindcss').Config} */
// eslint-disable-next-line @typescript-eslint/no-var-requires, no-undef
const { nextui } = require('@nextui-org/react');
export default {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
    './vendor/Tipi_Rankings/web/src/**/*.{js,ts,jsx,tsx}',
    './node_modules/@nextui-org/theme/dist/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        cyan: {
          DEFAULT: '#00e5ff',
          dim: '#00b8d4',
          dark: '#006272',
          glow: 'rgba(0, 229, 255, 0.35)',
          faint: 'rgba(0, 229, 255, 0.08)',
        },
        uls: {
          DEFAULT: '#00e5ff',
          dim: '#00b8d4',
          glow: 'rgba(0, 229, 255, 0.35)',
        },
        surface: {
          DEFAULT: 'rgba(2, 18, 30, 0.96)',
          light: 'rgba(0, 20, 35, 0.88)',
          border: 'rgba(0, 229, 255, 0.25)',
        },
      },
      fontFamily: {
        heading: ['Montserrat', 'sans-serif'],
        display: ['Montserrat', 'Bebas Neue', 'sans-serif'],
        body: ['Montserrat', 'Inter', 'sans-serif'],
      },
      animation: {
        'slide-up': 'slideUp 0.3s ease-out',
      },
      keyframes: {
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(12px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
    },
  },
  darkMode: 'class',
  plugins: [nextui()],
};
