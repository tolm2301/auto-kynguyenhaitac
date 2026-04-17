"""
Activity scheduler module - automatically runs features based on events.ini schedule.

Ported from AHK utils/scheduler.ahk
"""

import os
import time
import threading
import configparser
from datetime import datetime
from pathlib import Path
from typing import Optional, Any
from dataclasses import dataclass, field

from utils import get_logger, get_hour, get_minute
from utils.state import get_is_running, set_running, stop as state_stop

logger = get_logger()

# Paths
RESOURCES_DIR = Path(__file__).parent.parent / 'resources'
LOGS_DIR = Path(__file__).parent.parent / 'logs'
EVENTS_INI = RESOURCES_DIR / 'events.ini'

# Scheduler state
_scheduler_enabled = False
_scheduler_busy = False
_scheduler_lock = threading.Lock()
_activity_executed_map: dict[str, str] = {}
_scheduler_state_loaded_date = ""
_scheduler_timer: Optional[threading.Timer] = None
_status_callback = None
_count = 1


@dataclass
class ScheduledEvent:
    """Represents a scheduled event."""
    name: str
    days: list[int]
    hour: int
    minute: int
    run_key: str = ""


def _get_weekday() -> int:
    """Get current weekday (1=Monday, 7=Sunday) matching AHK convention.
    
    AHK: A_WDay is 1=Sunday, 2=Monday, ... 7=Saturday
    We convert: Mod(A_WDay, 7) -> 1=Monday, ..., 6=Saturday, 7=Sunday
    """
    # Python: Monday=0, Sunday=6
    py_wday = datetime.now().weekday()  # 0=Monday
    return py_wday + 1  # 1=Monday, 7=Sunday


def _scheduler_get_state_path(date: str = "") -> Path:
    """Get path to scheduler state file."""
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    d = date if date else datetime.now().strftime("%Y%m%d")
    return LOGS_DIR / f"scheduler_state_{d}.txt"


def _scheduler_load_executed_state() -> None:
    """Load executed state from file for today."""
    global _scheduler_state_loaded_date, _activity_executed_map

    today = datetime.now().strftime("%Y%m%d")
    if _scheduler_state_loaded_date == today:
        return

    _activity_executed_map = {}
    state_path = _scheduler_get_state_path(today)

    if state_path.exists():
        try:
            with open(state_path, 'r', encoding='utf-8') as f:
                for line in f:
                    key = line.strip()
                    if key:
                        _activity_executed_map[key] = "persisted"
        except Exception as e:
            logger.error(f"Error loading scheduler state: {e}")

    _scheduler_state_loaded_date = today


def _scheduler_append_executed_state(run_key: str) -> None:
    """Append executed state to file."""
    state_path = _scheduler_get_state_path()
    try:
        with open(state_path, 'a', encoding='utf-8') as f:
            f.write(f"{run_key}\n")
    except Exception as e:
        logger.error(f"Error appending scheduler state: {e}")


def _scheduler_mark_executed(run_key: str, status: str) -> None:
    """Mark an event as executed with given status."""
    global _activity_executed_map

    first_seen = run_key not in _activity_executed_map
    _activity_executed_map[run_key] = status
    if first_seen:
        _scheduler_append_executed_state(run_key)


def _scheduler_log(msg: str) -> None:
    """Write to scheduler log file."""
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    log_path = LOGS_DIR / "scheduler.log"
    today = datetime.now().strftime("%Y-%m-%d")

    try:
        # Check if we need to rotate the log
        if log_path.exists():
            with open(log_path, 'r', encoding='utf-8') as f:
                first_line = f.readline().strip()
            if first_line:
                import re
                match = re.match(r"\[(\d{4}-\d{2}-\d{2})", first_line)
                if match and match.group(1) != today:
                    log_path.unlink()
    except Exception:
        pass

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try:
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(f"[{timestamp}] {msg}\n")
    except Exception as e:
        logger.error(f"Error writing scheduler log: {e}")


