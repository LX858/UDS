import {observer} from 'mobx-react-lite';
import {Box, Image, Text} from 'lr-components';
import {canExchangeEntry} from './trader.data';
import type {TradeEntry} from './trader.data';

type DoiHomProps = {
  items: TradeEntry[];
  disabled?: boolean;
  onExchange: (entry: TradeEntry) => void;
};

const DoiHom = observer(({items, disabled = false, onExchange}: DoiHomProps) => {
  if (!items.length) {
    return <Text className="trader-empty" rFontSize={23} fontWeight={900}>Chưa có hòm để quy đổi.</Text>;
  }

  return (
    <Box className="chest-grid" rWidth={826} rHeight={469} rColumnGap={42} rRowGap={8}>
      {items.map(chest => {
        const canExchange = canExchangeEntry(chest) && !disabled;

        return (
          <Box className="chest-entry" key={chest.id}>
            <Box className="chest-art-wrap" rWidth={132} rHeight={104}>
              <Image
                className="chest-art"
                src={chest.image}
                alt={chest.name}
                fallbackSrc="./assets/no-picture.png"
                rWidth={116}
                rHeight={92}
              />
            </Box>
            <Text variant="h2" className="chest-title" rMaxWidth={210} rFontSize={17} rLineHeight={18} rMargin={[-2, 0, 2]} fontWeight={900}>
              {chest.name}
            </Text>
            <Box className="chest-cost-row" rMinHeight={17}>
              {chest.costs.map(cost => (
                <Text className={cost.owned >= cost.required ? 'is-ready' : 'is-missing'} rFontSize={12} fontWeight={800} key={cost.label}>
                  {cost.label} {cost.owned}/{cost.required}
                </Text>
              ))}
            </Box>
            <Box
              className={`exchange-image-button ${canExchange ? 'is-ready' : 'is-disabled'}`}
              rWidth={105}
              rHeight={35}
              rMargin={[2, 0, 0]}
              onClick={() => canExchange && onExchange(chest)}
            >
              {/* <Text rFontSize={13} rLineHeight={35} fontWeight={900}>Quy Đổi</Text> */}
            </Box>
          </Box>
        );
      })}
    </Box>
  );
});

export default DoiHom;
