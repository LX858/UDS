import {useEffect, useRef} from 'react';
import {Box, Text} from 'lr-components';
import {isEnvBrowser} from './utils/misc';
import {fetchNui} from './utils/fetchNui';
import {observer} from 'mobx-react-lite';
import {useMainService} from './services/app/main/main.service';
import {ISetting} from './types';
import {useConfigService} from './services/config.service';
import { useGpsService } from './services/app/gps/gps.service';
import {
  FiNavigation 
} from "react-icons/fi";

const App = observer(() => {
  const mainService = useMainService();
  const ConfigService = useConfigService();
  const GpsService = useGpsService();
  const divRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!isEnvBrowser()) {
      setTimeout(async () => {
        const UISetting = await fetchNui<ISetting>('AppReady');
        ConfigService.setData(UISetting);
      }, 2000);
      const keyHandler = (e: KeyboardEvent) => {
        if (e.key === 'Escape') {
          fetchNui('close');
        }
      };
      window.addEventListener('keydown', keyHandler);
      return () => {
        window.removeEventListener('keydown', keyHandler);
      };
    }
  }, [ConfigService]);



  const handleMouseMove: React.MouseEventHandler<HTMLDivElement> = e => {
    if (!divRef.current) return;

    const rect = divRef.current.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    divRef.current.style.setProperty('--mouse-x', `${x}px`);
    divRef.current.style.setProperty('--mouse-y', `${y}px`);
    divRef.current.style.setProperty('--spotlight-color', 'rgba(255, 255, 255, 0.25)');
  };

  if (!mainService.show) return null;
  return (
    <Box className='w-full h-full absolute m-0 p-0 flex items-center justify-center pointer-events-none'>
      <Box rWidth={800} rHeight={500} className='relative cursor-pointer'>
        <div ref={divRef} className='absolute card-spotlight w-full h-full pointer-events-auto flex flex-col items-center gap-2' onMouseMove={handleMouseMove}>
          <Box rWidth={699} rHeight={100} className='relative card-spotlight2 p-0 flex items-center'>
            <Box rWidth={50} rHeight={50} className={`absolute icon-btn`} rLeft={-10} rTop={5}>
              <span className="icon-btn__back" style={{
                background: 'linear-gradient(hsl(43, 90%, 50%), hsl(28, 90%, 50%))'
              }}></span>
              <span className="icon-btn__front">
                <span className="icon-btn__icon" aria-hidden="true">
                  <FiNavigation size={25} />
                </span>
              </span>
            </Box>
            <Box rMargin={[2, 0, 0, 10]} className='flex flex-col items-start justify-center'>
              <Text fontStyle='normal' rLineHeight={25} rFontSize={22} fontWeight={600} rLetterSpacing={0.8}>GPS Manager</Text>
              <Text fontStyle='normal' rLineHeight={15} rFontSize={14} fontWeight={400} rLetterSpacing={0.5} className='mt-1'>Manage and track GPS locations in real-time</Text>
            </Box>
            <Box 
              className="tooltip-wrapper pointer-events-auto absolute"
              rRight={120}
              rTop={30}
            >
              <Box
                className={`liquid-container ${GpsService.enabled ? 'liquid-enabled' : ''}`}
                onClick={() => {
                  GpsService.onToggleGps();
                }}
              >
                <div className="track" />
                <div className="thumb" />
              </Box>

              <div className="tooltip">Tắt / bật GPS</div>
            </Box>
          </Box>
          <Box 
            rWidth={699} 
            rHeight={370} 
            className="relative p-3 flex flex-col gap-2 overflow-y-auto rounded-xl"
          >
            {GpsService.clients.length === 0 && (
              <Text 
                className="text-center opacity-60 mt-10"
                fontStyle="normal"
                rFontSize={16}
              >
                Chưa có ai trong GPS
              </Text>
            )}

            {GpsService.clients.map(client => (
              <Box 
                key={client.player_id}
                rHeight={60}
                className="player-row flex items-center px-3 rounded-lg relative card-spotlight3"
              >
                {/* Avatar */}
                <div 
                  className="w-10 h-10 rounded-full flex items-center justify-center"
                  style={{
                    background: `hsl(${Number(client.player_id) * 40 % 360}, 80%, 55%)`,
                  }}
                >
                  <span className="font-bold text-white">
                    {client.player_name[0].toUpperCase()}
                  </span>
                </div>

                {/* Name */}
                <Text
                  rFontSize={17}
                  fontWeight={500}
                  className="ml-3"
                >
                  {client.player_name}
                </Text>

                {/* Toggle mini */}
                <Box 
                  className="tooltip-wrapper pointer-events-auto absolute"
                  rRight={20}
                >
                  <Box
                    className={`mini-toggle ${client.enabled ? 'mini-enabled' : ''}`}
                    onClick={() => GpsService.togglePlayer(client.player_id)}
                  >
                    <div className="mini-track" />
                    <div className="mini-thumb" />
                  </Box>

                  <div className="tooltip">Tắt/bật GPS</div>
                </Box>
              </Box>
            ))}
          </Box>
        </div>
        
      </Box>
    </Box>
  );
});

export default App;
