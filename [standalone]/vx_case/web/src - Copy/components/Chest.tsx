import { useEffect, useState } from 'react';
import { Box } from 'lr-components';

interface ChestProps {
  isVisible: boolean;
}

const Chest = ({ isVisible }: ChestProps) => {
  const [shake, setShake] = useState(false);

  useEffect(() => {
    let timeout: NodeJS.Timeout;
    let shakeTimeout: NodeJS.Timeout;

    const triggerShake = () => {
      const delay = Math.random() * 5000 + 5000;

      timeout = setTimeout(() => {
        setShake(true);

        shakeTimeout = setTimeout(() => {
          setShake(false);
          triggerShake();
        }, 700);
      }, delay);
    };

    triggerShake();

    return () => {
      clearTimeout(timeout);
      clearTimeout(shakeTimeout);
    };
  }, []);

  return (
    <Box
      className={`absolute left-[50%] -translate-x-1/2 transition-opacity duration-700 ${
        isVisible ? 'opacity-100' : 'opacity-0'
      }`}
      rTop={80}
    >
      <Box
        rWidth={534 * 0.9}
        rHeight={488 * 0.9}
        background="url(./assets/case.png) no-repeat center center / contain"
        className={shake && isVisible ? 'chest-shake' : ''}
      />
    </Box>
  );
};

export default Chest;
