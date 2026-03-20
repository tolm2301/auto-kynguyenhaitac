import urllib.request
import re
from datetime import datetime, timedelta
from .logger import get_logger

logger = get_logger()

_MONTHS = {
    'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
    'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
    'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
}


def get_gmt7() -> datetime:
    """Get current datetime in GMT+7 timezone."""
    try:
        req = urllib.request.Request(
            'https://www.google.com',
            method='HEAD',
            headers={'User-Agent': 'Mozilla/5.0'}
        )
        with urllib.request.urlopen(req, timeout=5) as response:
            date_str = response.headers.get('Date')
        
        if date_str:
            match = re.match(r'\w+, (\d+) (\w+) (\d+) (\d+):(\d+):(\d+)', date_str)
            if match:
                day, month, year, hour, minute, second = match.groups()
                dt = datetime(
                    int(year),
                    int(_MONTHS[month]),
                    int(day),
                    int(hour),
                    int(minute),
                    int(second)
                )
                dt += timedelta(hours=7)
                logger.debug(f'GMT+7 time from Google: {dt}')
                return dt
        
        dt = datetime.now() + timedelta(hours=7)
        logger.warning(f'Using local time +7h as fallback: {dt}')
        return dt
        
    except Exception as e:
        logger.error(f'Lỗi lấy giờ GMT+7: {e}')
        return datetime.now() + timedelta(hours=7)


def get_year() -> int:
    """Get current year in GMT+7."""
    return get_gmt7().year


def get_month() -> int:
    """Get current month in GMT+7."""
    return get_gmt7().month


def get_day() -> int:
    """Get current day in GMT+7."""
    return get_gmt7().day


def get_hour() -> int:
    """Get current hour in GMT+7."""
    return get_gmt7().hour


def get_minute() -> int:
    """Get current minute in GMT+7."""
    return get_gmt7().minute


def get_second() -> int:
    """Get current second in GMT+7."""
    return get_gmt7().second


def format_gmt7(format_str: str = '%Y-%m-%d %H:%M:%S') -> str:
    """Format current GMT+7 time."""
    return get_gmt7().strftime(format_str)
