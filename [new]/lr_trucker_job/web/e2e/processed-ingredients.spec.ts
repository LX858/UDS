import {expect, test} from '@playwright/test';

test('processed ingredients in both themes and responsive confirmations', async ({page}) => {
  await page.goto('/?procurement=1');
  for (const theme of ['sáng', 'tối']) {
    if (theme === 'tối') await page.getByRole('button', {name: 'Dùng giao diện tối'}).click();
    for (const viewport of [
      {width: 1600, height: 900}, {width: 1366, height: 768},
      {width: 1024, height: 600}, {width: 390, height: 700},
    ]) {
      await page.setViewportSize(viewport);
      await expect(page.getByRole('heading', {name: 'Dừa sơ chế'})).toBeVisible();
      await expect(page.getByRole('heading', {name: 'Gạo', exact: true})).toBeVisible();
      await page.getByRole('spinbutton', {name: 'Số lượng Dừa', exact: true}).fill('10');
      await page.getByRole('spinbutton', {name: 'Số lượng Lúa mì', exact: true}).fill('10');
      await page.getByRole('button', {name: 'Đặt giao hàng'}).click();
      const modal = page.getByRole('dialog', {name: 'Xác nhận thanh toán'});
      await expect(modal.getByText('10 Lúa mì → 10 Gạo')).toBeVisible();
      await expect(modal.getByText('10 Dừa → 10 Dừa sơ chế')).toBeVisible();
      const box = (await modal.boundingBox())!;
      expect(box.x).toBeGreaterThanOrEqual(0);
      expect(box.y).toBeGreaterThanOrEqual(0);
      expect(box.x + box.width).toBeLessThanOrEqual(viewport.width);
      expect(box.y + box.height).toBeLessThanOrEqual(viewport.height);
      await expect.poll(() => modal.evaluate(element => element.scrollWidth <= element.clientWidth)).toBe(true);
      await page.screenshot({path: `test-results/processed-${theme === 'tối' ? 'dark' : 'light'}-${viewport.width}.png`});
      await page.keyboard.press('Escape');
      await expect(modal).toBeHidden();
      await expect(page.getByRole('dialog', {name: 'Đặt giao nguyên liệu'})).toBeVisible();
    }
  }
});
