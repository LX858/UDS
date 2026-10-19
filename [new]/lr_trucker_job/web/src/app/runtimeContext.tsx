import React, {createContext, useContext} from 'react';
import {AppRuntime} from './runtime';

const AppRuntimeContext = createContext<AppRuntime | null>(null);

export function AppRuntimeProvider({
  runtime,
  children,
}: {
  runtime: AppRuntime;
  children: React.ReactNode;
}) {
  return (
    <AppRuntimeContext.Provider value={runtime}>
      {children}
    </AppRuntimeContext.Provider>
  );
}

export function useAppRuntime() {
  const runtime = useContext(AppRuntimeContext);
  if (!runtime) {
    throw new Error('AppRuntimeProvider is missing');
  }
  return runtime;
}

export function useStore<Name extends keyof AppRuntime['stores']>(name: Name) {
  return useAppRuntime().stores[name];
}
