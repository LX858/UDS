import {expect, test} from '@playwright/test';

interface RecordedEnvelope {
  version: number;
  module: string;
  kind: string;
  name: string;
  requestId?: string;
  sessionId?: string;
  revision?: number;
  payload?: unknown;
}

test('boots, receives client state, and closes through the typed NUI RPC', async ({
  page,
}) => {
  await page.addInitScript(() => {
    const runtimeWindow = window as typeof window & {
      GetParentResourceName: () => string;
      invokeNative: () => void;
      __bridgeCalls: RecordedEnvelope[];
      __sessionId?: string;
      __stateRevisions: Record<string, number>;
      __stateValues: Record<string, unknown>;
      __soundStarts: number;
    };
    runtimeWindow.GetParentResourceName = () => 'e2e-resource';
    runtimeWindow.invokeNative = () => undefined;
    runtimeWindow.__bridgeCalls = [];
    runtimeWindow.__stateRevisions = {};
    runtimeWindow.__stateValues = {};
    runtimeWindow.__soundStarts = 0;
    Object.defineProperty(window, 'AudioContext', {
      configurable: true,
      value: class {
        readonly state = 'running';
        readonly currentTime = 0;
        readonly destination = {};
        resume() {
          return Promise.resolve();
        }
        createOscillator() {
          return {
            type: 'sine',
            frequency: {
              setValueAtTime: () => undefined,
              exponentialRampToValueAtTime: () => undefined,
            },
            connect: () => undefined,
            start: () => {
              runtimeWindow.__soundStarts += 1;
            },
            stop: () => undefined,
          };
        }
        createGain() {
          return {
            gain: {
              setValueAtTime: () => undefined,
              exponentialRampToValueAtTime: () => undefined,
            },
            connect: () => undefined,
          };
        }
      },
    });
    window.fetch = async (_input, init) => {
      const request = JSON.parse(String(init?.body ?? '{}')) as RecordedEnvelope;
      runtimeWindow.__bridgeCalls.push(request);
      if (request.module === 'core' && request.name === 'ready') {
        if (!request.sessionId) throw new Error('ready request is missing sessionId');
        runtimeWindow.__sessionId = request.sessionId;
        window.setTimeout(() => {
          window.postMessage({
            version: 2,
            module: 'core',
            kind: 'event',
            name: 'synced',
            sessionId: request.sessionId,
            payload: {sessionId: request.sessionId},
          });
        }, 0);
      }
      const stateKey = `${request.module}:${request.name}`;
      const isStateWrite = request.kind === 'state.set' || request.kind === 'state.patch';
      if (request.kind === 'state.set') {
        runtimeWindow.__stateValues[stateKey] = request.payload;
      } else if (request.kind === 'state.patch') {
        runtimeWindow.__stateValues[stateKey] = {
          ...(runtimeWindow.__stateValues[stateKey] as object | undefined),
          ...(request.payload as object),
        };
      }
      const revision = isStateWrite
        ? (runtimeWindow.__stateRevisions[stateKey] ?? 1) + 1
        : undefined;
      if (revision !== undefined) runtimeWindow.__stateRevisions[stateKey] = revision;
      const response: RecordedEnvelope = {
        version: 2,
        module: request.module,
        kind: 'rpc.response',
        name: request.name,
        ...(request.requestId ? {requestId: request.requestId} : {}),
        ...(request.sessionId ? {sessionId: request.sessionId} : {}),
        ...(revision === undefined ? {} : {revision}),
        payload: isStateWrite
          ? runtimeWindow.__stateValues[stateKey]
          : request.module === 'core'
            ? {sessionId: request.sessionId}
            : request.module === 'trucker' && request.name === 'close'
              ? {success: true, message: ''}
              : {},
      };
      return new Response(JSON.stringify(response), {
        status: 200,
        headers: {'content-type': 'application/json'},
      });
    };
  });

  await page.goto('/');
  await expect
    .poll(() =>
      page.evaluate(() =>
        (
          window as typeof window & {__bridgeCalls: RecordedEnvelope[]}
        ).__bridgeCalls.some(
          envelope =>
            envelope.module === 'core' &&
            envelope.kind === 'event' &&
            envelope.name === 'ready'
        )
      )
    )
    .toBe(true);

  await page.evaluate(() => {
    const sessionId = (
      window as typeof window & {__sessionId?: string}
    ).__sessionId;
    window.postMessage({
      version: 2,
      module: 'trucker',
      kind: 'state.snapshot',
      name: 'visibility',
      sessionId,
      revision: 1,
      payload: {visible: true},
    });
    window.postMessage({
      version: 2,
      module: 'trucker',
      kind: 'state.snapshot',
      name: 'settings',
      sessionId,
      revision: 1,
      payload: {locale: {close: 'Close'}, dev: false},
    });
  });

  const dialog = page.getByRole('dialog', {name: 'Trung tâm vận chuyển'});
  await expect(dialog).toBeVisible();
  await expect
    .poll(() =>
      page.evaluate(
        () =>
          (window as typeof window & {__soundStarts: number}).__soundStarts
      )
    )
    .toBeGreaterThan(0);

  for (const viewport of [
    {width: 1600, height: 900},
    {width: 1366, height: 768},
    {width: 1024, height: 600},
    {width: 390, height: 700},
  ]) {
    await page.setViewportSize(viewport);
    const box = await dialog.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.x).toBeGreaterThanOrEqual(0);
    expect(box!.y).toBeGreaterThanOrEqual(0);
    expect(box!.x + box!.width).toBeLessThanOrEqual(viewport.width);
    expect(box!.y + box!.height).toBeLessThanOrEqual(viewport.height);
  }

  const fontFamilies = await page.evaluate(() => {
    const elements = [
      document.querySelector('[data-ui="trucker-dialog"]'),
      document.querySelector('[data-ui="trucker-close"]'),
      document.querySelector('input'),
    ].filter((element): element is Element => element !== null);
    return elements.map(element => getComputedStyle(element).fontFamily);
  });
  expect(fontFamilies).toHaveLength(2);
  expect(fontFamilies.every(font => font.includes('Roboto Condensed'))).toBe(true);

  await page.getByRole('button', {name: 'Close'}).click();
  await expect(dialog).toBeHidden();
  expect(
    await page.evaluate(
      () => (window as typeof window & {__soundStarts: number}).__soundStarts
    )
  ).toBeGreaterThanOrEqual(3);

  const calledCloseRpc = await page.evaluate(() =>
    (
      window as typeof window & {__bridgeCalls: RecordedEnvelope[]}
    ).__bridgeCalls.some(
      envelope =>
        envelope.module === 'trucker' &&
        envelope.kind === 'rpc.request' &&
        envelope.name === 'close'
    )
  );
  expect(calledCloseRpc).toBe(true);

  const visibilityWrite = await page.evaluate(() =>
    (
      window as typeof window & {__bridgeCalls: RecordedEnvelope[]}
    ).__bridgeCalls.find(
      envelope =>
        envelope.module === 'trucker' &&
        envelope.kind === 'state.set' &&
        envelope.name === 'visibility'
    )
  );
  expect(visibilityWrite).toMatchObject({
    requestId: expect.any(String),
    sessionId: expect.any(String),
    payload: {visible: false},
  });
  expect(visibilityWrite).not.toHaveProperty('revision');
});

