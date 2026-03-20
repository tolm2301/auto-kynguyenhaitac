import time
from utils import (
    get_logger, resize_game, get_game_window, 
    click_post, LogContext
)
from utils.state import set_running, stop as state_stop, get_is_running

logger = get_logger()


def feature_nammoiphattai(count: int = 1, status_callback=None) -> bool:
    """Feature: Năm mới phát tài (Lucky New Year)"""
    with LogContext(logger, 'feature_nammoiphattai', count=count):
        if status_callback:
            status_callback('Tính năng đang chạy: Năm mới phát tài')
        
        if not resize_game():
            logger.error('Không resize được game')
            state_stop()
            return False
        
        hwnd = get_game_window()
        if not hwnd:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False
        
        set_running('Năm Mới Phát Tài', None, status_callback)
        
        for i in range(count):
            if not get_is_running():
                logger.info('Feature stopped by user')
                break
            
            click_post(hwnd, 716, 443)
            time.sleep(0.5)
            from utils.post_message import post_key
            post_key(hwnd, 0x1B)
            time.sleep(1)
            logger.debug(f'Nam moi phat tai loop [{i+1}/{count}]')
        
        state_stop()
        logger.info(f'Feature nammoiphattai completed: {count} iterations')
        return True


def stop():
    """Stop the running feature."""
    state_stop()
    logger.info('Feature stop requested')
