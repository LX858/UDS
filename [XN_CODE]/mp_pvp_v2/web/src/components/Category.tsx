import { Box, Text, useWindowSize } from "lr-components";
import { useDispatch, useSelector } from "react-redux";
import type { AppDispatch, RootState } from "@/store";
import styled from "styled-components";
import { useButtonSoundEffect } from "@/hooks/useButtonSoundEffect";
import { setPage } from "@/store/main";
import { fetchNui } from "@/utils/fetchNui";

const AnimatedButton = styled(Box)<{ active: boolean }>`
  background-image: ${(props) =>
    props.active
      ? "url(./assets/webp/button_active.webp)"
      : "url(./assets/webp/button.webp)"};
  background-size: cover;
  background-repeat: no-repeat;
  &:hover {
    background-image: url(./assets/webp/button_active.webp);
    background-size: cover;
    background-repeat: no-repeat;
  }
  cursor: pointer;
  transition: background-image 0.3s ease;
`;
function Category() {
  const store = useSelector((state: RootState) => state.main);
  const windowSize = useWindowSize();
  const playSound = useButtonSoundEffect().playSound;
  const dispatch = useDispatch<AppDispatch>();
  return (
    <Box
      rWidth={652}
      rHeight={43}
      position="absolute"
      rTop={120}
      left={"50%"}
      transform="translateX(-50%)"
      display="flex"
      alignItems="center"
      justifyContent="left"
      rGap={32}
    >
      <AnimatedButton
        active={store.page === "room"}
        display="flex"
        alignItems="center"
        justifyContent="center"
        rWidth={196}
        rHeight={43}
        onClick={() => {
          dispatch(setPage("room"));
          playSound("submit");
        }}
      >
        <Text
          rFontSize={14}
          textTransform="uppercase"
          color={store.page === "room" ? "#FFF" : "#A6A6A6"}
          fontWeight={600}
        >
          ghép trận
        </Text>
      </AnimatedButton>
      <AnimatedButton
        active={store.page === "leaderboard"}
        display="flex"
        alignItems="center"
        justifyContent="center"
        rWidth={196}
        rHeight={43}
        onClick={() => {
          fetchNui("getLeaderboard");
          dispatch(setPage("leaderboard"));
          playSound("submit");
        }}
      >
        <Text
          rFontSize={14}
          textTransform="uppercase"
          color={store.page === "leaderboard" ? "#FFF" : "#A6A6A6"}
          fontWeight={600}
        >
          bảng xếp hạng
        </Text>
      </AnimatedButton>
      <AnimatedButton
        active={store.page === "histories"}
        display="flex"
        alignItems="center"
        justifyContent="center"
        rWidth={196}
        rHeight={43}
        onClick={() => {
          dispatch(setPage("histories"));
          playSound("submit");
        }}
      >
        <Text
          rFontSize={14}
          textTransform="uppercase"
          color={store.page === "histories" ? "#FFF" : "#A6A6A6"}
          fontWeight={600}
        >
          lịch sử đấu
        </Text>
      </AnimatedButton>
    </Box>
  );
}

export default Category;
