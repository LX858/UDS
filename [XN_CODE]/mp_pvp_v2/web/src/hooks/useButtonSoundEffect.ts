import { useCallback, useRef } from "react";

type EventHandler = (
  e: React.MouseEvent | React.MouseEvent<HTMLButtonElement>
) => void;

const SOUNDS = {
  click: "./sound_effects/hover.mp3",
  submit: "./sound_effects/submit.mp3",
  cancel: "./sound_effects/cancel.mp3",
} as const;

export function useButtonSoundEffect() {
  const soundRef = useRef<Record<keyof typeof SOUNDS, HTMLAudioElement> | null>(
    null
  );
  if (!soundRef.current) {
    soundRef.current = Object.fromEntries(
      Object.entries(SOUNDS).map(([key, src]) => [key, new Audio(src)])
    ) as Record<keyof typeof SOUNDS, HTMLAudioElement>;
    Object.values(soundRef.current).forEach((audio) => {
      audio.volume = 0.3; // Set a default volume
    });
  }

  const bind = (userHandlers?: {
    onClick?: { sound: keyof typeof SOUNDS; handle?: EventHandler };
  }) => ({
    onClick: (e: React.MouseEvent) => {
      if (userHandlers?.onClick) {
        const { sound, handle } = userHandlers.onClick;
        soundRef.current![sound].currentTime = 0;
        soundRef.current![sound].play().catch(() => {});
        handle?.(e);
      }
    },
  });

  const playSound = useCallback((sound: keyof typeof SOUNDS) => {
    soundRef.current![sound].currentTime = 0;
    soundRef.current![sound].play().catch(() => {});
  }, []);

  return { bind, playSound };
}
