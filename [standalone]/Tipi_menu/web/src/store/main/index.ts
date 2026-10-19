import { createSlice, PayloadAction } from "@reduxjs/toolkit";
import { isEnvBrowser } from "../../utils/misc";
import { EventCardConfig } from "../../types/eventCard";
import { FALLBACK_EVENT_CARDS } from "../../constants/eventCards";

interface InitialState {
  show: boolean;
  page: string;
  playerInfo: {
    name: string;
    id: number;
    job: string;
    phoneNumber?: string | number
    age?: string | null;
    timeRegistered: number;
  };
  playerCoin: number;
  time: number;
  primeTicket: number;
  license: {
    hasItemDrive: boolean;
    hasItemBoat: boolean;
    hasItemFly: boolean;
    hasItemWeapon: boolean;
    hasItemIdCard: boolean;
  };
  eventCards: EventCardConfig[];
  eventCardsAdmin: {
    open: boolean;
    cards: EventCardConfig[];
  };
  giftCodeAdmin: {
    open: boolean;
  };
}

const initialState: InitialState = isEnvBrowser()
  ? {
      show: true,
      page: "main",
      playerInfo: {
        name: "UnderStar",
        id: 1,
        job: "Cảnh Sát",
        phoneNumber: '0123456789',
        age: '10 tuổi',
        timeRegistered: 1727117365000.0,
      },
      playerCoin: 1234,
      time: 100,
      primeTicket: 1000,
      license: {
        hasItemDrive: true,
        hasItemBoat: true,
        hasItemFly: true,
        hasItemWeapon: true,
        hasItemIdCard: false,
      },
      eventCards: FALLBACK_EVENT_CARDS,
      eventCardsAdmin: {
        open: false,
        cards: [],
      },
      giftCodeAdmin: {
        open: false,
      },
    }
  : {
      show: false,
      page: "main",
      playerInfo: {
        name: "",
        id: 0,
        job: "",
        timeRegistered: 0,
      },
      playerCoin: 0,
      time: 0,
      primeTicket: 0,
      license: {
        hasItemDrive: false,
        hasItemBoat: false,
        hasItemFly: false,
        hasItemWeapon: false,
        hasItemIdCard: false,
      },
      eventCards: [],
      eventCardsAdmin: {
        open: false,
        cards: [],
      },
      giftCodeAdmin: {
        open: false,
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
    setPlayerInfo(state, action) {
      state.playerInfo = action.payload;
    },
    setPlayerCoin(state, action) {
      state.playerCoin = Number(action.payload) || 0;
    },
    setTime(state, action) {
      state.time = action.payload;
    },
    setPrimeTicket(state, action) {
      state.primeTicket = action.payload;
    },
    setLicense(state, action) {
      state.license = action.payload;
    },
    setEventCards(state, action: PayloadAction<EventCardConfig[]>) {
      state.eventCards = action.payload;
    },
    setEventCardsAdmin(
      state,
      action: PayloadAction<{ open: boolean; cards?: EventCardConfig[] }>,
    ) {
      state.eventCardsAdmin.open = action.payload.open;
      if (action.payload.cards) {
        state.eventCardsAdmin.cards = action.payload.cards;
      }
    },
    setGiftCodeAdmin(state, action: PayloadAction<{ open: boolean }>) {
      state.giftCodeAdmin.open = action.payload.open;
    },
  },
});

export const { setPage, setEventCards, setEventCardsAdmin, setGiftCodeAdmin } = mainSlice.actions;

export default mainSlice;
