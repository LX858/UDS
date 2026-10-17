import { useState, useCallback } from 'react';
import { fetchNui } from '../utils/nui';

export const useFetchNui = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const execute = useCallback(async (event, data = {}, scriptName = 'lbphone') => {
    setLoading(true);
    setError(null);
    try {
      const result = await fetchNui(event, data, scriptName);
      setLoading(false);
      return result;
    } catch (err) {
      setError(err.message);
      setLoading(false);
      return null;
    }
  }, []);

  return { execute, loading, error };
};

export default useFetchNui;
