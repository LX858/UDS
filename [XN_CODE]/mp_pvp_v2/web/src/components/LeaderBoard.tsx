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

const IndexColor = {
  0: {
    backgroundColor: "rgba(96, 107, 67, 0.39)",
    stroke: "1px solid rgba(225, 255, 0, 0.7)",
  },
  1: {
    backgroundColor: "rgba(106, 111, 130, 0.39)",
    stroke: "1px solid rgba(255, 255, 255, 0.7)",
  },
  2: {
    backgroundColor: "rgba(76, 62, 58, 0.39)",
    stroke: "1px solid rgba(266, 156, 131, 0.7)",
  },
};

function LeaderBoard() {
  const store = useSelector((state: RootState) => state.main);
  const windowSize = useWindowSize();
  const variants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1 },
  };

  return store.page === "leaderboard" ? (
    <motion.div
      initial="hidden"
      animate={store.page === "leaderboard" ? "visible" : "hidden"}
      variants={variants}
      transition={{ type: "keyframes", stiffness: 500, duration: 0.35 }}
      style={{
        width: windowSize.ratioWidth * 1345 + "px",
        height: windowSize.ratioHeight * 618 + "px",
        position: "absolute",
        top: windowSize.ratioHeight * 260 + "px",
        left: "50%",
        transform: "translateX(-50%)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: windowSize.ratioWidth * 32 + "px",
      }}
    >
      <Box
        rWidth={427}
        height={"100%"}
        display="flex"
        alignContent="flex-start"
        flexWrap="wrap"
        rGap={17}
      >
        <Box
          rWidth={427}
          rHeight={549}
          backgroundImage="url(./assets/webp/1vs1.webp)"
          backgroundSize="cover"
          backgroundRepeat="no-repeat"
          position="relative"
        >
          <ScrollBar
            rWidth={415}
            rHeight={482}
            overflowX="hidden"
            overflowY="auto"
            rGap={8}
            position="absolute"
            rTop={52}
            left={"50%"}
            transform="translateX(-50%)"
          >
            {store.leaderboard.solo.map((item, index) => (
              <Box
                width={"100%"}
                rHeight={41}
                key={index}
                position="relative"
                backgroundColor={
                  IndexColor[index as 0 | 1 | 2]
                    ? IndexColor[index as 0 | 1 | 2].backgroundColor
                    : "rgba(38,34,40, 0.39)"
                }
                border={
                  IndexColor[index as 0 | 1 | 2]
                    ? IndexColor[index as 0 | 1 | 2].stroke
                    : "1px solid rgba(159, 156, 255, 0.17)"
                }
              >
                <Box
                  rWidth={index < 1 ? 37 : 33}
                  rHeight={31}
                  position="absolute"
                  display="flex"
                  alignItems="center"
                  justifyContent="center"
                  top={"50%"}
                  transform="translateY(-50%)"
                  rLeft={7}
                  backgroundImage={`url(./assets/webp/${
                    index < 1 ? "position" : "position2"
                  }.png)`}
                  backgroundSize="cover"
                  backgroundPosition="center"
                  backgroundRepeat="no-repeat"
                >
                  <Text rFontSize={16} fontWeight={"bold"}>
                    {index + 1}
                  </Text>
                </Box>
                <Box
                  rWidth={item.rank === "thachdau" ? 21.5 : 21.1}
                  rHeight={32}
                  backgroundImage={`url(./assets/webp/${item.rank}.webp)`}
                  backgroundSize="contain"
                  backgroundRepeat="no-repeat"
                  position="absolute"
                  rLeft={58}
                  top={"50%"}
                  transform="translateY(-50%)"
                ></Box>
                <Text
                  rFontSize={16}
                  fontWeight={400}
                  rLineHeight={40}
                  position="absolute"
                  top={"50%"}
                  transform="translateY(-50%)"
                  rLeft={88}
                >
                  {item.name}
                </Text>
                <Box
                  rWidth={124.5}
                  rHeight={23}
                  backgroundImage={`url(./assets/webp/${item.rank}_badge2.png)`}
                  backgroundSize="cover"
                  backgroundRepeat="no-repeat"
                  top={"50%"}
                  transform="translateY(-50%)"
                  rRight={8}
                  position="absolute"
                  display="flex"
                  alignItems="center"
                  justifyContent="space-between"
                  paddingLeft={windowSize.ratioWidth * 9 + "px"}
                  paddingRight={windowSize.ratioWidth * 9 + "px"}
                >
                  <Text
                    rFontSize={11}
                    textTransform="uppercase"
                    color={`rgb(${colors[item.rank] || "255, 255, 255"})`}
                    rLineHeight={11}
                    fontWeight={"bold"}
                    paddingTop={windowSize.ratioHeight * 4 + "px"}
                  >
                    {item.rankLabel || ""}
                  </Text>
                  <Text rFontSize={11} fontWeight={"bold"}>
                    {item.point.toLocaleString()}
                  </Text>
                </Box>
              </Box>
            ))}
          </ScrollBar>
        </Box>
        <Box
          width={"100%"}
          rHeight={52}
          backgroundImage="url(./assets/webp/myrank.webp)"
          backgroundSize="cover"
          backgroundRepeat="no-repeat"
          position="relative"
        >
          <Box
            rWidth={33}
            rHeight={31}
            position="absolute"
            display="flex"
            alignItems="center"
            justifyContent="center"
            top={"50%"}
            transform="translateY(-50%)"
            rLeft={7}
            backgroundImage={`url(./assets/webp/position2.png)`}
            backgroundSize="cover"
            backgroundPosition="center"
            backgroundRepeat="no-repeat"
          >
            <Text rFontSize={16} fontWeight={"bold"}>
              {store.myRank.solo.position}
            </Text>
          </Box>
          <Box
            rWidth={32}
            rHeight={32}
            backgroundImage={`url(./assets/webp/${store.myRank.solo.rank}.webp)`}
            backgroundSize="contain"
            backgroundRepeat="no-repeat"
            position="absolute"
            rLeft={58}
            top={"50%"}
            transform="translateY(-50%)"
          ></Box>
          <Text
            rFontSize={16}
            fontWeight={400}
            rLineHeight={40}
            position="absolute"
            top={"50%"}
            transform="translateY(-50%)"
            rLeft={88}
          >
            Hạng của bạn
          </Text>
          <Box
            rWidth={124.5}
            rHeight={23}
            backgroundImage={`url(./assets/webp/${store.myRank.solo.rank}_badge2.png)`}
            backgroundSize="cover"
            backgroundRepeat="no-repeat"
            top={"50%"}
            transform="translateY(-50%)"
            rRight={8}
            position="absolute"
            display="flex"
            alignItems="center"
            justifyContent="space-between"
            paddingLeft={windowSize.ratioWidth * 9 + "px"}
            paddingRight={windowSize.ratioWidth * 9 + "px"}
          >
            <Text
              rFontSize={11}
              textTransform="uppercase"
              color={`rgb(${
                colors[store.myRank.solo.rank] || "255, 255, 255"
              })`}
              rLineHeight={11}
              fontWeight={"bold"}
              paddingTop={windowSize.ratioHeight * 4 + "px"}
            >
              {store.myRank.solo.rankLabel || ""}
            </Text>
            <Text rFontSize={11} fontWeight={"bold"}>
              {store.myRank.solo.point.toLocaleString()}
            </Text>
          </Box>
        </Box>
      </Box>

      {/* <Box
        rWidth={427}
        height={"100%"}
        display="flex"
        alignContent="flex-start"
        flexWrap="wrap"
        rGap={17}
      >
        <Box
          rWidth={427}
          rHeight={549}
          backgroundImage="url(./assets/webp/2vs2.webp)"
          backgroundSize="cover"
          backgroundRepeat="no-repeat"
          position="relative"
        >
          <ScrollBar
            rWidth={415}
            rHeight={482}
            overflowX="hidden"
            overflowY="auto"
            rGap={8}
            position="absolute"
            rTop={52}
            left={"50%"}
            transform="translateX(-50%)"
          >
            {store.leaderboard.dual.map((item, index) => (
              <Box
                width={"100%"}
                rHeight={41}
                key={index}
                position="relative"
                backgroundColor={
                  IndexColor[index as 0 | 1 | 2]
                    ? IndexColor[index as 0 | 1 | 2].backgroundColor
                    : "rgba(38,34,40, 0.39)"
                }
                border={
                  IndexColor[index as 0 | 1 | 2]
                    ? IndexColor[index as 0 | 1 | 2].stroke
                    : "1px solid rgba(159, 156, 255, 0.17)"
                }
              >
                <Box
                  rWidth={index < 1 ? 37 : 33}
                  rHeight={31}
                  position="absolute"
                  display="flex"
                  alignItems="center"
                  justifyContent="center"
                  top={"50%"}
                  transform="translateY(-50%)"
                  rLeft={7}
                  backgroundImage={`url(./assets/webp/${
                    index < 1 ? "position" : "position2"
                  }.png)`}
                  backgroundSize="cover"
                  backgroundPosition="center"
                  backgroundRepeat="no-repeat"
                >
                  <Text rFontSize={16} fontWeight={"bold"}>
                    {index + 1}
                  </Text>
                </Box>
                <Box
                  rWidth={item.rank === "thachdau" ? 21.5 : 21.1}
                  rHeight={32}
                  backgroundImage={`url(./assets/webp/${item.rank}.webp)`}
                  backgroundSize="cover"
                  backgroundRepeat="no-repeat"
                  position="absolute"
                  rLeft={58}
                  top={"50%"}
                  transform="translateY(-50%)"
                ></Box>
                <Text
                  rFontSize={16}
                  fontWeight={400}
                  rLineHeight={40}
                  position="absolute"
                  top={"50%"}
                  transform="translateY(-50%)"
                  rLeft={88}
                >
                  {item.name}
                </Text>
                <Box
                  rWidth={124.5}
                  rHeight={23}
                  backgroundImage={`url(./assets/webp/${item.rank}_badge2.png)`}
                  backgroundSize="cover"
                  backgroundRepeat="no-repeat"
                  top={"50%"}
                  transform="translateY(-50%)"
                  rRight={8}
                  position="absolute"
                  display="flex"
                  alignItems="center"
                  justifyContent="space-between"
                  paddingLeft={windowSize.ratioWidth * 9 + "px"}
                  paddingRight={windowSize.ratioWidth * 9 + "px"}
                >
                  <Text
                    rFontSize={11}
                    textTransform="uppercase"
                    color={`rgb(${colors[item.rank] || "255, 255, 255"})`}
                    rLineHeight={11}
                    fontWeight={"bold"}
                    paddingTop={windowSize.ratioHeight * 4 + "px"}
                  >
                    {item.rankLabel || ""}
                  </Text>
                  <Text rFontSize={11} fontWeight={"bold"}>
                    {item.point.toLocaleString()}
                  </Text>
                </Box>
              </Box>
            ))}
          </ScrollBar>
        </Box>
        <Box
          width={"100%"}
          rHeight={52}
          backgroundImage="url(./assets/webp/myrank.webp)"
          backgroundSize="cover"
          backgroundRepeat="no-repeat"
          position="relative"
        >
          <Box
            rWidth={33}
            rHeight={31}
            position="absolute"
            display="flex"
            alignItems="center"
            justifyContent="center"
            top={"50%"}
            transform="translateY(-50%)"
            rLeft={7}
            backgroundImage={`url(./assets/webp/position2.png)`}
            backgroundSize="cover"
            backgroundPosition="center"
            backgroundRepeat="no-repeat"
          >
            <Text rFontSize={16} fontWeight={"bold"}>
              {store.myRank.dual.position}
            </Text>
          </Box>
          <Box
            rWidth={store.myRank.dual.rank === "thachdau" ? 21.5 : 21.1}
            rHeight={32}
            backgroundImage={`url(./assets/webp/${store.myRank.dual.rank}.webp)`}
            backgroundSize="cover"
            backgroundRepeat="no-repeat"
            position="absolute"
            rLeft={58}
            top={"50%"}
            transform="translateY(-50%)"
          ></Box>
          <Text
            rFontSize={16}
            fontWeight={400}
            rLineHeight={40}
            position="absolute"
            top={"50%"}
            transform="translateY(-50%)"
            rLeft={88}
          >
            Hạng của bạn
          </Text>
          <Box
            rWidth={124.5}
            rHeight={23}
            backgroundImage={`url(./assets/webp/${store.myRank.dual.rank}_badge2.png)`}
            backgroundSize="cover"
            backgroundRepeat="no-repeat"
            top={"50%"}
            transform="translateY(-50%)"
            rRight={8}
            position="absolute"
            display="flex"
            alignItems="center"
            justifyContent="space-between"
            paddingLeft={windowSize.ratioWidth * 9 + "px"}
            paddingRight={windowSize.ratioWidth * 9 + "px"}
          >
            <Text
              rFontSize={11}
              textTransform="uppercase"
              color={`rgb(${
                colors[store.myRank.dual.rank] || "255, 255, 255"
              })`}
              rLineHeight={11}
              fontWeight={"bold"}
              paddingTop={windowSize.ratioHeight * 4 + "px"}
            >
              {store.myRank.dual.rankLabel || ""}
            </Text>
            <Text rFontSize={11} fontWeight={"bold"}>
              {store.myRank.dual.point.toLocaleString()}
            </Text>
          </Box>
        </Box>
      </Box>
      <Box
        rWidth={427}
        height={"100%"}
        display="flex"
        alignContent="flex-start"
        flexWrap="wrap"
        rGap={17}
      >
        <Box
          rWidth={427}
          rHeight={549}
          backgroundImage="url(./assets/webp/3vs3.webp)"
          backgroundSize="cover"
          backgroundRepeat="no-repeat"
          position="relative"
        >
          <ScrollBar
            rWidth={415}
            rHeight={482}
            overflowX="hidden"
            overflowY="auto"
            rGap={8}
            position="absolute"
            rTop={52}
            left={"50%"}
            transform="translateX(-50%)"
          >
            {store.leaderboard.trio.map((item, index) => (
              <Box
                width={"100%"}
                rHeight={41}
                key={index}
                position="relative"
                backgroundColor={
                  IndexColor[index as 0 | 1 | 2]
                    ? IndexColor[index as 0 | 1 | 2].backgroundColor
                    : "rgba(38,34,40, 0.39)"
                }
                border={
                  IndexColor[index as 0 | 1 | 2]
                    ? IndexColor[index as 0 | 1 | 2].stroke
                    : "1px solid rgba(159, 156, 255, 0.17)"
                }
              >
                <Box
                  rWidth={index < 1 ? 37 : 33}
                  rHeight={31}
                  position="absolute"
                  display="flex"
                  alignItems="center"
                  justifyContent="center"
                  top={"50%"}
                  transform="translateY(-50%)"
                  rLeft={7}
                  backgroundImage={`url(./assets/webp/${
                    index < 1 ? "position" : "position2"
                  }.png)`}
                  backgroundSize="cover"
                  backgroundPosition="center"
                  backgroundRepeat="no-repeat"
                >
                  <Text rFontSize={16} fontWeight={"bold"}>
                    {index + 1}
                  </Text>
                </Box>
                <Box
                  rWidth={item.rank === "thachdau" ? 21.5 : 21.1}
                  rHeight={32}
                  backgroundImage={`url(./assets/webp/${item.rank}.webp)`}
                  backgroundSize="cover"
                  backgroundRepeat="no-repeat"
                  position="absolute"
                  rLeft={58}
                  top={"50%"}
                  transform="translateY(-50%)"
                ></Box>
                <Text
                  rFontSize={16}
                  fontWeight={400}
                  rLineHeight={40}
                  position="absolute"
                  top={"50%"}
                  transform="translateY(-50%)"
                  rLeft={88}
                >
                  {item.name}
                </Text>
                <Box
                  rWidth={124.5}
                  rHeight={23}
                  backgroundImage={`url(./assets/webp/${item.rank}_badge2.png)`}
                  backgroundSize="cover"
                  backgroundRepeat="no-repeat"
                  top={"50%"}
                  transform="translateY(-50%)"
                  rRight={8}
                  position="absolute"
                  display="flex"
                  alignItems="center"
                  justifyContent="space-between"
                  paddingLeft={windowSize.ratioWidth * 9 + "px"}
                  paddingRight={windowSize.ratioWidth * 9 + "px"}
                >
                  <Text
                    rFontSize={11}
                    textTransform="uppercase"
                    color={`rgb(${colors[item.rank] || "255, 255, 255"})`}
                    rLineHeight={11}
                    fontWeight={"bold"}
                    paddingTop={windowSize.ratioHeight * 4 + "px"}
                  >
                    {item.rankLabel || ""}
                  </Text>
                  <Text rFontSize={11} fontWeight={"bold"}>
                    {item.point.toLocaleString()}
                  </Text>
                </Box>
              </Box>
            ))}
          </ScrollBar>
        </Box>
        <Box
          width={"100%"}
          rHeight={52}
          backgroundImage="url(./assets/webp/myrank.webp)"
          backgroundSize="cover"
          backgroundRepeat="no-repeat"
          position="relative"
        >
          <Box
            rWidth={33}
            rHeight={31}
            position="absolute"
            display="flex"
            alignItems="center"
            justifyContent="center"
            top={"50%"}
            transform="translateY(-50%)"
            rLeft={7}
            backgroundImage={`url(./assets/webp/position2.png)`}
            backgroundSize="cover"
            backgroundPosition="center"
            backgroundRepeat="no-repeat"
          >
            <Text rFontSize={16} fontWeight={"bold"}>
              {store.myRank.trio.position}
            </Text>
          </Box>
          <Box
            rWidth={store.myRank.trio.rank === "thachdau" ? 21.5 : 21.1}
            rHeight={32}
            backgroundImage={`url(./assets/webp/${store.myRank.trio.rank}.webp)`}
            backgroundSize="cover"
            backgroundRepeat="no-repeat"
            position="absolute"
            rLeft={58}
            top={"50%"}
            transform="translateY(-50%)"
          ></Box>
          <Text
            rFontSize={16}
            fontWeight={400}
            rLineHeight={40}
            position="absolute"
            top={"50%"}
            transform="translateY(-50%)"
            rLeft={88}
          >
            Hạng của bạn
          </Text>
          <Box
            rWidth={124.5}
            rHeight={23}
            backgroundImage={`url(./assets/webp/${store.myRank.trio.rank}_badge2.png)`}
            backgroundSize="cover"
            backgroundRepeat="no-repeat"
            top={"50%"}
            transform="translateY(-50%)"
            rRight={8}
            position="absolute"
            display="flex"
            alignItems="center"
            justifyContent="space-between"
            paddingLeft={windowSize.ratioWidth * 9 + "px"}
            paddingRight={windowSize.ratioWidth * 9 + "px"}
          >
            <Text
              rFontSize={11}
              textTransform="uppercase"
              color={`rgb(${
                colors[store.myRank.trio.rank] || "255, 255, 255"
              })`}
              rLineHeight={11}
              fontWeight={"bold"}
              paddingTop={windowSize.ratioHeight * 4 + "px"}
            >
              {store.myRank.trio.rankLabel || ""}
            </Text>
            <Text rFontSize={11} fontWeight={"bold"}>
              {store.myRank.trio.point.toLocaleString()}
            </Text>
          </Box>
        </Box>
      </Box> */}
    </motion.div>
  ) : null;
}

export default LeaderBoard;
