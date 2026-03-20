import time
import win32gui
import win32con
from tkinter import messagebox

from utils import (
    get_logger, resize_game, get_game_window, 
    send_key, LogContext
)

logger = get_logger()


def feature_test(status_callback=None) -> bool:
    """
    Feature: Test
    Testing function for development.
    """
    with LogContext(logger, 'feature_test'):
        if status_callback:
            status_callback('Tính năng đang chạy: Test')
        
        if not resize_game():
            logger.error('Không resize được game')
            return False
        
        hwnd = get_game_window()
        if not hwnd:
            logger.error('Không tìm thấy cửa sổ game')
            return False
        
        logger.info('Test feature executed')
        
        return True


def feature_change_win(status_callback=None) -> bool:
    """
    Feature: Change window title between 'Kỷ Nguyên Hải Tặc' and 'Kỷ Nguyên Hải Tặc 1'.
    """
    with LogContext(logger, 'feature_change_win'):
        try:
            hwnd = win32gui.FindWindow(None, 'Kỷ Nguyên Hải Tặc')
            
            if hwnd:
                win32gui.SetWindowText(hwnd, 'Kỷ Nguyên Hải Tặc 1')
                logger.info('Changed window title to "Kỷ Nguyên Hải Tặc 1"')
                messagebox.showinfo('Thông báo', 'Đã đổi tên thành: Kỷ Nguyên Hải Tặc 1')
            else:
                hwnd = win32gui.FindWindow(None, 'Kỷ Nguyên Hải Tặc 1')
                if hwnd:
                    win32gui.SetWindowText(hwnd, 'Kỷ Nguyên Hải Tặc')
                    logger.info('Changed window title to "Kỷ Nguyên Hải Tặc"')
                    messagebox.showinfo('Thông báo', 'Đã đổi tên thành: Kỷ Nguyên Hải Tặc')
                else:
                    logger.warning('Không tìm thấy cửa sổ game')
                    messagebox.showerror('Lỗi', 'Không tìm thấy cửa sổ game')
            
            return True
            
        except Exception as e:
            logger.error(f'Lỗi đổi tên: {e}')
            return False


def feature_lich_su_kien(status_callback=None):
    """Show event schedule."""
    messagebox.showinfo(
        'Sự Kiện Kỷ Nguyên Hải Tặc',
        'T2: Công xưởng smile(18h30-19h00)\n'
        'T3: Hải tặc thông thái (11h55), Uta world(19h), Closseum(19h45), Tranh bá trên biển(20h15).\n'
        'T4: Công xưởng smile(18h30-19h00), Chiến trường(19h45).\n'
        'T5: Hải tặc thông thái (11h55), Uta world(19h), Closseum(19h45), Tranh bá trên biển(20h15).\n'
        'T6: Công xưởng smile(18h30-19h00), Wano(19h45).\n'
        'T7: Chiến trường(19h45).\n'
        'Daily: Punk, Kraken, Kaido, Tầm bảo chiến.'
    )
