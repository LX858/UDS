import { useMainService } from "@/services/app/main/main.service";
import { Box } from "lr-components";
import { observer } from "mobx-react-lite";

const Weapons = observer(() => {
    const mainService = useMainService();

    if (!mainService.weapons) return null;
    return (
        <Box
            className="absolute"
            rWidth={516}
            rHeight={182}
            background={"url(./assets/weapons.png) no-repeat center center / contain"}
            rBottom={200}
        >
            <Box
                rHeight={95}
                rWidth={450}
                className="absolute left-1/2 -translate-x-1/2 flex items-center justify-center"
                rBottom={25}
                rGap={20}
            >
                {mainService.weapons.map(weapon => (
                    <Box
                        key={weapon.id}
                        className="brightness-[1.5] pointer-events-auto hover:scale-105 hover:cursor-pointer"
                        rWidth={135}
                        rHeight={100}
                        background={`url(./assets/${weapon.image}) no-repeat center center / contain`}
                        onClick={() => mainService.chooseWeapon(weapon.id)}
                    />
                ))}
            </Box>
        </Box>
    )
})

export default Weapons;
