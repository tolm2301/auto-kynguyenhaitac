"""
Register Event feature - automatically register for Uta World and other events.

Ported from AHK features/register_event.ahk
"""

import time

from utils import get_logger, get_game_windows, resize_all_games, click_post, send_key
from utils.state import set_running, stop as state_stop, get_is_running
from utils.worker_pool import WorkerPool

logger = get_logger()


def _register_single(hwnd: int) -> None:
    """Register for Uta World event on a single window."""
    # Open event menu
    click_post(hwnd, 729, 35)
    time.sleep(3)

    # Select Uta World
    click_post(hwnd, 414, 523)
    time.sleep(2)

    # Click register
    click_post(hwnd, 338, 200)
    time.sleep(2)

    # Confirm
    click_post(hwnd, 746, 556)
    time.sleep(1)

    # Close
    send_key(hwnd, 'Esc')


def feature_register_uta(status_callback=None) -> bool:
    """
    Feature: Register for Uta World event.

    Runs in parallel across all game windows.
    """
    resize_all_games()
    hwnds = get_game_windows()

    if not hwnds:
        logger.error("Không tìm thấy cửa sổ game")
        state_stop()
        return False

    if status_callback:
        status_callback("Tính năng đang chạy: Register Uta World")

    set_running("Register Uta World", None, status_callback)
    logger.info(f"Starting Register Uta World for {len(hwnds)} windows")

    try:
        pool = WorkerPool("Register Uta World", status_callback)
        pool.run(_register_single, hwnds)
    except Exception as e:
        logger.error(f"Register Uta World error: {e}")
    finally:
        state_stop()

    logger.info("Feature register_uta completed")
    return True


def feature_register_event(status_callback=None) -> bool:
    """Alias for feature_register_uta."""
    return feature_register_uta(status_callback)
