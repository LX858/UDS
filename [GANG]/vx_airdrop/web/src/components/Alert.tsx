import { useMainService } from "@/services/app/main/main.service";
import { Box, Text } from "lr-components";
import { observer } from "mobx-react-lite";
import { formatCountdown } from "@/utils/formatCountdown";

const Alert = observer(() => {
    const mainService = useMainService();
    const { alert } = mainService;

    if (!alert) return null;
    const remaining = Math.max(0, alert.endsAt - mainService.now);
    return (
        <Box
            className="absolute flex flex-col items-end"
            rWidth={285}
            rHeight={105}
            rRight={25}
            rGap={5}
        >
            <Box
                rWidth={285}
                rHeight={77}
                background={"url(./assets/alert.png) no-repeat center center / contain"}
            >
                <Box rRight={60} rBottom={36} className="absolute flex items-center justify-center" rWidth={80} rHeight={20}>
                    <Text rFontSize={16} color="#FFE08A" >{formatCountdown(remaining)}</Text>
                </Box>
            </Box>
            <Box
                rWidth={160}
                rHeight={20}
                className="flex items-center justify-center"
                rGap={10}
            >
                <Box rWidth={72} rHeight={19} background={"url(./assets/accept.png) no-repeat center center / contain"} />
                <Box rWidth={72} rHeight={19} background={"url(./assets/denied.png) no-repeat center center / contain"} />
            </Box>
        </Box>
    )
})

export default Alert;
