import time
from utils import (
    get_logger, resize_game, get_game_window, 
    click_post, send_key, LogContext
)
from utils.state import set_running, stop as state_stop, get_is_running

logger = get_logger()


def feature_tanconghaiquan(status_callback=None) -> bool:
    """Feature: Tấn công hải quân (Navy Attack)"""
    with LogContext(logger, 'feature_tanconghaiquan'):
        if status_callback:
            status_callback('Tính năng đang chạy: Tấn công hải quân')
        
        if not resize_game():
            logger.error('Không resize được game')
            state_stop()
            return False
        
        hwnd = get_game_window()
        if not hwnd:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False
        
        set_running('Tấn Công Hải Quân', None, status_callback)
        logger.info('Starting navy attack loop')
        
        while get_is_running():
            send_key(hwnd, '1'); time.sleep(0.3)
            click_post(hwnd, 114, 318); time.sleep(1)
            
            send_key(hwnd, '2'); time.sleep(0.3)
            click_post(hwnd, 114, 377); time.sleep(1)
            
            send_key(hwnd, '3'); time.sleep(0.3)
            click_post(hwnd, 114, 426); time.sleep(1)
            
            send_key(hwnd, '4'); time.sleep(0.3)
            click_post(hwnd, 114, 485); time.sleep(1)
            
            send_key(hwnd, '5'); time.sleep(0.3)
            click_post(hwnd, 114, 538); time.sleep(1)
        
        state_stop()
        logger.info('Feature tanconghaiquan stopped by user')
        return True


def stop():
    """Stop the running feature."""
    state_stop()
    logger.info('Feature stop requested')
