_feature_daily() {

    global FEATURE_TASK_SLEEP := 3000
    global FEATURE_TASK_LONG_SLEEP := 7000
    global LOAD_SLEEP := 1500
    global EXIT_FEATURE_SLEEP := 3000

    _win_resize_game()
    g_featureText.text := "Tính năng đang chạy: Cường hoá"
    hwnd := _win_get_game()
    global isRunning
    isRunning := true

    if !hwnd {
        MsgBox "Không tìm thấy cửa sổ game"
        return
    }

    ;; === TINH NANG ===
    _che_do(hwnd)
    _anh_hon(hwnd)
    _all_blue(hwnd)
    _imple_down(hwnd)
    _dung_luyen(hwnd)
    _vung_bien_than_bi(hwnd)
    _haki(hwnd)
    _nguyen_to(hwnd)
    _tap_kick(hwnd)

    ;; === NHAN VAT ===
    _tang_qua(hwnd)
    _bao_thach(hwnd)
    _tinh_ban(hwnd)

    ; ; === ben trai ===
    _ra_khoi(hwnd)
    _dat_hang(hwnd)
    _dau_truong(hwnd)
    _huan_luyen(hwnd)
    _nau_an(hwnd)
    _cong_hien(hwnd)
    _hoi_dam(hwnd)
    _linh_the_bai(hwnd)
    _cuong_hoa_tau_chien(hwnd)
    _mua_chien_tich(hwnd)
    _nhan_thuong_linh_danh_thue(hwnd)
    _boi_duong_tinh_linh(hwnd)
    _tam_bao(hwnd)
}

_tam_bao(hwnd) {
    _click_post(hwnd, 993, 40)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 836, 122)
    Sleep FEATURE_TASK_SLEEP

    Loop Integer(5) {
        _click_post(hwnd, 938, 38)
        Sleep LOAD_SLEEP
        _click_post(hwnd, 683, 364)
        Sleep LOAD_SLEEP
        _multi_click_post(hwnd, 908, 310, 30)
        Sleep LOAD_SLEEP
        _click_post(hwnd, 557, 570)
        Sleep 60000
        _click_post(hwnd, 150, 248)
        Sleep FEATURE_TASK_SLEEP
    }

    _click_post(hwnd, 1211, 36)
    Sleep FEATURE_TASK_SLEEP
}

_dau_truong(hwnd){
    _click_post(hwnd, 993, 40)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 763, 122)
    Sleep FEATURE_TASK_SLEEP
    Loop Integer(5) {
        _multi_click_post(hwnd, 759, 258, 20, 1000)
        _click_post(hwnd, 1013, 662)
        Sleep LOAD_SLEEP
        _post_with_vk_string(hwnd, "ESC")
        Sleep FEATURE_TASK_SLEEP
    }
    _click_post(hwnd, 1211, 36)
    Sleep FEATURE_TASK_SLEEP
}

_dat_hang(hwnd) {
    x := 704
    y := 245
    Loop Integer(10) {
        _click_post(hwnd, 1072, 614)
        Sleep LOAD_SLEEP
        _click_post(hwnd, 1000, 541)
        Sleep LOAD_SLEEP
        _click_post(hwnd, x, y)
        Sleep LOAD_SLEEP
        _multi_click_post(hwnd, 501, 268, 10, 700)
        _post_with_vk_string(hwnd, "ESC")
        Sleep LOAD_SLEEP
        _post_with_vk_string(hwnd, "ESC")
        Sleep LOAD_SLEEP
        y := y + 22
    }
    Sleep EXIT_FEATURE_SLEEP
}

_boi_duong_tinh_linh(hwnd) {
    _click_post(hwnd, 61, 365)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 926, 560)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 872, 485)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1037, 422)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ENTER")
    _click_post(hwnd, 1222, 42)
    Sleep EXIT_FEATURE_SLEEP
}

_nhan_thuong_linh_danh_thue(hwnd) {
    _click_post(hwnd, 61, 365)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 926, 560)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 872, 516)
    Sleep FEATURE_TASK_LONG_SLEEP
    _click_post(hwnd, 869, 33)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 738, 186)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 746, 285)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ENTER")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1222, 26)
    Sleep EXIT_FEATURE_SLEEP
}

