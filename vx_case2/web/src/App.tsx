import { useEffect } from 'react';
import { Box } from 'lr-components';
import { isEnvBrowser } from './utils/misc';
import { fetchNui } from './utils/fetchNui';
import { observer } from 'mobx-react-lite';
import { useMainService } from './services/app/main/main.service';
import { ISetting } from './types';
import { useConfigService } from './services/config.service';
import Index from './components/Index';
import RewardDialog from './components/RewardDialog';
import SelectDialog from './components/SelectDialog';

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
                    fetchNui('Close');
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
            pointerEvents="none"
        >
            <Index />

            {mainService.showNotes && <Box
                className='absolute bg-black/50 z-50 w-full h-full flex items-center justify-center'
            >
                <Box
                    rWidth={1222}
                    rHeight={687}
                    className='ghichu'
                    rLeft={90}
                    rTop={50}
                    background={"url(./assets/bgghichu.png) no-repeat center center / contain"}
                >
                    <Box onClick={() => {mainService.toggleNotes(false)}} rLeft={460} className='absolute pointer-events-auto hover:cursor-pointer hover:scale-105 hover:brightness-[1.2]' rBottom={0} rWidth={291} rHeight={97} background={"url(./assets/dahieu.png) no-repeat center center / contain"}/>
                </Box>
            </Box>}

            {mainService.rewards && <Box className='absolute bg-black/50 z-[100] w-full h-full flex items-center justify-center'>
                <RewardDialog rewards={mainService.rewards} confirm={() => {mainService.clearRewards()}}/>    
            </Box>}
            {mainService.selectDialogOpen && mainService.selectedItem && !mainService.rewards && (
                <Box className='absolute bg-black/50 z-[100] w-full h-full flex items-center justify-center'>
                    <SelectDialog
                        item={mainService.selectedItem}
                        currency={mainService.currency}
                        quantity={mainService.quantity}
                        maxQuantity={mainService.maxQuantity}
                        loading={mainService.loadingAction === 'purchase'}
                        onCurrencyChange={currency => mainService.setCurrency(currency)}
                        onQuantityChange={quantity => mainService.setQuantity(quantity)}
                        onMax={() => mainService.setMaxQuantity()}
                        onClose={() => mainService.closePurchase()}
                        onConfirm={() => { void mainService.purchase(); }}
                    />
                </Box>
            )}
        </Box>
    );
});

export default App;
