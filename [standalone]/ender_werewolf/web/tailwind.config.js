/** @type {import('tailwindcss').Config} */
export default {
	darkMode: ['class'],
	content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
	theme: {
		extend: {
			borderRadius: {
				lg: 'var(--radius)',
				md: 'calc(var(--radius) - 2px)',
				sm: 'calc(var(--radius) - 4px)'
			},
			colors: {
				background: 'hsl(var(--background))',
				foreground: 'hsl(var(--foreground))',
				card: {
					DEFAULT: 'hsl(var(--card))',
					foreground: 'hsl(var(--card-foreground))'
				},
				popover: {
					DEFAULT: 'hsl(var(--popover))',
					foreground: 'hsl(var(--popover-foreground))'
				},
				primary: {
					DEFAULT: 'hsl(var(--primary))',
					foreground: 'hsl(var(--primary-foreground))'
				},
				secondary: {
					DEFAULT: 'hsl(var(--secondary))',
					foreground: 'hsl(var(--secondary-foreground))'
				},
				muted: {
					DEFAULT: 'hsl(var(--muted))',
					foreground: 'hsl(var(--muted-foreground))'
				},
				accent: {
					DEFAULT: 'hsl(var(--accent))',
					foreground: 'hsl(var(--accent-foreground))'
				},
				destructive: {
					DEFAULT: 'hsl(var(--destructive))',
					foreground: 'hsl(var(--destructive-foreground))'
				},
				border: 'hsl(var(--border))',
				input: 'hsl(var(--input))',
				ring: 'hsl(var(--ring))',
				chart: {
					1: 'hsl(var(--chart-1))',
					2: 'hsl(var(--chart-2))',
					3: 'hsl(var(--chart-3))',
					4: 'hsl(var(--chart-4))',
					5: 'hsl(var(--chart-5))'
				},
				uls: '#b292f7'
			},
			fontFamily: {
				sans: ['Inter', 'Roboto', 'Arial', 'sans-serif'],
				heading: ['Oswald', 'Bebas Neue', 'Montserrat', 'sans-serif'],
				'akrobat-bold': ['Akrobat-Bold', 'Arial', 'sans-serif'],
			},
			keyframes: {
				fishreveal: {
					'0%': { opacity: '0', transform: 'scale(0.8)' },
					'100%': { opacity: '1', transform: 'scale(1)' }
				},
				rodshaking: {
					'0%, 100%': { transform: 'translateX(0)' },
					'25%': { transform: 'translateX(-0.2vh)' },
					'75%': { transform: 'translateX(0.2vh)' }
				},
				baitreveal: {
					'0%': { opacity: '0', transform: 'scale(0.5) translateY(-1vh)' },
					'100%': { opacity: '1', transform: 'scale(1) translateY(0)' }
				},
				touch: {
					'0%': { transform: 'scale(1)' },
					'50%': { transform: 'scale(1.2)' },
					'100%': { transform: 'scale(1.1)' }
				},
				// ripple: {
				//   '0%': {
				//     width: '1vh',
				//     height: '1vh',
				//     opacity: '1'
				//   },
				//   '100%': {
				//     width: '10vh',
				//     height: '10vh',
				//     opacity: '0'
				//   }
				// },
				pop: {
					'0%': { transform: 'scale(1)' },
					'50%': { transform: 'scale(1.3)' },
					'100%': { transform: 'scale(1.5)' }
				},
				floating: {
					'0%, 100%': { transform: 'translateY(0)' },
					'50%': { transform: 'translateY(-.85vh)' }
				}
			},
			animation: {
				fishreveal: 'fishreveal 0.25s ease',
				rodshaking: 'rodshaking 0.25s ease infinite',
				baitreveal: 'baitreveal 0.25s ease',
				touch: 'touch 0.1s ease-out forwards',
				// ripple: 'ripple 1s ease',
				pop: 'pop 0.5s ease-out forwards',
				floating: 'floating 2s ease-in-out infinite'
			},
			backgroundImage: {
				main: 'url(/images/bg.webp)',
				shop: 'url(/images/bg-shop.webp)'
			},
			backgroundSize: {
				'full-size': '100% 100%'
			},
			backgroundPosition: {
				'full-center': 'center center'
			},
			transitionDuration: {
				250: '250ms'
			}
		}
	},
	plugins: [require('tailwindcss-animate'), require('./vh-plugin')]
}