_cuong_hoa_tau_chien(hwnd) {
    _click_post(hwnd, 61, 365)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 926, 560)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 872, 456)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 634, 556)
    Sleep FEATURE_TASK_SLEEP
    _multi_click_post(hwnd, 768, 340, 5)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 768, 427, 5)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 768, 515, 5)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_mua_chien_tich(hwnd) {
    _click_post(hwnd, 61, 365)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 926, 560)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 872, 456)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 533, 500)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 459, 349)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_cong_hien(hwnd) {
    _click_post(hwnd, 61, 365)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 876, 515)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 497, 345)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 711, 349)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 590, 408)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_hoi_dam(hwnd) {
    _click_post(hwnd, 61, 365)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 876, 515)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 499, 457, 6, 2000)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_linh_the_bai(hwnd) {
    _click_post(hwnd, 61, 365)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 876, 546)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 692, 559)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_huan_luyen(hwnd) {
    _click_post(hwnd, 69, 201)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 576, 194)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 623, 544, 2)

    Sleep LOAD_SLEEP
    _click_post(hwnd, 576, 283)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 623, 544, 2)

    Sleep LOAD_SLEEP
    _click_post(hwnd, 576, 361)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 623, 544, 2)

    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_nau_an(hwnd) {
    _click_post(hwnd, 33, 225)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 518, 148)
    Sleep 1000
    _post_with_vk_string(hwnd, "ESC")
    Sleep 1000
    x1 := 365
    x2 := 599
    x3 := 827
    y1 := 266
    y2 := 389
    y3 := 510
    _support_nau_an(hwnd, x3, y3)
    _support_nau_an(hwnd, x2, y3)
    _support_nau_an(hwnd, x1, y3)

    _support_nau_an(hwnd, x3, y2)
    _support_nau_an(hwnd, x2, y2)
    _support_nau_an(hwnd, x1, y2)

    _support_nau_an(hwnd, x3, y1)
    _support_nau_an(hwnd, x2, y1)
    _support_nau_an(hwnd, x1, y1)

    Sleep EXIT_FEATURE_SLEEP
}

_support_nau_an(hwnd, x, y) {
    _click_post(hwnd, 33, 225)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, x, y)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 581, 449, 10)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
}

_ra_khoi(hwnd) {
    _click_post(hwnd, 45, 270)
    Sleep 3000
    Loop Integer(10) {
        _click_post(hwnd, 804, 210)
        sleep 500
    }
    _post_with_vk_string(hwnd, "ESC")
    Sleep 7000
}

_che_do(hwnd) {
    _click_post(hwnd, 925, 35)
    Sleep 1000
    _click_post(hwnd, 551, 125)
    Sleep 15000
    loop Integer(7) {
        _click_post(hwnd, 279, 405)
        Sleep 1000
        _post_with_vk_string(hwnd, "Enter")
        Sleep 500
    }
    Sleep 500
    _click_post(hwnd, 1089, 334)
    Sleep 1000
    _click_post(hwnd, 1143, 414)
    Sleep 1000
    _click_post(hwnd, 1208, 38)
    Sleep 7000
}

_anh_hon(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep 1000
    _click_post(hwnd, 690, 125)
    Sleep 15000
    ;
    _click_post(hwnd, 511, 623)
    Sleep 1000
    _click_post(hwnd, 711, 387)
    Sleep 1000
    _click_post(hwnd, 623, 440)
    Sleep 1000
    _post_with_vk_string(hwnd, "Enter")
    Sleep 1000
    _post_with_vk_string(hwnd, "ESC")
    Sleep 1000
    _click_post(hwnd, 1222, 41)
    Sleep 2000
}

_all_blue(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep 1000
    _click_post(hwnd, 765, 125)
    Sleep 15000
    ;
    ; bat ca
    ; _click_post(hwnd, 901, 43)
    ; Sleep 1000
    ; _click_post(hwnd, 745, 369)
    ; Sleep 1000
    ; _multi_click_post(hwnd, 763, 513, 10)
    ; Sleep 1000
    ; _post_with_vk_string(hwnd, "ESC")
    ; Sleep 1000
    ; _post_with_vk_string(hwnd, "ESC")
    ; Sleep 1000
    ; thu thap
    _support_all_blue(hwnd, 319, 201)
    _support_all_blue(hwnd, 738, 243)
    _support_all_blue(hwnd, 277, 446)
    _support_all_blue(hwnd, 614, 512)
    _support_all_blue(hwnd, 897, 505)
    Sleep 1000
    _click_post(hwnd, 1222, 41)
    Sleep 2000

}

_imple_down(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep 1000
    _click_post(hwnd, 832, 125)
    Sleep 15000
    _multi_click_post(hwnd, 557, 624, 4)
    Sleep 1000
    _click_post(hwnd, 1222, 41)
    Sleep 2000
}

