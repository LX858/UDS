import React, {useMemo, useState} from 'react';
import {observer} from 'mobx-react-lite';
import {Box, Text} from 'lr-components';
import TradeGrid from './TradeGrid';
import type {TradeEntry} from './trader.data';

type DoiVatPhamProps = {
  weapons: TradeEntry[];
  clothing: TradeEntry[];
  disabled?: boolean;
  onExchange: (entry: TradeEntry) => void;
  onPreview: (entry: TradeEntry) => void;
};

type Category = 'items' | 'clothes';
type Gender = 'male' | 'female';

const DoiVatPham = observer(({weapons, clothing, disabled = false, onExchange, onPreview}: DoiVatPhamProps) => {
  const [category, setCategory] = useState<Category>('items');
  const [gender, setGender] = useState<Gender>('male');
  const visibleClothes = useMemo(
    () => clothing.filter(item => item.gender === gender),
    [clothing, gender]
  );
  const items = category === 'items' ? weapons : visibleClothes;

  return (
    <Box className="items-layout" rWidth={1007} rHeight={469} rGap={30}>
      <Box className="items-sidebar" rLeft={-42} rWidth={150} rHeight={469} rPadding={[62, 0, 0]} rGap={24}>
        <Box
          className={`items-category-button ${category === 'items' ? 'is-active' : ''}`}
          rWidth={180}
          rHeight={65}
          rPadding={[0, 26, 2, 9]}
          onClick={() => setCategory('items')}
        >
          <Text rFontSize={17} rLineHeight={46} fontWeight={900}>Vật Phẩm</Text>
        </Box>
        <Box
          className={`items-category-button ${category === 'clothes' ? 'is-active' : ''}`}
          rWidth={180}
          rHeight={65}
          rPadding={[0, 26, 2, 9]}
          onClick={() => setCategory('clothes')}
        >
          <Text rFontSize={17} rLineHeight={46} fontWeight={900}>Quần Áo</Text>
        </Box>
      </Box>

      <Box className="items-panel" rLeft={-75} rWidth={827} rHeight={469} rPadding={[28, 38, 54, 0]}>
        {category === 'clothes' && (
          <Box className="gender-tabs z-50" rTop={25} rWidth={202} rHeight={36}>
            <Box
              className={`gender-button gender-button--left ${gender === 'male' ? 'is-active' : ''}`}
              rWidth={101}
              rHeight={36}
              onClick={() => setGender('male')}
            >
              <Text rFontSize={15} rLineHeight={33} fontWeight={900}>Nam</Text>
            </Box>
            <Box
              className={`gender-button gender-button--right ${gender === 'female' ? 'is-active' : ''}`}
              rWidth={101}
              rHeight={36}
              onClick={() => setGender('female')}
            >
              <Text rFontSize={15} rLineHeight={33} fontWeight={900}>Nữ</Text>
            </Box>
          </Box>
        )}
        <Box
          className="items-grid-slot"
          rHeight={category === 'clothes' ? 330 : 365}
          rMargin={[category === 'clothes' ? 64 : 25, 0, 0]}
          rPadding={[0, 0, 0, 60]}
        >
          <TradeGrid
            items={items}
            columns={4}
            height={335}
            emptyMessage="Chưa có vật phẩm trong danh mục này."
            disabled={disabled}
            onExchange={onExchange}
            onPreview={category === 'clothes' ? onPreview : undefined}
          />
        </Box>
      </Box>
    </Box>
  );
});

export default DoiVatPham;
