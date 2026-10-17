// GetParentResourceName only exists inside CEF; fall back so the UI can also be
// opened in a plain browser for development.
const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;

export async function fetchNui(eventName, data) {
  if (!resource) {
    window.parent?.postMessage({ __devNui: eventName, data: data }, '*');
    return null;
  }

  try {
    const resp = await fetch(`https://${resource}/${eventName}`, {
      method: 'post',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify(data),
    });

    return await resp.json();
  } catch (err) {
    return null;
  }
}
