import { useRef, useState, type CSSProperties, type TransitionEvent } from 'react';
import { Box, Text } from 'lr-components';
import { observer } from 'mobx-react-lite';
import { useMainService } from '../services/app/main/main.service';
import PriceItem from './PriceItem';

const FULL_TURN = 360;
const EXTRA_TURNS = 6;

type WheelStyle = CSSProperties & {
    '--wheel-rotation': string;
    '--wheel-background': string;
};

const normalizeAngle = (angle: number) =>
    ((angle % FULL_TURN) + FULL_TURN) % FULL_TURN;

const getTargetRotation = (
    currentRotation: number,
    selectedIndex: number,
    itemCount: number
) => {
    const sliceAngle = FULL_TURN / itemCount;
    const currentAngle = normalizeAngle(currentRotation);
    const targetAngle = normalizeAngle(-selectedIndex * sliceAngle);
    const alignmentDelta = normalizeAngle(targetAngle - currentAngle);

    return currentRotation + EXTRA_TURNS * FULL_TURN + alignmentDelta;
};

const createWheelBackground = (itemCount: number) => {
    if (itemCount <= 0) {
        return 'radial-gradient(circle, #8a130e 0%, #3c0806 100%)';
    }

    const sliceAngle = FULL_TURN / itemCount;
    const dividerAngle = Math.min(1.5, sliceAngle * 0.08);
    const colors = ['#c91c17', '#e99c16'];
    const stops = Array.from({ length: itemCount }, (_, index) => {
        const start = index * sliceAngle;
        const dividerStart = (index + 1) * sliceAngle - dividerAngle;
        const end = (index + 1) * sliceAngle;

        return [
            `${colors[index % colors.length]} ${start}deg ${dividerStart}deg`,
            `#ffe093 ${dividerStart}deg ${end}deg`,
        ].join(', ');
    }).join(', ');

    return `conic-gradient(from ${-sliceAngle / 2}deg, ${stops})`;
};

