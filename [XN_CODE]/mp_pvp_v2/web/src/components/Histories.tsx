import { Box, Text, useWindowSize } from "lr-components";
import type { RootState } from "../store";
import { useSelector } from "react-redux";
import { motion } from "framer-motion";
import styled from "styled-components";
import { colors } from "@/utils/misc";

const ScrollBar = styled(Box)`
  display: flex;
  flex-wrap: wrap;
  align-content: flex-start;
  &::-webkit-scrollbar {
    background-color: transparent;
    width: 0px;
  }
  &::-webkit-scrollbar-thumb {
    background-color: var(--primary-color);
    border-radius: 5px;
  }
  &::-webkit-scrollbar-track {
    background-color: transparent;
  }
`;

const AnimatedButton = styled(Box)`
  border: 1px solid rgba(167, 184, 255, 0.17);
  background-color: rgba(38, 34, 40, 0.39);
  &:hover {
    border: 1px solid rgba(167, 184, 255, 0.83);
    background-color: rgba(38, 34, 40, 0.49);
  }
  transition: all 0.2s ease;
`;
const formatTime = (time: number) => {
  const date = new Date(time * 1000);
  const hours = date.getHours().toString().padStart(2, "0");
  const minutes = date.getMinutes().toString().padStart(2, "0");
  const seconds = date.getSeconds().toString().padStart(2, "0");
  const day = date.getDate().toString().padStart(2, "0");
  const month = (date.getMonth() + 1).toString().padStart(2, "0");

  return `${hours}:${minutes}:${seconds} ${day}/${month}`;
};

const variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1 },
};

const DropDownValue: Record<string, string> = {
  solo: "Chế Độ 1vs1",
};

