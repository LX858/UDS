import { setReadyCheckAccepted } from "@/store/main";
import { fetchNui } from "@/utils/fetchNui";
import { Check, ShieldAlert, Swords, X } from "lucide-react";
import { motion } from "framer-motion";
import { useEffect, useMemo, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import styled, { css, keyframes } from "styled-components";
import type { AppDispatch, RootState } from "../store";

const sweep = keyframes`
  from { transform: translateX(-120%) skewX(-18deg); }
  to { transform: translateX(220%) skewX(-18deg); }
`;

const rotate = keyframes`
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
`;

const pulse = keyframes`
  0%, 100% { opacity: .46; transform: scale(.98); }
  50% { opacity: .9; transform: scale(1.03); }
`;

const Overlay = styled(motion.div)`
  position: fixed;
  inset: 0;
  z-index: 50;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background:
    linear-gradient(180deg, rgba(2, 5, 12, 0.72), rgba(1, 3, 8, 0.86)),
    repeating-linear-gradient(
      0deg,
      rgba(255, 255, 255, 0.035) 0,
      rgba(255, 255, 255, 0.035) 1px,
      transparent 1px,
      transparent 5px
    );
  backdrop-filter: blur(5px);
`;

const Panel = styled(motion.div)<{ $accepted: boolean }>`
  position: relative;
  width: min(430px, calc(100vw - 32px));
  min-height: 520px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  padding: 30px 28px 26px;
  border-radius: 8px;
  border: 1px solid ${({ $accepted }) => ($accepted ? "rgba(65, 255, 155, .54)" : "rgba(141, 181, 255, .42)")};
  background:
    linear-gradient(135deg, rgba(255, 255, 255, 0.1), transparent 32%),
    linear-gradient(180deg, rgba(24, 31, 47, 0.97), rgba(5, 8, 15, 0.98));
  box-shadow:
    0 24px 80px rgba(0, 0, 0, .58),
    0 0 54px ${({ $accepted }) => ($accepted ? "rgba(65, 255, 155, .2)" : "rgba(68, 124, 255, .2)")},
    inset 0 1px 0 rgba(255, 255, 255, .18),
    inset 0 -1px 0 rgba(255, 255, 255, .08);

  &::before {
    content: "";
    position: absolute;
    inset: 0;
    pointer-events: none;
    background:
      linear-gradient(90deg, transparent, rgba(255, 255, 255, .18), transparent),
      linear-gradient(180deg, ${({ $accepted }) => ($accepted ? "rgba(65, 255, 155, .12)" : "rgba(91, 137, 255, .12)")}, transparent 34%);
    animation: ${sweep} 2.8s ease-in-out infinite;
  }

  &::after {
    content: "";
    position: absolute;
    inset: 8px;
    border-radius: 6px;
    border: 1px solid rgba(255, 255, 255, .07);
    pointer-events: none;
  }

  @media (prefers-reduced-motion: reduce) {
    &::before {
      animation: none;
    }
  }
`;

const TopBar = styled.div`
  position: relative;
  z-index: 1;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
`;

const Badge = styled.div<{ $accepted: boolean }>`
  display: inline-flex;
  align-items: center;
  gap: 8px;
  min-height: 32px;
  padding: 0 12px;
  border-radius: 6px;
  border: 1px solid ${({ $accepted }) => ($accepted ? "rgba(65, 255, 155, .5)" : "rgba(141, 181, 255, .38)")};
  color: ${({ $accepted }) => ($accepted ? "#9fffc7" : "#d5e2ff")};
  background: ${({ $accepted }) => ($accepted ? "rgba(36, 255, 138, .12)" : "rgba(84, 128, 255, .12)")};
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0;
  text-transform: uppercase;
`;

const ReadyMeta = styled.div`
  color: rgba(226, 233, 255, .74);
  font-size: 13px;
  font-weight: 800;
  text-transform: uppercase;
`;

const Header = styled.div`
  position: relative;
  z-index: 1;
  width: 100%;
  text-align: center;
  display: grid;
  gap: 8px;
`;

const Title = styled.div`
  color: #ffffff;
  font-size: clamp(24px, 5vw, 32px);
  line-height: 1.05;
  font-weight: 900;
  letter-spacing: 0;
  text-transform: uppercase;
  text-shadow: 0 0 22px rgba(130, 168, 255, .28);
`;

const Meta = styled.div`
  min-height: 22px;
  color: rgba(226, 233, 255, .72);
  font-size: 14px;
  font-weight: 700;
  text-transform: uppercase;
`;

const Arena = styled.div`
  position: relative;
  z-index: 1;
  width: 246px;
  height: 246px;
  display: grid;
  place-items: center;
`;

const TickRing = styled.div`
  position: absolute;
  inset: 0;
  border-radius: 50%;
  background:
    repeating-conic-gradient(
      from -2deg,
      rgba(255, 255, 255, .38) 0deg 2deg,
      transparent 2deg 12deg
    );
  mask: radial-gradient(circle, transparent 68%, #000 69%);
  opacity: .42;
`;

const Orbit = styled.div<{ $accepted: boolean }>`
  position: absolute;
  inset: 14px;
  border-radius: 50%;
  border: 1px solid ${({ $accepted }) => ($accepted ? "rgba(65, 255, 155, .4)" : "rgba(141, 181, 255, .36)")};
  animation: ${rotate} 7s linear infinite;

  &::before,
  &::after {
    content: "";
    position: absolute;
    width: 9px;
    height: 9px;
    border-radius: 50%;
    background: ${({ $accepted }) => ($accepted ? "#41ff9b" : "#8db5ff")};
    box-shadow: 0 0 20px currentColor;
  }

  &::before {
    top: 18px;
    left: 24px;
  }

  &::after {
    right: 26px;
    bottom: 20px;
  }

  @media (prefers-reduced-motion: reduce) {
    animation: none;
  }
`;

const Ring = styled.div<{ $progress: number; $accepted: boolean; $urgent: boolean }>`
  position: relative;
  width: 206px;
  height: 206px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  background:
    conic-gradient(
      ${({ $accepted, $urgent }) => ($accepted ? "#41ff9b" : $urgent ? "#ff4d5d" : "#79a6ff")}
        ${({ $progress }) => $progress * 360}deg,
      rgba(255, 255, 255, .1) 0deg
    );
  box-shadow:
    0 0 38px ${({ $accepted, $urgent }) => ($accepted ? "rgba(65, 255, 155, .32)" : $urgent ? "rgba(255, 77, 93, .3)" : "rgba(91, 137, 255, .34)")},
    inset 0 0 0 1px rgba(255, 255, 255, .14);

  ${({ $urgent, $accepted }) =>
    $urgent &&
    !$accepted &&
    css`
      animation: ${pulse} .85s ease-in-out infinite;
    `}

  @media (prefers-reduced-motion: reduce) {
    animation: none;
  }
`;

const RingInner = styled.div`
  width: 166px;
  height: 166px;
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background:
    radial-gradient(circle at 50% 30%, rgba(55, 70, 104, .98), rgba(8, 11, 19, 1) 67%),
    #080b13;
  border: 1px solid rgba(255, 255, 255, .13);
  box-shadow:
    inset 0 16px 30px rgba(255, 255, 255, .05),
    inset 0 -20px 42px rgba(0, 0, 0, .45);
`;

const Count = styled.div<{ $urgent: boolean; $accepted: boolean }>`
  color: ${({ $accepted, $urgent }) => ($accepted ? "#9fffc7" : $urgent ? "#ffb6bd" : "#ffffff")};
  font-size: 62px;
  line-height: .9;
  font-weight: 900;
  font-variant-numeric: tabular-nums;
  text-shadow: 0 0 24px ${({ $accepted, $urgent }) => ($accepted ? "rgba(65, 255, 155, .34)" : $urgent ? "rgba(255, 77, 93, .4)" : "rgba(130, 168, 255, .32)")};
`;

const ReadyCount = styled.div`
  margin-top: 8px;
  color: rgba(226, 233, 255, .8);
  font-size: 15px;
  font-weight: 900;
  text-transform: uppercase;
`;

const Footer = styled.div`
  position: relative;
  z-index: 1;
  width: 100%;
  display: grid;
  gap: 12px;
`;

const AcceptButton = styled(motion.button)<{ $accepted: boolean }>`
  width: 100%;
  height: 58px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  border-radius: 6px;
  border: 1px solid ${({ $accepted }) => ($accepted ? "rgba(65, 255, 155, .78)" : "rgba(164, 194, 255, .72)")};
  background: ${({ $accepted }) =>
    $accepted
      ? "linear-gradient(180deg, rgba(65, 255, 155, .28), rgba(23, 158, 91, .2))"
      : "linear-gradient(180deg, rgba(126, 166, 255, .28), rgba(62, 96, 190, .2))"};
  color: #ffffff;
  box-shadow:
    0 14px 28px ${({ $accepted }) => ($accepted ? "rgba(23, 158, 91, .24)" : "rgba(62, 96, 190, .24)")},
    inset 0 1px 0 rgba(255, 255, 255, .28);
  font-size: 20px;
  font-weight: 900;
  text-transform: uppercase;
  cursor: ${({ $accepted }) => ($accepted ? "default" : "pointer")};

  &:hover {
    filter: brightness(1.08);
  }

  &:focus-visible {
    outline: 2px solid #ffffff;
    outline-offset: 3px;
  }
`;

const DeclineButton = styled(motion.button)`
  width: 100%;
  height: 42px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: 6px;
  border: 1px solid rgba(255, 94, 111, .5);
  background: rgba(255, 45, 64, .12);
  color: #ffd5da;
  font-size: 14px;
  font-weight: 900;
  text-transform: uppercase;
  cursor: pointer;

  &:hover {
    background: rgba(255, 45, 64, .2);
  }

  &:focus-visible {
    outline: 2px solid #ffd5da;
    outline-offset: 3px;
  }
`;

const Strip = styled.div<{ $accepted: boolean }>`
  height: 5px;
  width: 100%;
  overflow: hidden;
  border-radius: 999px;
  background: rgba(255, 255, 255, .1);

  &::before {
    content: "";
    display: block;
    width: 100%;
    height: 100%;
    transform-origin: left;
    transform: scaleX(${({ $accepted }) => ($accepted ? 1 : 0.5)});
    background: ${({ $accepted }) => ($accepted ? "#41ff9b" : "#79a6ff")};
    box-shadow: 0 0 18px ${({ $accepted }) => ($accepted ? "rgba(65, 255, 155, .55)" : "rgba(121, 166, 255, .55)")};
    transition: transform .25s ease, background .25s ease;
  }
`;

function ReadyCheck() {
  const readyCheck = useSelector((state: RootState) => state.main.readyCheck);
  const dispatch = useDispatch<AppDispatch>();
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    if (!readyCheck.open) return;
    const timer = window.setInterval(() => setNow(Date.now()), 100);
    return () => window.clearInterval(timer);
  }, [readyCheck.open]);

  const remaining = Math.max(0, readyCheck.deadline - now);
  const seconds = Math.ceil(remaining / 1000);
  const progress = useMemo(() => {
    if (!readyCheck.duration) return 0;
    return Math.max(0, Math.min(1, remaining / (readyCheck.duration * 1000)));
  }, [readyCheck.duration, remaining]);
  const urgent = seconds <= 5 && !readyCheck.accepted;
  const opponentName = readyCheck.opponentName || "Đang chờ xác nhận";
  const statusLabel = readyCheck.accepted ? "Đã khóa chọn" : urgent ? "Sắp hết thời gian" : "Ready check";

  if (!readyCheck.open) return null;

  const accept = () => {
    if (readyCheck.accepted) return;
    dispatch(setReadyCheckAccepted(true));
    fetchNui("readyMatch", { matchId: readyCheck.matchId, accepted: true });
  };

  const decline = () => {
    fetchNui("readyMatch", { matchId: readyCheck.matchId, accepted: false });
  };

  return (
    <Overlay initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
      <Panel
        $accepted={readyCheck.accepted}
        initial={{ opacity: 0, y: 28, scale: 0.94 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: "spring", stiffness: 260, damping: 24 }}
      >
        <TopBar>
          <Badge $accepted={readyCheck.accepted}>
            {readyCheck.accepted ? <Check size={15} strokeWidth={2.4} /> : <ShieldAlert size={15} strokeWidth={2.4} />}
            {statusLabel}
          </Badge>
          <ReadyMeta>
            {readyCheck.readyCount}/{readyCheck.total} ready
          </ReadyMeta>
        </TopBar>

        <Header>
          <Title>Trận đấu đã sẵn sàng</Title>
          {/* <Meta>{readyCheck.opponentName ? `Đối thủ: ${opponentName}` : opponentName}</Meta> */}
        </Header>

        <Arena>
          <TickRing />
          <Orbit $accepted={readyCheck.accepted} />
          <Ring $progress={progress} $accepted={readyCheck.accepted} $urgent={urgent}>
            <RingInner>
              <Swords size={28} strokeWidth={2.2} color={readyCheck.accepted ? "#9fffc7" : "#d8e4ff"} />
              <Count $urgent={urgent} $accepted={readyCheck.accepted}>
                {seconds}
              </Count>
              <ReadyCount>
                {readyCheck.accepted ? "Đang chờ đối thủ" : "Bấm sẵn sàng"}
              </ReadyCount>
            </RingInner>
          </Ring>
        </Arena>

        <Footer>
          <Strip $accepted={readyCheck.accepted} />
          <AcceptButton
            $accepted={readyCheck.accepted}
            onClick={accept}
            whileTap={readyCheck.accepted ? undefined : { scale: 0.98 }}
          >
            <Check size={22} strokeWidth={2.6} />
            {readyCheck.accepted ? "Đã sẵn sàng" : "Sẵn sàng"}
          </AcceptButton>
          {!readyCheck.accepted && (
            <DeclineButton onClick={decline} whileTap={{ scale: 0.98 }}>
              <X size={16} strokeWidth={2.6} />
              Từ chối
            </DeclineButton>
          )}
        </Footer>
      </Panel>
    </Overlay>
  );
}

export default ReadyCheck;
