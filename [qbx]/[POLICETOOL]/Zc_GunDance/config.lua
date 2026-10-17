-- 
Config = {}
Config.Gun = {
 --[[    [1] = {
        Gunname = 'weapon_pistol',
        Dance = true, -- Chọn một trong hai: Stunt hoặc Dance
        Stunt = false, -- Chọn một trong hai: Stunt hoặc Dance
        Stunttime = 10, ---- Thời gian ngã (giây)
        effect = false ,  ------- Bật hiệu ứng màn hình màu vàng không?
        TyreBust = true --- Làm nổ lốp không?
    }, ]]
  --[[   [1] = {
        Gunname = 'weapon_stungun',
        Dance = false, -- Chọn một trong hai: Stunt hoặc Dance
        Stunt = true, -- Chọn một trong hai: Stunt hoặc Dance
        Stunttime = 10, ---- Thời gian ngã (giây)
        effect = true , ------- Bật hiệu ứng màn hình màu vàng không?
        TyreBust = true --- Làm nổ lốp không?
    }, ]]
    [1] = {
        Gunname = 'weapon_pumpshotgun',
        Dance = false, -- Chọn một trong hai: Stunt hoặc Dance
        Stunt = true, -- Chọn một trong hai: Stunt hoặc Dance
        Stunttime = 8, ---- Thời gian ngã (giây)
        effect = true , ------- Bật hiệu ứng màn hình màu vàng không?
        TyreBust = false --- Làm nổ lốp không?
    },
  --[[   [2] = {
        Gunname = 'weapon_pumpshotgun',
        Dance = false, -- Chọn một trong hai: Stunt hoặc Dance
        Stunt = true, -- Chọn một trong hai: Stunt hoặc Dance
        Stunttime = 15, ---- Thời gian ngã (giây)
        effect = true , ------- Bật hiệu ứng màn hình màu vàng không?
        TyreBust = true --- Làm nổ lốp không?
    }, ]]

}

Config.ani = {   -------- Động tác nhảy ngẫu nhiên cho súng kích hoạt nhảy
    [0] = {
        dict = "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@",
        anim = "low_center"
    },
    [1] = {
        dict = "anim@amb@nightclub@dancers@solomun_entourage@",
        anim = "mi_dance_facedj_17_v1_female^1"

    },
    [2] = {
        dict = "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
        anim = "high_center"

    },
    [3] = {
        dict = "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
        anim = "high_center_up"

    },
    [4] = {
        dict = "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity",
        anim = "hi_dance_facedj_09_v2_female^1"

    },
    [5] = {
        dict = "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity",
        anim = "hi_dance_facedj_09_v2_female^3"

    },
    [6] = {
        dict = "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
        anim = "high_center_up"

    },
    [7] = {
        dict = "anim@amb@nightclub@dancers@podium_dancers@",
        anim = "hi_dance_facedj_17_v2_male^5"

    },
    [8] = {
        dict = "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@",
        anim = "high_center_down"

    },
    [9] = {
        dict = "anim@amb@nightclub@mini@dance@dance_solo@male@var_a@",
        anim = "high_center"

    },
    [10] = {
        dict = "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@",
        anim = "high_center_up"

    },
    [11] = {dict = "rcmnigel1bnmt_1b", anim = "dance_loop_tyler"},
    [12] = {dict = "misschinese2_crystalmazemcs1_cs", anim = "dance_loop_tao"},
    [13] = {dict = "misschinese2_crystalmazemcs1_ig", anim = "dance_loop_tao"},
    [14] = {dict = "missfbi3_sniping", anim = "dance_m_default"},
    [15] = {
        dict = "special_ped@mountain_dancer@monologue_3@monologue_3a",
        anim = "mnt_dnc_buttwag"

    },
    [16] = {dict = "move_clown@p_m_zero_idles@", anim = "fidget_short_dance"},
    [17] = {dict = "move_clown@p_m_two_idles@", anim = "fidget_short_dance"},
    [18] = {
        dict = "anim@amb@nightclub@lazlow@hi_podium@",
        anim = "danceidle_hi_11_buttwiggle_b_laz"

    },
    [19] = {dict = "timetable@tracy@ig_5@idle_a", anim = "idle_a"},
    [20] = {dict = "timetable@tracy@ig_8@idle_b", anim = "idle_d"},
    [21] = {
        dict = "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
        anim = "med_center_up"

    },
    [22] = {
        dict = "anim@mp_player_intcelebrationfemale@the_woogie",
        anim = "the_woogie"

    },
    [23] = {
        dict = "anim@amb@casino@mini@dance@dance_solo@female@var_b@",
        anim = "high_center"

    },
    [24] = {
        dict = "anim@amb@casino@mini@dance@dance_solo@female@var_a@",
        anim = "med_center"

    }
}

Config.Song = { -------- Bài hát ngẫu nhiên cho súng kích hoạt nhảy
    [1] = {time = 23, song = 'Santa.mp3', loud = 1.0},
    [2] = {time = 23, song = 'tiktok.mp3', loud = 1.0},

}
