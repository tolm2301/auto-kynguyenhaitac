---
name: python-packaging
description: Python packaging with pyproject.toml, dependencies, virtual environments, and distribution
license: MIT
compatibility: opencode
---

## What I do
- Configure `pyproject.toml` with proper build systems
- Set up virtual environments and dependency management
- Create proper package structure with `__init__.py`
- Configure linting (ruff, black, mypy) and pre-commit hooks

## pyproject.toml template
```toml
[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "automation-tool"
version = "1.0.0"
description = "Windows automation toolkit"
requires-python = ">=3.11"
dependencies = [
    "pywin32>=306",
    "Pillow>=10.0",
    "pytesseract>=0.3.10",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0",
    "pytest-cov>=4.0",
    "ruff>=0.1.0",
    "mypy>=1.0",
]

[tool.ruff]
target-version = "py311"
line-length = 100

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
```

## When to use me
Use this when setting up a new Python project, adding dependencies, or preparing for distribution.