def _is_supported_event(event_name: str) -> bool:
    """Check if event name is supported by scheduler."""
    supported = {
        "Rồng Punk", "Kraken", "Kaido", "Daily", "Tầm bảo chiến",
        "Cường Hoá", "Ra Khơi", "Năm Mới Phát Tài", "Ảnh hồn",
        "Tấn công hải quân", "Hỏi đáp có thưởng", "Register Uta World",
        "Hải tặc thông thái",
    }
    return event_name in supported


def _parse_events_ini() -> list[ScheduledEvent]:
    """Parse events.ini and return list of ScheduledEvent objects."""
    events = []

    if not EVENTS_INI.exists():
        logger.warning(f"Events file not found: {EVENTS_INI}")
        return events

    try:
        config = configparser.ConfigParser()
        config.read(EVENTS_INI, encoding='utf-8')

        if 'Events' not in config:
            logger.warning("No [Events] section in events.ini")
            return events

        for event_name, value in config['Events'].items():
            parts = value.split('|')
            if len(parts) < 2:
                continue

            days_str = parts[0].strip()
            time_str = parts[1].strip()

            days = [int(d.strip()) for d in days_str.split(',')]
            time_parts = time_str.split(':')
            if len(time_parts) < 2:
                continue

            hour = int(time_parts[0].strip())
            minute = int(time_parts[1].strip())

            events.append(ScheduledEvent(
                name=event_name,
                days=days,
                hour=hour,
                minute=minute,
            ))
    except Exception as e:
        logger.error(f"Error parsing events.ini: {e}")

    return events


def _scheduler_get_due_event() -> Optional[ScheduledEvent]:
    """Get the next due event that should be executed."""
    global _activity_executed_map

    current_day = _get_weekday()
    now_minutes = get_hour() * 60 + get_minute()

    events = _parse_events_ini()
    due_event = None
    due_minutes = -1

    for event in events:
        if not _is_supported_event(event.name):
            continue

        # Check if event is scheduled for today
        if current_day not in event.days:
            continue

        event_total_minutes = event.hour * 60 + event.minute

        # Event must be due (not in the future, and within 1 minute window)
        if event_total_minutes > now_minutes:
            continue
        if (now_minutes - event_total_minutes) > 1:
            continue

        # Check if already executed today
        run_key = f"{datetime.now().strftime('%Y%m%d')}|{event.name}|{event.hour:02d}:{event.minute:02d}"
        if run_key in _activity_executed_map:
            continue

        # Pick the latest due event (in case multiple are due)
        if event_total_minutes > due_minutes:
            due_minutes = event_total_minutes
            event.run_key = run_key
            due_event = event

    return due_event


def _scheduler_run_event(event_name: str) -> None:
    """Execute the feature corresponding to the event name."""
    global _count

    count = _count if _count > 0 else 1

    # Import features dynamically to avoid circular imports
    if event_name == "Rồng Punk":
        from features.boss import feature_punk
        feature_punk(status_callback=_status_callback)
    elif event_name == "Kraken":
        from features.boss import feature_kraken
        feature_kraken(status_callback=_status_callback)
    elif event_name == "Kaido":
        from features.boss import feature_kaido
        feature_kaido(status_callback=_status_callback)
    elif event_name == "Daily":
        from features.daily import feature_daily
        feature_daily(status_callback=_status_callback)
    elif event_name == "Tầm bảo chiến":
        from features.tambaochien import feature_tam_bao_chien
        feature_tam_bao_chien(status_callback=_status_callback)
    elif event_name == "Cường Hoá":
        from features.enhance import feature_enhance
        feature_enhance(count, status_callback=_status_callback)
    elif event_name == "Ra Khơi":
        from features.rakhoi import feature_rakhoi
        feature_rakhoi(count, status_callback=_status_callback)
    elif event_name == "Năm Mới Phát Tài":
        from features.nammoiphattai import feature_nammoiphattai
        feature_nammoiphattai(count, status_callback=_status_callback)
    elif event_name == "Ảnh hồn":
        from features.anhhon import feature_anhhon
        feature_anhhon(count, status_callback=_status_callback)
    elif event_name == "Tấn công hải quân":
        from features.tanconghaiquan import feature_tanconghaiquan
        feature_tanconghaiquan(status_callback=_status_callback)
    elif event_name == "Hỏi đáp có thưởng":
        from features.hoidapcothuong import feature_hoidapcothuong
        feature_hoidapcothuong(status_callback=_status_callback)
    elif event_name == "Register Uta World":
        from features.register_event import feature_register_uta
        feature_register_uta(status_callback=_status_callback)
    elif event_name == "Hải tặc thông thái":
        from features.haitacthongthai import feature_haitacthongthai
        feature_haitacthongthai(status_callback=_status_callback)
    else:
        raise ValueError(f"Event chưa được map feature: {event_name}")


