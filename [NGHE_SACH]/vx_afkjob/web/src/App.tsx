import {useEffect, useState} from 'react';
import {Box, Text} from 'lr-components';
import {isEnvBrowser} from './utils/misc';
import {fetchNui} from './utils/fetchNui';
import {observer} from 'mobx-react-lite';
import {ISetting} from './types';
import {useConfigService} from './services/config.service';
import {useNuiEvent} from './hooks/useNuiEvent';
import {debugData} from './utils/debugData';

type AFKJobStatus = 'idle' | 'ready' | 'moving' | 'farming' | 'stopped' | 'completed';

interface AFKJobUIState {
  visible: boolean;
  status: AFKJobStatus;
  progress: number;
  maxProgress: number;
}

const statusText: Record<AFKJobStatus, string> = {
  idle: 'Sẵn sàng',
  ready: 'Nhấn E để bắt đầu',
  moving: 'Đang di chuyển',
  farming: 'Đang farm',
  stopped: 'Đã dừng',
  completed: 'Hoàn thành',
};

debugData<AFKJobUIState>([
  {
    action: 'afkjob:update',
    data: {
      visible: true,
      status: 'farming',
      progress: 87,
      maxProgress: 200,
    },
  },
]);

const App = observer(() => {
  const ConfigService = useConfigService();
  const [afkJob, setAfkJob] = useState<AFKJobUIState>({
    visible: isEnvBrowser(),
    status: isEnvBrowser() ? 'farming' : 'idle',
    progress: isEnvBrowser() ? 87 : 0,
    maxProgress: 200,
  });

  useNuiEvent<AFKJobUIState>('afkjob:update', data => {
    setAfkJob({
      visible: Boolean(data.visible),
      status: data.status || 'idle',
      progress: Number(data.progress) || 0,
      maxProgress: Number(data.maxProgress) || 200,
    });
  });

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

  if (!afkJob.visible) return null;

  const progress = Math.min(Math.max(afkJob.progress, 0), afkJob.maxProgress);

  return (
    <Box
      width={'100vw'}
      height={'100vh'}
      top={0}
      left={0}
      display="flex"
      justifyContent="center"
      alignItems="center"
      className="prose"
      pointerEvents="none"
    >
      <Box 
        rWidth={350}
        rHeight={150}
        className='absolute flex flex-col items-end justify-center'
        rLeft={30}
        rTop={200}
        rGap={10}
      >
        <Box rWidth={186} rHeight={195} background={"url(./assets/logo.png) no-repeat center center / contain"} className='absolute' rLeft={0} rBottom={75}/>
        <Box rWidth={348} rHeight={43} background={"url(./assets/bg.png) no-repeat center center / contain"} className='flex items-center justify-end' rPadding={[0, 25, 0, 0]}>
          <Text rFontSize={16}>Tiến Trình : {progress}/{afkJob.maxProgress}</Text>
        </Box>
        {/* <Box rWidth={348} className='flex items-center justify-end' rPadding={[0, 25, 0, 0]}>
          <Text rFontSize={13}>{statusText[afkJob.status]}</Text>
        </Box> */}
        <Box className='flex items-center justify-end' rMargin={[0, 10, 0, 0]}>
          <Box rWidth={79} rHeight={29.11} background={"url(./assets/start.png) no-repeat center center / contain"} className={afkJob.status === 'ready' ? 'opacity-100' : 'opacity-[0.55]'} />
          <Box rWidth={79} rHeight={29.11} background={"url(./assets/stop.png) no-repeat center center / contain"} className={afkJob.status === 'moving' || afkJob.status === 'farming' ? 'opacity-100' : 'opacity-[0.55]'} />
        </Box>
      </Box>
    </Box>
  );
});

export default App;
