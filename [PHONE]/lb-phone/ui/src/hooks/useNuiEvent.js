import { useEffect } from 'react';

export const useNuiEvent = (action, callback) => {
  useEffect(() => {
    const handleMessage = (event) => {
      if (event.data?.action === action) {
        callback(event.data?.data);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [action, callback]);
};

export default useNuiEvent;
