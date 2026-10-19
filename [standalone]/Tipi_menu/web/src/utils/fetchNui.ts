/* eslint-disable @typescript-eslint/no-explicit-any */
import { isEnvBrowser } from './misc';

const NUI_TIMEOUT_MS = 8000;

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

export async function fetchNui<T = unknown>(
  eventName: string,
  data?: unknown,
  mockData?: T
): Promise<T> {
  if (isEnvBrowser() && mockData) return mockData;

  const controller = new AbortController();
  const timer = window.setTimeout(() => controller.abort(), NUI_TIMEOUT_MS);
  const options = {
    method: 'post',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data),
    signal: controller.signal,
  };

  const resourceName = (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : 'nui-frame-app';

  try {
    const resp = await fetch(`https://${resourceName}/${eventName}`, options);

    if (!resp.ok) {
      throw new Error(`NUI callback failed: ${eventName}`);
    }

    try {
      return (await resp.json()) as T;
    } catch {
      return {} as T;
    }
  } finally {
    window.clearTimeout(timer);
  }
}
