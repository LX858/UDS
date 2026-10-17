import { useEffect } from 'react';
import { Box } from 'lr-components';
import { fetchNui } from './utils/fetchNui';
import { observer } from 'mobx-react-lite';
import { useMainService } from './services/app/main/main.service';
import { ISetting } from './types';
import { useConfigService } from './services/config.service';
import Alert from './components/Alert';
import Scoreboard from './components/Scoreboard';
import Weapons from './components/Weapons';
import Winner from './components/Winner';
import Loster from './components/Loster';

const App = observer(() => {
    const mainService = useMainService();
    const ConfigService = useConfigService();

    useEffect(() => {
        setTimeout(async () => {
            if (!('GetParentResourceName' in window)) return;
            const UISetting = await fetchNui<ISetting>('AppReady');
            ConfigService.setData(UISetting);
        }, 2000);
    }, [ConfigService]);
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
            <Alert />
            <Scoreboard />
            <Weapons />
            {mainService.result === 'win' && <Winner />}
            {mainService.result === 'lose' && <Loster />}
        </Box>
    );
});

export default App;
