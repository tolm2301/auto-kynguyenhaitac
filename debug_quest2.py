#!/usr/bin/env python3
"""Debug Quest OCR"""

from utils import get_game_window
from utils.ocr import screenshot_region, screenshot_window, OCRReader
from features.questing import (
    QUEST_PANEL_X, QUEST_PANEL_Y, QUEST_PANEL_W, QUEST_PANEL_H,
    DIALOG_X, DIALOG_Y, DIALOG_W, DIALOG_H,
    normalize_text, fuzzy_match, QUEST_KEYWORDS, DIALOG_SKIP_KEYWORDS
)

def main():
    hwnd = get_game_window()
    if not hwnd:
        print('Game not found!')
        return
    
    print('Initializing OCR...')
    ocr = OCRReader(languages=['vi', 'en'])
    
    print('\n=== TESTING NORMALIZE & FUZZY ===')
    test_texts = ['đi tìm', 'tim', 'di tim', 'hoàn thành', 'hoan thanh', 'click bất kỳ']
    for t in test_texts:
        result = fuzzy_match(t, QUEST_KEYWORDS)
        print(f'fuzzy_match("{t}"): {result}')
    
    print('\n=== QUEST PANEL OCR ===')
    img = screenshot_region(QUEST_PANEL_X, QUEST_PANEL_Y, QUEST_PANEL_W, QUEST_PANEL_H, hwnd)
    if img is not None:
        results = ocr.read_text(img)
        print(f'Found {len(results)} regions:')
        for item in results:
            if isinstance(item, tuple) and len(item) >= 3:
                bbox, text, conf = item[0], item[1], item[2]
                match = fuzzy_match(text, QUEST_KEYWORDS)
                status = f'-> MATCH: {match}' if match else ''
                print(f'  [{conf:.2f}] "{text}" {status}')
    else:
        print('Failed to capture!')
    
    print('\n=== DIALOG OCR ===')
    img = screenshot_region(DIALOG_X, DIALOG_Y, DIALOG_W, DIALOG_H, hwnd)
    if img is not None:
        results = ocr.read_text(img)
        print(f'Found {len(results)} regions:')
        for item in results:
            if isinstance(item, tuple) and len(item) >= 3:
                bbox, text, conf = item[0], item[1], item[2]
                match = fuzzy_match(text, DIALOG_SKIP_KEYWORDS)
                status = f'-> MATCH: {match}' if match else ''
                print(f'  [{conf:.2f}] "{text}" {status}')
    else:
        print('Failed to capture!')
    
    print('\n=== TEST COMPLETE ===')

if __name__ == '__main__':
    main()
