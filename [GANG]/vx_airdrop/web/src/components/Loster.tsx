import { Box } from "lr-components";

const Loster = () => {

    return (
        <Box
            className="absolute w-full h-full z-50 bg-black/30 flex items-center justify-center"
        >
            <Box
                rWidth={991}
                rHeight={396}
                background={"url(./assets/loster.png) no-repeat center center / contain"}
            />
        </Box>
    )
}

export default Loster;