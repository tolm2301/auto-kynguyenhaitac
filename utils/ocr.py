"""
OCR module using EasyOCR for Vietnamese text recognition.

EasyOCR is recommended for Vietnamese OCR as it:
- Has built-in Vietnamese language support
- Handles Vietnamese diacritics well
- Supports both print and handwriting
- Is easy to use with Python

Alternative options:
1. pytesseract + Vietnamese tessdata - Requires Tesseract installation
2. Windows.Media.Ocr via win32com - Windows only, built-in Vietnamese support
3. Google Cloud Vision API - Requires API key
4. AWS Textract - Requires AWS credentials

EasyOCR is chosen for:
- Best Vietnamese support out of open-source options
- No external dependencies (except PyTorch)
- Works offline after model download
- Cross-platform support
"""

import os
import time
import numpy as np
from typing import Tuple, List, Optional, Dict
from pathlib import Path
from PIL import Image
import cv2

from .logger import get_logger

logger = get_logger()

try:
    import easyocr
    EASYOCR_AVAILABLE = True
except ImportError:
    EASYOCR_AVAILABLE = False
    logger.warning('EasyOCR not installed. Install with: pip install easyocr')


class OCRReader:
    """
    OCR Reader using EasyOCR for Vietnamese text recognition.
    
    Features:
    - Supports Vietnamese language (vi)
    - Supports English language (en)
    - Can detect text regions
    - Returns bounding boxes and text
    """
    
    _instance: Optional['OCRReader'] = None
    _reader: Optional['easyocr.Reader'] = None
    
    def __new__(cls, languages: List[str] = None, gpu: bool = True, verbose: bool = False):
        """Singleton pattern to reuse OCR model."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self, languages: List[str] = None, gpu: bool = True, verbose: bool = False):
        if self._initialized:
            return
            
        if not EASYOCR_AVAILABLE:
            raise RuntimeError('EasyOCR not installed. Run: pip install easyocr')
        
        if languages is None:
            languages = ['vi', 'en']
        
        self.languages = languages
        self.gpu = gpu
        self.verbose = verbose
        
        cache_dir = Path(__file__).parent.parent / 'models'
        cache_dir.mkdir(exist_ok=True)
        
        logger.info(f'Initializing EasyOCR with languages: {languages}')
        start_time = time.time()
        
        self._reader = easyocr.Reader(
            languages,
            gpu=gpu,
            verbose=verbose,
            model_storage_directory=str(cache_dir),
            download_enabled=True
        )
        
        elapsed = time.time() - start_time
        logger.info(f'EasyOCR initialized in {elapsed:.2f}s')
        self._initialized = True
    
    def read_text(self, image: np.ndarray, detail: int = 1) -> List:
        """
        Read text from image.
        
        Args:
            image: numpy array (BGR or RGB) or PIL Image
            detail: 0 = simple text, 1 = detailed with bounding boxes
            
        Returns:
            List of tuples: [(bbox, text, confidence), ...]
        """
        if isinstance(image, Image.Image):
            image = np.array(image)
        
        if len(image.shape) == 2:
            image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
        elif image.shape[2] == 4:
            image = cv2.cvtColor(image, cv2.COLOR_RGBA2RGB)
        elif image.shape[2] == 3:
            image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        logger.debug(f'Running OCR on image shape: {image.shape}')
        start_time = time.time()
        
        results = self._reader.readtext(image, detail=detail)
        
        elapsed = time.time() - start_time
        logger.debug(f'OCR completed in {elapsed:.2f}s, found {len(results)} text regions')
        
        return results
    
    def read_text_from_region(
        self, 
        x: int, 
        y: int, 
        width: int, 
        height: int,
        screenshot_func=None
    ) -> str:
        """
        Read text from screen region.
        
        Args:
            x, y: Top-left corner of region
            width, height: Region dimensions
            screenshot_func: Function to capture screenshot (default: uses PIL)
            
        Returns:
            Recognized text string
        """
        try:
            if screenshot_func is None:
                from PIL import ImageGrab
                bbox = (x, y, x + width, y + height)
                img = ImageGrab.grab(bbox=bbox)
            else:
                img = screenshot_func(x, y, width, height)
            
            results = self.read_text(img)
            
            if not results:
                return ''
            
            full_text = ' '.join([item[1] if isinstance(item, tuple) else str(item) 
                                  for item in results])
            
            logger.debug(f'Region OCR result: {full_text[:100]}...')
            return full_text
            
        except Exception as e:
            logger.error(f'Lỗi OCR region: {e}')
            return ''
    
    def find_text(
        self, 
        image: np.ndarray, 
        search_text: str, 
        confidence_threshold: float = 0.3
    ) -> List[Dict]:
        """
        Find all occurrences of text in image.
        
        Args:
            image: numpy array image
            search_text: Text to search for
            confidence_threshold: Minimum confidence score
            
        Returns:
            List of dicts with text, bbox, and confidence
        """
        results = self.read_text(image)
        
        found = []
        search_lower = search_text.lower().strip()
        
        for item in results:
            if not isinstance(item, tuple) or len(item) < 3:
                continue
                
            bbox, text, conf = item[0], item[1], item[2]
            
            if conf < confidence_threshold:
                continue
            
            text_clean = text.lower().strip()
            
            if search_lower in text_clean or text_clean in search_lower:
                found.append({
                    'text': text,
                    'bbox': bbox,
                    'confidence': conf
                })
                logger.debug(f'Found text "{text}" with confidence {conf:.2f}')
        
        return found
    
    @staticmethod
    def get_available_languages() -> List[str]:
        """Get list of languages supported by EasyOCR."""
        if not EASYOCR_AVAILABLE:
            return []
        
        return ['af', 'ar', 'az', 'be', 'bg', 'bn', 'bs', 'cs', 'cy', 
                'da', 'de', 'en', 'es', 'et', 'fa', 'fr', 'he', 'hi', 
                'hr', 'hu', 'id', 'is', 'it', 'ja', 'ka', 'kk', 'km', 
                'ko', 'ku', 'lt', 'lv', 'mk', 'ml', 'mn', 'mr', 'ms', 
                'my', 'ne', 'nl', 'no', 'pl', 'pt', 'ro', 'ru', 'rs', 
                'si', 'sk', 'sl', 'sq', 'sr', 'sv', 'ta', 'te', 'th', 
                'tl', 'tr', 'ug', 'uk', 'uz', 'vi', 'zh']
    
    @classmethod
    def cleanup(cls):
        """Cleanup OCR resources."""
        cls._instance = None
        cls._reader = None
        logger.debug('OCR reader cleaned up')


def screenshot_region(x: int, y: int, width: int, height: int) -> np.ndarray:
    """Capture screen region and return as numpy array."""
    from PIL import ImageGrab
    bbox = (x, y, x + width, y + height)
    img = ImageGrab.grab(bbox=bbox)
    return np.array(img)


def screenshot_window(hwnd: int) -> Optional[np.ndarray]:
    """Capture window content."""
    try:
        import win32gui
        import win32ui
        from ctypes import windll
        
        left, top, right, bot = win32gui.GetWindowRect(hwnd)
        width = right - left
        height = bot - top
        
        hdesktop = windll.user32.GetDesktopWindow()
        hdc = windll.user32.GetDC(hdesktop)
        mfcDC = win32ui.CreateDCFromHandle(hdc)
        saveDC = mfcDC.CreateCompatibleDC()
        
        saveBitMap = win32ui.CreateBitmap()
        saveBitMap.CreateCompatibleBitmap(mfcDC, width, height)
        saveDC.SelectObject(saveBitMap)
        
        result = windll.user32.PrintWindow(hwnd, saveDC.GetSafeHdc(), 0)
        
        bmpinfo = saveBitMap.GetInfo()
        bmpstr = saveBitMap.GetBitmapBits(True)
        
        img = np.frombuffer(bmpstr, dtype=np.uint8).reshape((bmpinfo['bmHeight'], bmpinfo['bmWidth'], 4))
        img = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)
        
        win32gui.DeleteObject(saveBitMap.GetHandle())
        saveDC.DeleteDC()
        mfcDC.DeleteDC()
        windll.user32.ReleaseDC(hdesktop, hdc)
        
        return img
        
    except Exception as e:
        logger.error(f'Lỗi screenshot window: {e}')
        return None
