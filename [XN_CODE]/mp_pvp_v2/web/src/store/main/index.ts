import { createSlice } from "@reduxjs/toolkit";
import { isEnvBrowser } from "@/utils/misc";
import type { IHistories, IPlayer } from "@/types";
import { toast } from "react-toastify";
interface InitialState {
  show: boolean;
  page: "room" | "leaderboard" | "histories";
  histories: IHistories[];
  players: IPlayer[];
  playerId: number;
  searching: boolean;
  pvpOpenState: {
    open: boolean;
    scheduleLabel: string;
    secondsRemaining: number;
  };
  readyCheck: {
    open: boolean;
    matchId: string;
    duration: number;
    deadline: number;
    readyCount: number;
    total: number;
    accepted: boolean;
    opponentName?: string;
  };
  myRank: {
    solo: {
      position: number;
      point: number;
      rank: string;
      rankLabel?: string;
      kda?: number;
    };
    dual: {
      position: number;
      point: number;
      rank: string;
      rankLabel?: string;
      kda?: number;
    };
    trio: {
      position: number;
      point: number;
      rank: string;
      rankLabel?: string;
      kda?: number;
    };
  };
  leaderboard: {
    solo: {
      id: number;
      name: string;
      point: number;
      rank: string;
      rankLabel?: string;
    }[];
    dual: {
      id: number;
      name: string;
      point: number;
      rank: string;
      rankLabel?: string;
    }[];
    trio: {
      id: number;
      name: string;
      point: number;
      rank: string;
      rankLabel?: string;
    }[];
  };
}

const initialState: InitialState = {
  show: isEnvBrowser(),
  page: "room",
  histories: isEnvBrowser()
    ? [
        {
          state: "win",
          time: 1718438400,
          type: "1vs1",
          point: 100,
        },
        {
          state: "lose",
          time: 1718438400,
          type: "1vs1",
          point: 100,
        },
        {
          state: "win",
          time: 1718438400,
          type: "1vs1",
          point: 100,
        },
        {
          state: "lose",
          time: 1718438400,
          type: "1vs1",
          point: 100,
        },
        {
          state: "win",
          time: 1718438400,
          type: "1vs1",
          point: 100,
        },
        {
          state: "lose",
          time: 1718438400,
          type: "1vs1",
          point: 100,
        },
        {
          state: "win",
          time: 1718438400,
          type: "1vs1",
          point: 100,
        },
        {
          state: "lose",
          time: 1718438400,
          type: "1vs1",
          point: 100,
        },
        {
          state: "win",
          time: 1718438400,
          type: "1vs1",
          point: 100,
        },
      ]
    : [],
  players: isEnvBrowser()
    ? [
        {
          id: 1,
          name: "Player 1",
          soloRank: "vang",
          soloRankLabel: "Vàng",
          solo: 2022,
          dualRank: "thachdau",
          dualRankLabel: "Thách Đấu",
          dual: 200,
          trioRank: "kimcuong",
          trioRankLabel: "Kim Cương",
          trio: 1100,
          leader: true,
        },
        {
          id: 2,
          name: "Player 2",
          soloRank: "dong",
          soloRankLabel: "Đồng",
          solo: 200,
          dualRank: "bachkim",
          dualRankLabel: "Bạch Kim",
          dual: 2022,
          trioRank: "kimcuong",
          trioRankLabel: "Kim Cương",
          trio: 1100,
          leader: false,
        },
        // {
        //   id: 3,
        //   name: "Player 3",
        //   soloRank: "kimcuong",
        //   soloRankLabel: "Kim Cương",
        //   solo: 1100,
        //   dualRank: "dong",
        //   dualRankLabel: "Đồng",
        //   dual: 200,
        //   trioRank: "thachdau",
        //   trioRankLabel: "Thách Đấu",
        //   trio: 2022,
        //   leader: false,
        // },
      ]
    : [],
  playerId: isEnvBrowser() ? 1 : 0,
  searching: false,
  pvpOpenState: {
    open: isEnvBrowser(),
    scheduleLabel: "20:00 - 10:00",
    secondsRemaining: isEnvBrowser() ? 0 : 0,
  },
  readyCheck: {
    open: false,
    matchId: "",
    duration: 15,
    deadline: 0,
    readyCount: 0,
    total: 2,
    accepted: false,
  },
  leaderboard: isEnvBrowser()
    ? {
        solo: [
          {
            id: 1,
            name: "Player 1",
            point: 100,
            rank: "dong",
            rankLabel: "Đồng",
          },
          {
            id: 2,
            name: "Player 2",
            point: 100,
            rank: "bac",
            rankLabel: "Bạc",
          },
          {
            id: 3,
            name: "Player 3",
            point: 100,
            rank: "vang",
            rankLabel: "Vàng",
          },
          {
            id: 4,
            name: "Player 4",
            point: 100,
            rank: "bachkim",
            rankLabel: "Bạch Kim",
          },
          {
            id: 5,
            name: "Player 5",
            point: 100,
            rank: "lucbao",
            rankLabel: "Lục Bảo",
          },
          {
            id: 6,
            name: "Player 6",
            point: 100,
            rank: "kimcuong",
            rankLabel: "Kim Cương",
          },
          {
            id: 7,
            name: "Player 7",
            point: 100,
            rank: "caothu",
            rankLabel: "Cao Thủ",
          },
          {
            id: 8,
            name: "Player 8",
            point: 100,
            rank: "thachdau",
            rankLabel: "Thách Đấu",
          },
          {
            id: 9,
            name: "Player 8",
            point: 100,
            rank: "thachdau",
            rankLabel: "Thách Đấu",
          },
          {
            id: 10,
            name: "Player 8",
            point: 100,
            rank: "thachdau",
            rankLabel: "Thách Đấu",
          },
          {
            id: 11,
            name: "Player 8",
            point: 100,
            rank: "thachdau",
            rankLabel: "Thách Đấu",
          },
          {
            id: 12,
            name: "Player 8",
            point: 100,
            rank: "thachdau",
            rankLabel: "Thách Đấu",
          },
          {
            id: 13,
            name: "Player 8",
            point: 100,
            rank: "thachdau",
            rankLabel: "Thách Đấu",
          },
        ],
        dual: [
          {
            id: 1,
            name: "Player 1",
            point: 100,
            rank: "thachdau",
          },
          {
            id: 2,
            name: "Player 2",
            point: 100,
            rank: "dong",
          },
        ],
        trio: [
          {
            id: 1,
            name: "Player 1",
            point: 100,
            rank: "thachdau",
          },
          {
            id: 2,
            name: "Player 2",
            point: 100,
            rank: "dong",
          },
        ],
      }
    : {
        solo: [],
        dual: [],
        trio: [],
      },
  myRank: isEnvBrowser()
    ? {
        solo: {
          position: 25,
          point: 100,
          rank: "dong",
          rankLabel: "Đồng",
        },
        dual: {
          position: 25,
          point: 100,
          rank: "thachdau",
          rankLabel: "Thách Đấu",
        },
        trio: {
          position: 25,
          point: 100,
          rank: "kimcuong",
          rankLabel: "Kim Cương",
        },
      }
    : {
        solo: { position: 0, point: 0, rank: "" },
        dual: { position: 0, point: 0, rank: "" },
        trio: { position: 0, point: 0, rank: "" },
      },
};

