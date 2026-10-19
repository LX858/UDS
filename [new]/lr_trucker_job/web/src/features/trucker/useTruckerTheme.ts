import {useCallback, useEffect, useState} from 'react';

export type TruckerTheme = 'light' | 'dark';

const STORAGE_PREFIX = 'lr_trucker_job:theme:';

function applyTheme(theme: TruckerTheme) {
  document.documentElement.dataset.theme = theme;
  document.documentElement.classList.toggle('dark', theme === 'dark');
}

export function useTruckerTheme(citizenId: string) {
  const [theme, setThemeState] = useState<TruckerTheme>('light');

  useEffect(() => {
    let nextTheme: TruckerTheme = 'light';
    if (citizenId) {
      try {
        const saved = localStorage.getItem(`${STORAGE_PREFIX}${citizenId}`);
        if (saved === 'light' || saved === 'dark') nextTheme = saved;
      } catch {
        // FiveM can disable storage in hardened browser profiles.
      }
    }
    setThemeState(nextTheme);
    applyTheme(nextTheme);
  }, [citizenId]);

  const setTheme = useCallback(
    (nextTheme: TruckerTheme) => {
      setThemeState(nextTheme);
      applyTheme(nextTheme);
      if (!citizenId) return;
      try {
        localStorage.setItem(`${STORAGE_PREFIX}${citizenId}`, nextTheme);
      } catch {
        // Keep the in-memory preference when storage is unavailable.
      }
    },
    [citizenId]
  );

  return {theme, setTheme};
}
