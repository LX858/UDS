import { Box, Text } from 'lr-components';
import type { ShopItem } from '../services/app/main/main.service';

const formatNumber = (value: number) => new Intl.NumberFormat('vi-VN').format(value);

interface PriceItemProps {
    item?: ShopItem;
    disabled?: boolean;
    onBuy?: (item: ShopItem) => void;
}

const PriceItem = ({ item, disabled = false, onBuy }: PriceItemProps) => {
    if (!item) {
        return <Box rWidth={115} rHeight={145} />;
    }

    const discounted = item.price < item.basePrice;
    const image = item.image || './assets/previewitem.png';

    return (
        <Box
            rWidth={115}
            rHeight={145}
            className={`priceItem relative flex flex-col items-center justify-center${disabled ? ' priceItem--disabled' : ''}`}
            style={{ opacity: disabled ? 0.55 : 1 }}
        >
            <Box rWidth={115} rHeight={115} background={`url(${image}) no-repeat center center / contain`} />
            <Text rFontSize={15} rLineHeight={15} fontWeight={600} color="rgba(1, 51, 28, 0.8)">
                {item.label}
            </Text>
            <Box rWidth={115} rHeight={15} rGap={6} className="flex items-center justify-center">
                {discounted && (
                    <Text rLineHeight={15} rFontSize={15} fontWeight={600} color="#4eec05" textDecoration="line-through">
                        {formatNumber(item.basePrice)}
                    </Text>
                )}
                <Text rLineHeight={15} rFontSize={15} fontWeight={600} color="#4eec05">
                    {formatNumber(item.price)} XU
                </Text>
            </Box>
            <Box
                className="buy-btn absolute"
                rWidth={100}
                rHeight={45}
                background="url(./assets/mua.png) no-repeat center center / cover"
                onClick={() => { if (!disabled) onBuy?.(item); }}
            />
        </Box>
    );
};

export default PriceItem;
