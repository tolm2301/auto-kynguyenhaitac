"""
Boss features (Rồng Punk, Kraken, Kaido) with multi-threading support.

Ported from AHK features/boss.ahk with worker pool pattern.
Each game window gets its own worker thread for parallel execution.
"""

import time
from utils import (
    get_logger, get_game_windows, resize_all_games,
    click_post, multi_click_post, get_hour, get_minute, LogContext
)
from utils.state import set_running, stop as state_stop, get_is_running
from utils.worker_pool import WorkerPool

logger = get_logger()

# Boss fight duration: 15 minutes
BOSS_FIGHT_DURATION = 15 * 60  # seconds


def _boss_fight_loop(hwnd: int, should_click_attack: bool = True) -> None:
    """Main boss fight loop - clicks attack every 2 seconds for 15 minutes."""
    end_time = time.time() + BOSS_FIGHT_DURATION

    while time.time() < end_time:
        if not get_is_running():
            return

        if should_click_attack:
            click_post(hwnd, 748, 156)

        time.sleep(2)

    # Boss fight ended
    time.sleep(5)
    from utils import send_key
    send_key(hwnd, 'Esc')


def _boss_run_punk_single(hwnd: int) -> None:
    """Run Rồng Punk boss for a single window."""
    time.sleep(3)
    click_post(hwnd, 729, 35); time.sleep(3)
    click_post(hwnd, 339, 200); time.sleep(1)
    click_post(hwnd, 893, 558); time.sleep(2)
    click_post(hwnd, 680, 73); time.sleep(1)
    multi_click_post(hwnd, 582, 145, 10); time.sleep(1)

    _boss_fight_loop(hwnd)


def _boss_run_kraken_single(hwnd: int) -> None:
    """Run Kraken boss for a single window."""
    time.sleep(3)
    click_post(hwnd, 729, 35); time.sleep(3)
    click_post(hwnd, 402, 259); time.sleep(1)
    click_post(hwnd, 893, 558); time.sleep(2)
    click_post(hwnd, 680, 73); time.sleep(1)
    multi_click_post(hwnd, 582, 145, 10); time.sleep(1)

    _boss_fight_loop(hwnd)


def _boss_run_kaido_single(hwnd: int) -> None:
    """Run Kaido boss for a single window."""
    time.sleep(3)
    click_post(hwnd, 1125, 541); time.sleep(5)
    click_post(hwnd, 1129, 122); time.sleep(1)
    click_post(hwnd, 1129, 173); time.sleep(1)

    _boss_fight_loop(hwnd, should_click_attack=False)


def _run_boss_parallel(mode: str, feature_name: str, worker_func, status_callback=None) -> bool:
    """Run boss feature in parallel across all game windows."""
    with LogContext(logger, f'feature_{mode}'):
        if status_callback:
            status_callback(f'Tính năng đang chạy: {feature_name}')

        resize_all_games()
        hwnds = get_game_windows()
        if not hwnds:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False

        set_running(feature_name, None, status_callback)
        logger.info(f'{feature_name} started for {len(hwnds)} windows')

        try:
            pool = WorkerPool(feature_name, status_callback)
            results = pool.run(worker_func, hwnds)

            success_count = sum(1 for r in results if r.success)
            logger.info(f'{feature_name} completed: {success_count}/{len(results)} windows')
        except Exception as e:
            logger.error(f'{feature_name} error: {e}')
        finally:
            state_stop()

        logger.info(f'Feature {mode} stopped')
        return True


def feature_punk(status_callback=None) -> bool:
    """Feature: Rồng Punk boss."""
    return _run_boss_parallel('punk', 'Rồng Punk', _boss_run_punk_single, status_callback)


def feature_kraken(status_callback=None) -> bool:
    """Feature: Kraken boss."""
    return _run_boss_parallel('kraken', 'Kraken', _boss_run_kraken_single, status_callback)


def feature_kaido(status_callback=None) -> bool:
    """Feature: Kaido boss."""
    return _run_boss_parallel('kaido', 'Kaido', _boss_run_kaido_single, status_callback)


def stop():
    """Stop the running feature."""
    state_stop()
    logger.info('Feature stop requested')
