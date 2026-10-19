import { Box } from "lr-components";
import React from "react";
import Main from "./Main";
import Shop from "./Shop";
import Business from "./Business";
import Settings from "./Settings";
import { useSelector } from "react-redux";
import { RootState } from "../store";

function IndexPage() {
  const store = useSelector((state: RootState) => state.main);
  const getImageBg = () => {
    if (store.page === "shop") {
      return "url(./assets/webp/bg2.webp)";
    } else {
      return "url(./assets/webp/bg.webp)";
    }
  };
  return (
    <Box
      width={"100%"}
      height={"100%"}
      position="relative"
      zIndex={0}
      /* backgroundImage={getImageBg()}
      backgroundSize={"cover"}
      backgroundPosition={"center"}
      backgroundRepeat="no-repeat" */
    >
      <Main />
      <Shop />
      <Business />
      <Settings />
    </Box>
  );
}

export default IndexPage;
