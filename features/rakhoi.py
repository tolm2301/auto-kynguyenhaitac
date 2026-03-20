import time
from utils import (
    get_logger, resize_game, get_game_window, 
    click_post, LogContext
)
from utils.state import set_running, stop as state_stop, get_is_running

logger = get_logger()


def feature_rakhoi(count: int = 1, status_callback=None) -> bool:
    """Feature: Ra khơi (Going out to sea)"""
    with LogContext(logger, 'feature_rakhoi', count=count):
        if status_callback:
            status_callback('Tính năng đang chạy: Ra khơi')
        
        if not resize_game():
            logger.error('Không resize được game')
            state_stop()
            return False
        
        hwnd = get_game_window()
        if not hwnd:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False
        
        set_running('Ra Khơi', None, status_callback)
        
        for i in range(count):
            if not get_is_running():
                logger.info('Feature stopped by user')
                break
            
            click_post(hwnd, 820, 231)
            time.sleep(0.2)
            click_post(hwnd, 820, 281)
            time.sleep(0.2)
            click_post(hwnd, 413, 481)
            time.sleep(0.2)
            logger.debug(f'Ra khoi loop [{i+1}/{count}]')
        
        state_stop()
        logger.info(f'Feature rakhoi completed: {count} iterations')
        return True


def stop():
    """Stop the running feature."""
    state_stop()
    logger.info('Feature stop requested')
