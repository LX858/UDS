import {useEffect} from 'react';
import {Box} from 'lr-components';
import {isEnvBrowser} from './utils/misc';
import {fetchNui} from './utils/fetchNui';
import {observer} from 'mobx-react-lite';
import {useMainService} from './services/app/main/main.service';
import {ISetting} from './types';
import {useConfigService} from './services/config.service';
import Trader from './components/Trader';
const App = observer(() => {
  const mainService = useMainService();
  const ConfigService = useConfigService();

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
  if (!mainService.show) return null;
  return (
    <Box
      width={'100vw'}
      height={'100vh'}
      top={0}
      left={0}
      className="prose flex items-center justify-center"
    >
      <Trader />
    </Box>
  );
});

export default App;
