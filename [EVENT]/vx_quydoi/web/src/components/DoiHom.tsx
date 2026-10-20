import {observer} from 'mobx-react-lite';
import {Box} from 'lr-components';
import TradeGrid from './TradeGrid';
import type {TradeEntry} from './trader.data';

type DoiHomProps = {
  items: TradeEntry[];
  disabled?: boolean;
  onExchange: (entry: TradeEntry) => void;
};

const DoiHom = observer(({items, disabled = false, onExchange}: DoiHomProps) => (
  <Box className='flex items-center justify-center' rPadding={[25, 0, 0, 0]}>
    <TradeGrid
      items={items}
      columns={5}
      height={380}
      emptyMessage="Chưa có hòm để quy đổi."
      disabled={disabled}
      onExchange={onExchange}
    />
  </Box>
));

export default DoiHom;