def _scheduler_execute_event(event: ScheduledEvent) -> None:
    """Execute a scheduled event."""
    global _status_callback

    _scheduler_mark_executed(event.run_key, "running")

    if _status_callback:
        _status_callback(f"Tính năng đang chạy (auto): {event.name}")

    _scheduler_log(f"Auto run: {event.name} at {event.hour:02d}:{event.minute:02d}")

    try:
        _scheduler_run_event(event.name)
        _scheduler_mark_executed(event.run_key, "done")
        _scheduler_log(f"Completed: {event.name}")
    except Exception as e:
        _scheduler_mark_executed(event.run_key, "failed")
        _scheduler_log(f"Failed: {event.name} - {e}")
    finally:
        # Reset running status
        if _status_callback:
            _status_callback("Tính năng đang chạy: Chưa có")


def _scheduler_tick() -> None:
    """Scheduler tick - check for due events."""
    global _scheduler_busy, _scheduler_timer

    with _scheduler_lock:
        if _scheduler_busy:
            return
        _scheduler_busy = True

    try:
        _scheduler_load_executed_state()
        event = _scheduler_get_due_event()
        if event:
            _scheduler_execute_event(event)
    except Exception as e:
        logger.error(f"Scheduler error: {e}")
        _scheduler_log(f"Scheduler error: {e}")
    finally:
        with _scheduler_lock:
            _scheduler_busy = False

    # Schedule next tick
    if _scheduler_enabled:
        _scheduler_timer = threading.Timer(5.0, _scheduler_tick)
        _scheduler_timer.daemon = True
        _scheduler_timer.start()


def start_scheduler(status_callback=None, count: int = 1) -> None:
    """Start the activity scheduler."""
    global _scheduler_enabled, _status_callback, _count

    if _scheduler_enabled:
        logger.warning("Scheduler already running")
        return

    _scheduler_enabled = True
    _status_callback = status_callback
    _count = count

    _scheduler_load_executed_state()
    _scheduler_log("Scheduler started")
    logger.info("Activity scheduler started")

    # Run first tick immediately
    _scheduler_tick()


def stop_scheduler() -> None:
    """Stop the activity scheduler."""
    global _scheduler_enabled, _scheduler_timer

    _scheduler_enabled = False

    if _scheduler_timer:
        _scheduler_timer.cancel()
        _scheduler_timer = None

    _scheduler_log("Scheduler stopped")
    logger.info("Activity scheduler stopped")


def get_next_event_text() -> str:
    """Get text describing the next scheduled event."""
    if not EVENTS_INI.exists():
        return "Sự kiện tiếp theo: Không có lịch"

    current_day = _get_weekday()
    current_hour = get_hour()
    current_minute = get_minute()

    if current_hour >= 22:
        return "Trạng thái: Kết thúc hoạt động"

    events = _parse_events_ini()
    event_list = []

    for event in events:
        if current_day in event.days:
            event_list.append(event)

    if not event_list:
        return "Sự kiện tiếp theo: Không có hôm nay"

    next_event = None
    min_diff = 999999

    for event in event_list:
        diff = (event.hour - current_hour) * 60 + (event.minute - current_minute)
        if 0 < diff < min_diff:
            min_diff = diff
            next_event = event

    if not next_event:
        return "Sự kiện tiếp theo: Không còn hôm nay"

    time_str = f"{next_event.hour:02d}:{next_event.minute:02d}"
    return f"Sự kiện tiếp theo: {next_event.name} - {time_str}"
