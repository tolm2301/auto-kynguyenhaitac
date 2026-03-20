#!/usr/bin/env python3
"""
Auto VHT - Kỷ Nguyên Hải Tặc Automation Tool

A Python automation tool for the game "Kỷ Nguyên Hải Tặc" (Pirate Era).
Provides various features for auto-playing the game.

Requirements:
    pip install -r requirements.txt

Usage:
    python main.py

Features:
    - Cường hoá (Enhancement)
    - Ra khơi (Going out to sea)
    - Daily tasks
    - Ảnh hồn (Soul Image)
    - Boss automation (Rồng Punk, Kraken)
    - Hỏi đáp có thưởng (Q&A with rewards) using EasyOCR for Vietnamese OCR
    - And more...

Author: Auto Kynguyenhaitac
Version: 2.0.0 (Python rewrite)
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from utils import setup_logger
from gui import MainWindow


def main():
    """Main entry point for Auto VHT."""
    logger = setup_logger('main')
    logger.info('=' * 50)
    logger.info('Auto VHT - Kỷ Nguyên Hải Tặc')
    logger.info('Version: 2.0.0 (Python)')
    logger.info('=' * 50)
    
    try:
        app = MainWindow()
        app.run()
    except KeyboardInterrupt:
        logger.info('Interrupted by user')
        sys.exit(0)
    except Exception as e:
        logger.error(f'Unhandled exception: {e}', exc_info=True)
        sys.exit(1)
    
    logger.info('Application exited normally')


if __name__ == '__main__':
    main()
