// Will return whether the current environment is in a regular browser

import type { IResponse, IResponseSuccess } from "@/types";
import { toast } from "react-toastify";

// and not CEF
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const isEnvBrowser = (): boolean => !(window as any).invokeNative;

// Basic no operation function
export const noop = () => {};

export const Sleep = (ms: number) => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

export const GuardResponse = (
  response: IResponse
): response is IResponseSuccess => {
  if (!response) return false;
  if (response.status === "error") throw new Error(response.message);
  if (response.message) {
    toast.success(response.message);
  }
  return response.status === "success";
};


export const colors: Record<string, string> = {
  dong: "181, 150, 112",
  bac: "197, 201, 199",
  vang: "252, 225, 48",
  bachkim: "82, 211, 222",
  kimcuong: "196, 135, 245",
  lucbao: "123, 255, 187",
  caothu: "191, 66, 14",
  thachdau: "237, 20, 0",
};