Citizen.CreateThread(function()
    StartAudioScene("DLC_MPHEIST_TRANSITION_TO_APT_FADE_IN_RADIO_SCENE")
    SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_01_STAGE",false)
    SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_02_MAIN_ROOM",false)
    SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_03_BACK_ROOM",false)
    
    -- Tắt nhạc Mexican Restaurant
    SetStaticEmitterEnabled("SE_DLC_BTL_NIGHTCLUB_MEXICAN_MUSIC",false)
    SetStaticEmitterEnabled("SE_DLC_BATTLE_MEXICAN_MUSIC",false)
    SetStaticEmitterEnabled("SE_MEXICAN_MUSIC",false)
    SetStaticEmitterEnabled("LOS_SANTOS_MEXICAN_RESTAURANT",false)
end)
