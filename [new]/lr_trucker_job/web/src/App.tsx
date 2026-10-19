import {observer} from 'mobx-react-lite';
import {useEffect} from 'react';
import {useStore} from './app/runtimeContext';
import {MissionHud} from './features/trucker/MissionWidgets';
import {TransportDashboard} from './features/trucker/TransportDashboard';
import {useTruckerController} from './features/trucker/useTruckerController';
import {playUiSound} from './features/trucker/sound';
import {useTruckerTheme} from './features/trucker/useTruckerTheme';

const App = observer(() => {
  const trucker = useStore('trucker');
  const controller = useTruckerController();
  const mission = trucker.snapshot.mission;
  const L = trucker.L.bind(trucker);
  const {theme, setTheme} = useTruckerTheme(trucker.snapshot.player.citizenId);

  useEffect(() => {
    if (trucker.visibility.visible) playUiSound('open');
  }, [trucker.visibility.visible]);

  return (
    <>
      {mission.active && !trucker.visibility.visible ? (
        <MissionHud mission={mission} L={L} />
      ) : null}
      {trucker.visibility.visible ? (
        <TransportDashboard
          snapshot={trucker.snapshot}
          L={L}
          closeLabel={trucker.settings.locale.close ?? 'Đóng'}
          controller={controller}
          theme={theme}
          onThemeChange={setTheme}
        />
      ) : null}
    </>
  );
});

export default App;
