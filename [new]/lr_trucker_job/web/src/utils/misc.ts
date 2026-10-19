// Will return whether the current environment is in a regular browser

// and not CEF
export const isEnvBrowser = (): boolean =>
  !(window as typeof window & {invokeNative?: unknown}).invokeNative;

// Basic no operation function
export const noop = () => {};

export const Sleep = (ms: number) => {
  return new Promise(resolve => setTimeout(resolve, ms));
};
