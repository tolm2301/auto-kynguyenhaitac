import time
import unicodedata
from typing import Optional, Tuple, Dict, List
from pathlib import Path
import configparser

from utils import (
    get_logger, resize_game, get_game_window, 
    click_post, LogContext, screenshot_region
)
from utils.state import set_running, stop as state_stop, get_is_running

logger = get_logger()

QUEST_PANEL_X = 1085
QUEST_PANEL_Y = 206
QUEST_PANEL_W = 169
QUEST_PANEL_H = 200

DIALOG_X = 250
DIALOG_Y = 152
DIALOG_W = 427
DIALOG_H = 234

DIALOG_SKIP_X = 895
DIALOG_SKIP_Y = 631
DIALOG_SKIP_W = 208
DIALOG_SKIP_H = 48

DIALOG_CLICK_ANY_X = 1188
DIALOG_CLICK_ANY_Y = 9
DIALOG_SKIP_COUNT = 15

QUEST_KEYWORDS = [
    'đi tìm', 'di tim', 'tim',
    'đi đến', 'di den', 'đến', 'den',
    'nói chuyện', 'noi chuyen', 'chuyện', 'chuyen',
    'tiêu diệt', 'tieu diet', 'diệt', 'diet',
    'thu thập', 'thu thap', 'thập', 'thap',
    'giao hàng', 'giao hang',
]

DIALOG_FINISH_KEYWORDS = [
    'hoàn thành', 'hoan thanh', 'thành', 'thanh',
]

DIALOG_NEXT_KEYWORDS = [
    'tiếp theo', 'tiep theo', 'tiếp', 'tiep',
    'kế tiếp', 'ke tiep',
]

DIALOG_SKIP_KEYWORDS = [
    'click', 'bất kỳ', 'bat ky', 'phím', 'phim', 'tiếp tục', 'tiep tuc',
]

def normalize_text(text: str) -> str:
    text = text.lower()
    text = unicodedata.normalize('NFD', text)
    text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
    return text

def fuzzy_match(text: str, keywords: List[str], threshold: float = 0.5) -> Optional[str]:
    text_norm = normalize_text(text)
    
    for kw in keywords:
        kw_norm = normalize_text(kw)
        
        if kw_norm in text_norm or text_norm in kw_norm:
            return kw
        
        words = kw_norm.split()
        if len(words) > 1:
            match_count = sum(1 for w in words if w in text_norm)
            if match_count >= len(words) * threshold:
                return kw
    
    return None

