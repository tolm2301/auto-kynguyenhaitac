import logging
import os
import sys
from datetime import datetime
from pathlib import Path

_loggers = {}

def setup_logger(name: str = 'auto_vht', log_dir: str = None, level: int = logging.DEBUG) -> logging.Logger:
    """Setup logger with file and console handlers."""
    if name in _loggers:
        return _loggers[name]
    
    logger = logging.getLogger(name)
    logger.setLevel(level)
    logger.handlers.clear()
    
    formatter = logging.Formatter(
        '%(asctime)s | %(levelname)-8s | %(name)s | %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    if log_dir is None:
        log_dir = Path(__file__).parent.parent / 'logs'
    else:
        log_dir = Path(log_dir)
    
    log_dir.mkdir(parents=True, exist_ok=True)
    
    log_file = log_dir / f'{name}_{datetime.now().strftime("%Y%m%d")}.log'
    file_handler = logging.FileHandler(log_file, encoding='utf-8')
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    
    _loggers[name] = logger
    return logger

def get_logger(name: str = 'auto_vht') -> logging.Logger:
    """Get existing logger or create new one."""
    if name not in _loggers:
        return setup_logger(name)
    return _loggers[name]

class LogContext:
    """Context manager for logging code execution with trace."""
    
    def __init__(self, logger: logging.Logger, operation: str, **kwargs):
        self.logger = logger
        self.operation = operation
        self.context_data = kwargs
        self.start_time = None
    
    def __enter__(self):
        self.start_time = datetime.now()
        context_str = ' | '.join(f'{k}={v}' for k, v in self.context_data.items()) if self.context_data else ''
        if context_str:
            self.logger.debug(f'START | {self.operation} | {context_str}')
        else:
            self.logger.debug(f'START | {self.operation}')
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        duration = (datetime.now() - self.start_time).total_seconds()
        if exc_type:
            self.logger.error(f'ERROR | {self.operation} | {exc_type.__name__}: {exc_val} | Duration: {duration:.3f}s')
        else:
            self.logger.debug(f'END   | {self.operation} | Duration: {duration:.3f}s')
        return False

def log_trace(logger: logging.Logger = None):
    """Decorator for logging function calls with arguments and return values."""
    def decorator(func):
        nonlocal logger
        if logger is None:
            logger = get_logger()
        
        def wrapper(*args, **kwargs):
            func_logger = logger
            func_name = func.__name__
            
            args_repr = [repr(a) for a in args]
            kwargs_repr = [f'{k}={v!r}' for k, v in kwargs.items()]
            signature = ', '.join(args_repr + kwargs_repr)
            
            func_logger.debug(f'CALL  | {func_name}({signature})')
            
            try:
                result = func(*args, **kwargs)
                func_logger.debug(f'RETURN| {func_name} -> {result!r}')
                return result
            except Exception as e:
                func_logger.error(f'EXCEPT| {func_name} | {type(e).__name__}: {e}')
                raise
        
        return wrapper
    return decorator
