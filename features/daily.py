"""
Daily tasks feature - runs all daily tasks for all game windows in parallel.

Ported from AHK features/daily.ahk with multi-threading support.
Includes progress persistence (resume from last completed task).
"""

import time
import configparser
from pathlib import Path
from typing import Optional, Callable

from utils import (
    get_logger, get_game_windows, resize_all_games,
    click_post, multi_click_post, send_key, LogContext
)
from utils.state import set_running, stop as state_stop, get_is_running
from utils.worker_pool import WorkerPool

logger = get_logger()

# Paths
RESOURCES_DIR = Path(__file__).parent.parent / 'resources'
LOGS_DIR = Path(__file__).parent.parent / 'logs'
STATE_INI = RESOURCES_DIR / 'dailystate.ini'

# Timing constants (matching AHK)
FEATURE_TASK_SLEEP = 5.0
FEATURE_TASK_LONG_SLEEP = 15.0
LOAD_SLEEP = 2.0
SHORT_LOAD_SLEEP = 1.0
EXIT_FEATURE_SLEEP = 7.0


def _daily_log(msg: str) -> None:
    """Write to daily log file."""
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    log_path = LOGS_DIR / "daily.log"
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    try:
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(f"[{timestamp}] {msg}\n")
    except Exception as e:
        logger.error(f"Error writing daily log: {e}")


def _get_state_section() -> str:
    return "Daily"


def _get_today_key() -> str:
    return time.strftime("%Y%m%d")


def _load_progress(tasks: list, total_tasks: int) -> tuple[int, int, str]:
    """
    Load progress from state file.
    Returns (start_index, completed_index, completed_task_id).
    """
    default_state = (1, 0, "")

    if not STATE_INI.exists():
        return default_state

    try:
        config = configparser.ConfigParser()
        config.read(STATE_INI, encoding='utf-8')
        section = _get_state_section()

        if section not in config:
            return default_state

        saved_index = int(config.get(section, "lastCompletedTaskIndex", fallback="0"))
        saved_task_id = config.get(section, "lastCompletedTaskId", fallback="")

        if saved_index < 0 or saved_index > total_tasks:
            return default_state

        completed_index = saved_index

        # Verify task ID matches
        if saved_task_id:
            for i, (task_id, _) in enumerate(tasks, 1):
                if task_id == saved_task_id:
                    completed_index = i
                    break

        start_index = completed_index + 1
        if start_index > total_tasks:
            return default_state

        return (start_index, completed_index, saved_task_id)
    except Exception as e:
        logger.error(f"Error loading daily progress: {e}")
        return default_state


def _save_progress(task_index: int, task_id: str) -> None:
    """Save progress to state file."""
    try:
        RESOURCES_DIR.mkdir(parents=True, exist_ok=True)

        config = configparser.ConfigParser()
        if STATE_INI.exists():
            config.read(STATE_INI, encoding='utf-8')

        section = _get_state_section()
        if section not in config:
            config[section] = {}

        config[section]["lastCompletedTaskIndex"] = str(task_index)
        config[section]["lastCompletedTaskId"] = task_id
        config[section]["updatedAt"] = time.strftime("%Y%m%d%H%M%S")

        with open(STATE_INI, 'w', encoding='utf-8') as f:
            config.write(f)
    except Exception as e:
        logger.error(f"Error saving daily progress: {e}")


def _reset_progress() -> None:
    """Reset progress in state file."""
    if not STATE_INI.exists():
        return

    try:
        config = configparser.ConfigParser()
        config.read(STATE_INI, encoding='utf-8')
        section = _get_state_section()

        if section in config:
            config.remove_section(section)

            with open(STATE_INI, 'w', encoding='utf-8') as f:
                config.write(f)
    except Exception as e:
        logger.error(f"Error resetting daily progress: {e}")


