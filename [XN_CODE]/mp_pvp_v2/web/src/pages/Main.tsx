import { Box } from "lr-components";
import Histories from "@/components/Histories";
import Room from "@/components/Room";
import LeaderBoard from "@/components/LeaderBoard";
import Category from "@/components/Category";

function Main() {
  return (
    <Box
      width={"100%"}
      height={"100%"}
      position={"relative"}
      backgroundImage="url(./assets/webp/bg.webp)"
      backgroundSize={"cover"}
      backgroundRepeat={"no-repeat"}
      backgroundPosition={"center"}
    >
      <Box
        rWidth={338}
        rHeight={120}
        backgroundImage="url(./assets/webp/info.webp)"
        backgroundSize={"cover"}
        backgroundRepeat={"no-repeat"}
        position="absolute"
        rTop={82}
        rLeft={82}
      ></Box>
      <Category />
      <Room />
      <LeaderBoard />
      <Histories />
    </Box>
  );
}

export default Main;
