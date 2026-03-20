import time
from utils import (
    get_logger, resize_game, get_game_window, 
    click_post, LogContext
)
from utils.state import set_running, stop as state_stop, get_is_running

logger = get_logger()


def feature_enhance(count: int = 1, status_callback=None) -> bool:
    """Feature: Cường hoá (Enhancement)"""
    global logger
    
    with LogContext(logger, 'feature_enhance', count=count):
        if status_callback:
            status_callback('Tính năng đang chạy: Cường hoá')
        
        if not resize_game():
            logger.error('Không resize được game')
            state_stop()
            return False
        
        hwnd = get_game_window()
        if not hwnd:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False
        
        set_running('Cường Hoá', None, status_callback)
        
        for i in range(count):
            if not get_is_running():
                logger.info('Feature stopped by user')
                break
            
            click_post(hwnd, 930, 530)
            logger.debug(f'Enhance click [{i+1}/{count}]')
            time.sleep(0.3)
        
        state_stop()
        logger.info(f'Feature enhance completed: {count} clicks')
        return True


def stop():
    """Stop the running feature."""
    state_stop()
    logger.info('Feature stop requested')
