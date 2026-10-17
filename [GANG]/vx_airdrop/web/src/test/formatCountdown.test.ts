import { describe, expect, it } from 'vitest';
import { formatCountdown } from '../utils/formatCountdown';

describe('airdrop countdown display', () => {
  it('shows registration and match durations as minutes:seconds', () => {
    expect(formatCountdown(300)).toBe('05:00');
    expect(formatCountdown(1500)).toBe('25:00');
    expect(formatCountdown(299)).toBe('04:59');
    expect(formatCountdown(61)).toBe('01:01');
  });

  it('keeps the last partial second visible and stops at zero', () => {
    expect(formatCountdown(0.1)).toBe('00:01');
    expect(formatCountdown(0)).toBe('00:00');
    expect(formatCountdown(-3)).toBe('00:00');
  });
});
