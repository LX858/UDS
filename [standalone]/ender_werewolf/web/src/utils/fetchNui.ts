import { isEnvBrowser } from './misc'

/**
 * Simple wrapper around fetch API tailored for CEF/NUI use. This abstraction
 * can be extended to include AbortController if needed or if the response isn't
 * JSON. Tailor it to your needs.
 *
 * @param eventName - The endpoint eventname to target
 * @param data - Data you wish to send in the NUI Callback
 * @param mockData - Mock data to be returned if in the browser
 *
 * @return returnData - A promise for the data sent back by the NuiCallbacks CB argument
 */

export async function fetchNui<T = unknown>(eventName: string, data?: unknown, mockData?: T): Promise<T> {
	const options = {
		method: 'post',
		headers: {
			'Content-Type': 'application/json; charset=UTF-8'
		},
		body: JSON.stringify(data)
	}

	if (isEnvBrowser() && mockData) return mockData

	const resourceName = (window as any).GetParentResourceName
		? (window as any).GetParentResourceName()
		: 'fivem-react-boilerplate-lua'

	const resp = await fetch(`https://${resourceName}/${eventName}`, options)

	const respFormatted = await resp.json()

	return respFormatted
}

export class fetchNuiClass {
	private readonly resourceName: string
	private identify: string

	constructor() {
		this.resourceName = (window as any).GetParentResourceName
			? (window as any).GetParentResourceName()
			: 'fivem-react-boilerplate-lua'
		this.identify = ''
	}

	setIdentify(identify: string): void {
		this.identify = identify
	}

	clearIdentify(): void {
		this.identify = ''
	}

	async fetch<T = unknown>(eventName: string, data?: unknown, mockData?: T): Promise<T> {
		const options = {
			method: 'post',
			headers: {
				'Content-Type': 'application/json; charset=UTF-8'
			},
			body: JSON.stringify(data)
		}

		if (isEnvBrowser() && mockData) return mockData

		const resp = await fetch(`https://${this.resourceName}/${eventName + this.identify}`, options)

		const respFormatted = await resp.json()

		return respFormatted
	}
}