test('persists theme and supports the rental picker', async ({
  page,
}) => {
  await page.goto('/');

  const dashboard = page.getByRole('dialog', {name: 'Trung tâm vận chuyển'});
  await expect(dashboard).toBeVisible();

  await page.getByRole('button', {name: 'Giao diện tối'}).click();
  await expect(page.locator('html')).toHaveClass(/dark/);
  await expect
    .poll(() => page.evaluate(() => localStorage.getItem('lr_trucker_job:theme:PREVIEW28')))
    .toBe('dark');

  await page.reload();
  await expect(dashboard).toBeVisible();
  await expect(page.locator('html')).toHaveClass(/dark/);
  await expect(page.getByRole('button', {name: 'Giao diện tối'})).toHaveAttribute('aria-pressed', 'true');

  await expect(page.getByRole('tab', {name: 'Garage'})).toHaveCount(0);
  await page.getByRole('button', {name: 'Nhận đơn'}).first().click();
  const picker = page.getByRole('dialog', {name: 'Chọn xe thuê'});
  await expect(picker).toBeVisible();
  await expect(picker.getByRole('radio', {checked: true})).toContainText(/mule/i);
  await expect(picker.getByText('TRK 942')).toHaveCount(0);

  for (const viewport of [
    {width: 1600, height: 900},
    {width: 1366, height: 768},
    {width: 1024, height: 600},
    {width: 390, height: 700},
  ]) {
    await page.setViewportSize(viewport);
    const box = await picker.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.x).toBeGreaterThanOrEqual(0);
    expect(box!.y).toBeGreaterThanOrEqual(0);
    expect(box!.x + box!.width).toBeLessThanOrEqual(viewport.width);
    expect(box!.y + box!.height).toBeLessThanOrEqual(viewport.height);
  }

  await page.keyboard.press('Escape');
  await expect(picker).toBeHidden();
  await expect(dashboard).toBeVisible();

  await page.getByRole('button', {name: 'Nhận đơn'}).first().click();
  await page.getByRole('button', {name: 'Thuê xe và nhận đơn'}).click();
  await expect(picker).toBeHidden();
  await expect(dashboard).toBeVisible();
});

test('procurement portal supports responsive multi-item ordering', async ({page}) => {
  await page.goto('/?procurement=1');
  const portal = page.getByRole('dialog', {name: 'Đặt giao nguyên liệu'});
  await expect(portal).toBeVisible();
  await expect(page.getByRole('heading', {name: 'Quán ăn'})).toBeVisible();
  await expect(page.getByText('Kho: 0')).toBeVisible();

  await page.getByRole('button', {name: 'Tăng Dừa'}).click();
  await page.getByRole('button', {name: 'Tăng Lúa mì'}).click();
  await expect(page.getByText('2/21')).toBeVisible();
  await page.getByRole('button', {name: 'Đặt giao hàng'}).click();
  const confirmation = page.getByRole('dialog', {name: 'Xác nhận thanh toán'});
  await expect(confirmation).toBeVisible();
  await expect(confirmation.getByText('1 Dừa → 1 Dừa sơ chế')).toBeVisible();
  await expect(confirmation.getByText('1 Lúa mì → 1 Gạo')).toBeVisible();
  await page.getByRole('button', {name: 'Quay lại'}).click();

  for (const viewport of [
    {width: 1600, height: 900},
    {width: 1024, height: 600},
    {width: 390, height: 700},
  ]) {
    await page.setViewportSize(viewport);
    const box = await portal.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.x).toBeGreaterThanOrEqual(0);
    expect(box!.y).toBeGreaterThanOrEqual(0);
    expect(box!.x + box!.width).toBeLessThanOrEqual(viewport.width);
    expect(box!.y + box!.height).toBeLessThanOrEqual(viewport.height);
  }
});
