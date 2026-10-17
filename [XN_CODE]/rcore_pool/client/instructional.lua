
function InstructionalButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function InstructionalButton(controlString)
    ScaleformMovieMethodAddParamPlayerNameString(controlString)
end

function SetupScaleformDataSlot(scaleform, slotIndex, keyCode, labelText)
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(slotIndex)
    InstructionalButton(GetControlInstructionalButton(2, keyCode, true))
    InstructionalButtonMessage(labelText)
    PopScaleformMovieFunctionVoid()
end

function FinalizeInstructionalScaleform(scaleform)
    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()
end

function LoadScaleformMovie(name)
    local scaleform = RequestScaleformMovie(name)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end

    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

function setupInstructionalScaleform(name)
    local scaleform = LoadScaleformMovie(name)

    SetupScaleformDataSlot(scaleform, 5, Config.Keys.BACK.code,       Config.Text.BACK)
    SetupScaleformDataSlot(scaleform, 4, Config.Keys.BALL_IN_HAND.code, Config.Text.BALL_IN_HAND)
    SetupScaleformDataSlot(scaleform, 3, Config.Keys.CUE_HIT.code,    Config.Text.HIT)
    SetupScaleformDataSlot(scaleform, 2, Config.Keys.CUE_LEFT.code,   Config.Text.AIM_LEFT)
    SetupScaleformDataSlot(scaleform, 1, Config.Keys.CUE_RIGHT.code,  Config.Text.AIM_RIGHT)
    SetupScaleformDataSlot(scaleform, 0, Config.Keys.AIM_SLOWER.code, Config.Text.AIM_SLOWER)

    FinalizeInstructionalScaleform(scaleform)
    return scaleform
end

function setupInstructionalBallInHandScaleform(name)
    local scaleform = LoadScaleformMovie(name)

    SetupScaleformDataSlot(scaleform, 4, Config.Keys.BALL_IN_HAND_LEFT.code,  Config.Text.BALL_IN_HAND_LEFT)
    SetupScaleformDataSlot(scaleform, 3, Config.Keys.BALL_IN_HAND_RIGHT.code, Config.Text.BALL_IN_HAND_RIGHT)
    SetupScaleformDataSlot(scaleform, 2, Config.Keys.BALL_IN_HAND_UP.code,    Config.Text.BALL_IN_HAND_UP)
    SetupScaleformDataSlot(scaleform, 1, Config.Keys.BALL_IN_HAND_DOWN.code,  Config.Text.BALL_IN_HAND_DOWN)
    SetupScaleformDataSlot(scaleform, 0, Config.Keys.BALL_IN_HAND.code,       Config.Text.BALL_IN_HAND_BACK)

    FinalizeInstructionalScaleform(scaleform)
    return scaleform
end
