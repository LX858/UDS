export async function emitNet<T = unknown>(
  eventName: string,
  params?: {
    payload?: unknown;
    handler?: (payload: T) => void;
  }
): Promise<T> {
  const options = {
    method: "POST",
    headers: {
      "Content-Type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify(params?.payload),
  };

  const resourceName = (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : "nui-frame-app";

  const response = await fetch(`https://${resourceName}/${eventName}`, options);
  const responseFormatted = await response.json();

  if (params?.handler) {
    params.handler(responseFormatted);
  }

  return responseFormatted;
}
