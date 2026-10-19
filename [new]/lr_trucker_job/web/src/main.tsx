import React from 'react';
import {createRoot} from 'react-dom/client';
import '@fontsource-variable/roboto-condensed';
import App from './App';
import './index.css';
import {createAppRuntime} from './app/runtime';
import {AppRuntimeProvider} from './app/runtimeContext';
import {isEnvBrowser} from './utils/misc';

const start = () => {
  const rootNode = document.getElementById('root');
  if (!rootNode) {
    document.body.style.display = 'flex';
    document.body.style.alignItems = 'center';
    document.body.style.justifyContent = 'center';
    document.body.style.backgroundColor = 'black';
    document.body.style.color = 'red';
    document.body.textContent = 'Invalid HTML template, no root node available';
    return null;
  }

  if (isEnvBrowser()) rootNode.style.backgroundColor = '#111827';

  const runtime = createAppRuntime();
  const reactRoot = createRoot(rootNode);
  reactRoot.render(
    <React.StrictMode>
      <AppRuntimeProvider runtime={runtime}>
        <App />
      </AppRuntimeProvider>
    </React.StrictMode>
  );
  if (import.meta.hot) {
    import.meta.hot.dispose(() => {
      reactRoot.unmount();
      runtime.dispose();
    });
  }
  return runtime;
};

start();

export default start;
