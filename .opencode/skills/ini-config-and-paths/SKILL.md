---
name: ini-config-and-paths
description: Manage INI configs, resource paths, and file layout for AHK2 projects
compatibility: opencode
metadata:
  domain: ahk2
  area: config
---

## What I do
- Store runtime values in INI
- Resolve relative and absolute paths cleanly
- Keep resource files in predictable locations

## Checklist
1. Normalize paths before use.
2. Avoid magic strings in features.
3. Keep config reads centralized.
