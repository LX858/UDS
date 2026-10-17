import React from "react";
import { createRoot } from "react-dom/client";
import { Provider } from "react-redux";
import { store } from "./store";
import "./index.css";
import App from "./App.tsx";
import { isEnvBrowser } from "./utils/misc.ts";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
const root = document.getElementById("root");
if (isEnvBrowser()) {
  // https://i.imgur.com/iPTAdYV.webp - Night time img
  root!.style.backgroundImage = 'url("https://i.imgur.com/3pzRj9n.webp")';
  root!.style.backgroundSize = "cover";
  root!.style.backgroundRepeat = "no-repeat";
  root!.style.backgroundPosition = "center";
}

createRoot(root!).render(
  <React.StrictMode>
    <Provider store={store}>
      <App />
      <ToastContainer
        position="top-right"
        autoClose={3000}
        hideProgressBar={false}
        newestOnTop
        closeOnClick
        rtl={false}
        pauseOnFocusLoss
        draggable
        pauseOnHover
        theme="dark"
      />
    </Provider>
  </React.StrictMode>
);
