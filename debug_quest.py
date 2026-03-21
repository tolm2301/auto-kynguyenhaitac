#!/usr/bin/env python3
"""Debug script for Quest OCR testing"""

from utils import get_game_window
from utils.ocr import screenshot_region, screenshot_window, OCRReader

def test_quest_regions():
    hwnd = get_game_window()
    if not hwnd:
        print('Game not found!')
        return
    
    print('Initializing OCR...')
    ocr = OCRReader(languages=['vi', 'en'])
    
    # Full screen
    print('\n=== FULL SCREEN ===')
    img = screenshot_window(hwnd)
    if img is not None:
        results = ocr.read_text(img)
        for item in results:
            if isinstance(item, tuple) and len(item) >= 3:
                bbox, text, conf = item[0], item[1], item[2]
                if conf > 0.3 and len(text.strip()) > 1:
                    # Check for keywords
                    keyword_match = ''
                    text_lower = text.lower()
                    keywords = ['đi tìm', 'đi đến', 'nói chuyện', 'tiêu diệt', 'hoàn thành', 'tiếp theo']
                    for kw in keywords:
                        if kw in text_lower:
                            keyword_match = f' [MATCH: {kw}]'
                            break
                    print(f'[{conf:.2f}] {text}{keyword_match}')
    
    # Quest Panel
    QUEST_PANEL_X = 1085
    QUEST_PANEL_Y = 206
    QUEST_PANEL_W = 169
    QUEST_PANEL_H = 200
    
    print(f'\n=== QUEST PANEL ({QUEST_PANEL_X},{QUEST_PANEL_Y},{QUEST_PANEL_W},{QUEST_PANEL_H}) ===')
    img = screenshot_region(QUEST_PANEL_X, QUEST_PANEL_Y, QUEST_PANEL_W, QUEST_PANEL_H, hwnd)
    if img is not None:
        results = ocr.read_text(img)
        for item in results:
            if isinstance(item, tuple) and len(item) >= 3:
                bbox, text, conf = item[0], item[1], item[2]
                if conf > 0.2 and len(text.strip()) > 0:
                    print(f'[{conf:.2f}] {text}')
    
    # Dialog
    DIALOG_X = 250
    DIALOG_Y = 152
    DIALOG_W = 427
    DIALOG_H = 234
    
    print(f'\n=== DIALOG ({DIALOG_X},{DIALOG_Y},{DIALOG_W},{DIALOG_H}) ===')
    img = screenshot_region(DIALOG_X, DIALOG_Y, DIALOG_W, DIALOG_H, hwnd)
    if img is not None:
        results = ocr.read_text(img)
        for item in results:
            if isinstance(item, tuple) and len(item) >= 3:
                bbox, text, conf = item[0], item[1], item[2]
                if conf > 0.2 and len(text.strip()) > 0:
                    print(f'[{conf:.2f}] {text}')
    
    # Skip Dialog
    DIALOG_SKIP_X = 895
    DIALOG_SKIP_Y = 631
    DIALOG_SKIP_W = 208
    DIALOG_SKIP_H = 48
    
    print(f'\n=== SKIP DIALOG ({DIALOG_SKIP_X},{DIALOG_SKIP_Y},{DIALOG_SKIP_W},{DIALOG_SKIP_H}) ===')
    img = screenshot_region(DIALOG_SKIP_X, DIALOG_SKIP_Y, DIALOG_SKIP_W, DIALOG_SKIP_H, hwnd)
    if img is not None:
        results = ocr.read_text(img)
        for item in results:
            if isinstance(item, tuple) and len(item) >= 3:
                bbox, text, conf = item[0], item[1], item[2]
                if conf > 0.2 and len(text.strip()) > 0:
                    print(f'[{conf:.2f}] {text}')
    
    print('\n=== TEST COMPLETE ===')

if __name__ == '__main__':
    test_quest_regions()
