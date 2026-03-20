import threading
from utils import get_logger
from utils.state import stop as state_stop, get_is_running

logger = get_logger()


def feature_stop(status_callback=None):
    """Stop any running feature."""
    logger.info('Feature stop called')
    state_stop()
    
    if status_callback:
        status_callback('Tính năng đang chạy: Chưa có')
    
    return True