const Index = observer(() => {
    const mainService = useMainService();

    const { spinItems } = mainService;
    const [rotation, setRotation] = useState(0);
    const [isSpinning, setIsSpinning] = useState(false);
    const [isSpinSequenceActive, setIsSpinSequenceActive] = useState(false);
    const [pendingIndex, setPendingIndex] = useState<number | null>(null);
    const [pendingRewardLabel, setPendingRewardLabel] = useState<string>();
    const [selectedIndex, setSelectedIndex] = useState<number | null>(null);
    const spinAudioRef = useRef<HTMLAudioElement | null>(null);

    const itemCount = spinItems.length;
    const sliceAngle = itemCount > 0 ? FULL_TURN / itemCount : 0;
    const wheelStyle: WheelStyle = {
        '--wheel-rotation': `${rotation}deg`,
        '--wheel-background': createWheelBackground(itemCount),
    };

    const handleSpin = async () => {
        if (
            isSpinning ||
            isSpinSequenceActive ||
            itemCount === 0 ||
            !mainService.canSpin ||
            !mainService.canInteract
        ) return;

        const response = await mainService.spin();
        const nextIndex = response.result?.index;
        if (!response.ok || nextIndex === undefined || nextIndex < 0 || nextIndex >= itemCount) return;
        const spinAudio = spinAudioRef.current;

        mainService.clearRewards();
        setIsSpinSequenceActive(true);
        if (spinAudio) {
            spinAudio.volume = 0.3;
            spinAudio.pause();
            spinAudio.currentTime = 0;
            void spinAudio.play().catch(() => {
                setIsSpinSequenceActive(false);
            });
        } else {
            setIsSpinSequenceActive(false);
        }

        setSelectedIndex(null);
        setPendingIndex(nextIndex);
        setPendingRewardLabel(response.result?.reward.label);
        setIsSpinning(true);
        setRotation(currentRotation =>
            getTargetRotation(currentRotation, nextIndex, itemCount)
        );
    };

    const handleSpinEnd = (event: TransitionEvent<HTMLDivElement>) => {
        if (
            event.target !== event.currentTarget ||
            event.propertyName !== 'transform' ||
            !isSpinning
        ) {
            return;
        }

        if (pendingIndex === null) {
            setIsSpinning(false);
            return;
        }

        const selectedItem = spinItems[pendingIndex];

        setSelectedIndex(pendingIndex);
        setPendingIndex(null);
        setIsSpinning(false);

        if (selectedItem) {
            mainService.setRewards(pendingRewardLabel ?? selectedItem.label);
        }
        setPendingRewardLabel(undefined);
    };

    const handleSpinAudioEnd = () => {
        setIsSpinSequenceActive(false);
    };

    return (
        <Box
            rWidth={1414}
            rHeight={795}
            background={"url(./assets/bg.png) no-repeat center center / contain"}
            className='relative'
        >
            <Box className='absolute z-20' rLeft={-39} rTop={-39} rWidth={226} rHeight={795} background={"url(./assets/nv.png) no-repeat center center / contain"} />
            <Box
                rWidth={374}
                rHeight={163}
                background={"url(./assets/bg2.png) no-repeat center center / contain"}
                className='absolute z-50 flex flex-col items-center justify-center'
                rBottom={0}
                rLeft={-10}
                rPadding={[39, 0, 0, 0]}
                rGap={5}
            >
                <Text className='lalezar' color='#FF0000' rFontSize={15} rLineHeight={16}>TIỀN XU NHẬN QUÀ</Text>
                <Text className='lalezar' color='#070000' rFontSize={25} rLineHeight={26} textShadow='0 0 2.5px black'>
                    {mainService.state.progress} / {mainService.state.milestoneTarget} XU
                </Text>
            </Box>
            <Box
                rWidth={310}
                rHeight={110}
                background={"url(./assets/bg3.png) no-repeat center center / contain"}
                className='absolute'
                rBottom={0}
                rLeft={295}
            >
                {/* todo special items */}
            </Box>

            <Box
                rWidth={536}
                rHeight={679}
                rLeft={125}
                rTop={-10}
                className='absolute z-10 flex flex-col items-center justify-center'
            >
                <Box
                    rWidth={100}
                    rHeight={100}
                    background={"url(./assets/muiten.png) no-repeat center center / contain"}
                    className='wheel-pointer relative z-30'
                />
                <Box
                    rWidth={480}
                    rHeight={480}
                    className='wheel-stage relative rounded-full vongquay'
                >
                    <div
                        className={`wheel-disc${isSpinning ? ' wheel-disc--spinning' : ''}`}
                        style={wheelStyle}
                        onTransitionEnd={handleSpinEnd}
                    >
                        {spinItems.map((item, index) => (
                            <div
                                className='wheel-item-spoke'
                                style={{ transform: `rotate(${index * sliceAngle}deg)` }}
                                key={item.id}
                            >
                                <div className='wheel-item'>
                                    <Text
                                        rFontSize={20}
                                        fontWeight={600}
                                        className={`wheel-item__label Roboto ${selectedIndex === index
                                            ? ' wheel-item__label--selected'
                                            : ''
                                            }`}
                                    >
                                        {item.label}
                                    </Text>
                                </div>
                            </div>
                        ))}
                    </div>

                    <button
                        aria-label={
                            isSpinning
                                ? 'Vòng quay đang quay'
                                : isSpinSequenceActive
                                    ? 'Đang phát âm thanh phần thưởng'
                                    : 'Quay thưởng'
                        }
                        className='spin-button'
                        disabled={
                            isSpinning ||
                            isSpinSequenceActive ||
                            itemCount === 0 ||
                            !mainService.canSpin ||
                            !mainService.canInteract
                        }
                        onClick={handleSpin}
                        style={{ backgroundImage: 'url(./assets/quay.png)' }}
                        type='button'
                    />

                    <audio
                        onEnded={handleSpinAudioEnd}
                        onError={handleSpinAudioEnd}
                        preload='auto'
                        ref={spinAudioRef}
                        src='./assets/spinning-wheel.mp3'
                    />

                    <span className='sr-only' aria-live='polite'>
                        {selectedIndex !== null
                            ? `Bạn đã quay trúng ${spinItems[selectedIndex]?.label ?? ''}`
                            : ''}
                    </span>
                </Box>
            </Box>
            <Box
                rWidth={121}
                rHeight={43}
                background={"url(./assets/ghichu.png) no-repeat center center / contain"}
                className='absolute pointer-events-auto hover:cursor-pointer hover:scale-105 hover:brightness-[1.2]'
                rBottom={10}
                rRight={10}
                onClick={() => { mainService.toggleNotes(true) }}
            />
            <Box
                rWidth={741}
                rHeight={452}
                background={"url(./assets/bg5.png) no-repeat center center / contain"}
                rRight={25}
                rTop={100}
                className='absolute'
            >
                {!mainService.rewards && <Box
                    rWidth={278}
                    rHeight={278}
                    background={"url(./assets/tho.png) no-repeat center center / contain"}
                    className='absolute'
                    rTop={-125}
                />}
                {!mainService.rewards && <Box
                    rWidth={278}
                    rHeight={278}
                    background={"url(./assets/hangnga.png) no-repeat center center / contain"}
                    className='absolute'
                    rTop={-125}
                    rRight={0}
                />}
                <Box
                    rWidth={288}
                    rHeight={96}
                    background={"url(./assets/lammoi.png) no-repeat center center / contain"}
                    className={`absolute left-1/2 -translate-x-1/2 ${mainService.canInteract
                        ? 'pointer-events-auto hover:cursor-pointer hover:scale-105 hover:brightness-[1.2]'
                        : 'opacity-50'
                        }`}
                    rBottom={-100}
                    onClick={() => { void mainService.refreshItems(); }}
                />

                <Box
                    rWidth={650}
                    rHeight={300}
                    rTop={100}
                    className='absolute left-1/2 -translate-x-1/2'
                >
                    <Box className='absolute top-1/2 -translate-y-1/2' rLeft={25}>
                        <PriceItem item={mainService.state.shopItems[0]} disabled={!mainService.canInteract} onBuy={item => mainService.openPurchase(item)} />
                    </Box>
                    <Box rLeft={190} className='absolute flex flex-col items-center justify-center' rGap={0}>
                        <PriceItem item={mainService.state.shopItems[1]} disabled={!mainService.canInteract} onBuy={item => mainService.openPurchase(item)} />
                        <PriceItem item={mainService.state.shopItems[2]} disabled={!mainService.canInteract} onBuy={item => mainService.openPurchase(item)} />
                    </Box>
                    <Box rRight={190} className='absolute flex flex-col items-center justify-center' rGap={0}>
                        <PriceItem item={mainService.state.shopItems[3]} disabled={!mainService.canInteract} onBuy={item => mainService.openPurchase(item)} />
                        <PriceItem item={mainService.state.shopItems[4]} disabled={!mainService.canInteract} onBuy={item => mainService.openPurchase(item)} />
                    </Box>
                    <Box className='absolute top-1/2 -translate-y-1/2' rRight={25}>
                        <PriceItem item={mainService.state.shopItems[5]} disabled={!mainService.canInteract} onBuy={item => mainService.openPurchase(item)} />
                    </Box>
                </Box>
            </Box>
        </Box>
    )
})

export default Index;
