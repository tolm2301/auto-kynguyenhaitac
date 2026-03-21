import os
import re
import time
import threading
import tkinter as tk
from tkinter import messagebox
from typing import Optional, Tuple, Dict
import numpy as np

from utils import get_logger, OCRReader, screenshot_region
from rapidfuzz import fuzz, process

logger = get_logger()

is_running = False
_current_question = None
_ocr_reader: Optional[OCRReader] = None


def feature_hoidapcothuong(status_callback=None) -> bool:
    """
    Feature: Hỏi đáp có thưởng (Q&A with rewards)
    Uses OCR to capture question and fuzzy search for answer.
    """
    global is_running, _current_question, _ocr_reader
    
    with LogContext(logger, 'feature_hoidapcothuong'):
        if status_callback:
            status_callback('Tính năng đang chạy: Hỏi đáp có thưởng')
        
        if _ocr_reader is None:
            logger.info('Initializing OCR reader (this may take a moment)...')
            try:
                _ocr_reader = OCRReader(languages=['vi', 'en'], gpu=True)
            except Exception as e:
                logger.error(f'Failed to initialize OCR: {e}')
                return False
        
        is_running = True
        
        selection = _select_region()
        if not selection:
            logger.info('No region selected')
            return False
        
        x, y, w, h = selection
        
        logger.info(f'Capturing region: ({x}, {y}, {w}, {h})')
        
        img = screenshot_region(x, y, w, h)
        
        logger.debug(f'Screenshot captured: shape={img.shape if img is not None else None}')
        
        text = _ocr_reader.read_text(img)
        
        if not text:
            logger.warning('No text detected in region')
            return False
        
        full_text = ' '.join([item[1] if isinstance(item, tuple) else str(item) 
                              for item in text])
        
        full_text = re.sub(r'\s+', ' ', full_text).strip()
        
        logger.info(f'OCR Result: {full_text[:200]}...')
        
        ini_path = _get_question_ini_path()
        result = _find_fuzzy_match(ini_path, full_text, threshold=0.7)
        
        if result and result['score'] > 0:
            logger.info(f'Found answer: {result["answer"]} (score: {result["score"]:.2f})')
            messagebox.showinfo(
                'KẾT QUẢ',
                f'CÂU HỎI: {result["question"]}\n\nĐÁP ÁN: {result["answer"]}'
            )
        else:
            logger.info('No matching answer found')
            messagebox.showinfo(
                'THÔNG BÁO',
                f'CÂU HỎI: {full_text}\n\nĐÁP ÁN: CHƯA CÓ TRONG DATA (Độ giống < 40%)'
            )
        
        return True


def _select_region() -> Optional[Tuple[int, int, int, int]]:
    """Let user select a screen region using mouse drag."""
    root = tk.Tk()
    root.withdraw()
    
    selection = {'start': None, 'end': None, 'rect': None}
    
    def on_mouse_down(event):
        selection['start'] = (event.x, event.y)
        selection['rect'] = canvas.create_rectangle(
            event.x, event.y, event.x+1, event.y+1, outline='red', width=2
        )
    
    def on_mouse_move(event):
        if selection['start'] and selection['rect']:
            canvas.coords(
                selection['rect'],
                selection['start'][0], selection['start'][1],
                event.x, event.y
            )
    
    def on_mouse_up(event):
        selection['end'] = (event.x, event.y)
        root.quit()
    
    screen_width = root.winfo_screenwidth()
    screen_height = root.winfo_screenheight()
    
    overlay = tk.Toplevel(root)
    overlay.attributes('-fullscreen', True)
    overlay.attributes('-alpha', 0.3)
    overlay.attributes('-topmost', True)
    overlay.configure(bg='gray')
    
    canvas = tk.Canvas(overlay, width=screen_width, height=screen_height, bg='gray', cursor='cross')
    canvas.pack()
    
    canvas.bind('<Button-1>', on_mouse_down)
    canvas.bind('<B1-Motion>', on_mouse_move)
    canvas.bind('<ButtonRelease-1>', on_mouse_up)
    
    overlay.focus_force()
    root.mainloop()
    root.destroy()
    
    if not selection['start'] or not selection['end']:
        return None
    
    x1, y1 = selection['start']
    x2, y2 = selection['end']
    
    x = min(x1, x2)
    y = min(y1, y2)
    w = abs(x2 - x1)
    h = abs(y2 - y1)
    
    if w < 5 or h < 5:
        return None
    
    return (x, y, w, h)


