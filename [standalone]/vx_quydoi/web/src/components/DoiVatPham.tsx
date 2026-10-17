import {useMemo, useState} from 'react';
import {observer} from 'mobx-react-lite';
import {Box, Image, Text} from 'lr-components';
import {canExchangeEntry, getItemImage} from './trader.data';
import type {TradeCost, TradeEntry} from './trader.data';

type DoiVatPhamProps = {
  weapons: TradeEntry[];
  clothing: TradeEntry[];
  disabled?: boolean;
  onExchange: (entry: TradeEntry) => void;
  onPreview: (entry: TradeEntry) => void;
};

type Category = 'items' | 'clothes';
type Gender = 'male' | 'female';

const ItemImage = ({item, className, width, height}: {item: TradeEntry; className: string; width: number; height: number}) => (
  <Image
    className={className}
    src={item.image}
    alt={item.name}
    fallbackSrc="./assets/no-picture.png"
    rWidth={width}
    rHeight={height}
  />
);

const CostRequirement = ({cost, compact = false}: {cost?: TradeCost; compact?: boolean}) => {
  if (!cost) return null;

  const isReady = cost.owned >= cost.required;
  return (
    <Box
      className={`trade-cost-requirement ${compact ? 'is-compact' : ''} ${isReady ? 'is-ready' : 'is-missing'}`}
      rHeight={compact ? 21 : 26}
      rGap={compact ? 4 : 7}
    >
      <Image
        className="trade-cost-image"
        src={getItemImage(cost.item)}
        fallbackSrc="./assets/no-picture.png"
        alt={cost.label}
        rWidth={compact ? 19 : 24}
        rHeight={compact ? 19 : 24}
      />
      <Text
        className="trade-cost-label"
        rMaxWidth={compact ? 100 : 190}
        rFontSize={compact ? 10 : 13}
        rLineHeight={compact ? 19 : 24}
        fontWeight={900}
      >
        {cost.required} {cost.label}
      </Text>
    </Box>
  );
};

