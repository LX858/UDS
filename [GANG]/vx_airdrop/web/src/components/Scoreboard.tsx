import { useMainService } from "@/services/app/main/main.service";
import { Box, Text } from "lr-components";
import { observer } from "mobx-react-lite";
import { formatCountdown } from "@/utils/formatCountdown";

const Scoreboard = observer(() => {
    const mainService = useMainService();
    const { gameData } = mainService;

    if (!gameData) return null;

    const team1Score = Math.max(0, gameData.team1Score);
    const team2Score = Math.max(0, gameData.team2Score);
    const totalScore = team1Score + team2Score;
    const team1Percent = totalScore > 0 ? (team1Score / totalScore) * 100 : 50;

    return (
        <Box
            className="absolute flex flex-col items-center justify-center"
            rWidth={500}
            rHeight={100}
            rTop={10}
            rGap={10}
        >
            <Box
                rWidth={458}
                rHeight={76}
                background={"url(./assets/scoreboard.png) no-repeat center center / contain"}
            >
                {mainService.myTeam === "A" && (
                    <Box className="absolute" rLeft={30} rBottom={20} rWidth={110} rHeight={21} background={"url(./assets/myteam.png) no-repeat center center / contain"}/>
                )}
                <Box
                    rWidth={50}
                    rHeight={30}
                    className="flex items-center justify-center absolute"
                    rLeft={143}
                    rTop={33}
                >
                    <Text rFontSize={16} color="#FF0000">{gameData.team1Score}</Text>
                </Box>
                <Box rWidth={65} rHeight={25} className="absolute flex items-center justify-center left-1/2 -translate-x-1/2" rTop={35}>
                    <Text rFontSize={16} color="#15FF00">{gameData.overtime ? 'OT' : formatCountdown(gameData.endsAt - mainService.now)}</Text>
                </Box>
                {mainService.myTeam === "B" && (
                    <Box className="absolute" rRight={30} rBottom={20} rWidth={110} rHeight={21} background={"url(./assets/myteam.png) no-repeat center center / contain"}/>
                )}
                <Box
                    rWidth={50}
                    rHeight={30}
                    className="flex items-center justify-center absolute"
                    rRight={143}
                    rTop={33}
                >
                    <Text rFontSize={16} color="#6EEFFF">{gameData.team2Score}</Text>
                </Box>
            </Box>
            <Box rWidth={429} rHeight={8} className="rounded-full relative">
                <Box className="airdrop absolute -translate-x-1/2 z-50" style={{ left: `${team1Percent}%` }} rTop={-10} rWidth={33} rHeight={30} background={"url(./assets/airdrop.png) no-repeat center center / contain"} />
                <Box rWidth={429} rHeight={8} className="scorebar rounded-full overflow-hidden flex">
                    <Box className="h-full" style={{ width: `${team1Percent}%` }} backgroundColor="#00C8FF" />
                    <Box className="h-full flex-1" backgroundColor="#FF0000" />
                </Box>
            </Box>
        </Box>
    )
})

export default Scoreboard;
