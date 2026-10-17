import React from 'react'
import ReactDOM from 'react-dom/client'
import './index.css'
import App from './app'
import { isEnvBrowser } from './utils'
import { Toaster } from '@/components/ui/sonner'
import { TooltipProvider } from '@/components/ui/tooltip'

const root = document.getElementById('root')

if (isEnvBrowser()) {
	// https://i.imgur.com/iPTAdYV.png - Night time img
	// https://i.imgur.com/3pzRj9n.png - Day time img
	root!.style.backgroundImage = 'url("https://i.imgur.com/3pzRj9n.png")'
	root!.style.backgroundSize = 'cover'
	root!.style.backgroundRepeat = 'no-repeat'
	root!.style.backgroundPosition = 'center'
}

document.documentElement.classList.add('dark')
ReactDOM.createRoot(root!).render(
	<React.StrictMode>
		<TooltipProvider>
			<App />
			<Toaster position='bottom-right' richColors />
		</TooltipProvider>
	</React.StrictMode>
)