def _get_task_list() -> list[tuple[str, Callable]]:
    """Get list of daily tasks (id, function)."""
    return [
        ("che_do", che_do),
        ("anh_hon", anh_hon),
        ("all_blue", all_blue),
        ("imple_down", imple_down),
        ("dung_luyen", dung_luyen),
        ("vung_bien_than_bi", vung_bien_than_bi),
        ("haki", haki),
        ("nguyen_to", nguyen_to),
        ("tap_kick", tap_kick),
        ("tang_qua", tang_qua),
        ("bao_thach", bao_thach),
        ("tinh_ban", tinh_ban),
        ("ra_khoi", ra_khoi),
        ("linh_treo_thuong", linh_treo_thuong),
        ("dau_truong", dau_truong),
        ("huan_luyen", huan_luyen),
        ("nau_an", nau_an),
        ("tam_bao", tam_bao),
        ("boi_duong_tinh_linh", boi_duong_tinh_linh),
        ("nhan_thuong_linh_danh_thue", nhan_thuong_linh_danh_thue),
        ("dat_hang", dat_hang),
        ("linh_the_bai", linh_the_bai),
        ("cuong_hoa_tau_chien", cuong_hoa_tau_chien),
        ("nhon_hop_qua", nhon_hop_qua),
    ]


def _run_daily_single(hwnd: int) -> None:
    """Run all daily tasks for a single game window with progress persistence."""
    tasks = _get_task_list()
    total_tasks = len(tasks)
    progress = _load_progress(tasks, total_tasks)
    start_index = progress[0]

    if start_index > 1:
        _daily_log(f"Resume từ task #{start_index} (đã xong #{progress[1]} | id={progress[2]})")

    for task_index, (task_id, task_func) in enumerate(tasks, 1):
        if task_index < start_index:
            continue

        if not get_is_running():
            _daily_log(f"Stop signal hwnd={hwnd} tại task #{task_index}")
            return

        try:
            task_func(hwnd)
            _save_progress(task_index, task_id)
            _daily_log(f"Done hwnd={hwnd} task #{task_index} | id={task_id}")
        except Exception as e:
            _daily_log(f"Fail hwnd={hwnd} task #{task_index} | id={task_id} | err={e}")
            raise

    _reset_progress()
    _daily_log(f"Complete daily hwnd={hwnd}, reset progress")


# ==================== Daily Task Functions ====================


def che_do(hwnd: int) -> None:
    """Chế độ task."""
    if not get_is_running():
        return
    logger.debug('Task: Che do')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 551, 125); time.sleep(15)
    for _ in range(7):
        if not get_is_running():
            return
        click_post(hwnd, 279, 405); time.sleep(1)
        send_key(hwnd, 'Enter'); time.sleep(0.5)
    time.sleep(0.5)
    click_post(hwnd, 1089, 334); time.sleep(1)
    click_post(hwnd, 1143, 414); time.sleep(1)
    click_post(hwnd, 1208, 38); time.sleep(7)


def anh_hon(hwnd: int) -> None:
    """Ảnh hồn task."""
    if not get_is_running():
        return
    logger.debug('Task: Anh hon')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 690, 125); time.sleep(15)
    click_post(hwnd, 511, 623); time.sleep(1)
    click_post(hwnd, 711, 387); time.sleep(1)
    click_post(hwnd, 623, 440); time.sleep(1)
    send_key(hwnd, 'Enter'); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def all_blue(hwnd: int) -> None:
    """All Blue task."""
    if not get_is_running():
        return
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


def imple_down(hwnd: int) -> None:
    """Imple Down task."""
    if not get_is_running():
        return
    logger.debug('Task: Imple down')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 832, 125); time.sleep(15)
    multi_click_post(hwnd, 557, 624, 4); time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def dung_luyen(hwnd: int) -> None:
    """Dung luyện task."""
    if not get_is_running():
        return
    logger.debug('Task: Dung luyen')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 972, 125); time.sleep(15)
    click_post(hwnd, 548, 548); time.sleep(1)
    send_key(hwnd, 'Enter'); time.sleep(2)
    click_post(hwnd, 1189, 46); time.sleep(2)


