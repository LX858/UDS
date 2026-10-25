import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'
import { isEnvBrowser } from './utils'

const root = document.getElementById('root')!

if (isEnvBrowser()) {
	root.style.backgroundImage = 'url("https://i.imgur.com/3pzRj9n.png")'
	root.style.backgroundSize = 'cover'
	root.style.backgroundRepeat = 'no-repeat'
	root.style.backgroundPosition = 'center'
}

ReactDOM.createRoot(root).render(
	<React.StrictMode>
		<App />
	</React.StrictMode>
)
