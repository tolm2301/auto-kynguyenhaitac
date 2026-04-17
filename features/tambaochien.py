"""
Tầm bảo chiến (Treasure Battle) feature - standalone version.

Runs in a loop across all game windows, re-entering battles every ~30 minutes.
Stops automatically at 15:00 (when Rồng Punk starts).

Ported from AHK gui_main.ahk -> _feature_tam_bao_chien
"""

import time

from utils import (
    get_logger, get_game_windows, resize_all_games,
    click_post, multi_click_post, send_key, get_hour, LogContext
)
from utils.state import set_running, stop as state_stop, get_is_running
from utils.worker_pool import WorkerPool

logger = get_logger()

# Timing constants (matching AHK)
FEATURE_SLEEP = 4.0
LOAD_SLEEP = 1.5
TBC_SLEEP = 60 * 30 + 10  # 30 minutes + 10 seconds


def _tbc_cycle(hwnd: int) -> None:
    """Run one TBC cycle for a single window."""
    # Enter TBC area
    click_post(hwnd, 1218, 538)
    time.sleep(FEATURE_SLEEP)
    click_post(hwnd, 1142, 52)
    time.sleep(LOAD_SLEEP)
    click_post(hwnd, 615, 507)
    time.sleep(LOAD_SLEEP)
    click_post(hwnd, 790, 490)
    time.sleep(LOAD_SLEEP)
    send_key(hwnd, 'Enter')
    time.sleep(LOAD_SLEEP)
    multi_click_post(hwnd, 918, 181, 3, 0.7)
    time.sleep(LOAD_SLEEP)

    # Exit TBC area
    click_post(hwnd, 632, 587)
    time.sleep(LOAD_SLEEP)
    click_post(hwnd, 1213, 52)
    time.sleep(LOAD_SLEEP)


def _tbc_worker(hwnd: int) -> None:
    """TBC worker for a single window - runs cycles in a loop."""
    count = 0

    while get_is_running():
        # Stop at 15:00 (Rồng Punk time)
        if get_hour() == 15:
            logger.info("TBC stopping - 15:00 reached")
            return

        # Run cycle every TBC_SLEEP iterations (or immediately on first run)
        if count >= TBC_SLEEP or count == 0:
            _tbc_cycle(hwnd)
            count = 1

        count += 1
        time.sleep(1)


def feature_tam_bao_chien(status_callback=None) -> bool:
    """
    Feature: Tầm bảo chiến (Treasure Battle) - standalone version.

    Runs in a loop across all game windows, re-entering battles every ~30 minutes.
    Stops automatically at 15:00.
    """
    with LogContext(logger, 'feature_tam_bao_chien'):
        if status_callback:
            status_callback('Tính năng đang chạy: Tầm bảo chiến')

        resize_all_games()
        hwnds = get_game_windows()

        if not hwnds:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False

        set_running('Tầm bảo chiến', None, status_callback)
        logger.info(f'Starting Tầm bảo chiến for {len(hwnds)} windows')

        try:
            pool = WorkerPool('Tầm bảo chiến', status_callback)
            results = pool.run(_tbc_worker, hwnds)

            success_count = sum(1 for r in results if r.success)
            logger.info(f'TBC completed: {success_count}/{len(results)} windows')
        except Exception as e:
            logger.error(f'Tầm bảo chiến error: {e}')
        finally:
            state_stop()

        logger.info('Feature tam_bao_chien completed')
        return True


def stop():
    """Stop the running feature."""
    state_stop()
    logger.info('Feature stop requested')