def vung_bien_than_bi(hwnd: int) -> None:
    """Vùng biển thần bí task."""
    if not get_is_running():
        return
    logger.debug('Task: Vung bien than bi')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 625, 181); time.sleep(15)

    for _ in range(10):
        if not get_is_running():
            return
        _support_vung_bien_than_bi(hwnd)
    time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def haki(hwnd: int) -> None:
    """Haki task."""
    if not get_is_running():
        return
    logger.debug('Task: Haki')
    click_post(hwnd, 925, 35); time.sleep(1)
    click_post(hwnd, 697, 181); time.sleep(15)
    click_post(hwnd, 574, 615); time.sleep(2)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 1222, 41); time.sleep(2)


def nguyen_to(hwnd: int) -> None:
    """Nguyên tố task."""
    if not get_is_running():
        return
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


def tap_kick(hwnd: int) -> None:
    """Tạp kỹ task."""
    if not get_is_running():
        return
    logger.debug('Task: Tap kick')
    click_post(hwnd, 732, 36); time.sleep(3)
    click_post(hwnd, 405, 321); time.sleep(1)
    click_post(hwnd, 886, 554); time.sleep(3)
    click_post(hwnd, 364, 201); time.sleep(1)
    click_post(hwnd, 699, 546); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(2)


def tang_qua(hwnd: int) -> None:
    """Tặng quà task."""
    if not get_is_running():
        return
    logger.debug('Task: Tang qua')
    click_post(hwnd, 576, 612); time.sleep(3)
    click_post(hwnd, 416, 136); time.sleep(1)
    click_post(hwnd, 569, 461); time.sleep(1)
    click_post(hwnd, 560, 445); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(2)


def bao_thach(hwnd: int) -> None:
    """Bảo thạch task."""
    if not get_is_running():
        return
    logger.debug('Task: Bao thach')
    click_post(hwnd, 858, 615); time.sleep(15)
    click_post(hwnd, 679, 389); time.sleep(15)
    click_post(hwnd, 415, 59); time.sleep(1)
    multi_click_post(hwnd, 710, 408, 3); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 864, 38); time.sleep(2)
    click_post(hwnd, 828, 224); time.sleep(1)
    for _ in range(5):
        if not get_is_running():
            return
        click_post(hwnd, 569, 368); time.sleep(4)
        click_post(hwnd, 569, 408); time.sleep(4)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 1235, 29); time.sleep(2)


def tinh_ban(hwnd: int) -> None:
    """Tình bạn task."""
    if not get_is_running():
        return
    logger.debug('Task: Tinh ban')
    click_post(hwnd, 957, 615); time.sleep(2)
    click_post(hwnd, 336, 559); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(2)


def ra_khoi(hwnd: int) -> None:
    """Ra khơi task (bến trái)."""
    if not get_is_running():
        return
    logger.debug('Task: Ra khoi (ben trai)')
    click_post(hwnd, 45, 270); time.sleep(3)
    for _ in range(15):
        if not get_is_running():
            return
        click_post(hwnd, 804, 210); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(7)


def linh_treo_thuong(hwnd: int) -> None:
    """Linh treo thuong task."""
    if not get_is_running():
        return
    logger.debug('Task: Linh treo thuong')
    click_post(hwnd, 1184, 616); time.sleep(5)
    click_post(hwnd, 855, 533); time.sleep(2)
    send_key(hwnd, 'Esc'); time.sleep(5)


def dau_truong(hwnd: int) -> None:
    """Đấu trường task."""
    if not get_is_running():
        return
    logger.debug('Task: Dau truong')
    click_post(hwnd, 993, 40); time.sleep(1)
    click_post(hwnd, 763, 122); time.sleep(2)
    for _ in range(5):
        if not get_is_running():
            return
        multi_click_post(hwnd, 759, 258, 15, 1.0)
        click_post(hwnd, 1013, 662); time.sleep(1)
        send_key(hwnd, 'Esc'); time.sleep(2)
    click_post(hwnd, 1211, 36); time.sleep(2)


