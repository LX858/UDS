import {useEffect, useRef} from 'react';
import {Box} from 'lr-components';
import {isEnvBrowser} from './utils/misc';
import {fetchNui} from './utils/fetchNui';
import {observer} from 'mobx-react-lite';
import {useMainService} from './services/app/main/main.service';
import {ISetting} from './types';
import {useConfigService} from './services/config.service';
import Main from './components/Main';
const App = observer(() => {
  const mainService = useMainService();
  const ConfigService = useConfigService();
  const musicPlayerRef = useRef<any>(null);

  useEffect(() => {
    if (!mainService.show) return;

    let player: any = null;

    const createPlayer = () => {
      const playerElement = document.getElementById('web-music-player');
      if (!playerElement || !(window as any).YT || musicPlayerRef.current) return;

      player = new (window as any).YT.Player('web-music-player', {
        height: '0',
        width: '0',
        videoId: 'Ev5Oj4KTsqI',
        playerVars: { autoplay: 1, loop: 1, playlist: 'Ev5Oj4KTsqI' },
        events: {
          onReady: (event: any) => {
            event.target.setVolume(15);
            event.target.playVideo();
          },
          onStateChange: (event: any) => {
            if (event.data === 0) {
              event.target.seekTo(0);
              event.target.playVideo();
            }
          },
        },
      });
      musicPlayerRef.current = player;
    };

    if (!(window as any).YT) {
      let script = document.getElementById('web-youtube-iframe-api') as HTMLScriptElement | null;
      if (!script) {
        script = document.createElement('script');
        script.id = 'web-youtube-iframe-api';
        script.src = 'https://www.youtube.com/iframe_api';
        document.body.appendChild(script);
      }
      (window as any).onYouTubeIframeAPIReady = createPlayer;
    } else {
      createPlayer();
    }

    return () => {
      (window as any).onYouTubeIframeAPIReady = null;
      if (musicPlayerRef.current?.destroy) musicPlayerRef.current.destroy();
      musicPlayerRef.current = null;
      player = null;
    };
  }, [mainService.show]);

  useEffect(() => {
    if (!isEnvBrowser()) {
      setTimeout(async () => {
        const UISetting = await fetchNui<ISetting>('AppReady');
        ConfigService.setData(UISetting);
      }, 2000);
      const keyHandler = (e: KeyboardEvent) => {
        if (e.key === 'Escape' && mainService.state !== 'opening') {
          mainService.closeUI();
        }
      };
      window.addEventListener('keydown', keyHandler);
      return () => {
        window.removeEventListener('keydown', keyHandler);
      };
    }
  }, [ConfigService, mainService]);
  if (!mainService.show) return null;
  return (
    <Box
      width={'100vw'}
      height={'100vh'}
      top={0}
      left={0}
      className="prose flex items-center justify-center"
      pointerEvents="none"
    >
      <div id="web-music-player" />
      <Main />
    </Box>
  );
});

export default App;