const DoiVatPham = observer(({weapons, clothing, disabled = false, onExchange, onPreview}: DoiVatPhamProps) => {
  const [category, setCategory] = useState<Category>('items');
  const [gender, setGender] = useState<Gender>('male');
  const [selectedId, setSelectedId] = useState(weapons[0]?.id ?? '');

  const visibleClothes = useMemo(
    () => clothing.filter(item => item.gender === gender),
    [clothing, gender]
  );

  const items = category === 'items' ? weapons : visibleClothes;
  // The first two catalog entries are the main exchange items;
  // entries 3 and 4 are the vertical special cards on the right.
  const standardItems = items.filter((item, index) => index < 2 && !item.special);
  const specialItems = items.filter((item, index) => index >= 2 || item.special);
  const selected = items.find(item => item.id === selectedId) ?? items[0];

  const changeCategory = (nextCategory: Category) => {
    const nextItems = nextCategory === 'items' ? weapons : clothing.filter(item => item.gender === gender);
    setCategory(nextCategory);
    setSelectedId(nextItems[0]?.id ?? '');
  };

  const changeGender = (nextGender: Gender) => {
    const nextItems = clothing.filter(item => item.gender === nextGender);
    setGender(nextGender);
    setSelectedId(nextItems[0]?.id ?? '');
  };

  return (
    <Box className="items-layout" rWidth={1007} rHeight={469} rGap={30}>
      <Box className="items-sidebar" rLeft={-42} rWidth={150} rHeight={469} rPadding={[62, 0, 0]} rGap={24}>
        <Box
          className={`items-category-button ${category === 'items' ? 'is-active' : ''}`}
          rWidth={180}
          rHeight={65}
          rPadding={[0, 26, 2, 9]}
          onClick={() => changeCategory('items')}
        >
          <Text rFontSize={17} rLineHeight={46} fontWeight={900}>Vật Phẩm</Text>
        </Box>
        <Box
          className={`items-category-button ${category === 'clothes' ? 'is-active' : ''}`}
          rWidth={180}
          rHeight={65}
          rPadding={[0, 26, 2, 9]}
          onClick={() => changeCategory('clothes')}
        >
          <Text rFontSize={17} rLineHeight={46} fontWeight={900}>Quần Áo</Text>
        </Box>
      </Box>

      <Box
        className="items-panel"
        rLeft={-75}
        rWidth={827}
        rHeight={469}
        rPadding={[28, 38, 54, 0]}
      >
        {category === 'clothes' && (
          <Box className="gender-tabs z-50" rTop={25} rWidth={202} rHeight={36}>
            <Box
              className={`gender-button gender-button--left ${gender === 'male' ? 'is-active' : ''}`}
              rWidth={101}
              rHeight={36}
              onClick={() => changeGender('male')}
            >
              <Text rFontSize={15} rLineHeight={33} fontWeight={900}>Nam</Text>
            </Box>
            <Box
              className={`gender-button gender-button--right ${gender === 'female' ? 'is-active' : ''}`}
              rWidth={101}
              rHeight={36}
              onClick={() => changeGender('female')}
            >
              <Text rFontSize={15} rLineHeight={33} fontWeight={900}>Nữ</Text>
            </Box>
          </Box>
        )}

        {!items.length ? (
          <Text className="trader-empty" rFontSize={23} fontWeight={900}>Chưa có vật phẩm trong danh mục này.</Text>
        ) : category === 'items' ? (
          <>
            <Box className="weapon-grid" rLeft={-28} rWidth={480} rMargin={[28, 0, 0]} rGridTemplateColumns={[2, 220]} rColumnGap={16}>
              {standardItems.map(item => (
                <Box
                  className={`weapon-entry ${selected?.id === item.id ? 'is-selected' : ''}`}
                  rWidth={220}
                  rHeight={230}
                  rPadding={[10, 6]}
                  rBorderRadius={8}
                  key={item.id}
                  onClick={() => setSelectedId(item.id)}
                >
                  <ItemImage item={item} className="weapon-art" width={165} height={108} />
                  <Text className="weapon-name" rMaxWidth={190} rFontSize={15} rMargin={[4, 0, 0]} fontWeight={900}>
                    {item.name}
                  </Text>
                  <Box
                    className={`exchange-mini ${canExchangeEntry(item) && !disabled ? '' : 'is-disabled'}`}
                    rWidth={78}
                    rHeight={26}
                    rMargin={[3, 0, 0]}
                    onClick={event => {
                      event.stopPropagation();
                      if (canExchangeEntry(item) && !disabled) onExchange(item);
                    }}
                  />
                  <CostRequirement cost={item.costs[0]} compact />
                </Box>
              ))}
            </Box>

            {!!specialItems.length && (
              <Box className="weapon-special-list" rTop={25} rRight={-52} rWidth={235} rGap={8}>
                {specialItems.map(item => (
                  <Box
                    className={`weapon-special-entry ${selected?.id === item.id ? 'is-selected' : ''}`}
                    rWidth={235}
                    rHeight={188}
                    rPadding={[2, 0, 0]}
                    rBorderRadius={8}
                    key={item.id}
                    onClick={() => setSelectedId(item.id)}
                  >
                    <ItemImage item={item} className="weapon-special-art" width={210} height={112} />
                    <Box
                      className={`exchange-mini ${canExchangeEntry(item) && !disabled ? '' : 'is-disabled'}`}
                      rWidth={82}
                      rHeight={25}
                      rMargin={[1, 0, 0]}
                      onClick={event => {
                        event.stopPropagation();
                        if (canExchangeEntry(item) && !disabled) onExchange(item);
                      }}
                    />
                    <CostRequirement cost={item.costs[0]} compact />
                  </Box>
                ))}
              </Box>
            )}
          </>
        ) : (
          <Box className="clothing-grid" rMargin={[39, 0, 0]} rGridTemplateColumns={[5, 126]} rColumnGap={18} rRowGap={5}>
            {items.map(item => (
              <Box
                className={`clothing-entry ${selected?.id === item.id ? 'is-selected' : ''}`}
                rWidth={126}
                rHeight={180}
                key={item.id}
                onClick={() => setSelectedId(item.id)}
              >
                <Box className="clothing-frame" rWidth={126} rHeight={158}>
                  <ItemImage item={item} className="clothing-art" width={92} height={112} />
                  <Box
                    className="outfit-view-button"
                    rTop={9}
                    rRight={9}
                    rWidth={15}
                    rHeight={15}
                    onClick={event => {
                      event.stopPropagation();
                      onPreview(item);
                    }}
                  >
                    <Image src="./assets/view.png" alt={`Xem trước ${item.name}`} rWidth={15} rHeight={15} />
                  </Box>
                  <Box
                    className={`outfit-exchange-button ${canExchangeEntry(item) && !disabled ? '' : 'is-disabled'}`}
                    rBottom={7}
                    rWidth={76}
                    rHeight={25}
                    onClick={event => {
                      event.stopPropagation();
                      if (canExchangeEntry(item) && !disabled) onExchange(item);
                    }}
                  />
                </Box>
                <Box className="clothing-view-row" rHeight={21}>
                  <CostRequirement cost={item.costs[0]} compact />
                </Box>
              </Box>
            ))}
          </Box>
        )}

      </Box>
    </Box>
  );
});

export default DoiVatPham;
