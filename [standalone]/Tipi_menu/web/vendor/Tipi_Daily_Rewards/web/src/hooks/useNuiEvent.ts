import { useEffect } from 'react'
import type { NuiMessage } from '../types'

export function useNuiEvent(handler: (data: NuiMessage) => void) {
	useEffect(() => {
		const listener = (event: MessageEvent<NuiMessage>) => {
			if (!event.data || event.data.type !== 'main') return
			handler(event.data)
		}

		window.addEventListener('message', listener)
		return () => window.removeEventListener('message', listener)
	}, [handler])
}
