export type UiSound = 'open' | 'hover' | 'press' | 'success' | 'error' | 'close';

let audioContext: AudioContext | null = null;
let soundsEnabled = true;

const presets: Record<UiSound, {frequency: number; endFrequency: number; duration: number; gain: number}> = {
  open: {frequency: 420, endFrequency: 620, duration: 0.12, gain: 0.035},
  hover: {frequency: 520, endFrequency: 560, duration: 0.035, gain: 0.012},
  press: {frequency: 260, endFrequency: 210, duration: 0.055, gain: 0.025},
  success: {frequency: 520, endFrequency: 780, duration: 0.16, gain: 0.04},
  error: {frequency: 190, endFrequency: 125, duration: 0.16, gain: 0.04},
  close: {frequency: 410, endFrequency: 250, duration: 0.1, gain: 0.03},
};

export function setUiSoundsEnabled(enabled: boolean) {
  soundsEnabled = enabled;
}

export function playUiSound(sound: UiSound) {
  if (!soundsEnabled || typeof window === 'undefined' || !window.AudioContext) return;
  try {
    audioContext ??= new window.AudioContext();
    if (audioContext.state === 'suspended') void audioContext.resume();
    const now = audioContext.currentTime;
    const preset = presets[sound];
    const oscillator = audioContext.createOscillator();
    const gain = audioContext.createGain();
    oscillator.type = sound === 'error' ? 'square' : 'sine';
    oscillator.frequency.setValueAtTime(preset.frequency, now);
    oscillator.frequency.exponentialRampToValueAtTime(
      preset.endFrequency,
      now + preset.duration
    );
    gain.gain.setValueAtTime(preset.gain, now);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + preset.duration);
    oscillator.connect(gain);
    gain.connect(audioContext.destination);
    oscillator.start(now);
    oscillator.stop(now + preset.duration);
  } catch {
    audioContext = null;
  }
}
