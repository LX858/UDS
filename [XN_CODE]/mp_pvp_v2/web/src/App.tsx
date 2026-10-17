import { useEffect } from "react";
import { useSelector } from "react-redux";
import type { RootState } from "./store";
import { fetchNui } from "./utils/fetchNui";
import { isEnvBrowser } from "./utils/misc";
import AppActionHook from "./components/AppActionHook";
import { Box } from "lr-components";
import { AppActions } from "./store";
import Main from "./pages/Main";
import { toast } from "react-toastify";
import ReadyCheck from "./components/ReadyCheck";

function App() {
  const show = useSelector((state: RootState) => state.main.show);
  useEffect(() => {
    if (!isEnvBrowser()) {
      setTimeout(async () => {
        fetchNui("AppReady");
      }, 2000);
      const keyHandler = (e: KeyboardEvent) => {
        if (e.key === "Escape") {
          toast.dismiss();
          fetchNui("close");
        }
      };
      window.addEventListener("keydown", keyHandler);
      return () => {
        window.removeEventListener("keydown", keyHandler);
      };
    }
  }, []);
  return (
    <>
      <Box
        display="flex"
        position="absolute"
        flexWrap="wrap"
        justifyContent="center"
        alignItems="center"
        flexDirection="column"
        width={"50%"}
        height={"50%"}
        rGap={10}
      >
        {Object.keys(AppActions).map((action) => {
          return (
            <AppActionHook
              key={action}
              action={action as keyof typeof AppActions}
            ></AppActionHook>
          );
        })}
      </Box>
      {show && (
        <Box
          width={"100vw"}
          height={"100vh"}
          position="relative"
          top={0}
          left={0}
          className="prose"
          backgroundColor="rgba(0, 0, 0, 0.63)"
          // pointerEvents='none'
        >
          <Main />
        </Box>
      )}
      <ReadyCheck />
    </>
  );
}

export default App;
