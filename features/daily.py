import time
from utils import (
    get_logger, resize_game, get_game_window, 
    click_post, multi_click_post, send_key, LogContext
)
from utils.state import set_running, stop as state_stop, get_is_running

logger = get_logger()


def feature_daily(status_callback=None) -> bool:
    """Feature: Daily tasks"""
    with LogContext(logger, 'feature_daily'):
        if status_callback:
            status_callback('Tính năng đang chạy: Daily')
        
        if not resize_game():
            logger.error('Không resize được game')
            state_stop()
            return False
        
        hwnd = get_game_window()
        if not hwnd:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False
        
        set_running('Daily', None, status_callback)
        logger.info('Starting daily tasks...')
        
        anh_hon(hwnd)
        if not get_is_running(): state_stop(); return True
        
        all_blue(hwnd)
        if not get_is_running(): state_stop(); return True
        
        imple_down(hwnd)
        if not get_is_running(): state_stop(); return True
        
        dung_luyen(hwnd)
        if not get_is_running(): state_stop(); return True
        
        vung_bien_than_bi(hwnd)
        if not get_is_running(): state_stop(); return True
        
        haki(hwnd)
        if not get_is_running(): state_stop(); return True
        
        nguyen_to(hwnd)
        if not get_is_running(): state_stop(); return True
        
        tap_kick(hwnd)
        if not get_is_running(): state_stop(); return True
        
        tang_qua(hwnd)
        if not get_is_running(): state_stop(); return True
        
        bao_thach(hwnd)
        if not get_is_running(): state_stop(); return True
        
        tinh_ban(hwnd)
        
        state_stop()
        logger.info('Feature daily completed')
        return True


def anh_hon(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Anh hon')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 690, 125); time.sleep(5)
    click_post(hwnd, 511, 623); time.sleep(1)
    click_post(hwnd, 710, 285); time.sleep(1)
    click_post(hwnd, 623, 440); time.sleep(1)
    send_key(hwnd, 'Enter'); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def all_blue(hwnd):
    if not get_is_running(): return
    logger.debug('Task: All blue')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 765, 125); time.sleep(5)
    click_post(hwnd, 901, 43); time.sleep(1)
    click_post(hwnd, 745, 369); time.sleep(1)
    multi_click_post(hwnd, 763, 513, 10); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    _support_all_blue(hwnd, 456, 201)
    _support_all_blue(hwnd, 858, 243)
    _support_all_blue(hwnd, 400, 446)
    _support_all_blue(hwnd, 733, 512)
    _support_all_blue(hwnd, 1020, 505)
    time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def imple_down(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Imple down')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 832, 125); time.sleep(7)
    multi_click_post(hwnd, 557, 624, 4); time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def dung_luyen(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Dung luyen')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 972, 125); time.sleep(5)
    click_post(hwnd, 755, 548); time.sleep(1)
    send_key(hwnd, 'Enter'); time.sleep(2)
    click_post(hwnd, 1189, 46); time.sleep(2)


def vung_bien_than_bi(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Vung bien than bi')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 625, 181); time.sleep(5)
    click_post(hwnd, 449, 587); time.sleep(1)
    for _ in range(40):
        if not get_is_running(): return
        click_post(hwnd, 790, 453)
        _support_tra_loi_vbtb(hwnd)
        time.sleep(0.5)
    time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def haki(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Haki')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 697, 181); time.sleep(5)
    click_post(hwnd, 574, 615); time.sleep(2)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def nguyen_to(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Nguyen to')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 835, 181); time.sleep(5)
    click_post(hwnd, 936, 43); time.sleep(2)
    click_post(hwnd, 688, 252); time.sleep(1)
    click_post(hwnd, 470, 354); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 549, 470); time.sleep(1)
    multi_click_post(hwnd, 626, 575, 7); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def tap_kick(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Tap kick')
    click_post(hwnd, 732, 36); time.sleep(3)
    click_post(hwnd, 405, 321); time.sleep(1)
    click_post(hwnd, 886, 554); time.sleep(3)
    click_post(hwnd, 364, 201); time.sleep(1)
    click_post(hwnd, 699, 546); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(2)


def tang_qua(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Tang qua')
    click_post(hwnd, 576, 612); time.sleep(3)
    click_post(hwnd, 416, 136); time.sleep(1)
    click_post(hwnd, 569, 461); time.sleep(1)
    click_post(hwnd, 560, 445); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(2)


def bao_thach(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Bao thach')
    click_post(hwnd, 858, 615); time.sleep(5)
    click_post(hwnd, 679, 389); time.sleep(5)
    click_post(hwnd, 422, 551); time.sleep(1)
    click_post(hwnd, 864, 38); time.sleep(1)
    click_post(hwnd, 828, 535); time.sleep(1)
    for _ in range(10):
        if not get_is_running(): return
        click_post(hwnd, 569, 368); time.sleep(4)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 1235, 29); time.sleep(2)


def tinh_ban(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Tinh ban')
    click_post(hwnd, 957, 615); time.sleep(2)
    click_post(hwnd, 336, 559); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(2)


def _support_all_blue(hwnd, x, y):
    if not get_is_running(): return
    time.sleep(1)
    click_post(hwnd, x, y); time.sleep(1)
    for _ in range(10):
        if not get_is_running(): return
        click_post(hwnd, x, y); time.sleep(0.5)
        send_key(hwnd, 'Esc')


def _support_tra_loi_vbtb(hwnd):
    time.sleep(0.2)
    click_post(hwnd, 524, 332); time.sleep(0.1)
    click_post(hwnd, 860, 647); time.sleep(0.1)
    click_post(hwnd, 508, 345)


def stop():
    """Stop the running feature."""
    state_stop()
    logger.info('Feature stop requested')
