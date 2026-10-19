import { MutableRefObject, useEffect, useRef } from "react";
import { noop } from "../utils/misc";
import { fetchNui } from "../utils/fetchNui";

interface NuiMessageData<T = unknown> {
  action: string;
  data: T;
}

type NuiHandlerSignature<T> = (data: T) => void;



export const useNuiEvent = <T = unknown>(
  action: string,
  handler: (data: T) => void
) => {
  const savedHandler: MutableRefObject<NuiHandlerSignature<T>> = useRef(noop);

  // Make sure we handle for a reactive handler
  useEffect(() => {
    savedHandler.current = handler;
  }, [handler]);

  useEffect(() => {
    const eventListener = (event: MessageEvent<NuiMessageData<T>>) => {
      const { action: eventAction, data } = event.data;

      if (savedHandler.current) {
        if (eventAction === action) {
          savedHandler.current(data);
        }
      }
    };

    window.addEventListener("message", eventListener);

    return () => {
      window.removeEventListener("message", eventListener);
    };
  }, [action]);
};