def huan_luyen(hwnd: int) -> None:
    """Huấn luyện task."""
    if not get_is_running():
        return
    logger.debug('Task: Huan luyen')
    click_post(hwnd, 69, 201); time.sleep(5)
    click_post(hwnd, 576, 194); time.sleep(1)
    multi_click_post(hwnd, 623, 544, 2)
    time.sleep(1)
    click_post(hwnd, 576, 283); time.sleep(1)
    multi_click_post(hwnd, 623, 544, 2)
    time.sleep(1)
    click_post(hwnd, 576, 361); time.sleep(1)
    multi_click_post(hwnd, 623, 544, 2)
    time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(7)


def nau_an(hwnd: int) -> None:
    """Nấu ăn task."""
    if not get_is_running():
        return
    logger.debug('Task: Nau an')
    click_post(hwnd, 33, 225); time.sleep(5)
    click_post(hwnd, 518, 148); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)

    x_coords = [365, 599, 827]
    y_coords = [266, 389, 510]

    for y in reversed(y_coords):
        for x in reversed(x_coords):
            if not get_is_running():
                return
            _support_nau_an(hwnd, x, y)

    time.sleep(7)


def tam_bao(hwnd: int) -> None:
    """Tầm bảo task."""
    if not get_is_running():
        return
    logger.debug('Task: Tam bao')
    click_post(hwnd, 993, 40); time.sleep(1)
    click_post(hwnd, 836, 122); time.sleep(2)

    for _ in range(5):
        if not get_is_running():
            return
        click_post(hwnd, 938, 38); time.sleep(1)
        click_post(hwnd, 683, 364); time.sleep(1)
        multi_click_post(hwnd, 908, 310, 30); time.sleep(1)
        click_post(hwnd, 557, 570); time.sleep(60)
        click_post(hwnd, 150, 248); time.sleep(2)

    click_post(hwnd, 1211, 36); time.sleep(2)


def boi_duong_tinh_linh(hwnd: int) -> None:
    """Bồi dưỡng tinh linh task."""
    if not get_is_running():
        return
    logger.debug('Task: Boi duong tinh linh')
    click_post(hwnd, 692, 599); time.sleep(5)
    click_post(hwnd, 483, 610); time.sleep(1)
    click_post(hwnd, 1037, 422); time.sleep(1)
    send_key(hwnd, 'Enter'); time.sleep(1)
    click_post(hwnd, 1227, 38); time.sleep(7)


def nhan_thuong_linh_danh_thue(hwnd: int) -> None:
    """Nhận thưởng linh danh thuê task."""
    if not get_is_running():
        return
    logger.debug('Task: Nhan thuong linh danh thue')
    click_post(hwnd, 926, 41); time.sleep(5)
    click_post(hwnd, 1045, 193); time.sleep(5)
    click_post(hwnd, 409, 503); time.sleep(15)
    click_post(hwnd, 869, 33); time.sleep(1)
    click_post(hwnd, 738, 186); time.sleep(1)
    click_post(hwnd, 746, 285); time.sleep(1)
    send_key(hwnd, 'Enter'); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    click_post(hwnd, 1222, 26); time.sleep(7)


def dat_hang(hwnd: int) -> None:
    """Đặt hàng task."""
    if not get_is_running():
        return
    logger.debug('Task: Dat hang')
    x = 704
    y_positions = [245, 302, 357, 418, 476]

    for y in y_positions:
        if not get_is_running():
            return
        click_post(hwnd, 1072, 614); time.sleep(1)
        click_post(hwnd, 1000, 541); time.sleep(1)
        click_post(hwnd, x, y); time.sleep(1)
        multi_click_post(hwnd, 501, 268, 10, 0.7)
        send_key(hwnd, 'Esc'); time.sleep(1)
        send_key(hwnd, 'Esc'); time.sleep(1)

    time.sleep(7)


