import {cleanup, fireEvent, render, screen} from '@testing-library/react';
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';
import {useTruckerTheme} from '@/features/trucker/useTruckerTheme';

function ThemeHarness({citizenId}: {citizenId: string}) {
  const {theme, setTheme} = useTruckerTheme(citizenId);
  return (
    <div>
      <output aria-label="theme">{theme}</output>
      <button type="button" onClick={() => setTheme('dark')}>Dark</button>
      <button type="button" onClick={() => setTheme('light')}>Light</button>
    </div>
  );
}

describe('trucker theme preference', () => {
  beforeEach(() => {
    localStorage.clear();
    document.documentElement.classList.remove('dark');
    delete document.documentElement.dataset.theme;
  });

  afterEach(() => {
    cleanup();
    vi.restoreAllMocks();
  });

  it('stores and restores a separate preference for each citizen', () => {
    const view = render(<ThemeHarness citizenId="citizen-a" />);
    fireEvent.click(screen.getByRole('button', {name: 'Dark'}));
    expect(localStorage.getItem('lr_trucker_job:theme:citizen-a')).toBe('dark');

    view.rerender(<ThemeHarness citizenId="citizen-b" />);
    expect(screen.getByLabelText('theme').textContent).toBe('light');
    expect(localStorage.getItem('lr_trucker_job:theme:citizen-b')).toBeNull();

    fireEvent.click(screen.getByRole('button', {name: 'Dark'}));
    expect(localStorage.getItem('lr_trucker_job:theme:citizen-b')).toBe('dark');
    fireEvent.click(screen.getByRole('button', {name: 'Light'}));
    expect(localStorage.getItem('lr_trucker_job:theme:citizen-b')).toBe('light');

    view.rerender(<ThemeHarness citizenId="citizen-a" />);
    expect(screen.getByLabelText('theme').textContent).toBe('dark');
    expect(document.documentElement.classList.contains('dark')).toBe(true);
  });

  it('does not write a key before the citizen id is available', () => {
    render(<ThemeHarness citizenId="" />);
    fireEvent.click(screen.getByRole('button', {name: 'Dark'}));
    expect(screen.getByLabelText('theme').textContent).toBe('dark');
    expect(localStorage.length).toBe(0);
  });

  it('keeps working when localStorage is unavailable', () => {
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
      throw new Error('storage disabled');
    });
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new Error('storage disabled');
    });

    render(<ThemeHarness citizenId="citizen-a" />);
    fireEvent.click(screen.getByRole('button', {name: 'Dark'}));
    expect(screen.getByLabelText('theme').textContent).toBe('dark');
    expect(document.documentElement.classList.contains('dark')).toBe(true);
  });
});
