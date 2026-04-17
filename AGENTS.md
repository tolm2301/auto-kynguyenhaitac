# Python Automation Project

This is a Windows automation project migrated from AutoHotkey2 to Python.

## Project Structure
- `main.py` - Entry point
- `gui/` - GUI components (tkinter/PyQt)
- `features/` - Automation feature modules
- `utils/` - Shared utilities (OCR, logging, Win32 helpers)
- `lib/` - Third-party wrappers and adapters
- `resources/` - Config files, images, templates
- `tests/` - pytest test suite

## Code Standards
- Python 3.11+ with type hints on all public functions
- PEP 8 naming: classes PascalCase, functions/variables snake_case, constants UPPER_SNAKE_CASE
- Use dataclasses or Pydantic for config objects
- Structured returns: `{"ok": bool, "data": Any, "err": Optional[str]}`
- All automation flows must have retry, timeout, and logging

## Automation Principles
1. Prefer API/control automation over pixel-based interaction
2. Write modular code: feature -> utils/lib -> entry point
3. Every automation flow needs retry, timeout, and logging
4. Reduce hard-coding: extract coordinates, titles, paths into config objects
5. When interacting with windows: verify hwnd/pid/title before sending input
6. When using OCR/ImageSearch: always normalize text and provide multiple fallbacks

## Available Skills
- `@python-testing` - pytest patterns, fixtures, mocking
- `@python-packaging` - pyproject.toml, dependencies, virtualenv
- `@python-debugging` - logging, retry, timeout, error handling
- `@python-automation` - pywin32, DllCall, OCR, ImageSearch, GUI control

## Commands
- Run: `python main.py`
- Test: `pytest`
- Lint: `ruff check .`
- Format: `ruff format .`
- Type check: `mypy .`
