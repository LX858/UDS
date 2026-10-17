import {useState} from 'react';
import {observer} from 'mobx-react-lite';
import {Box, Image, Text} from 'lr-components';
import {ArrowLeft} from 'lucide-react';
import DoiHom from './DoiHom';
import DoiVatPham from './DoiVatPham';
import {getMaxExchangeQuantity, type TradeEntry} from './trader.data';
import {useMainService} from '@/services/app/main/main.service';
import {useTraderService} from '@/services/app/trader/trader.service';
import './Trader.css';

type Selection = {
  entry: TradeEntry;
};

const Trader = observer(() => {
  const mainService = useMainService();
  const traderService = useTraderService();
  const {page} = mainService;
  const [selection, setSelection] = useState<Selection | null>(null);
  const [preview, setPreview] = useState<TradeEntry | null>(null);
  const [confirmed, setConfirmed] = useState(false);
  const [dialogMessage, setDialogMessage] = useState('');
  const [dialogError, setDialogError] = useState(false);
  const [quantity, setQuantity] = useState(1);

  const selectForExchange = (entry: TradeEntry) => {
    setConfirmed(false);
    setDialogMessage('');
    setDialogError(false);
    setQuantity(1);
    setSelection({entry});
  };

  const closeDialog = () => {
    setSelection(null);
    setConfirmed(false);
    setDialogMessage('');
    setDialogError(false);
    setQuantity(1);
  };

  const maxQuantity = selection
    ? getMaxExchangeQuantity(selection.entry)
    : 0;

  const setSafeQuantity = (nextQuantity: number) => {
    const safeMaximum = Math.max(1, maxQuantity);
    const normalized = Number.isFinite(nextQuantity)
      ? Math.trunc(nextQuantity)
      : 1;
    setQuantity(Math.min(safeMaximum, Math.max(1, normalized)));
  };

  const confirmExchange = async () => {
    if (!selection || traderService.exchanging) return;
    if (quantity < 1 || quantity > maxQuantity) {
      setDialogMessage('Số lượng quy đổi không hợp lệ.');
      setDialogError(true);
      return;
    }

    setDialogMessage('');
    setDialogError(false);
    const result = await traderService.exchange(selection.entry.id, quantity);
    setDialogMessage(result.message);
    setDialogError(!result.success);
    setConfirmed(result.success);

    if (!result.success && result.catalog) {
      const refreshedEntry = [
        ...result.catalog.chests,
        ...result.catalog.items,
        ...result.catalog.outfits,
      ].find(entry => entry.id === selection.entry.id);

      if (refreshedEntry) {
        const refreshedMaximum = getMaxExchangeQuantity(refreshedEntry);
        setSelection({entry: refreshedEntry});
        setQuantity(current => Math.max(1, Math.min(current, refreshedMaximum || 1)));
      }
    }
  };

  const exchangeFormula = selection
    ? `${selection.entry.costs
      .map(cost => `${cost.required * quantity} ${cost.label}`)
      .join(' + ')} = x${(selection.entry.rewardAmount ?? 1) * quantity} ${selection.entry.name}`
    : '';

  return (
    <Box className="trader-stage" rWidth={1231} rHeight={747}>
      <Box className={`trader-frame ${preview ? 'is-previewing' : ''}`} rWidth={1231} rHeight={747}>
        <Box className="trader-main-tabs" rTop={160} rWidth={360} rHeight={65}>
          <Box
            className={`trader-main-tab trader-main-tab--left ${page === 'home' ? 'is-active' : ''}`}
            rWidth={180}
            rHeight={65}
            onClick={() => mainService.setPage('home')}
          >
            <Text rFontSize={22} rLineHeight={65} fontWeight={900}>Đổi Hòm</Text>
          </Box>
          <Box
            className={`trader-main-tab trader-main-tab--right ${page === 'items' ? 'is-active' : ''}`}
            rWidth={180}
            rHeight={65}
            onClick={() => mainService.setPage('items')}
          >
            <Text rFontSize={22} rLineHeight={65} fontWeight={900}>Đổi Vật Phẩm</Text>
          </Box>
        </Box>

        <Box className="trader-content" rTop={202} rLeft={112} rWidth={1007} rHeight={469}>
          {page === 'home' ? (
            <DoiHom
              items={traderService.catalog.chests}
              disabled={traderService.loading || traderService.exchanging}
              onExchange={selectForExchange}
            />
          ) : (
            <DoiVatPham
              weapons={traderService.catalog.items}
              clothing={traderService.catalog.outfits}
              disabled={traderService.loading || traderService.exchanging}
              onExchange={selectForExchange}
              onPreview={setPreview}
            />
          )}
        </Box>

        {preview && (
          <Box className="outfit-preview" rWidth={1231} rHeight={747}>
            <Box
              className="outfit-preview-back"
              rTop={203}
              rLeft={145}
              rHeight={34}
              rGap={8}
              onClick={() => setPreview(null)}
            >
              <Box className="outfit-preview-back-icon" rWidth={30} rHeight={30}>
                <ArrowLeft aria-hidden="true" strokeWidth={3.2} />
              </Box>
              <Text className="outfit-preview-title" rFontSize={25} rLineHeight={32} fontWeight={900}>
                Xem Trước
              </Text>
            </Box>
            <Image
              className="outfit-preview-art"
              src={preview.image}
              alt={preview.name}
              fallbackSrc="./assets/no-picture.png"
              rTop={170}
              rWidth={360}
              rHeight={470}
            />
            <Box
              className="outfit-preview-close"
              rTop={55}
              rRight={72}
              rWidth={46}
              rHeight={46}
              onClick={() => setPreview(null)}
            >
              <Text rFontSize={34} rLineHeight={41} fontWeight={900}>×</Text>
            </Box>
          </Box>
        )}
      </Box>

      {selection && (
        <Box className="trader-dialog-layer" onClick={closeDialog}>
          <Box
            className="trader-dialog"
            rWidth={655}
            rHeight={491}
            role="dialog"
            aria-modal="true"
            aria-label={`Quy đổi ${selection.entry.name}`}
            onClick={event => event.stopPropagation()}
          >
            <Image
              className="trader-dialog-mascot trader-dialog-mascot--rabbit"
              src="./assets/tho.png"
              alt=""
              rTop={-48}
              rLeft={-68}
              rWidth={258}
              rHeight={258}
            />
            <Image
              className="trader-dialog-mascot trader-dialog-mascot--girl"
              src="./assets/hangnga.png"
              alt=""
              rRight={-96}
              rBottom={-82}
              rWidth={342}
              rHeight={342}
            />
            <Box
              className="trader-dialog-close"
              rTop={81}
              rRight={25}
              rWidth={36}
              rHeight={36}
              role="button"
              tabIndex={0}
              aria-label="Đóng"
              onClick={closeDialog}
              onKeyDown={event => {
                if (event.key === 'Enter' || event.key === ' ') closeDialog();
              }}
            >
              <Text rFontSize={25} rLineHeight={30} fontWeight={900}>×</Text>
            </Box>

            <Box className="trader-dialog-body" rTop={179} rLeft={98} rWidth={459} rHeight={216}>
              <Text className="trader-dialog-kicker" rFontSize={12} rLineHeight={16} fontWeight={900}>
                Quy Đổi Vật Phẩm
              </Text>
              <Text className="trader-dialog-formula" rMaxWidth={430} rFontSize={22} rLineHeight={29} fontWeight={900}>
                {exchangeFormula}
              </Text>
              <Text
                className={`trader-dialog-message ${dialogError ? 'is-error' : ''}`}
                rMinHeight={18}
                rFontSize={13}
                rLineHeight={18}
                fontWeight={900}
              >
                {traderService.exchanging ? 'Đang xử lý giao dịch...' : dialogMessage}
              </Text>

              <Box className={`trader-quantity-control ${confirmed ? 'is-disabled' : ''}`} rWidth={300} rHeight={34}>
                <Text className="trader-quantity-label" rFontSize={13} rLineHeight={34} fontWeight={900}>
                  Số Lượng:
                </Text>
                <input
                  className="trader-quantity-input"
                  type="number"
                  inputMode="numeric"
                  min={1}
                  max={maxQuantity}
                  step={1}
                  value={quantity}
                  disabled={confirmed || traderService.exchanging}
                  aria-label="Số lượng quy đổi"
                  onChange={event => setSafeQuantity(Number(event.target.value))}
                  onWheel={event => event.currentTarget.blur()}
                  onKeyDown={event => {
                    if (event.key === 'Enter') void confirmExchange();
                  }}
                />
                <Box className="trader-quantity-stepper" rWidth={20} rHeight={30}>
                  <button
                    type="button"
                    aria-label="Tăng số lượng"
                    disabled={confirmed || traderService.exchanging || quantity >= maxQuantity}
                    onClick={() => setSafeQuantity(quantity + 1)}
                  >▲</button>
                  <button
                    type="button"
                    aria-label="Giảm số lượng"
                    disabled={confirmed || traderService.exchanging || quantity <= 1}
                    onClick={() => setSafeQuantity(quantity - 1)}
                  >▼</button>
                </Box>
                <Box
                  className="trader-quantity-max"
                  role="button"
                  tabIndex={confirmed || traderService.exchanging ? -1 : 0}
                  aria-label={`Chọn tối đa ${maxQuantity}`}
                  onClick={() => {
                    if (!confirmed && !traderService.exchanging) setSafeQuantity(maxQuantity);
                  }}
                  onKeyDown={event => {
                    if ((event.key === 'Enter' || event.key === ' ') && !confirmed && !traderService.exchanging) {
                      setSafeQuantity(maxQuantity);
                    }
                  }}
                >
                  <Text rFontSize={13} rLineHeight={34} fontWeight={900}>Max</Text>
                </Box>
              </Box>

              <Box
                className={`trader-confirm-button ${traderService.exchanging ? 'is-busy' : ''}`}
                rWidth={187}
                rHeight={63}
                onClick={confirmed ? closeDialog : confirmExchange}
                role="button"
                tabIndex={traderService.exchanging ? -1 : 0}
                aria-label={confirmed ? 'Đóng' : 'Xác nhận quy đổi'}
                onKeyDown={event => {
                  if (event.key === 'Enter' || event.key === ' ') {
                    if (confirmed) closeDialog();
                    else void confirmExchange();
                  }
                }}
              />
            </Box>
          </Box>
        </Box>
      )}
    </Box>
  );
});

export default Trader;
