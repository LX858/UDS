// @vitest-environment jsdom
import React from 'react';
import {afterEach, describe, expect, it, vi} from 'vitest';
import {cleanup, fireEvent, render, screen} from '@testing-library/react';

vi.mock('lr-components', async () => {
  const React = await import('react');
  const Stub = (props: Record<string, any>) => React.createElement('div', {
    className: props.className,
    title: props.title,
    role: props.role,
    tabIndex: props.tabIndex,
    'aria-label': props['aria-label'],
    'aria-disabled': props['aria-disabled'],
    onClick: props.onClick,
    onKeyDown: props.onKeyDown,
  }, props.children);
  return {
    Box: Stub,
    Text: Stub,
    Image: (props: Record<string, any>) => React.createElement('img', {
      className: props.className,
      src: props.src,
      alt: props.alt,
    }),
  };
});

import TradeGrid from '../components/TradeGrid';
import DoiVatPham from '../components/DoiVatPham';
import type {TradeEntry} from '../components/trader.data';

afterEach(cleanup);

const entry = (id: string, owned = 20): TradeEntry => ({
  id,
  name: `Vật phẩm ${id}`,
  image: './assets/no-picture.png',
  costs: [
    {item: 'token_a', label: 'Thẻ A', owned, required: 10},
    {item: 'token_b', label: 'Thẻ B', owned, required: 15},
  ],
});

describe('TradeGrid', () => {
  it('shows the empty message', () => {
    render(<TradeGrid items={[]} columns={4} height={365} emptyMessage="Danh mục trống" onExchange={vi.fn()} />);
    expect(screen.getByText('Danh mục trống')).toBeTruthy();
  });

  it('keeps configured order and renders every cost for a long catalog', () => {
    const items = Array.from({length: 12}, (_, index) => entry(String(index + 1)));
    const {container} = render(
      <TradeGrid items={items} columns={4} height={365} emptyMessage="Trống" onExchange={vi.fn()} />
    );
    expect(Array.from(container.querySelectorAll('.trade-card-name'), node => node.textContent))
      .toEqual(items.map(item => item.name));
    expect(container.querySelectorAll('.trade-card')).toHaveLength(12);
    expect(container.querySelectorAll('.trade-card-cost')).toHaveLength(24);
    expect(screen.getAllByText('Thẻ A: 20/10')).toHaveLength(12);
    expect(screen.getAllByText('Thẻ B: 20/15')).toHaveLength(12);
  });

  it('allows exchange only when all costs are available and keeps outfit preview', () => {
    const onExchange = vi.fn();
    const onPreview = vi.fn();
    const ready = {...entry('ready'), gender: 'male' as const};
    const missing = {...entry('missing', 11), gender: 'male' as const};
    render(
      <TradeGrid
        items={[ready, missing]}
        columns={4}
        height={330}
        emptyMessage="Trống"
        onExchange={onExchange}
        onPreview={onPreview}
      />
    );
    fireEvent.click(screen.getByRole('button', {name: 'Quy đổi Vật phẩm missing'}));
    expect(onExchange).not.toHaveBeenCalled();
    fireEvent.click(screen.getByRole('button', {name: 'Quy đổi Vật phẩm ready'}));
    expect(onExchange).toHaveBeenCalledWith(ready);
    fireEvent.click(screen.getByRole('button', {name: 'Xem trước Vật phẩm ready'}));
    expect(onPreview).toHaveBeenCalledWith(ready);
  });
});

describe('DoiVatPham', () => {
  it('filters outfits by gender', () => {
    const male = {...entry('nam'), gender: 'male' as const};
    const female = {...entry('nu'), gender: 'female' as const};
    render(
      <DoiVatPham
        weapons={[]}
        clothing={[male, female]}
        onExchange={vi.fn()}
        onPreview={vi.fn()}
      />
    );
    fireEvent.click(screen.getByText('Quần Áo'));
    expect(screen.getByText(male.name)).toBeTruthy();
    expect(screen.queryByText(female.name)).toBeNull();
    fireEvent.click(screen.getByText('Nữ'));
    expect(screen.getByText(female.name)).toBeTruthy();
    expect(screen.queryByText(male.name)).toBeNull();
  });
});
