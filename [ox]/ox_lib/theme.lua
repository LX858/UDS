--[[
    ox_lib UI colours (NoPixel V inspired design)

    Change any colour to match your server, then restart ox_lib. No rebuild needed.
    Colours can be written as '#3ee0f5', '#3ee0f5cc', 'rgb(62, 224, 245)' or 'rgba(14, 15, 17, 0.9)'.
    Use rgba(...) for see-through backgrounds: the last number is how solid it is (0 = invisible, 1 = solid).
]]

return {
    -- Main colour: SUBMIT buttons, progress bars, ticked checkboxes, sliders, info notifications
    accent = '#3ee0f5',
    -- Text drawn on top of the main colour (e.g. the word SUBMIT)
    accentText = '#0b0c0e',

    -- Backgrounds
    panel = 'rgba(14, 15, 17, 0.9)',      -- menu titles, dialogs, notifications
    panelSoft = 'rgba(14, 15, 17, 0.78)', -- menu option lists, key hint bars
    radial = 'rgba(0, 0, 0, 0.68)',    -- the radial (circle) menu
    dropdown = '#121316',                 -- open select / date lists in dialogs
    progressTrack = 'rgba(0, 0, 0, 0.45)', -- the empty part of progress bars

    -- Text
    text = '#ffffff',                      -- titles and options
    mutedText = 'rgba(255, 255, 255, 0.62)', -- descriptions and field labels
    dimText = 'rgba(255, 255, 255, 0.36)',   -- disabled options, small print

    -- The hovered / selected option (menus and radial menu)
    highlight = '#ffffff',
    highlightText = '#0b0c0e',

    -- Key badges like [E], [ESC], [ENTER]
    key = '#ffffff',
    keyText = '#0b0c0e',

    -- Text boxes in dialogs
    input = '#ffffff',
    inputText = '#0b0c0e',

    -- Notification colours (icon and timer line)
    info = '#3ee0f5',
    success = '#3ee07d',
    warning = '#ffb321',
    error = '#ff3b52',
}
