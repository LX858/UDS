-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

Config = {}

Config.CheckForUpdates = false -- Check for updates? Recommended

Config.BackgroundType = 'video'  -- image, video or slideshow (for image, just add the background.jpg to the assets/images folder & for slideshow add multiple images to the assets/images folder like background1.jpg, background2.jpg, etc)

Config.UseLocalVideo = false -- If above you set video and you want to use a local video add it to the assets folder named 'background.webm', otherwise set the youtube URL below

Config.Platform = 'streamable'  -- youtube or streamable (only used if UseLocalVideo is set to false)

Config.VideoID = '2urn05' -- Only used if UseLocalVideo is set to false (if you are using a youtube video get the video code from the URL after the v= & if you are using streamable get the video code from the URL after the /)

Config.AddBlurToBackground = false               -- Add blur to the background image/video

Config.MainColor = '#00FFFF'                    -- Main color used for the whole UI

Config.DelayOnStaffSlides = 5                   -- Delay on staff slides in seconds

Config.TebexLink = 'Under Star Community' -- Link to your Tebex store

Config.UseVideoAudio = true                   -- Set to true to use audio directly from the video (disables separate background music), false to use Config.Songs

Config.RandomizeMusics = true                   -- Randomize the music playlist order (only used if UseVideoAudio is false)

Config.DefaultVolume = 0.1                      -- Default music volume

Config.SlideshowUpdateInterval = 5              -- Slideshow update interval in seconds

Config.AddBackgroundEffect = 'none'             -- Add a background effect to the background (snow & rain or none)

Config.KeyboardLayout = 'QWERTY'                -- QWERTY or AZERTY

Config.Translations = {                         -- You can change the UI text to your own language
    servername = 'Under Star Community',
    serverdesc = 'Roleplay Server',
    updates = 'Updates',
    team = 'Team',
    rules = 'Rules',
    keyboard = 'Keyboard',
    tebexlink = 'Under Star Community',
    loading = 'The city is now loading...',
}

Config.HiddenOptions = {
    -- possible values: "updates", "team", "rules", "keyboard"
    'updates',
    'team',
    'rules',
    'keyboard'
}

Config.Updates = {
    [1] = {
        title = "Patch Note #1",
        date = "27 Dec, 2024",
        name = "New Vehicles Added",
        description =
        "New vehicles have been added to our fleet, providing a more diverse and exciting driving experience. Among the new models are high-performance sports cars, SUVs, and normal vehicles."
    },
    [2] = {
        title = "Patch Note #2",
        date = "03 Jan, 2025",
        name = "Performance Improvements",
        description =
        "We have made significant performance improvements to enhance the overall user experience. These updates include faster load times, reduced lag, and optimized resource usage."
    },
    [3] = {
        title = "Patch Note #3",
        date = "11 Jan, 2025",
        name = "Bug Fixes and Stability",
        description =
        "We have addressed several bugs and stability issues reported by the community. These fixes include resolving crashes, improving server stability, and fixing various gameplay glitches."
    },
    [4] = {
        title = "Patch Note #4",
        date = "21 Jan, 2025",
        name = "New Missions Added",
        description =
        "We have added new missions to the game, providing more challenges and opportunities for players to explore and engage with the city."
    }
}

Config.Rules = {
    [1] = {
        title = "Respect Staff",
        description =
        "Always show respect to the server staff. They are here to help and ensure a smooth gaming experience for everyone."
    },
    [2] = {
        title = "No Harassment",
        description =
        "Harassment of any kind, including bullying, discrimination, or hate speech, will not be tolerated and will result in a ban."
    },
    [3] = {
        title = "Ask for Help",
        description =
        "If you need assistance or have any questions, do not hesitate to ask the staff. We are here to support you."
    },
    [4] = {
        title = "Follow Instructions",
        description =
        "Follow the instructions given by the staff. They are in place to ensure the server runs smoothly and fairly for all players."
    },
    [5] = {
        title = "Report Issues",
        description =
        "If you encounter any issues or witness rule-breaking, report it to the staff immediately. Your cooperation helps maintain a positive environment."
    },
    [6] = {
        title = "Stay Informed",
        description =
        "Keep yourself updated with the server rules and announcements. Ignorance of the rules is not an excuse for breaking them."
    }
}

Config.Team = {
    [1] = {
        name = "Alice Johnson",
        title = "Project Manager",
        image = "user.png"
    },
    [2] = {
        name = "Bob Smith",
        title = "Lead Developer",
        image = "user.png"
    },
    [3] = {
        name = "Charlie Brown",
        title = "Community Manager",
        image = "user.png"
    },
    [4] = {
        name = "Diana Prince",
        title = "Content Creator",
        image = "user.png"
    },
    [5] = {
        name = "Eve Adams",
        title = "Graphic Designer",
        image = "user.png"
    }
}

Config.Songs = {
    [1] = {
        name = "Doxx My Heart",
        artist = "Diamond Eyes",
        file = "doxxmyheart.mp3"
    },
    [2] = {
        name = "Overdrive",
        artist = "Aspyer",
        file = "overdrive.mp3"
    },
    [3] = {
        name = "Muscle Up",
        artist = "Skan",
        file = "muscleup.mp3"
    },
    [4] = {
        name = "Freefall",
        artist = "Rienk & Nct",
        file = "freefall.mp3"
    },
}

Config.Links = {
    tiktok = {
        url = "https://www.tiktok.com/@gtavnrp",
        icon = "fa-brands fa-tiktok",
    },
    youtube = {
        url = "https://www.facebook.com/GTAVNRP",
        icon = "fa-brands fa-facebook",
    },
    discord = {
        url = "https://discord.gg/understar",
        icon = "fa-brands fa-discord",
    },
}

Config.KeyboardKeys = {
    f1 = "Open Help Menu",
    f2 = "Open Settings",
    f3 = "Toggle HUD",
    e = "Interact",
    h = "Horn",
    j = "Toggle Siren",
    k = "Toggle Door Lock",
    m = "Open Map",
    n = "Toggle Voice Chat",
    q = "Quick Inventory",
    r = "Reload Weapon",
    v = "Change View",
    y = "Open Phone",
    i = "Open Inventory",
    o = "Open Objectives",
    home = "Open Admin Menu",
}