def _get_question_ini_path() -> str:
    """Get path to question database."""
    script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(script_dir, 'resources', 'Question.ini')


def _find_fuzzy_match(ini_path: str, search_text: str, threshold: float = 0.4) -> Optional[Dict]:
    """
    Find fuzzy match in question database.
    
    Args:
        ini_path: Path to Question.ini file
        search_text: Text to search for
        threshold: Minimum similarity score (0-1)
        
    Returns:
        Dict with question, answer, and score or None
    """
    if not os.path.exists(ini_path):
        logger.warning(f'Question database not found: {ini_path}')
        return None
    
    search_text_lower = search_text.lower().strip()
    search_text_no_accent = _remove_vietnamese_accents(search_text_lower)
    
    best_match = None
    best_score = 0
    
    try:
        with open(ini_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#') or line.startswith(';'):
                    continue
                
                if '=' not in line:
                    continue
                
                question, answer = line.split('=', 1)
                question = question.strip()
                answer = answer.strip()
                
                question_lower = question.lower()
                question_no_accent = _remove_vietnamese_accents(question_lower)
                
                score = fuzz.ratio(search_text_no_accent, question_no_accent) / 100.0
                
                if score > best_score:
                    best_score = score
                    best_match = {
                        'question': question,
                        'answer': answer,
                        'score': score
                    }
                
    except Exception as e:
        logger.error(f'Lỗi đọc file question: {e}')
        return None
    
    if best_score >= threshold:
        return best_match
    
    return None


def _remove_vietnamese_accents(text: str) -> str:
    """Remove Vietnamese diacritical marks."""
    vietnamese_chars = {
        'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
        'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
        'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
        'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
        'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
        'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
        'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
        'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
        'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
        'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
        'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
        'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
        'đ': 'd',
        'Á': 'A', 'À': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A',
        'Ắ': 'A', 'Ằ': 'A', 'Ẳ': 'A', 'Ẵ': 'A', 'Ặ': 'A',
        'Ấ': 'A', 'Ầ': 'A', 'Ẩ': 'A', 'Ẫ': 'A', 'Ậ': 'A',
        'É': 'E', 'È': 'E', 'Ẻ': 'E', 'Ẽ': 'E', 'Ẹ': 'E',
        'Ế': 'E', 'Ề': 'E', 'Ể': 'E', 'Ễ': 'E', 'Ệ': 'E',
        'Í': 'I', 'Ì': 'I', 'Ỉ': 'I', 'Ĩ': 'I', 'Ị': 'I',
        'Ó': 'O', 'Ò': 'O', 'Ỏ': 'O', 'Õ': 'O', 'Ọ': 'O',
        'Ố': 'O', 'Ồ': 'O', 'Ổ': 'O', 'Ỗ': 'O', 'Ộ': 'O',
        'Ớ': 'O', 'Ờ': 'O', 'Ở': 'O', 'Ỡ': 'O', 'Ợ': 'O',
        'Ú': 'U', 'Ù': 'U', 'Ủ': 'U', 'Ũ': 'U', 'Ụ': 'U',
        'Ứ': 'U', 'Ừ': 'U', 'Ử': 'U', 'Ữ': 'U', 'Ự': 'U',
        'Ý': 'Y', 'Ỳ': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y', 'Ỵ': 'Y',
        'Đ': 'D',
    }
    
    result = []
    for char in text:
        result.append(vietnamese_chars.get(char, char))
    
    return ''.join(result)


class LogContext:
    """Context manager for logging."""
    def __init__(self, logger, operation, **kwargs):
        self.logger = logger
        self.operation = operation
        self.kwargs = kwargs
        self.start_time = None
    
    def __enter__(self):
        self.start_time = time.time()
        context = ' | '.join(f'{k}={v}' for k, v in self.kwargs.items())
        self.logger.info(f'START | {self.operation} | {context}')
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        duration = time.time() - self.start_time
        if exc_type:
            self.logger.error(f'ERROR | {self.operation} | {exc_type.__name__}: {exc_val}')
        else:
            self.logger.info(f'END | {self.operation} | Duration: {duration:.3f}s')
        return False


def stop():
    """Stop the running feature."""
    global is_running
    is_running = False
    logger.info('Feature stop requested')