class QuestConfig:
    def __init__(self):
        self.quest_keywords: List[str] = QUEST_KEYWORDS.copy()
        self.dialog_finish_keywords: List[str] = DIALOG_FINISH_KEYWORDS.copy()
        self.dialog_next_keywords: List[str] = DIALOG_NEXT_KEYWORDS.copy()
        self.dialog_skip_keywords: List[str] = DIALOG_SKIP_KEYWORDS.copy()
        
        self.delay_after_click_quest = 10
        self.delay_after_complete_quest = 5
        self.delay_after_dialog_click = 3
        self.delay_after_skip_dialog = 2
        self.delay_between_ocr = 2.0
        self.confidence_threshold = 0.1
        
        self.load_from_ini()
    
    def load_from_ini(self):
        ini_path = Path(__file__).parent.parent / 'resources' / 'quest_config.ini'
        if not ini_path.exists():
            self.create_default_ini(ini_path)
            return
        
        try:
            config = configparser.ConfigParser()
            config.read(ini_path, encoding='utf-8')
            
            if 'QUEST' in config:
                keywords = config['QUEST'].get('keywords', '')
                if keywords:
                    self.quest_keywords = [k.strip().lower() for k in keywords.split(',')]
                    logger.info(f'Loaded {len(self.quest_keywords)} quest keywords from ini')
            
            if 'DIALOG' in config:
                finish_kw = config['DIALOG'].get('finish_keywords', '')
                if finish_kw:
                    self.dialog_finish_keywords = [k.strip().lower() for k in finish_kw.split(',')]
                    logger.info(f'Loaded {len(self.dialog_finish_keywords)} dialog finish keywords')
                
                next_kw = config['DIALOG'].get('next_keywords', '')
                if next_kw:
                    self.dialog_next_keywords = [k.strip().lower() for k in next_kw.split(',')]
                    logger.info(f'Loaded {len(self.dialog_next_keywords)} dialog next keywords')
                
                skip_kw = config['DIALOG'].get('skip_keywords', '')
                if skip_kw:
                    self.dialog_skip_keywords = [k.strip().lower() for k in skip_kw.split(',')]
                    logger.info(f'Loaded {len(self.dialog_skip_keywords)} dialog skip keywords')
            
            if 'DELAY' in config:
                self.delay_after_click_quest = config['DELAY'].getfloat('after_click_quest', 10)
                self.delay_after_complete_quest = config['DELAY'].getfloat('after_complete_quest', 5)
                self.delay_after_dialog_click = config['DELAY'].getfloat('after_dialog_click', 3)
                self.delay_after_skip_dialog = config['DELAY'].getfloat('after_skip_dialog', 2)
                self.delay_between_ocr = config['DELAY'].getfloat('between_ocr', 2.0)
                self.confidence_threshold = config['DELAY'].getfloat('confidence_threshold', 0.2)
                logger.info(f'Loaded delays: between_ocr={self.delay_between_ocr}s, conf={self.confidence_threshold}')
                    
        except Exception as e:
            logger.error(f'Error loading quest config: {e}')
    
    def create_default_ini(self, path: Path):
        try:
            config = configparser.ConfigParser()
            config['QUEST'] = {
                'keywords': ', '.join(QUEST_KEYWORDS),
            }
            config['DIALOG'] = {
                'panel_x': str(QUEST_PANEL_X),
                'panel_y': str(QUEST_PANEL_Y),
                'panel_w': str(QUEST_PANEL_W),
                'panel_h': str(QUEST_PANEL_H),
                'npc_x': str(DIALOG_X),
                'npc_y': str(DIALOG_Y),
                'npc_w': str(DIALOG_W),
                'npc_h': str(DIALOG_H),
                'skip_x': str(DIALOG_SKIP_X),
                'skip_y': str(DIALOG_SKIP_Y),
                'skip_w': str(DIALOG_SKIP_W),
                'skip_h': str(DIALOG_SKIP_H),
                'click_x': str(DIALOG_CLICK_ANY_X),
                'click_y': str(DIALOG_CLICK_ANY_Y),
                'skip_count': str(DIALOG_SKIP_COUNT),
                'finish_keywords': ', '.join(DIALOG_FINISH_KEYWORDS),
                'next_keywords': ', '.join(DIALOG_NEXT_KEYWORDS),
                'skip_keywords': ', '.join(DIALOG_SKIP_KEYWORDS),
            }
            config['DELAY'] = {
                'after_click_quest': '10',
                'after_complete_quest': '5',
                'after_dialog_click': '3',
                'after_skip_dialog': '2',
                'between_ocr': '2.0',
                'confidence_threshold': '0.2',
            }
            
            path.parent.mkdir(parents=True, exist_ok=True)
            with open(path, 'w', encoding='utf-8') as f:
                config.write(f)
            logger.info(f'Created default quest config at {path}')
        except Exception as e:
            logger.error(f'Error creating default ini: {e}')


