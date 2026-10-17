import { Box, Text } from 'lr-components';
import type { Currency, ShopItem } from '../services/app/main/main.service';

const formatNumber = (value: number) => new Intl.NumberFormat('vi-VN').format(value);

interface SelectDialogProps {
    item: ShopItem;
    currency: Currency;
    quantity: number;
    maxQuantity: number;
    loading: boolean;
    onCurrencyChange: (currency: Currency) => void;
    onQuantityChange: (quantity: number) => void;
    onMax: () => void;
    onClose: () => void;
    onConfirm: () => void;
}

const SelectDialog = ({
    item,
    currency,
    quantity,
    maxQuantity,
    loading,
    onCurrencyChange,
    onQuantityChange,
    onMax,
    onClose,
    onConfirm,
}: SelectDialogProps) => {
    const hasCashPrice = item.priceMoney !== undefined;

    return (
        <Box
            rWidth={655}
            rHeight={491}
            background="url(./assets/luachon.png) no-repeat center center / cover"
            className="absolute z-[100] flex items-center justify-center"
        >
            <Box
                rWidth={278}
                rHeight={278}
                background="url(./assets/tho.png) no-repeat center center / contain"
                className="absolute"
                rTop={-85}
                rLeft={-85}
            />
            <Box
                rWidth={278}
                rHeight={278}
                background="url(./assets/hangnga.png) no-repeat center center / contain"
                className="absolute"
                rBottom={-35}
                rRight={-155}
            />

            <Box
                rWidth={65}
                rHeight={65}
                background="url(./assets/thoat.png) no-repeat center center / contain"
                className="absolute pointer-events-auto hover:cursor-pointer hover:scale-105 hover:brightness-[1.2]"
                rTop={80}
                rRight={0}
                onClick={() => { if (!loading) onClose(); }}
            />

            <Box className="absolute flex items-center justify-center" rGap={5} rTop={215}>
                <Text
                    onClick={() => onCurrencyChange('coins')}
                    color={currency === 'coins' ? '#51f129' : '#360303'}
                    className="LilitaOne pointer-events-auto hover:cursor-pointer"
                    rFontSize={currency === 'coins' ? 60 : 50}
                    rLineHeight={50}
                    fontWeight={500}
                >
                    {formatNumber(item.price)} XU
                </Text>
                {hasCashPrice && (
                    <>
                        <Text color="#f75252" rFontSize={20} fontWeight={200}>HOẶC</Text>
                        <Text
                            onClick={() => onCurrencyChange('cash')}
                            color={currency === 'cash' ? '#51f129' : '#360303'}
                            className="LilitaOne pointer-events-auto hover:cursor-pointer"
                            rFontSize={currency === 'cash' ? 60 : 50}
                            rLineHeight={50}
                            fontWeight={500}
                        >
                            {formatNumber(item.priceMoney ?? 0)} IG
                        </Text>
                    </>
                )}
            </Box>

            <Box className="absolute" rTop={280}>
                <Box className="trader-quantity-control" rWidth={300} rHeight={34}>
                    <Text className="trader-quantity-label" rFontSize={13} rLineHeight={34} fontWeight={900}>
                        Số Lượng:
                    </Text>
                    <input
                        className="trader-quantity-input pointer-events-auto"
                        type="number"
                        inputMode="numeric"
                        min={1}
                        max={999}
                        value={quantity}
                        step={1}
                        disabled={loading}
                        aria-label="Số lượng mua"
                        placeholder="Nhập số lượng..."
                        onChange={event => onQuantityChange(Number(event.currentTarget.value))}
                        onWheel={event => event.currentTarget.blur()}
                    />
                    <Box className="trader-quantity-stepper pointer-events-auto" rWidth={20} rHeight={30}>
                        <button type="button" disabled={loading} aria-label="Tăng số lượng" onClick={() => onQuantityChange(quantity + 1)}>▲</button>
                        <button type="button" disabled={loading} aria-label="Giảm số lượng" onClick={() => onQuantityChange(quantity - 1)}>▼</button>
                    </Box>
                    <Box
                        className="trader-quantity-max pointer-events-auto"
                        aria-label={`Chọn tối đa ${maxQuantity}`}
                        onClick={() => { if (!loading) onMax(); }}
                    >
                        <Text rFontSize={13} rLineHeight={34} fontWeight={900}>Max</Text>
                    </Box>
                </Box>
            </Box>
            <Box
                rWidth={187}
                rHeight={63}
                background="url(./assets/xacnhan.png) no-repeat center center / contain"
                className="absolute left-1/2 -translate-x-1/2 pointer-events-auto hover:cursor-pointer hover:scale-105 hover:brightness-[1.2]"
                rBottom={105}
                onClick={() => { if (!loading) onConfirm(); }}
            />
        </Box>
    );
};

export default SelectDialog;