_dung_luyen(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep 1000
    _click_post(hwnd, 972, 125)
    Sleep 15000
    ;
    _click_post(hwnd, 548, 548)
    Sleep 1000
    _post_with_vk_string(hwnd, "Enter")
    Sleep 2000
    _click_post(hwnd, 1189, 46)
    Sleep 2000
}

_vung_bien_than_bi(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep 1000
    _click_post(hwnd, 625, 181)
    Sleep 15000
    ;
    ; _click_post(hwnd, 449, 587)
    ; Sleep 1000
    Loop Integer(10) {
        _support_vung_bien_than_bi(hwnd)
    }
    Sleep 1000
    _click_post(hwnd, 1222, 41)
    Sleep 2000
}

_haki(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep 1000
    _click_post(hwnd, 697, 181)
    Sleep 15000
    ;
    _click_post(hwnd, 574, 615)
    Sleep 2000
    _post_with_vk_string(hwnd, "Esc")
    Sleep 1000
    _click_post(hwnd, 1222, 41)
    Sleep 2000
}

_nguyen_to(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep 1000
    _click_post(hwnd, 835, 181)
    Sleep 15000
    ;
    ; mua nguyen to
    _click_post(hwnd, 936, 43)
    Sleep 2000
    _click_post(hwnd, 688, 252)
    Sleep 1000
    _click_post(hwnd, 470, 354)
    Sleep 1000
    _post_with_vk_string(hwnd, "ESC")
    Sleep 1000
    _post_with_vk_string(hwnd, "ESC")
    Sleep 1000
    _click_post(hwnd, 549, 470)
    Sleep 1000
    _multi_click_post(hwnd, 626, 575, 7)
    Sleep 1000
    _post_with_vk_string(hwnd, "ESC")
    Sleep 1000
    _click_post(hwnd, 1222, 41)
    Sleep 2000
}

_tap_kick(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 732, 36)
    Sleep 3000
    _click_post(hwnd, 405, 321)
    Sleep 1000
    _click_post(hwnd, 886, 554)
    Sleep 3000
    ;
    _click_post(hwnd, 364, 201)
    Sleep 1000
    _click_post(hwnd, 699, 546)
    Sleep 1000
    _post_with_vk_string(hwnd, "ESC")
    Sleep 2000
}

; tangqua
_tang_qua(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 576, 612)
    Sleep 3000
    _click_post(hwnd, 416, 136)
    Sleep 1000
    _click_post(hwnd, 569, 461)
    Sleep 1000
    _click_post(hwnd, 560, 445)
    Sleep 1000
    _post_with_vk_string(hwnd, "ESC")
    Sleep 2000
}

; bao thach
_bao_thach(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 858, 615)
    Sleep 15000
    _click_post(hwnd, 679, 389)
    Sleep 15000
    _click_post(hwnd, 422, 551)
    Sleep 1000
    ;; Me tran
    _click_post(hwnd, 864, 38)
    Sleep 1000
    _click_post(hwnd, 828, 224)
    Sleep 1000
    Loop Integer(5) {
        _click_post(hwnd, 569, 368)
        Sleep 4000
        _click_post(hwnd, 569, 408)
        Sleep 4000
    }
    _post_with_vk_string(hwnd, "ESC")
    Sleep 1000
    _click_post(hwnd, 1235, 29)
    Sleep 2000

}

; tinh ban
_tinh_ban(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 957, 615)
    Sleep 2000
    _click_post(hwnd, 336, 559)
    Sleep 1000
    _post_with_vk_string(hwnd, "ESC")
    Sleep 2000
}

; linh treo thuong
_treo_thuong(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 1179, 615)
    Sleep 2000
    _click_post(hwnd, 855, 533)
    Sleep 1000
    _post_with_vk_string(hwnd, "ESC")
    Sleep 2000
}
; ra khoi
; nau an
; dau truong


_support_all_blue(hwnd, x, y) {
    Sleep 1000
    _click_post(hwnd, x, y)
    Sleep 1000
    Loop Integer(10) {
        _click_post(hwnd, x, y)
        Sleep 500
        _post_with_vk_string(hwnd, "Esc")
    }
}

_support_vung_bien_than_bi(hwnd) {
    _click_post(hwnd, 563, 583)
    _support_tra_loi_vbtb(hwnd)
    Sleep 500
}

_support_tra_loi_vbtb(hwnd) {
    Sleep 200
    _click_post(hwnd, 524, 332)
    Sleep 100
    _click_post(hwnd, 860, 647)
    Sleep 100
    _click_post(hwnd, 508, 345)
    Sleep 100
    _click_post(hwnd, 543, 229)
    Sleep 100
}