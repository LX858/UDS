/**
 * NUI Communication utilities for LB Phone
 */

export const fetchNui = async (event, data = {}, scriptName = 'lbphone') => {
  try {
    const response = await fetch(`https://${scriptName}/${event}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      throw new Error(`${response.status} - ${response.statusText}`);
    }

    return await response.json();
  } catch (error) {
    console.error(`Error fetching ${event}:`, error);
    return null;
  }
};

export const sendNuiMessage = (action, data = {}) => {
  window.postMessage({
    action,
    data,
  }, '*');
};

export const onNuiEvent = (action, callback) => {
  window.addEventListener('message', (event) => {
    if (event.data?.action === action) {
      callback(event.data?.data);
    }
  });
};

export const isPhoneVisible = () => {
  return document.querySelector('.phone-frame') !== null;
};
