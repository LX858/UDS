import { Box, Text } from "lr-components"
const RewardDialog = ({ rewards, confirm }: { rewards: string, confirm: () => void }) => {
    
    return (
        <Box
            rWidth={655}
            rHeight={491}
            background={"url(./assets/chucmung.png) no-repeat center center / cover"}
            className="absolute z-[100] flex items-center justify-center"
        >
            <Box
                rWidth={278}
                rHeight={278}
                background={"url(./assets/tho.png) no-repeat center center / contain"}
                className='absolute'
                rTop={-85}
                rLeft={-85}
            />
            <Box
                rWidth={278}
                rHeight={278}
                background={"url(./assets/hangnga.png) no-repeat center center / contain"}
                className='absolute'
                rBottom={-35}
                rRight={-155}
            />
            <Box className="absolute left-1/2 -translate-x-1/2" rTop={225}>
                <Text className="LilitaOne" rFontSize={50} fontWeight={500} color="#000">{rewards}</Text>
            </Box>
            <Box
                rWidth={187}
                rHeight={63}
                background={"url(./assets/xacnhan.png) no-repeat center center / contain"}
                className="absolute left-1/2 -translate-x-1/2 pointer-events-auto hover:cursor-pointer hover:scale-105 hover:brightness-[1.2]"
                rBottom={115}
                onClick={()=>{confirm()}}
            />
        </Box>
    )
}

export default RewardDialog;