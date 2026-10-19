import React from 'react';
import {Box, Image, Text} from 'lr-components';
import {canExchangeEntry} from './trader.data';
import type {TradeEntry} from './trader.data';

type TradeGridProps = {
  items: TradeEntry[];
  columns: 4 | 5;
  height: number;
  emptyMessage: string;
  disabled?: boolean;
  onExchange: (entry: TradeEntry) => void;
  onPreview?: (entry: TradeEntry) => void;
};

const TradeGrid = ({
  items, columns, height, emptyMessage, disabled = false, onExchange, onPreview,
}: TradeGridProps) => {
  if (!items.length) {
    return (
      <Box className="trader-empty" rWidth={columns === 5 ? 1007 : 786} rHeight={height}>
        <Text rFontSize={23} fontWeight={900}>{emptyMessage}</Text>
      </Box>
    );
  }

  return (
    <Box
      className="trade-grid bg-black"
      rWidth={columns === 5 ? 900 : 786}
      rHeight={height}
      rGridTemplateColumns={[columns, 180]}
      rColumnGap={columns === 5 ? 20 : 14}
      rRowGap={12}
    >
      {items.map(item => {
        const available = canExchangeEntry(item) && !disabled;
        const exchange = () => {
          if (available) onExchange(item);
        };

        return (
          <Box className="trade-card" rWidth={180} rHeight={250} rPadding={[8, 10, 10]} key={item.id}>
            <Box className={`trade-card-media ${onPreview ? 'is-outfit' : ''}`} rWidth={160} rHeight={99}>
              <Image
                className="trade-card-art"
                src={item.image}
                alt={item.name}
                fallbackSrc="./assets/no-picture.png"
                rWidth={132}
                rHeight={95}
              />
              {onPreview && (
                <Box
                  className="trade-card-preview"
                  rTop={4}
                  rRight={4}
                  rWidth={23}
                  rHeight={23}
                  role="button"
                  tabIndex={0}
                  aria-label={`Xem trước ${item.name}`}
                  onClick={() => onPreview(item)}
                  onKeyDown={event => {
                    if (event.key === 'Enter' || event.key === ' ') {
                      event.preventDefault();
                      onPreview(item);
                    }
                  }}
                >
                  <Image src="./assets/view.png" alt="" rWidth={17} rHeight={17} />
                </Box>
              )}
            </Box>
            <Text className="trade-card-name" title={item.name} rWidth={160} rHeight={36} rFontSize={15} rLineHeight={17} fontWeight={900}>
              {item.name}
            </Text>
            <Box className="trade-card-costs" rWidth={160} rHeight={61}>
              {item.costs.map(cost => (
                <Text
                  className={`trade-card-cost ${cost.owned >= cost.required ? 'is-ready' : 'is-missing'}`}
                  title={`${cost.label}: ${cost.owned}/${cost.required}`}
                  rFontSize={13}
                  rLineHeight={20}
                  key={cost.item}
                >
                  {cost.label}: {cost.owned}/{cost.required}
                </Text>
              ))}
            </Box>
            <Box
              className={`trade-card-exchange ${available ? '' : 'is-disabled'}`}
              rWidth={101}
              rHeight={32}
              role="button"
              tabIndex={available ? 0 : -1}
              aria-label={`Quy đổi ${item.name}`}
              aria-disabled={!available}
              onClick={exchange}
              onKeyDown={event => {
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault();
                  exchange();
                }
              }}
            />
          </Box>
        );
      })}
    </Box>
  );
};

export default TradeGrid;