function Histories() {
  const store = useSelector((state: RootState) => state.main);
  const windowSize = useWindowSize();
  const currentDropdown = "solo";
  return (
    store.page === "histories" && (
      <motion.div
        initial="hidden"
        animate={store.show ? "visible" : "hidden"}
        variants={variants}
        transition={{ type: "keyframes", stiffness: 500, duration: 0.35 }}
        style={{
          width: windowSize.ratioWidth * 1584 + "px",
          height: windowSize.ratioHeight * 604 + "px",
          position: "absolute",
          left: "50%",
          transform: "translateX(-50%)",
          top: windowSize.ratioHeight * 259 + "px",
          display: "flex",
          alignItems: "center",
          justifyContent: "left",
          gap: windowSize.ratioWidth * 32 + "px",
        }}
      >
        <Box
          rWidth={1131}
          rHeight={604}
          backgroundImage="url(./assets/webp/histories.webp)"
          backgroundSize={"cover"}
          backgroundRepeat={"no-repeat"}
          position="relative"
        >
          <ScrollBar
            rWidth={1109}
            rHeight={558}
            position="absolute"
            left={"50%"}
            transform="translateX(-50%)"
            bottom={0}
            overflowX="hidden"
            overflowY="auto"
            rGap={8}
          >
            {store.histories.map((history, index) => (
              <AnimatedButton
                key={index}
                width={"100%"}
                rHeight={78}
                position="relative"
              >
                <Text
                  rWidth={51}
                  textAlign="center"
                  rFontSize={24}
                  rLeft={28}
                  position="absolute"
                  top={"50%"}
                  transform="translateY(-50%)"
                  color={history.state === "win" ? "#07FF3D" : "#FF0707"}
                  textTransform="uppercase"
                  fontWeight={"bold"}
                  textShadow={
                    history.state === "win"
                      ? "0 0 10px #07FF3D"
                      : "0 0 10px #FF0707"
                  }
                >
                  {history.state}
                </Text>
                <Text
                  rWidth={137}
                  textAlign="center"
                  rFontSize={20}
                  rLeft={208}
                  position="absolute"
                  top={"50%"}
                  transform="translateY(-50%)"
                  color={history.state === "win" ? "#7DFF99" : "#FF7D7D"}
                  fontWeight={"bold"}
                >
                  {history.state === "win" ? "Chiến Thắng" : "Thất bại"}
                </Text>
                <Text
                  rWidth={137}
                  textAlign="center"
                  rFontSize={20}
                  rLeft={444}
                  position="absolute"
                  top={"50%"}
                  transform="translateY(-50%)"
                  color={"#FFF"}
                  fontWeight={"bold"}
                >
                  {history.type}
                </Text>
                <Text
                  rWidth={190}
                  textAlign="center"
                  rFontSize={20}
                  rLeft={685}
                  position="absolute"
                  top={"50%"}
                  transform="translateY(-50%)"
                  color={"rgba(227,228,233, 0.7)"}
                  textTransform="uppercase"
                >
                  {formatTime(history.time)}
                </Text>
                <Text
                  rWidth={178}
                  textAlign="center"
                  rFontSize={20}
                  rRight={8}
                  position="absolute"
                  top={"50%"}
                  transform="translateY(-50%)"
                  color={history.state === "win" ? "#7DFF99" : "#FF7D7D"}
                  textTransform="uppercase"
                >
                  {history.state === "win"
                    ? `+${history.point}`
                    : `-${history.point}`}
                </Text>
              </AnimatedButton>
            ))}
          </ScrollBar>
        </Box>
        <Box
          rWidth={427}
          rHeight={605}
          backgroundImage="url(./assets/webp/myrank2.webp)"
          backgroundSize={"cover"}
          backgroundRepeat={"no-repeat"}
          position="relative"
        >
          <Text
            width={"100%"}
            rTop={91}
            position="absolute"
            textAlign="center"
            rFontSize={20}
            fontWeight={"bold"}
          >
            XẾP HẠNG CỦA BẠN
          </Text>
          <Box
            rWidth={227}
            rHeight={40}
            backgroundImage={`url(./assets/webp/${store.myRank[currentDropdown].rank}_badge3.webp`}
            backgroundSize={"cover"}
            backgroundRepeat={"no-repeat"}
            position="absolute"
            rTop={125}
            left={"50%"}
            transform="translateX(-50%)"
            display="flex"
            alignItems="center"
            justifyContent="space-between"
            paddingLeft={windowSize.ratioWidth * 15 + "px"}
            paddingRight={windowSize.ratioWidth * 15 + "px"}
          >
            <Text
              rFontSize={18}
              textTransform="uppercase"
              color={`rgb(${colors[store.myRank[currentDropdown].rank]})`}
              fontWeight={600}
            >
              {store.myRank[currentDropdown].rankLabel || "Chưa Xếp Hạng"}
            </Text>
            <Text
              rFontSize={18}
              textTransform="uppercase"
              color="#FFF"
              fontWeight={600}
            >
              {store.myRank[currentDropdown].point.toLocaleString() || 0}
            </Text>
          </Box>
          <Box
            rWidth={
              store.myRank[currentDropdown].rank === "thachdau" ? 170 : 155
            }
            rHeight={
              store.myRank[currentDropdown].rank === "thachdau" ? 253 : 235
            }
            backgroundImage={`url(./assets/webp/${store.myRank[currentDropdown].rank}.webp`}
            backgroundSize={"contain"}
            backgroundRepeat={"no-repeat"}
            position="absolute"
            left={"50%"}
            transform="translateX(-50%)"
            rTop={185}
            filter={`drop-shadow(0px 0px 10px rgba(${
              colors[store.myRank[currentDropdown].rank]
            }, 0.5))`}
          ></Box>
          <Text
            rFontSize={20}
            color="#8782FF"
            position="absolute"
            rTop={470}
            left={0}
            width={"100%"}
            textAlign="center"
          >
            K/D:{" "}
            <span style={{ fontWeight: "bold", color: "#FFF" }}>
              {" "}
              {store.myRank[currentDropdown].kda?.toFixed(2) || "0.00"}
            </span>
          </Text>
          <Box
            rWidth={223}
            rHeight={41}
            display="flex"
            flexWrap="wrap"
            alignContent="flex-start"
            rGap={10}
            flexFlow="wrap"
            position="absolute"
            rBottom={45}
            left={"50%"}
            transform="translateX(-50%)"
          >
            <Box
              width={"100%"}
              rHeight={41}
              rBorderRadius={100}
              border={"1px solid #535897"}
              backgroundColor={"rgba(65, 106, 183, 0.08)"}
              display="flex"
              alignItems="center"
              justifyContent="center"
              rGap={4}
            >
              <Text rFontSize={20} fontWeight={600} color="#D4E8FF">
                {DropDownValue[currentDropdown]}
              </Text>
            </Box>
          </Box>
        </Box>
      </motion.div>
    )
  );
}

export default Histories;
