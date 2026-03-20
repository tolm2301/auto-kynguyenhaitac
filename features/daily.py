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
        
        che_do(hwnd)
        if not get_is_running(): state_stop(); return True
        
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
        if not get_is_running(): state_stop(); return True
        
        ra_khoi(hwnd)
        
        state_stop()
        logger.info('Feature daily completed')
        return True


def che_do(hwnd):
    """Chế độ task."""
    if not get_is_running(): return
    logger.debug('Task: Che do')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 551, 125); time.sleep(15)
    for _ in range(7):
        if not get_is_running(): return
        click_post(hwnd, 279, 405); time.sleep(1)
        send_key(hwnd, 'Enter'); time.sleep(0.5)
    time.sleep(0.5)
    click_post(hwnd, 1089, 334); time.sleep(1)
    click_post(hwnd, 1143, 414); time.sleep(1)
    click_post(hwnd, 1208, 38); time.sleep(7)


def anh_hon(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Anh hon')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 690, 125); time.sleep(15)
    click_post(hwnd, 511, 623); time.sleep(1)
    click_post(hwnd, 711, 387); time.sleep(1)
    click_post(hwnd, 623, 440); time.sleep(1)
    send_key(hwnd, 'Enter'); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def all_blue(hwnd):
    if not get_is_running(): return
    logger.debug('Task: All blue')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 765, 125); time.sleep(15)
    
    _support_all_blue(hwnd, 319, 201)
    _support_all_blue(hwnd, 738, 243)
    _support_all_blue(hwnd, 277, 446)
    _support_all_blue(hwnd, 614, 512)
    _support_all_blue(hwnd, 897, 505)
    time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def imple_down(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Imple down')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 832, 125); time.sleep(15)
    multi_click_post(hwnd, 557, 624, 4); time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def dung_luyen(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Dung luyen')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 972, 125); time.sleep(15)
    click_post(hwnd, 548, 548); time.sleep(1)
    send_key(hwnd, 'Enter'); time.sleep(2)
    click_post(hwnd, 1189, 46); time.sleep(2)


def vung_bien_than_bi(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Vung bien than bi')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 625, 181); time.sleep(15)
    
    for _ in range(10):
        if not get_is_running(): return
        _support_vung_bien_than_bi(hwnd)
    time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def haki(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Haki')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 697, 181); time.sleep(15)
    click_post(hwnd, 574, 615); time.sleep(2)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def nguyen_to(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Nguyen to')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 835, 181); time.sleep(15)
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
    click_post(hwnd, 858, 615); time.sleep(15)
    click_post(hwnd, 679, 389); time.sleep(15)
    click_post(hwnd, 422, 551); time.sleep(1)
    click_post(hwnd, 864, 38); time.sleep(1)
    click_post(hwnd, 828, 224); time.sleep(1)
    for _ in range(5):
        if not get_is_running(): return
        click_post(hwnd, 569, 368); time.sleep(4)
        click_post(hwnd, 569, 408); time.sleep(4)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 1235, 29); time.sleep(2)


def tinh_ban(hwnd):
    if not get_is_running(): return
    logger.debug('Task: Tinh ban')
    click_post(hwnd, 957, 615); time.sleep(2)
    click_post(hwnd, 336, 559); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(2)


def ra_khoi(hwnd):
    """Ra khơi task (bến trái)."""
    if not get_is_running(): return
    logger.debug('Task: Ra khoi (ben trai)')
    click_post(hwnd, 45, 270); time.sleep(3)
    for _ in range(10):
        if not get_is_running(): return
        click_post(hwnd, 804, 210); time.sleep(0.5)
    send_key(hwnd, 'Esc'); time.sleep(7)


def _support_all_blue(hwnd, x, y):
    if not get_is_running(): return
    time.sleep(1)
    click_post(hwnd, x, y); time.sleep(1)
    for _ in range(10):
        if not get_is_running(): return
        click_post(hwnd, x, y); time.sleep(0.5)
        send_key(hwnd, 'Esc')


def _support_vung_bien_than_bi(hwnd):
    click_post(hwnd, 563, 583)
    _support_tra_loi_vbtb(hwnd)
    time.sleep(0.5)


def _support_tra_loi_vbtb(hwnd):
    time.sleep(0.2)
    click_post(hwnd, 524, 332); time.sleep(0.1)
    click_post(hwnd, 860, 647); time.sleep(0.1)
    click_post(hwnd, 508, 345); time.sleep(0.1)
    click_post(hwnd, 543, 229)


def stop():
    """Stop the running feature."""
    state_stop()
    logger.info('Feature stop requested')
