_feature_daily() {
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

    ; === ben trai ===
    _ra_khoi(hwnd)
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