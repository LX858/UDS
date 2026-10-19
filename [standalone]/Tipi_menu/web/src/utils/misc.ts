// Will return whether the current environment is in a regular browser

import { toast } from 'react-toastify';
import { IResponse, IResponseSuccess } from '../types';

type FiveMWindow = Window & {
  invokeNative?: unknown;
  GetParentResourceName?: () => string;
};

/** Đang chạy trong NUI FiveM (CEF) */
export const isFiveM = (): boolean => {
  const w = window as FiveMWindow;
  return typeof w.GetParentResourceName === 'function' || typeof w.invokeNative === 'function';
};

/**
 * Preview trên trình duyệt (vite dev) — KHÔNG dùng khi đã vào game.
 * Trước đây chỉ check invokeNative → FiveM báo nhầm là browser → hiện chữ "Menu đang tắt".
 */
export const isEnvBrowser = (): boolean => !isFiveM() && import.meta.env.DEV;

/** Tránh animation opacity 0 khi preview trong trình duyệt */
export const motionPageInitial = (): 'hidden' | 'visible' =>
  isEnvBrowser() ? 'visible' : 'hidden';

export const noop = () => {};

/** File trong web/public — dev: /assets/... | build/NUI: ./assets/... */
export const publicAsset = (relativePath: string): string => {
  const clean = relativePath.replace(/^\//, '');
  if (import.meta.env.DEV) {
    return `/${clean}`;
  }
  return `./${clean}`;
};

export const Sleep = (ms: number) => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

export const GuardResponse = (
  response: IResponse
): response is IResponseSuccess => {
  if (!response) return false;
  if (response.status === 'error') throw new Error(response.message);
  if (response.message) {
    toast.success(response.message);
  }
  return response.status === 'success';
};
