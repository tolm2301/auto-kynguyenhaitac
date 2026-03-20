import time
from utils import (
    get_logger, get_game_windows, resize_all_games,
    click_post, get_hour, get_minute, LogContext
)
from utils.state import set_running, stop as state_stop, get_is_running

logger = get_logger()


def feature_punk(status_callback=None) -> bool:
    """Feature: Rồng Punk"""
    with LogContext(logger, 'feature_punk'):
        if status_callback:
            status_callback('Tính năng đang chạy: Rồng Punk')
        
        resize_all_games()
        hwnds = get_game_windows()
        if not hwnds:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False
        
        set_running('Rồng Punk', None, status_callback)
        logger.info(f'Rồng Punk monitoring started for {len(hwnds)} windows')
        
        while get_is_running():
            current_hour = get_hour()
            current_minute = get_minute()
            
            if current_hour == 15 and current_minute == 30:
                logger.info('Rồng Punk event starting!')
                time.sleep(3)
                
                for hwnd in hwnds:
                    click_post(hwnd, 729, 35); time.sleep(2)
                    click_post(hwnd, 339, 200); time.sleep(1)
                    click_post(hwnd, 893, 558); time.sleep(2)
                    click_post(hwnd, 680, 73); time.sleep(1)
                
                while get_is_running():
                    if get_hour() == 15 and get_minute() == 45:
                        logger.info('Rồng Punk event ended')
                        state_stop()
                        return True
                    for hwnd in hwnds:
                        click_post(hwnd, 748, 156)
                    time.sleep(2)
            
            if current_hour == 15 and current_minute > 30:
                while get_is_running():
                    if get_hour() == 15 and get_minute() == 45:
                        logger.info('Rồng Punk event ended')
                        state_stop()
                        return True
                    for hwnd in hwnds:
                        click_post(hwnd, 748, 156)
                    time.sleep(2)
            
            time.sleep(1)
        
        state_stop()
        logger.info('Feature punk stopped by user')
        return True


def feature_kraken(status_callback=None) -> bool:
    """Feature: Kraken"""
    with LogContext(logger, 'feature_kraken'):
        if status_callback:
            status_callback('Tính năng đang chạy: Kraken')
        
        resize_all_games()
        hwnds = get_game_windows()
        if not hwnds:
            logger.error('Không tìm thấy cửa sổ game')
            state_stop()
            return False
        
        set_running('Kraken', None, status_callback)
        logger.info(f'Kraken monitoring started for {len(hwnds)} windows')
        
        while get_is_running():
            current_hour = get_hour()
            current_minute = get_minute()
            
            if current_hour == 21 and current_minute == 0:
                logger.info('Kraken event starting!')
                time.sleep(3)
                
                for hwnd in hwnds:
                    click_post(hwnd, 729, 35); time.sleep(1)
                    click_post(hwnd, 402, 259); time.sleep(1)
                    click_post(hwnd, 893, 558); time.sleep(2)
                    click_post(hwnd, 680, 73); time.sleep(1)
                
                while get_is_running():
                    if get_hour() == 21 and get_minute() == 15:
                        logger.info('Kraken event ended')
                        state_stop()
                        return True
                    for hwnd in hwnds:
                        click_post(hwnd, 748, 156)
                    time.sleep(2)
            
            if current_hour == 21 and current_minute > 0:
                while get_is_running():
                    if get_hour() == 21 and get_minute() == 15:
                        logger.info('Kraken event ended')
                        state_stop()
                        return True
                    for hwnd in hwnds:
                        click_post(hwnd, 748, 156)
                    time.sleep(2)
            
            time.sleep(1)
        
        state_stop()
        logger.info('Feature kraken stopped by user')
        return True


def stop():
    """Stop the running feature."""
    state_stop()
    logger.info('Feature stop requested')
