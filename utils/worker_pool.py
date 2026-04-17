"""
Worker pool module for running features across multiple game windows in parallel.

Ported from AHK boss_worker.ahk and daily_worker.ahk patterns.
Uses threading to run features concurrently for each game window.
"""

import os
import time
import threading
import tempfile
from pathlib import Path
from typing import Callable, Optional
from dataclasses import dataclass, field

from utils import get_logger, get_game_windows, resize_all_games
from utils.state import get_is_running, stop as state_stop

logger = get_logger()

LOGS_DIR = Path(__file__).parent.parent / 'logs'


@dataclass
class WorkerResult:
    """Result from a worker thread."""
    hwnd: int
    success: bool
    error: Optional[str] = None


class WorkerPool:
    """Manages parallel execution of features across multiple game windows."""

    def __init__(self, feature_name: str, status_callback=None):
        self.feature_name = feature_name
        self.status_callback = status_callback
        self.threads: list[threading.Thread] = []
        self.results: list[WorkerResult] = []
        self.results_lock = threading.Lock()
        self.stop_flag = threading.Event()
        self.stop_file: Optional[str] = None

    def _build_stop_file(self) -> str:
        """Create a unique stop flag file path."""
        LOGS_DIR.mkdir(parents=True, exist_ok=True)
        timestamp = time.time()
        tick = int(time.monotonic() * 1000)
        self.stop_file = str(LOGS_DIR / f"worker_stop_{timestamp}_{tick}.flag")
        return self.stop_file

    def _should_continue(self) -> bool:
        """Check if workers should continue running."""
        if not get_is_running():
            return False
        if self.stop_file and Path(self.stop_file).exists():
            return False
        return not self.stop_flag.is_set()

    def _signal_stop(self) -> None:
        """Signal all workers to stop."""
        self.stop_flag.set()
        if self.stop_file:
            try:
                Path(self.stop_file).touch()
            except Exception as e:
                logger.error(f"Error creating stop file: {e}")

    def _run_worker(self, hwnd: int, worker_func: Callable[[int], None]) -> None:
        """Run a single worker for one game window."""
        try:
            logger.info(f"Worker started for hwnd={hwnd}")
            worker_func(hwnd)
            with self.results_lock:
                self.results.append(WorkerResult(hwnd=hwnd, success=True))
            logger.info(f"Worker completed for hwnd={hwnd}")
        except Exception as e:
            logger.error(f"Worker failed for hwnd={hwnd}: {e}")
            with self.results_lock:
                self.results.append(WorkerResult(hwnd=hwnd, success=False, error=str(e)))

    def run(self, worker_func: Callable[[int], None], hwnds: list[int] = None) -> list[WorkerResult]:
        """
        Run worker_func for each game window in parallel.

        Args:
            worker_func: Function that takes hwnd and performs the feature
            hwnds: List of window handles (auto-detected if None)

        Returns:
            List of WorkerResult objects
        """
        if hwnds is None:
            resize_all_games()
            hwnds = get_game_windows()

        if not hwnds:
            logger.error("No game windows found")
            return []

        self._build_stop_file()
        self.results = []
        self.threads = []

        logger.info(f"Starting {self.feature_name} for {len(hwnds)} windows")

        for hwnd in hwnds:
            t = threading.Thread(
                target=self._run_worker,
                args=(hwnd, worker_func),
                daemon=True,
                name=f"{self.feature_name}-worker-{hwnd}"
            )
            self.threads.append(t)
            t.start()

        # Wait for all workers to complete
        self._wait_for_workers()

        # Cleanup stop file
        if self.stop_file and Path(self.stop_file).exists():
            try:
                Path(self.stop_file).unlink()
            except Exception:
                pass

        logger.info(f"All workers completed for {self.feature_name}")
        return self.results

    def _wait_for_workers(self) -> None:
        """Wait for all worker threads to finish, with stop support."""
        while True:
            alive = any(t.is_alive() for t in self.threads)
            if not alive:
                break

            if not self._should_continue():
                self._signal_stop()
                # Give threads a moment to notice the stop flag
                time.sleep(0.5)
                break

            time.sleep(0.5)

        # Join all threads
        for t in self.threads:
            t.join(timeout=5.0)

    def stop(self) -> None:
        """Stop all workers."""
        self._signal_stop()


def run_parallel(feature_name: str, worker_func: Callable[[int], None],
                 hwnds: list[int] = None, status_callback=None) -> list[WorkerResult]:
    """
    Convenience function to run a feature in parallel across all game windows.

    Args:
        feature_name: Name of the feature (for logging)
        worker_func: Function(hwnd) to run for each window
        hwnds: List of window handles (auto-detected if None)
        status_callback: Optional callback for status updates

    Returns:
        List of WorkerResult objects
    """
    pool = WorkerPool(feature_name, status_callback)
    return pool.run(worker_func, hwnds)
