import { Box, Text, useWindowSize } from "lr-components";
import type { RootState } from "../store";
import { useSelector } from "react-redux";
import { motion } from "framer-motion";
import styled from "styled-components";
import { fetchNui } from "@/utils/fetchNui";
import type { IPlayer } from "@/types";
import { colors } from "@/utils/misc";
import { useEffect, useState } from "react";

const AnimatedButton = styled(Box)`
  cursor: pointer;
  transition: transform 0.3s ease-in-out;
  &:hover {
    transform: scale(1.05);
  }
`;
const variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1 },
};

const formatCooldown = (seconds: number) => {
  const value = Math.max(Math.floor(seconds), 0);
  const hours = Math.floor(value / 3600)
    .toString()
    .padStart(2, "0");
  const minutes = Math.floor((value % 3600) / 60)
    .toString()
    .padStart(2, "0");
  const remainSeconds = Math.floor(value % 60)
    .toString()
    .padStart(2, "0");
  return `${hours}:${minutes}:${remainSeconds}`;
};

function Room() {
  const store = useSelector((state: RootState) => state.main);
  const windowSize = useWindowSize();
  const leader = store.players.find((player) => player.leader);
  const isNegativeLocked = (leader?.solo ?? 0) <= -150;
  const [openCooldown, setOpenCooldown] = useState(
    store.pvpOpenState.secondsRemaining
  );
  const isPvpClosed = !store.pvpOpenState.open;

  useEffect(() => {
    setOpenCooldown(store.pvpOpenState.secondsRemaining);
  }, [store.pvpOpenState.secondsRemaining, store.pvpOpenState.open]);

  useEffect(() => {
    if (!isPvpClosed) return;
    const timer = window.setInterval(() => {
      setOpenCooldown((value) => Math.max(value - 1, 0));
    }, 1000);

    return () => window.clearInterval(timer);
  }, [isPvpClosed]);

  const getRankWithType = (type: number, player: IPlayer) => {
    if (type === 1) {
      return {
        rank: player.soloRank,
        label: player.soloRankLabel,
        point: player.solo,
      };
    } else if (type === 2) {
      return {
        rank: player.dualRank,
        label: player.dualRankLabel,
        point: player.dual,
      };
    } else if (type === 3) {
      return {
        rank: player.trioRank,
        label: player.trioRankLabel,
        point: player.trio,
      };
    } else {
      return { rank: "", label: "", point: 0 };
    }
  };

  const getType = () => {
    return 1;
  };
  return store.page === "room" ? (
    <motion.div
      initial="hidden"
      animate={store.page === "room" ? "visible" : "hidden"}
      variants={variants}
      transition={{ type: "keyframes", stiffness: 500, duration: 0.35 }}
      style={{
        width: windowSize.ratioWidth * 1053 + "px",
        height: windowSize.ratioHeight * 671 + "px",
        position: "absolute",
        top: windowSize.ratioHeight * 264 + "px",
        left: "50%",
        transform: "translateX(-50%)",
      }}
    >
      <Box width={"100%"} height={"100%"} position="relative" rGap={64}>
        <Box
          width={"100%"}
          rHeight={453}
          position="absolute"
          top={0}
          left={0}
          display="flex"
          alignItems="center"
          justifyContent="center"
          rGap={64}
        >
          {/* <Box
            rWidth={300}
            rHeight={419}
            backgroundImage={
              playerWithoutLeader[0]
                ? `url(./assets/webp/item.webp)`
                : "url(./assets/webp/empty.webp)"
            }
            backgroundSize="cover"
            backgroundPosition="center"
            backgroundRepeat="no-repeat"
          >
            <Box width={"100%"} height={"100%"} position={"relative"}>
              {store.playerId == leader?.id && playerWithoutLeader[0] && (
                <Box
                  rWidth={15}
                  rHeight={15}
                  position="absolute"
                  left={"50%"}
                  transform={"translateX(-50%)"}
                  rBottom={35}
                  backgroundImage="url(./assets/svg/kick.svg)"
                  backgroundSize="cover"
                  backgroundRepeat="no-repeat"
                  backgroundPosition="center"
                  cursor="pointer"
                  onClick={() => {
                    fetchNui("kickPlayer", playerWithoutLeader[0].id);
                  }}
                ></Box>
              )}

              {playerWithoutLeader[0] ? (
                <>
                  <Box
                    rWidth={195}
                    rHeight={35}
                    position="absolute"
                    rTop={49}
                    left={"50%"}
                    transform="translateX(-50%)"
                    backgroundImage={`url(./assets/webp/${
                      getRankWithType(getType(), playerWithoutLeader[0]).rank ||
                      ""
                    }_badge.webp)`}
                    backgroundSize="cover"
                    backgroundRepeat="no-repeat"
                    display="flex"
                    alignItems="center"
                    justifyContent="center"
                  >
                    <Text
                      rFontSize={16}
                      fontWeight={600}
                      display="flex"
                      alignItems="center"
                      justifyContent="center"
                      textTransform="uppercase"
                      color={
                        colors[
                          getRankWithType(getType(), playerWithoutLeader[0])
                            .rank || ""
                        ]
                          ? `rgba(${
                              colors[
                                getRankWithType(
                                  getType(),
                                  playerWithoutLeader[0]
                                ).rank || ""
                              ]
                            }, 1)`
                          : "#000"
                      }
                    >
                      {getRankWithType(getType(), playerWithoutLeader[0]).label}
                    </Text>
                  </Box>
                  <Box
                    rWidth={
                      getRankWithType(getType(), playerWithoutLeader[0])
                        .rank === "thachdau"
                        ? 105
                        : 105
                    }
                    rHeight={
                      getRankWithType(getType(), playerWithoutLeader[0])
                        .rank === "thachdau"
                        ? 156
                        : 158
                    }
                    position="absolute"
                    left={"50%"}
                    transform={"translateX(-50%)"}
                    rTop={126}
                    backgroundImage={`url(./assets/webp/${
                      getRankWithType(getType(), playerWithoutLeader[0]).rank
                    }.webp)`}
                    backgroundSize="cover"
                    backgroundPosition="center"
                    backgroundRepeat="no-repeat"
                    filter={`drop-shadow(0px 0px 20px rgba(${
                      colors[
                        getRankWithType(getType(), playerWithoutLeader[0])
                          .rank || ""
                      ]
                    }, 0.8))`}
                  ></Box>
                  <Text
                    width={"100%"}
                    position="absolute"
                    rTop={317}
                    color="#47464D"
                    textAlign="center"
                    rFontSize={16}
                    rLineHeight={40}
                    fontWeight={600}
                    textTransform="uppercase"
                  >
                    {playerWithoutLeader[0].name}
                  </Text>
                  <Text
                    width={"100%"}
                    position="absolute"
                    textAlign="center"
                    rFontSize={20}
                    fontWeight={"bold"}
                    rTop={96}
                  >
                    {getRankWithType(getType(), playerWithoutLeader[0]).point}
                  </Text>
                </>
              ) : (
                <>
                  <ButtonInvite
                    rWidth={131}
                    rHeight={131}
                    backgroundImage="url(./assets/webp/plus.webp)"
                    backgroundSize="cover"
                    backgroundPosition="center"
                    backgroundRepeat="no-repeat"
                    position="absolute"
                    cursor="pointer"
                    left={"50%"}
                    rTop={124}
                    onClick={() => {
                      fetchNui("invitePlayer");
                    }}
                  ></ButtonInvite>
                  <Text
                    rFontSize={20}
                    textTransform="uppercase"
                    position="absolute"
                    left={"50%"}
                    transform={"translateX(-50%)"}
                    rBottom={115}
                    fontWeight={600}
                  >
                    mời thêm
                  </Text>
                </>
              )}
            </Box>
          </Box> */}
          <Box
            rWidth={325}
            rHeight={453}
            backgroundImage="url(./assets/webp/item2.webp)"
            backgroundSize="cover"
            backgroundPosition="center"
            backgroundRepeat="no-repeat"
          >
            {leader && (
              <Box width={"100%"} height={"100%"} position="relative">
                <Box
                  rWidth={195}
                  rHeight={35}
                  position="absolute"
                  rTop={49}
                  left={"50%"}
                  transform="translateX(-50%)"
                  backgroundImage={`url(./assets/webp/${
                    getRankWithType(getType(), leader).rank || ""
                  }_badge.webp)`}
                  backgroundSize="cover"
                  backgroundRepeat="no-repeat"
                  display="flex"
                  alignItems="center"
                  justifyContent="center"
                >
                  <Text
                    rFontSize={16}
                    fontWeight={600}
                    display="flex"
                    alignItems="center"
                    justifyContent="center"
                    textTransform="uppercase"
                    color={
                      colors[getRankWithType(getType(), leader).rank || ""]
                        ? `rgba(${
                            colors[
                              getRankWithType(getType(), leader).rank || ""
                            ]
                          }, 1)`
                        : "#000"
                    }
                  >
                    {getRankWithType(getType(), leader).label}
                  </Text>
                </Box>
                <Box
                  rWidth={
                    getRankWithType(getType(), leader).rank === "thachdau"
                      ? 205
                      : 205
                  }
                  rHeight={
                    getRankWithType(getType(), leader).rank === "thachdau"
                      ? 205
                      : 205
                  }
                  position="absolute"
                  left={"50%"}
                  transform={"translateX(-50%)"}
                  rTop={128}
                  backgroundImage={`url(./assets/webp/${
                    getRankWithType(getType(), leader).rank || ""
                  }.webp)`}
                  backgroundSize="contain"
                  backgroundPosition="center"
                  backgroundRepeat="no-repeat"
                  filter={`drop-shadow(0px 0px 20px rgba(${
                    colors[getRankWithType(getType(), leader).rank || ""]
                  }, 0.8))`}
                ></Box>
                <Text
                  width={"100%"}
                  position="absolute"
                  rTop={335}
                  color="#47464D"
                  rLineHeight={40}
                  textAlign="center"
                  rFontSize={16}
                  fontWeight={"bold"}
                  textTransform="uppercase"
                >
                  {leader?.name}
                </Text>
                <Text
                  width={"100%"}
                  position="absolute"
                  rTop={96}
                  textAlign="center"
                  rFontSize={20}
                  fontWeight={900}
                >
                  {getRankWithType(getType(), leader).point}
                </Text>
              </Box>
            )}
          </Box>
          {/* <Box
            rWidth={300}
            rHeight={419}
            backgroundImage={
              playerWithoutLeader[1]
                ? `url(./assets/webp/item.webp)`
                : "url(./assets/webp/empty.webp)"
            }
            backgroundSize="cover"
            backgroundPosition="center"
            backgroundRepeat="no-repeat"
          >
            <Box width={"100%"} height={"100%"} position={"relative"}>
              {store.playerId == leader?.id && playerWithoutLeader[1] && (
                <Box
                  rWidth={15}
                  rHeight={15}
                  position="absolute"
                  left={"50%"}
                  transform={"translateX(-50%)"}
                  rBottom={35}
                  backgroundImage="url(./assets/svg/kick.svg)"
                  backgroundSize="cover"
                  backgroundPosition="center"
                  backgroundRepeat="no-repeat"
                  cursor="pointer"
                  onClick={() => {
                    fetchNui("kickPlayer", playerWithoutLeader[1].id);
                  }}
                ></Box>
              )}

              {playerWithoutLeader[1] ? (
                <>
                  <Box
                    rWidth={195}
                    rHeight={35}
                    position="absolute"
                    rTop={49}
                    left={"50%"}
                    transform="translateX(-50%)"
                    backgroundImage={`url(./assets/webp/${
                      getRankWithType(getType(), playerWithoutLeader[1]).rank ||
                      ""
                    }_badge.webp)`}
                    backgroundSize="cover"
                    backgroundRepeat="no-repeat"
                    display="flex"
                    alignItems="center"
                    justifyContent="center"
                  >
                    <Text
                      rFontSize={16}
                      fontWeight={600}
                      display="flex"
                      alignItems="center"
                      justifyContent="center"
                      textTransform="uppercase"
                      color={
                        colors[
                          getRankWithType(getType(), playerWithoutLeader[1])
                            .rank || ""
                        ]
                          ? `rgba(${
                              colors[
                                getRankWithType(
                                  getType(),
                                  playerWithoutLeader[1]
                                ).rank || ""
                              ]
                            }, 1)`
                          : "#000"
                      }
                    >
                      {getRankWithType(getType(), playerWithoutLeader[1]).label}
                    </Text>
                  </Box>
                  <Box
                    rWidth={
                      getRankWithType(getType(), playerWithoutLeader[1])
                        .rank === "thachdau"
                        ? 105
                        : 105
                    }
                    rHeight={
                      getRankWithType(getType(), playerWithoutLeader[1])
                        .rank === "thachdau"
                        ? 156
                        : 158
                    }
                    position="absolute"
                    left={"50%"}
                    transform={"translateX(-50%)"}
                    rTop={128}
                    backgroundImage={`url(./assets/webp/${
                      getRankWithType(getType(), playerWithoutLeader[1]).rank
                    }.webp)`}
                    backgroundSize="cover"
                    backgroundPosition="center"
                    backgroundRepeat="no-repeat"
                    filter={`drop-shadow(0px 0px 20px rgba(${
                      colors[
                        getRankWithType(getType(), playerWithoutLeader[1])
                          .rank || ""
                      ]
                    }, 0.8))`}
                  ></Box>
                  <Text
                    width={"100%"}
                    position="absolute"
                    rTop={317}
                    color="#47464D"
                    textAlign="center"
                    rFontSize={16}
                    rLineHeight={40}
                    fontWeight={600}
                    textTransform="uppercase"
                  >
                    {playerWithoutLeader[1].name}
                  </Text>
                  <Text
                    width={"100%"}
                    position="absolute"
                    rTop={96}
                    textAlign="center"
                    rFontSize={20}
                    fontWeight={"bold"}
                  >
                    {getRankWithType(getType(), playerWithoutLeader[1]).point}
                  </Text>
                </>
              ) : (
                <>
                  <ButtonInvite
                    rWidth={131}
                    rHeight={131}
                    backgroundImage="url(./assets/webp/plus.webp)"
                    backgroundSize="cover"
                    backgroundPosition="center"
                    backgroundRepeat="no-repeat"
                    position="absolute"
                    cursor="pointer"
                    left={"50%"}
                    rTop={124}
                    onClick={() => {
                      fetchNui("invitePlayer");
                    }}
                  ></ButtonInvite>
                  <Text
                    rFontSize={20}
                    textTransform="uppercase"
                    position="absolute"
                    left={"50%"}
                    transform={"translateX(-50%)"}
                    rBottom={115}
                    fontWeight={600}
                  >
                    mời thêm
                  </Text>
                </>
              )}
            </Box>
          </Box> */}
        </Box>
        <Box
          rWidth={494}
          rHeight={isPvpClosed || isNegativeLocked ? 246 : 196}
          position="absolute"
          left={"50%"}
          transform="translateX(-50%)"
          bottom={0}
          display="flex"
          alignContent="flex-start"
          flexWrap="wrap"
          rGap={12}
        >
          <Box
            width={"100%"}
            display="flex"
            alignContent="flex-start"
            flexWrap="wrap"
          >
            <Text
              rFontSize={24}
              textTransform="uppercase"
              width={"100%"}
              textAlign="center"
              fontWeight={600}
            >
              {store.searching ? "ĐANG TÌM TRẬN.." : "ĐANG CHUẨN BỊ"}
            </Text>
            {/* <Text
              rFontSize={16}
              textTransform="uppercase"
              width={"100%"}
              textAlign="center"
            >
              Tổ đội: {store.players.length}/
              <span style={{ color: "#33FF00" }}>3</span>
            </Text> */}
          </Box>
          {isPvpClosed && (
            <Box
              rWidth={360}
              rHeight={58}
              marginLeft="auto"
              marginRight="auto"
              backgroundColor="rgba(15, 18, 31, 0.78)"
              border="1px solid rgba(159, 156, 255, 0.28)"
              display="flex"
              flexDirection="column"
              alignItems="center"
              justifyContent="center"
            >
              <Text
                rFontSize={13}
                textTransform="uppercase"
                color="rgba(227, 228, 233, 0.72)"
                fontWeight={600}
              >
                mở pvp: {store.pvpOpenState.scheduleLabel}
              </Text>
              <Text
                rFontSize={18}
                textTransform="uppercase"
                color="#FFF"
                fontWeight={900}
              >
                cooldown {formatCooldown(openCooldown)}
              </Text>
            </Box>
          )}
          {isNegativeLocked && (
            <AnimatedButton
              rWidth={231}
              rHeight={43}
              marginLeft="auto"
              marginRight="auto"
              backgroundImage="url(./assets/webp/button.webp)"
              backgroundSize="cover"
              backgroundRepeat="no-repeat"
              display="flex"
              alignItems="center"
              justifyContent="center"
              onClick={() => {
                fetchNui("restoreNegativePoint");
              }}
            >
              <Text
                rFontSize={14}
                textTransform="uppercase"
                color="#FFF"
                fontWeight={600}
              >
                khôi phục coin
              </Text>
            </AnimatedButton>
          )}
          <Box
            width={"100%"}
            rHeight={66}
            display="flex"
            alignItems="center"
            justifyContent="center"
            rGap={32}
          >
            <AnimatedButton
              rWidth={231}
              rHeight={66}
              backgroundImage="url(./assets/webp/search.webp)"
              backgroundSize="cover"
              backgroundRepeat="no-repeat"
              onClick={() => {
                if (!store.searching && !isNegativeLocked) {
                  fetchNui("findMatch");
                }
              }}
            ></AnimatedButton>
            <AnimatedButton
              rWidth={231}
              rHeight={66}
              backgroundImage="url(./assets/webp/cancel1.webp)"
              backgroundSize="cover"
              backgroundRepeat="no-repeat"
              onClick={() => {
                fetchNui("cancelSearch");
              }}
            ></AnimatedButton>
          </Box>
        </Box>
      </Box>
    </motion.div>
  ) : null;
}

export default Room;