def linh_the_bai(hwnd: int) -> None:
    """Linh thẻ bài task."""
    if not get_is_running():
        return
    logger.debug('Task: Linh the bai')
    click_post(hwnd, 728, 43); time.sleep(5)
    click_post(hwnd, 419, 524); time.sleep(1)
    click_post(hwnd, 400, 323); time.sleep(5)
    click_post(hwnd, 692, 559); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(7)


def cuong_hoa_tau_chien(hwnd: int) -> None:
    """Cường hoá tàu chiến task."""
    if not get_is_running():
        return
    logger.debug('Task: Cuong hoa tau chien')
    click_post(hwnd, 728, 43); time.sleep(5)
    multi_click_post(hwnd, 419, 524, 2, LOAD_SLEEP); time.sleep(5)
    click_post(hwnd, 332, 200); time.sleep(1)
    click_post(hwnd, 619, 560)
    time.sleep(5)
    multi_click_post(hwnd, 768, 340, 20); time.sleep(1)
    multi_click_post(hwnd, 768, 427, 20); time.sleep(1)
    multi_click_post(hwnd, 768, 515, 20); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(7)


def nhon_hop_qua(hwnd: int) -> None:
    """Nhộn hợp quả task."""
    if not get_is_running():
        return
    logger.debug('Task: Nhon hop qua')
    click_post(hwnd, 61, 365); time.sleep(5)

    # Hop 1-4
    hop_x_positions = [393, 507, 619, 742]
    for hx in hop_x_positions:
        if not get_is_running():
            return
        click_post(hwnd, hx, 176); time.sleep(1)
        click_post(hwnd, 630, 460); time.sleep(1)

    send_key(hwnd, 'Esc'); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(7)


# ==================== Support Functions ====================


def _support_all_blue(hwnd: int, x: int, y: int) -> None:
    """Support function for All Blue task."""
    if not get_is_running():
        return
    time.sleep(1)
    click_post(hwnd, x, y); time.sleep(1)
    for _ in range(10):
        if not get_is_running():
            return
        click_post(hwnd, x, y); time.sleep(0.5)
        send_key(hwnd, 'Esc')


def _support_vung_bien_than_bi(hwnd: int) -> None:
    """Support function for Vùng biển thần bí task."""
    click_post(hwnd, 563, 583)
    _support_tra_loi_vbtb(hwnd)
    time.sleep(0.5)


def _support_tra_loi_vbtb(hwnd: int) -> None:
    """Support function for answering VBTB questions."""
    time.sleep(0.2)
    click_post(hwnd, 524, 332); time.sleep(0.1)
    click_post(hwnd, 860, 647); time.sleep(0.1)
    click_post(hwnd, 508, 345); time.sleep(0.1)
    click_post(hwnd, 543, 229)


def _support_nau_an(hwnd: int, x: int, y: int) -> None:
    """Support function for Nấu ăn task."""
    click_post(hwnd, 33, 225); time.sleep(5)
    click_post(hwnd, x, y); time.sleep(1)
    multi_click_post(hwnd, 581, 449, 10); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)
    send_key(hwnd, 'Esc'); time.sleep(1)


# ==================== Feature Entry Point ====================


def feature_daily(status_callback=None) -> bool:
    """
    Feature: Daily tasks - runs all daily tasks for all game windows in parallel.

    Uses worker pool for multi-threading and progress persistence for resume capability.
    """
    with LogContext(logger, 'feature_daily'):
        if status_callback:
            status_callback('Tính năng đang chạy: Daily')

        resize_all_games()
        hwnds = get_game_windows()
        if not hwnds:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False

        set_running('Daily', None, status_callback)
        logger.info(f'Starting daily tasks for {len(hwnds)} windows')

        try:
            pool = WorkerPool('Daily', status_callback)
            results = pool.run(_run_daily_single, hwnds)

            success_count = sum(1 for r in results if r.success)
            logger.info(f'Daily completed: {success_count}/{len(results)} windows')
        except Exception as e:
            logger.error(f'Daily error: {e}')
        finally:
            state_stop()

        logger.info('Feature daily completed')
        return True


def stop():
    """Stop the running feature."""
    state_stop()
    logger.info('Feature stop requested')
