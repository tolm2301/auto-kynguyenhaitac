import tkinter as tk
from tkinter import ttk, messagebox
import threading

from utils import get_logger, setup_logger, resize_all_games
from utils.state import stop as state_stop, get_is_running, set_running
from features import (
    feature_enhance, feature_rakhoi, feature_nammoiphattai, 
    feature_daily, feature_anhhon, feature_tanconghaiquan,
    feature_hoidapcothuong, feature_punk, feature_kraken,
    feature_test, feature_change_win, feature_lich_su_kien
)


class MainWindow:
    """Main GUI window for Auto VHT."""
    
    def __init__(self):
        self.logger = setup_logger('gui')
        self.logger.info('Initializing GUI')
        
        self.root = tk.Tk()
        self.root.title('Auto VHT')
        self.root.geometry('400x650')
        self.root.resizable(False, False)
        self.root.configure(bg='#f0f0f0')
        
        try:
            self.root.iconbitmap('resources/icon.ico')
        except Exception:
            self.logger.warning('Icon not found, using default')
        
        self.root.protocol('WM_DELETE_WINDOW', self.on_close)
        
        self.feature_thread = None
        self._create_widgets()
        self._update_status('Chưa có tính năng nào đang chạy')
        
        self.logger.info('GUI initialized successfully')
    
    def _create_widgets(self):
        """Create all GUI widgets with better layout."""
        style = ttk.Style()
        style.configure('Title.TLabel', font=('Arial', 14, 'bold'), foreground='#2e5090')
        style.configure('Header.TLabel', font=('Arial', 11, 'bold'), foreground='#333')
        style.configure('Status.TLabel', font=('Arial', 10), foreground='#006400')
        style.configure('Feature.TButton', padding=8)
        style.configure('Action.TButton', padding=5)
        
        main_frame = ttk.Frame(self.root, padding='15')
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        title = ttk.Label(main_frame, text='🔧 AUTO VHT', style='Title.TLabel')
        title.pack(pady=(0, 5))
        
        subtitle = ttk.Label(main_frame, text='Kỷ Nguyên Hải Tặc', font=('Arial', 9), foreground='#666')
        subtitle.pack(pady=(0, 15))
        
        status_frame = ttk.LabelFrame(main_frame, text='Trạng thái', padding='10')
        status_frame.pack(fill=tk.X, pady=(0, 15))
        
        self.status_label = ttk.Label(status_frame, text='Chưa có', style='Status.TLabel')
        self.status_label.pack()
        
        input_frame = ttk.Frame(main_frame)
        input_frame.pack(fill=tk.X, pady=(0, 15))
        
        ttk.Label(input_frame, text='Số lượt:').pack(side=tk.LEFT)
        self.count_var = tk.StringVar(value='1')
        count_entry = ttk.Entry(input_frame, textvariable=self.count_var, width=8)
        count_entry.pack(side=tk.LEFT, padx=(10, 0))
        
        btn_control = ttk.Frame(main_frame)
        btn_control.pack(fill=tk.X, pady=(0, 15))
        
        btn_stop = ttk.Button(btn_control, text='⏹ Dừng', command=self._on_stop, style='Action.TButton')
        btn_stop.pack(side=tk.LEFT, padx=(0, 5), fill=tk.X, expand=True)
        
        btn_resize = ttk.Button(btn_control, text='📐 Resize', command=self._on_resize, style='Action.TButton')
        btn_resize.pack(side=tk.LEFT, padx=(0, 5), fill=tk.X, expand=True)
        
        btn_change = ttk.Button(btn_control, text='✏️ Đổi tên', command=self._on_change_name, style='Action.TButton')
        btn_change.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        nb = ttk.Notebook(main_frame)
        nb.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        features_tab = ttk.Frame(nb, padding='10')
        nb.add(features_tab, text='📋 Tính năng')
        
        features = [
            ('⚡ Cường Hoá', self._on_enhance),
            ('⛵ Ra Khơi', self._on_rakhoi),
            ('🎊 Năm Mới Phát Tài', self._on_nammoiphattai),
            ('📅 Daily', self._on_daily),
            ('👻 Ảnh Hồn', self._on_anhhon),
            ('⚔️ Tấn Công Hải Quân', self._on_tanconghaiquan),
            ('❓ Hỏi Đáp Có Thưởng', self._on_hoidapcothuong),
        ]
        
        for i, (text, cmd) in enumerate(features):
            btn = ttk.Button(features_tab, text=text, command=cmd, style='Feature.TButton')
            btn.pack(fill=tk.X, pady=3)
        
        boss_tab = ttk.Frame(nb, padding='10')
        nb.add(boss_tab, text='🐉 Boss')
        
        boss_features = [
            ('🐎 Rồng Punk (15:30)', self._on_punk),
            ('🦑 Kraken (21:00)', self._on_kraken),
        ]
        
        for text, cmd in boss_features:
            btn = ttk.Button(boss_tab, text=text, command=cmd, style='Feature.TButton')
            btn.pack(fill=tk.X, pady=3)
        
        tools_tab = ttk.Frame(nb, padding='10')
        nb.add(tools_tab, text='🔧 Công cụ')
        
        ttk.Button(tools_tab, text='🧪 Test', command=self._on_test, style='Feature.TButton').pack(fill=tk.X, pady=3)
        ttk.Button(tools_tab, text='📅 Lịch Sự Kiện', command=self._on_lich_su_kien, style='Feature.TButton').pack(fill=tk.X, pady=3)
    
    def _get_count(self) -> int:
        """Get count from input field."""
        try:
            return int(self.count_var.get())
        except ValueError:
            return 1
    
    def _run_feature(self, feature_func, *args, **kwargs):
        """Run a feature in a separate thread."""
        def thread_target():
            try:
                feature_func(*args, **kwargs)
            except Exception as e:
                self.logger.error(f'Feature error: {e}')
                self.root.after(0, lambda: messagebox.showerror('Lỗi', f'Lỗi feature: {e}'))
            finally:
                self.root.after(0, lambda: self._update_status('Chưa có tính năng nào đang chạy'))
        
        if get_is_running():
            messagebox.showwarning('Cảnh báo', 'Một tính năng đang chạy! Vui lòng bấm Dừng trước.')
            return
        
        self._update_status('Đang chạy...')
        self.feature_thread = threading.Thread(target=thread_target, daemon=True)
        self.feature_thread.start()
    
    def _update_status(self, text: str):
        """Update status label."""
        self.status_label.config(text=text)
    
    def _on_stop(self):
        """Stop button clicked."""
        self.logger.info('Stop button clicked')
        state_stop()
        self._update_status('Đã dừng!')
        self.logger.info('Feature stopped')
    
    def _on_test(self):
        """Test button clicked."""
        self.logger.info('Test button clicked')
        self._run_feature(feature_test)
    
    def _on_change_name(self):
        """Change name button clicked."""
        self.logger.info('Change name button clicked')
        feature_change_win()
    
    def _on_resize(self):
        """Resize button clicked."""
        self.logger.info('Resize button clicked')
        count = resize_all_games()
        messagebox.showinfo('Thông báo', f'Đã resize {count} cửa sổ game')
    
    def _on_enhance(self):
        self.logger.info('Enhance clicked')
        self._run_feature(feature_enhance, self._get_count(), status_callback=self._update_status)
    
    def _on_rakhoi(self):
        self.logger.info('Ra khoi clicked')
        self._run_feature(feature_rakhoi, self._get_count(), status_callback=self._update_status)
    
    def _on_nammoiphattai(self):
        self.logger.info('Nam moi phat tai clicked')
        self._run_feature(feature_nammoiphattai, self._get_count(), status_callback=self._update_status)
    
    def _on_daily(self):
        self.logger.info('Daily clicked')
        self._run_feature(feature_daily, status_callback=self._update_status)
    
    def _on_anhhon(self):
        self.logger.info('Anh hon clicked')
        self._run_feature(feature_anhhon, self._get_count(), status_callback=self._update_status)
    
    def _on_tanconghaiquan(self):
        self.logger.info('Tan cong hai quan clicked')
        self._run_feature(feature_tanconghaiquan, status_callback=self._update_status)
    
    def _on_hoidapcothuong(self):
        self.logger.info('Hoi dap co thuong clicked')
        self._run_feature(feature_hoidapcothuong, status_callback=self._update_status)
    
    def _on_punk(self):
        self.logger.info('Punk clicked')
        self._run_feature(feature_punk, status_callback=self._update_status)
    
    def _on_kraken(self):
        self.logger.info('Kraken clicked')
        self._run_feature(feature_kraken, status_callback=self._update_status)
    
    def _on_lich_su_kien(self):
        self.logger.info('Lich su kien clicked')
        feature_lich_su_kien()
    
    def on_close(self):
        """Window close event."""
        if get_is_running():
            if messagebox.askyesno('Xác nhận', 'Có tính năng đang chạy. Bạn có chắc muốn thoát?'):
                state_stop()
                self.logger.info('Application closing')
                self.root.quit()
        else:
            self.logger.info('Application closing')
            self.root.quit()
    
    def run(self):
        """Start the GUI main loop."""
        self.logger.info('Starting GUI main loop')
        self.root.mainloop()
