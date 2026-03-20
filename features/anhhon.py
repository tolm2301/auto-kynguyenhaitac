import time
from utils import (
    get_logger, resize_game, get_game_window, 
    click_post, LogContext
)
from utils.state import set_running, stop as state_stop, get_is_running

logger = get_logger()


def feature_anhhon(count: int = 1, status_callback=None) -> bool:
    """Feature: Ảnh hồn (Soul Image)"""
    with LogContext(logger, 'feature_anhhon', count=count):
        if status_callback:
            status_callback('Tính năng đang chạy: Ảnh hồn')
        
        if not resize_game():
            logger.error('Không resize được game')
            state_stop()
            return False
        
        hwnd = get_game_window()
        if not hwnd:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False
        
        set_running('Ảnh Hồn', None, status_callback)
        
        for i in range(count):
            if not get_is_running():
                logger.info('Feature stopped by user')
                break
            
            click_post(hwnd, 739, 626); time.sleep(4)
            click_post(hwnd, 1170, 184); time.sleep(3)
            click_post(hwnd, 627, 634); time.sleep(3)
            logger.debug(f'Anh hon loop [{i+1}/{count}]')
        
        state_stop()
        logger.info(f'Feature anhhon completed: {count} iterations')
        return True


def stop():
    """Stop the running feature."""
    state_stop()
    logger.info('Feature stop requested')
