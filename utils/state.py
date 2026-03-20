"""
Global state manager for controlling feature execution.
"""

import threading
from typing import Optional, Callable

_state_lock = threading.Lock()
_is_running = False
_current_feature: Optional[str] = None
_current_thread: Optional[threading.Thread] = None
_status_callback: Optional[Callable] = None


def get_is_running() -> bool:
    """Check if any feature is currently running."""
    with _state_lock:
        return _is_running


def set_running(feature_name: str, thread=None, callback: Optional[Callable] = None):
    """Mark feature as running."""
    global _is_running, _current_feature, _current_thread, _status_callback
    with _state_lock:
        _is_running = True
        _current_feature = feature_name
        _current_thread = thread
        _status_callback = callback


def stop():
    """Stop the currently running feature."""
    global _is_running, _current_feature, _current_thread, _status_callback
    with _state_lock:
        _is_running = False
        _current_feature = None
        
        if _status_callback:
            _status_callback('Tính năng đang chạy: Chưa có')
        
        thread_to_stop = _current_thread
        _current_thread = None
        _status_callback = None
    
    if thread_to_stop and thread_to_stop.is_alive():
        pass
    
    return True


def get_current_feature() -> Optional[str]:
    """Get name of currently running feature."""
    with _state_lock:
        return _current_feature


def is_running() -> bool:
    """Check if feature is running (alias for get_is_running)."""
    return get_is_running()
