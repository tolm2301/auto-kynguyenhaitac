---
name: python-debugging
description: Debug and stability patterns for Python - logging, retry, timeout, and error handling
license: MIT
compatibility: opencode
---

## What I do
- Set up structured logging with timestamps and levels
- Implement retry patterns with exponential backoff
- Add timeout guards for blocking operations
- Provide debug checklist for automation failures

## Logging pattern
```python
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

def setup_logging(log_file: str = "logs/automation.log"):
    logging.basicConfig(
        level=logging.INFO,
        format="[%(asctime)s] [%(levelname)s] %(message)s",
        handlers=[
            logging.FileHandler(log_file, encoding="utf-8"),
            logging.StreamHandler(),
        ],
    )
```

## Retry pattern
```python
import time
from typing import Callable, Any

def retry(
    action_fn: Callable[[], Any],
    max_tries: int = 3,
    delay_ms: int = 500,
    backoff: float = 1.5,
) -> Any:
    delay = delay_ms / 1000
    for attempt in range(max_tries):
        try:
            result = action_fn()
            return result
        except Exception as err:
            logger.warning(f"Retry {attempt + 1} error: {err}")
            if attempt < max_tries - 1:
                time.sleep(delay)
                delay *= backoff
    raise RuntimeError(f"Failed after {max_tries} attempts")
```

## Timeout guard
```python
import time
from typing import Callable

def wait_until(
    predicate_fn: Callable[[], bool],
    timeout_ms: int = 3000,
    tick_ms: int = 100,
) -> bool:
    start = time.time()
    timeout = timeout_ms / 1000
    tick = tick_ms / 1000
    while time.time() - start < timeout:
        if predicate_fn():
            return True
        time.sleep(tick)
    return False
```

## Debug checklist
1. Verify CoordMode/screen region before click/search operations
2. Log all important input variables (region, image path, window title)
3. Record fail point: which step, which retry attempt
4. Catch exceptions at entry functions to prevent full app crash
5. When errors are hard to reproduce: screenshot + timestamp log

## When to use me
Use this when debugging automation issues, adding logging, or improving stability of existing code.
