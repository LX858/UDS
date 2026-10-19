import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";
import "@tipi-daily-rewards/components.css";
import { Provider } from "react-redux";
import { store } from "./store";
import { isEnvBrowser } from "./utils/misc";
import { NextUIProvider } from "@nextui-org/react";
import "react-toastify/dist/ReactToastify.css";

const root = document.getElementById("root");
if (isEnvBrowser()) {
  // https://i.imgur.com/iPTAdYV.webp - Night time img
  root!.style.backgroundImage = 'url("https://i.imgur.com/iPTAdYV.webp")';
  root!.style.backgroundSize = "cover";
  root!.style.backgroundRepeat = "no-repeat";
  root!.style.backgroundPosition = "center";
}

ReactDOM.createRoot(root!).render(
  <React.StrictMode>
    <Provider store={store}>
      <NextUIProvider>
        <App />
      </NextUIProvider>
    </Provider>
  </React.StrictMode>
);
