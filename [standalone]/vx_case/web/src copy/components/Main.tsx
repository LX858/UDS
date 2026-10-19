import { useEffect, useRef } from 'react';
import { Box, Image, Text } from 'lr-components';
import { observer } from 'mobx-react-lite';
import { gsap } from 'gsap';
import { useMainService } from '../services/app/main/main.service';
import { IReward } from '../services/app/main/main.service';
import Chest from './Chest';

const Main = observer(() => {
    const mainService = useMainService();
    const { state, count, result, spinningItems, spinRound, currentRewardIndex } = mainService;
  const trackRef = useRef<HTMLDivElement | null>(null);
  const viewportRef = useRef<HTMLDivElement | null>(null);
  const arrowRef = useRef<HTMLDivElement | null>(null);
  const itemRefs = useRef<Map<number, HTMLDivElement>>(new Map());
  const spinAudioRef = useRef<HTMLAudioElement | null>(null);
    const isIdle = state === 'idle';
    const isOpening = state === 'opening';
  const isReward = state === 'reward';

  useEffect(() => {
    if (!isOpening) return;

    const audio = new Audio('./assets/spinning.mp3');
    audio.volume = 0.3;
    spinAudioRef.current = audio;
    audio.currentTime = 0;
    audio.play().catch(error => console.warn('Không thể phát âm thanh quay:', error));

    return () => {
      audio.pause();
      audio.currentTime = 0;
      if (spinAudioRef.current === audio) spinAudioRef.current = null;
    };
  }, [isOpening, spinRound]);

    useEffect(() => {
        if (!isOpening || !trackRef.current || !viewportRef.current) return;
        const targetIndex = currentRewardIndex;
        const target = itemRefs.current.get(targetIndex);
        if (targetIndex < 0 || !target) return;

        const track = trackRef.current;
        const viewport = viewportRef.current;
        const arrow = arrowRef.current;
        if (arrow) {
            gsap.killTweensOf(arrow);
            gsap.set(arrow, { rotation: 0 });
            gsap.to(arrow, {
                rotation: 2160,
                duration: 8,
                ease: 'power2.inOut',
            });
        }
        gsap.killTweensOf(track);
        const currentX = Number(gsap.getProperty(track, 'x')) || 0;
        const viewportRect = viewport.getBoundingClientRect();
        const targetRect = target.getBoundingClientRect();
        const offsetX = viewportRect.left + viewportRect.width / 2 - (targetRect.left + targetRect.width / 2);
        let finishTimer: ReturnType<typeof setTimeout> | undefined;
        let highlightTween: gsap.core.Tween | undefined;
        const tween = gsap.to(track, { x: currentX + offsetX, duration: 8, ease: 'power2.inOut', onComplete: () => {
            highlightTween = gsap.to(target, {
                scale: 1.18,
                duration: 0.35,
                ease: 'back.out(1.7)',
                onComplete: () => {
                    finishTimer = setTimeout(() => mainService.finishOpening(), 1000);
                },
            });
        } });
        return () => {
            tween.kill();
            if (arrow) gsap.killTweensOf(arrow);
            if (highlightTween) highlightTween.kill();
            if (finishTimer) clearTimeout(finishTimer);
        };
    }, [isOpening, mainService, spinningItems, currentRewardIndex]);

    const getItemImage = (item: IReward) => {
        if (item.metadata?.imageurl) return item.metadata.imageurl;
        return `https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/${item.name}.webp`;
    };

    const getRewardLabel = () => result.map(item => {
        const amount = item.amount || 1;
        return amount > 1 ? `${amount} ${item.label || item.name}` : (item.label || item.name);
    }).join(', ');

    const rewardItems = mainService.mutiplier === 5 ? result.slice(0, 5) : result.slice(0, 1);

    return (
        <Box rWidth={1178} rHeight={662} background={`url(./assets/${isIdle ? 'bg' : 'blurbg'}.png) no-repeat center center / contain`} className='relative'>
            <Box className={`absolute transition-opacity duration-500 ${isIdle ? 'opacity-100' : 'opacity-0'}`} rWidth={183.26} rHeight={61.09} background='url(./assets/conlai.png) no-repeat center center / contain' rTop={10} rLeft={225}>
                <Box className='absolute flex items-center justify-center text-[#FFD63D]' rWidth={50} rHeight={20} rBottom={18} rRight={45}><Text rFontSize={15}>{count}</Text></Box>
            </Box>
            <Chest isVisible={isIdle} />

            <Box rWidth={339} rHeight={339} className='absolute nhanvat z-[50]' rLeft={isIdle ? 0 : -225} rBottom={120}>
                <Image className='h-full w-full' src='./assets/tho.png' />
                <span className='sparkle sparkle-1'>✦</span><span className='sparkle sparkle-2'>✦</span><span className='sparkle sparkle-3'>✧</span><span className='sparkle sparkle-4'>✦</span>
            </Box>
            <Box rWidth={339} rHeight={339} className='absolute nhanvat z-[50]' rRight={isIdle ? 0 : -225} rBottom={120}>
                <Image className='h-full w-full' src='./assets/hangnga.png' />
                <span className='sparkle sparkle-1'>✦</span><span className='sparkle sparkle-2'>✦</span><span className='sparkle sparkle-3'>✧</span><span className='sparkle sparkle-4'>✦</span>
            </Box>

            {isOpening && <Box className='absolute left-0 bottom-[20%] z-[10] flex w-full flex-col items-center justify-center' rHeight={295} rBottom={180} rGap={10}>
                <Box ref={arrowRef} rWidth={105} rHeight={105} background='url(./assets/muiten.png) no-repeat center center / contain' />
                <Box ref={viewportRef} className='w-full overflow-hidden' rHeight={180}>
                    <Box ref={trackRef} className='flex h-full w-max items-center gap-[15px] px-[32px]'>
                        {spinningItems.map((item, index) => <Box key={`${item.name}-${index}`} ref={element => { if (element) itemRefs.current.set(index, element); else itemRefs.current.delete(index); }} rWidth={150} rHeight={150} className='flex flex-shrink-0 items-center justify-center' rPadding={[15, 0, 0, 0]} background='url(./assets/item-bg.png) no-repeat center center / contain'>
                            <Box rWidth={69} rHeight={69} background={`url(${getItemImage(item)}) no-repeat center center / contain`} />
                        </Box>)}
                    </Box>
                </Box>
            </Box>}

            {isIdle && <Box rWidth={329} rHeight={110} background='url(./assets/open.png) no-repeat center center / contain' className='absolute left-[50%] -translate-x-1/2 transition-transform hover:scale-105 hover:cursor-pointer' rBottom={40} pointerEvents='auto' onClick={() => mainService.openChest()} />}
            {isIdle && <Box
                rWidth={128}
                rHeight={28}
                className='roboto absolute left-[50%] -translate-x-1/2 flex items-center justify-center gap-1 rounded-full border border-[#FFD778] bg-gradient-to-r from-[#7A2B08] via-[#D56D18] to-[#7A2B08] px-2 shadow-[0_2px_0_rgba(75,24,5,0.7),0_0_10px_rgba(255,190,64,0.35)] transition-all duration-200 hover:scale-105 hover:brightness-110 hover:cursor-pointer'
                rBottom={18}
                pointerEvents='auto'
                onClick={() => mainService.changeMultiplier()}
            >
                <Text className='roboto text-[#FFF2B0]' rFontSize={12} fontWeight={700}>SỐ LƯỢNG</Text>
                <Box className='flex items-center gap-0.5 rounded-full bg-black/30 px-1 py-0.5'>
                    <Text className={mainService.mutiplier === 1 ? 'text-white' : 'text-white/45'} rFontSize={10} fontWeight={700}>×1</Text>
                    <Text className='roboto text-white/60' rFontSize={12}>/</Text>
                    <Text className={mainService.mutiplier === 5 ? 'text-[#FFF27A]' : 'text-white/45'} rFontSize={10} fontWeight={700}>×5</Text>
                </Box>
            </Box>}
            {isReward && result[0] && <Box className='absolute inset-0 z-[60] flex flex-col items-center justify-center' pointerEvents='auto'>
                <Box rWidth={400} rHeight={133} background='url(./assets/chucmung.png) center / contain' />
                <Box className='rounded-full border border-[#FFD778] bg-[#6E260D]/80 px-4 py-1 shadow-[0_0_12px_rgba(255,190,64,0.35)]'>
                    <Text className='roboto text-[#FFF2B0]' rFontSize={15} fontWeight={700}>LƯỢT QUAY ×{mainService.mutiplier}</Text>
                </Box>
                <Box className={`flex items-center justify-center gap-3 ${mainService.mutiplier === 5 ? 'w-[94%]' : ''}`}>
                    {rewardItems.map((item, index) => (
                        <Box
                            key={`${item.name}-${index}`}
                            rWidth={mainService.mutiplier === 5 ? 112 : 180}
                            rHeight={mainService.mutiplier === 5 ? 112 : 180}
                            className='flex flex-shrink-0 items-center justify-center'
                            background='url(./assets/item-bg.png) center / contain'
                            rPadding={[15, 0, 0, 0]}
                        >
                            <Image
                                rWidth={mainService.mutiplier === 5 ? 50 : 95}
                                rHeight={mainService.mutiplier === 5 ? 50 : 95}
                                src={getItemImage(item)}
                            />
                        </Box>
                    ))}
                </Box>
                <Text className='roboto mt-2 text-center text-white' rFontSize={18}>{getRewardLabel()}</Text>
                <Box className='flex items-center justify-center' rWidth={600}>
                    <Box rWidth={228} rHeight={98} background='url(./assets/quaytiep.png) no-repeat center center / contain' className='mt-4 hover:scale-105 hover:cursor-pointer' onClick={() => mainService.spinAgain()} />
                </Box>
            </Box>}
        </Box>
    );
});

export default Main;