class QuestManager:
    def __init__(self, hwnd: int):
        self.hwnd = hwnd
        self.ocr = None
        self.last_ocr_time = 0
        self.is_in_dialog = False
        self.quest_found = False
        
        self.config = QuestConfig()
    

    
    def _check_dialog_npc_ocr(self) -> Optional[Tuple[str, int, int, str]]:
        if self.ocr is None:
            try:
                from utils.ocr import OCRReader
                self.ocr = OCRReader(languages=['vi', 'en'])
            except Exception as e:
                logger.error(f'Failed to initialize OCR: {e}')
                return None
        
        img = screenshot_region(DIALOG_X, DIALOG_Y, DIALOG_W, DIALOG_H, self.hwnd)
        if img is None:
            return None
        
        try:
            results = self.ocr.read_text(img)
            
            for item in results:
                if not isinstance(item, tuple) or len(item) < 3:
                    continue
                
                bbox, text, conf = item[0], item[1], item[2]
                
                if conf < self.config.confidence_threshold:
                    continue
                
                match = fuzzy_match(text, self.config.dialog_finish_keywords)
                if match:
                    x1 = int(min([p[0] for p in bbox]))
                    y1 = int(min([p[1] for p in bbox]))
                    x2 = int(max([p[0] for p in bbox]))
                    y2 = int(max([p[1] for p in bbox]))
                    
                    click_x = DIALOG_X + (x1 + x2) // 2
                    click_y = DIALOG_Y + y2 + 20
                    
                    logger.info(f'[DIALOG] OCR: "{text}" -> finish, click ({click_x}, {click_y})')
                    return ('finish', click_x, click_y, text)
                
                match = fuzzy_match(text, self.config.dialog_next_keywords)
                if match:
                    x1 = int(min([p[0] for p in bbox]))
                    y1 = int(min([p[1] for p in bbox]))
                    x2 = int(max([p[0] for p in bbox]))
                    y2 = int(max([p[1] for p in bbox]))
                    
                    click_x = DIALOG_X + (x1 + x2) // 2
                    click_y = DIALOG_Y + y2 + 20
                    
                    logger.info(f'[DIALOG] OCR: "{text}" -> next, click ({click_x}, {click_y})')
                    return ('next', click_x, click_y, text)
            
            return None
            
        except Exception as e:
            logger.error(f'OCR dialog NPC error: {e}')
            return None
    
    def _check_click_any(self) -> bool:
        if self.ocr is None:
            try:
                from utils.ocr import OCRReader
                self.ocr = OCRReader(languages=['vi', 'en'])
            except Exception as e:
                logger.error(f'Failed to initialize OCR: {e}')
                return False
        
        img = screenshot_region(DIALOG_SKIP_X, DIALOG_SKIP_Y, DIALOG_SKIP_W, DIALOG_SKIP_H, self.hwnd)
        if img is None:
            return False
        
        try:
            results = self.ocr.read_text(img)
            
            for item in results:
                if not isinstance(item, tuple) or len(item) < 3:
                    continue
                
                bbox, text, conf = item[0], item[1], item[2]
                
                if conf < self.config.confidence_threshold:
                    continue
                
                match = fuzzy_match(text, self.config.dialog_skip_keywords)
                if match:
                    x1 = int(min([p[0] for p in bbox]))
                    y1 = int(min([p[1] for p in bbox]))
                    x2 = int(max([p[0] for p in bbox]))
                    y2 = int(max([p[1] for p in bbox]))
                    
                    click_x = DIALOG_SKIP_X + (x1 + x2) // 2
                    click_y = DIALOG_SKIP_Y + y2 + 20
                    
                    logger.info(f'[DIALOG] Skip "{text}" match="{match}", click ({click_x}, {click_y})')
                    for _ in range(DIALOG_SKIP_COUNT):
                        click_post(self.hwnd, click_x, click_y)
                        time.sleep(0.2)
                    return True
            
            return False
            
        except Exception as e:
            logger.error(f'OCR click any error: {e}')
            return False
    
    def _check_task_panel_ocr(self) -> Optional[Dict]:
        if self.ocr is None:
            try:
                from utils.ocr import OCRReader
                self.ocr = OCRReader(languages=['vi', 'en'])
            except Exception as e:
                logger.error(f'Failed to initialize OCR: {e}')
                return None
        
        img = screenshot_region(QUEST_PANEL_X, QUEST_PANEL_Y, QUEST_PANEL_W, QUEST_PANEL_H, self.hwnd)
        if img is None:
            return None
        
        try:
            results = self.ocr.read_text(img)
            
            for item in results:
                if not isinstance(item, tuple) or len(item) < 3:
                    continue
                
                bbox, text, conf = item[0], item[1], item[2]
                
                if conf < self.config.confidence_threshold:
                    continue
                
                matched_keyword = fuzzy_match(text, self.config.quest_keywords)
                
                if matched_keyword:
                    x1 = int(min([p[0] for p in bbox]))
                    y1 = int(min([p[1] for p in bbox]))
                    x2 = int(max([p[0] for p in bbox]))
                    y2 = int(max([p[1] for p in bbox]))
                    
                    click_x = QUEST_PANEL_X + (x1 + x2) // 2
                    click_y = QUEST_PANEL_Y + y2 + 20
                    
                    logger.info(f'[QUEST] OCR: "{text}" [{conf:.2f}] kw="{matched_keyword}"')
                    logger.info(f'[QUEST] bbox=({x1},{y1},{x2},{y2}) click=({click_x},{click_y})')
                    
                    return {
                        'x': click_x,
                        'y': click_y,
                        'keyword': matched_keyword,
                        'text': text,
                        'confidence': conf
                    }
            
            return None
            
        except Exception as e:
            logger.error(f'OCR error: {e}')
            return None
    
    def reset_state(self):
        self.quest_found = False
        self.is_in_dialog = False
    
    def execute(self, status_callback=None) -> bool:
        logger.info('[QUEST] Bắt đầu tính năng Quest')
        
        if status_callback:
            status_callback('[QUEST] Đang xử lý nhiệm vụ...')
        
        iteration = 0
        max_iterations = 1000
        
        while get_is_running() and iteration < max_iterations:
            iteration += 1
            
            if iteration % 10 == 0:
                logger.debug(f'[QUEST] Iteration {iteration}')
                if status_callback:
                    status_callback(f'[QUEST] Đang chạy... (vòng {iteration})')
            
            current_time = time.time()
            if current_time - self.last_ocr_time < self.config.delay_between_ocr:
                time.sleep(0.5)
                continue
            self.last_ocr_time = current_time
            
            # 1. Check skip dialog
            if self._check_click_any():
                time.sleep(self.config.delay_after_skip_dialog)
                continue
            
            # 2. Check quest panel (luôn quét)
            quest_info = self._check_task_panel_ocr()
            if quest_info:
                logger.info(f'[QUEST] Phát hiện: "{quest_info["text"][:30]}..."')
                click_post(self.hwnd, quest_info['x'], quest_info['y'])
                time.sleep(self.config.delay_after_click_quest)
                continue
            
            # 3. Check dialog NPC (finish/next)
            dialog_result = self._check_dialog_npc_ocr()
            if dialog_result:
                action, x, y, text = dialog_result
                logger.info(f'[DIALOG] {action}: "{text[:30]}..."')
                click_post(self.hwnd, x, y)
                time.sleep(self.config.delay_after_dialog_click)
                continue
            
            if iteration % 30 == 0:
                self.reset_state()
                click_post(self.hwnd, QUEST_PANEL_X + 50, QUEST_PANEL_Y + 50)
                time.sleep(1)
            
            time.sleep(1)
        
        logger.info(f'[QUEST] Kết thúc (sau {iteration} vòng lặp)')
        return True


def feature_quest(status_callback=None) -> bool:
    with LogContext(logger, 'feature_quest'):
        if status_callback:
            status_callback('[QUEST] Đang khởi tạo...')
        
        if not resize_game():
            logger.error('Không resize được game')
            state_stop()
            return False
        
        hwnd = get_game_window()
        if not hwnd:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False
        
        set_running('Quest', None, status_callback)
        logger.info('Starting quest feature')
        
        manager = QuestManager(hwnd)
        result = manager.execute(status_callback)
        
        state_stop()
        logger.info('Feature quest completed')
        return result


def stop():
    state_stop()
    logger.info('Quest feature stop requested')
