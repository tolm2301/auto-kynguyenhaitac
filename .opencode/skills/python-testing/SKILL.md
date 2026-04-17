---
name: python-testing
description: Python testing patterns with pytest, fixtures, mocking, and coverage best practices
license: MIT
compatibility: opencode
---

## What I do
- Set up pytest with proper fixtures and parametrization
- Mock external dependencies and Windows APIs
- Write integration tests for automation flows
- Configure coverage thresholds and reports

## Testing patterns

### Basic test structure
```python
import pytest
from unittest.mock import patch, MagicMock

class TestFeature:
    @pytest.fixture
    def config(self):
        return {"timeout": 3000, "retries": 3}

    def test_success_case(self, config):
        result = run_feature(config)
        assert result["ok"] is True
        assert result["data"] is not None

    @patch("utils.ocr.read_text")
    def test_ocr_failure(self, mock_ocr):
        mock_ocr.return_value = None
        result = run_feature({})
        assert result["ok"] is False
```

### Parametrized tests
```python
@pytest.mark.parametrize("input_text,expected", [
    ("  hello  ", "hello"),
    ("HELLO", "hello"),
    ("", ""),
])
def test_normalize_text(input_text, expected):
    assert normalize_text(input_text) == expected
```

## When to use me
Use this when writing or reviewing tests for Python automation code.