const mainSlice = createSlice({
  name: "main",
  initialState,
  reducers: {
    setShow(state, action) {
      state.show = action.payload;
    },
    setPage(state, action) {
      state.page = action.payload;
    },
    setHistories(state, action) {
      state.histories = action.payload;
    },
    setPlayerId(state, action) {
      state.playerId = action.payload;
    },
    setPlayers(state, action) {
      state.players = action.payload;
    },
    setToast(state, action) {
      if (action.payload.type === "success") {
        toast.success(action.payload.message);
      } else if (action.payload.type === "error") {
        toast.error(action.payload.message);
      } else if (action.payload.type === "warning") {
        toast.warning(action.payload.message);
      } else if (action.payload.type === "info") {
        toast.info(action.payload.message);
      }
    },
    setSearching(state, action) {
      state.searching = action.payload;
    },
    setPvpOpenState(state, action) {
      state.pvpOpenState = {
        open: action.payload.open === true,
        scheduleLabel: action.payload.scheduleLabel || "20:00 - 10:00",
        secondsRemaining: action.payload.secondsRemaining || 0,
      };
    },
    showReadyCheck(state, action) {
      state.readyCheck = {
        open: true,
        matchId: action.payload.matchId,
        duration: action.payload.duration || 15,
        deadline: Date.now() + (action.payload.duration || 15) * 1000,
        readyCount: action.payload.readyCount || 0,
        total: action.payload.total || 2,
        accepted: false,
        opponentName: action.payload.opponentName,
      };
    },
    updateReadyCheck(state, action) {
      state.readyCheck.readyCount = action.payload.readyCount ?? state.readyCheck.readyCount;
      state.readyCheck.total = action.payload.total ?? state.readyCheck.total;
    },
    setReadyCheckAccepted(state, action) {
      state.readyCheck.accepted = action.payload;
    },
    hideReadyCheck(state) {
      state.readyCheck.open = false;
      state.readyCheck.matchId = "";
      state.readyCheck.accepted = false;
      state.readyCheck.readyCount = 0;
      state.readyCheck.deadline = 0;
      state.readyCheck.opponentName = undefined;
    },
    setLeaderboard(state, action) {
      state.leaderboard = action.payload;
    },
    setMyRank(state, action) {
      state.myRank = action.payload;
    },
  },
});

export const { setShow, setPage, setToast, setReadyCheckAccepted } = mainSlice.actions;

export default mainSlice;
