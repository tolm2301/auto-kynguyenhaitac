import tkinter as tk
from tkinter import ttk, messagebox
import threading
import queue
import logging

from utils import get_logger, setup_logger, resize_all_games
from utils.state import stop as state_stop, get_is_running, set_running
from utils.scheduler import start_scheduler, stop_scheduler, get_next_event_text


class TextHandler(logging.Handler):
    def __init__(self, text_widget, q):
        logging.Handler.__init__(self)
        self.text_widget = text_widget
        self.queue = q
    
    def emit(self, record):
        msg = self.format(record)
        self.queue.put(msg)
    
    def process_queue(self):
        while True:
            try:
                msg = self.queue.get_nowait()
                self.text_widget.insert(tk.END, msg + '\n')
                self.text_widget.see(tk.END)
            except queue.Empty:
                break


class LogViewer:
    def __init__(self, text_widget):
        self.text_widget = text_widget
        self.queue = queue.Queue()
        self.handler = None
        
    def setup(self, logger):
        self.handler = TextHandler(self.text_widget, self.queue)
        self.handler.setFormatter(logging.Formatter('%(asctime)s | %(levelname)s | %(message)s', datefmt='%H:%M:%S'))
        logger.addHandler(self.handler)
        self._poll_queue()
    
    def _poll_queue(self):
        if self.handler:
            self.handler.process_queue()
        if self.text_widget.winfo_exists():
            self.text_widget.after(100, self._poll_queue)


class MainWindow:
    """Main GUI window for Auto VHT."""
    
    def __init__(self):
        self.logger = setup_logger('gui')
        self.logger.info('Initializing GUI')
        
        self.root = tk.Tk()
        self.root.title('Auto VHT')
        self.root.geometry('420x750')
        self.root.resizable(True, True)
        self.root.minsize(400, 500)
        self.root.configure(bg='#f0f0f0')
        
        try:
            self.root.iconbitmap('resources/icon.ico')
        except Exception:
            self.logger.warning('Icon not found, using default')
        
        self.root.protocol('WM_DELETE_WINDOW', self.on_close)
        
        self.feature_thread = None
        self._scheduler_running = False
        self._create_widgets()
        self._update_status('Chưa có tính năng nào đang chạy')
        
        self.log_viewer.setup(self.logger)
        
        # Start event timer for next event display
        self._update_next_event()
        self.root.after(60000, self._update_next_event)
        
        self.logger.info('GUI initialized successfully')
    
    def _create_widgets(self):
        """Create all GUI widgets with better layout."""
        style = ttk.Style()
        style.configure('Title.TLabel', font=('Arial', 14, 'bold'), foreground='#2e5090')
        style.configure('Header.TLabel', font=('Arial', 11, 'bold'), foreground='#333')
        style.configure('Status.TLabel', font=('Arial', 10), foreground='#006400')
        style.configure('Feature.TButton', padding=8)
        style.configure('Action.TButton', padding=5)
        style.configure('Scheduler.TButton', padding=5, foreground='#006400')
        style.configure('SchedulerOff.TButton', padding=5, foreground='#cc0000')
        
        main_frame = ttk.Frame(self.root, padding='15')
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        title = ttk.Label(main_frame, text='🔧 AUTO VHT', style='Title.TLabel')
        title.pack(pady=(0, 5))
        
        subtitle = ttk.Label(main_frame, text='Kỷ Nguyên Hải Tặc', font=('Arial', 9), foreground='#666')
        subtitle.pack(pady=(0, 15))
        
        status_frame = ttk.LabelFrame(main_frame, text='Trạng thái / Log', padding='5')
        status_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        self.log_text = tk.Text(status_frame, height=8, width=45, font=('Consolas', 8), bg='#1e1e1e', fg='#00ff00')
        self.log_text.pack(fill=tk.BOTH, expand=True)
        
        self.log_viewer = LogViewer(self.log_text)
        
        self.status_label = ttk.Label(status_frame, text='Chưa có', style='Status.TLabel')
        self.status_label.pack()
        
        # Next event display
        self.next_event_label = ttk.Label(status_frame, text='', font=('Arial', 9), foreground='#2e5090')
        self.next_event_label.pack()
        
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
        
        # Scheduler toggle button
        self.scheduler_btn = ttk.Button(
            main_frame, text='⏰ Bật Lịch Tự Động',
            command=self._toggle_scheduler,
            style='SchedulerOff.TButton'
        )
        self.scheduler_btn.pack(fill=tk.X, pady=(0, 15))
        
        nb = ttk.Notebook(main_frame)
        nb.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        # ===== Main Tab =====
        main_tab = ttk.Frame(nb, padding='5')
        nb.add(main_tab, text='📋 Main')
        
        canvas_main = tk.Canvas(main_tab, bg='#f0f0f0', highlightthickness=0)
        scrollbar_main = ttk.Scrollbar(main_tab, orient='vertical', command=canvas_main.yview)
        main_inner = ttk.Frame(canvas_main)
        main_inner.bind('<Configure>', lambda e: canvas_main.configure(scrollregion=canvas_main.bbox('all')))
        canvas_main.create_window((0, 0), window=main_inner, anchor='nw')
        canvas_main.configure(yscrollcommand=scrollbar_main.set)
        canvas_main.pack(side='left', fill='both', expand=True)
        scrollbar_main.pack(side='right', fill='y')
        
        main_features = [
            ('📅 Daily', self._on_daily),
            ('⚔️ Tầm Bảo Chiến', self._on_tam_bao_chien),
            ('🧠 Hải Tặc Thông Thái', self._on_haitacthongthai),
        ]
        
        for text, cmd in main_features:
            btn = ttk.Button(main_inner, text=text, command=cmd, style='Feature.TButton')
            btn.pack(fill=tk.X, pady=3, padx=5)
        
        # ===== Boss Tab =====
        boss_tab = ttk.Frame(nb, padding='5')
        nb.add(boss_tab, text='🐉 Boss')
        
        canvas_boss = tk.Canvas(boss_tab, bg='#f0f0f0', highlightthickness=0)
        scrollbar_boss = ttk.Scrollbar(boss_tab, orient='vertical', command=canvas_boss.yview)
        boss_inner = ttk.Frame(canvas_boss)
        boss_inner.bind('<Configure>', lambda e: canvas_boss.configure(scrollregion=canvas_boss.bbox('all')))
        canvas_boss.create_window((0, 0), window=boss_inner, anchor='nw')
        canvas_boss.configure(yscrollcommand=scrollbar_boss.set)
        canvas_boss.pack(side='left', fill='both', expand=True)
        scrollbar_boss.pack(side='right', fill='y')
        
        ttk.Label(boss_inner, text='Boss chạy tự động theo lịch (scheduler)',
                  font=('Arial', 9), foreground='#666').pack(pady=(0, 10))
        
        boss_features = [
            ('🐎 Rồng Punk (15:30)', self._on_punk),
            ('🦑 Kraken (21:00)', self._on_kraken),
            ('🐲 Kaido (21:30)', self._on_kaido),
        ]
        
        for text, cmd in boss_features:
            btn = ttk.Button(boss_inner, text=text, command=cmd, style='Feature.TButton')
            btn.pack(fill=tk.X, pady=3, padx=5)
        
        # ===== Support Tab =====
        support_tab = ttk.Frame(nb, padding='5')
        nb.add(support_tab, text='🔧 Phụ trợ')
        
        canvas_support = tk.Canvas(support_tab, bg='#f0f0f0', highlightthickness=0)
        scrollbar_support = ttk.Scrollbar(support_tab, orient='vertical', command=canvas_support.yview)
        support_inner = ttk.Frame(canvas_support)
        support_inner.bind('<Configure>', lambda e: canvas_support.configure(scrollregion=canvas_support.bbox('all')))
        canvas_support.create_window((0, 0), window=support_inner, anchor='nw')
        canvas_support.configure(yscrollcommand=scrollbar_support.set)
        canvas_support.pack(side='left', fill='both', expand=True)
        scrollbar_support.pack(side='right', fill='y')
        
        support_features = [
            ('⚡ Cường Hoá', self._on_enhance),
            ('⛵ Ra Khơi', self._on_rakhoi),
            ('🎊 Năm Mới Phát Tài', self._on_nammoiphattai),
            ('👻 Ảnh Hồn', self._on_anhhon),
            ('⚔️ Tấn Công Hải Quân', self._on_tanconghaiquan),
            ('❓ Hỏi Đáp Có Thưởng', self._on_hoidapcothuong),
        ]
        
        for text, cmd in support_features:
            btn = ttk.Button(support_inner, text=text, command=cmd, style='Feature.TButton')
            btn.pack(fill=tk.X, pady=3, padx=5)
        
        ttk.Separator(support_inner, orient='horizontal').pack(fill=tk.X, pady=10)
        
        # Gift code section
        gift_frame = ttk.LabelFrame(support_inner, text='Gift Code', padding='5')
        gift_frame.pack(fill=tk.X, pady=5, padx=5)
        
        ttk.Button(gift_frame, text='🎁 Nhập Gift Code', command=self._on_giftcode_dialog,
                   style='Feature.TButton').pack(fill=tk.X, pady=3)
        
        # ===== Tools Tab =====
        tools_tab = ttk.Frame(nb, padding='5')
        nb.add(tools_tab, text='🔧 Công cụ')
        
        canvas_tools = tk.Canvas(tools_tab, bg='#f0f0f0', highlightthickness=0)
        scrollbar_tools = ttk.Scrollbar(tools_tab, orient='vertical', command=canvas_tools.yview)
        tools_inner = ttk.Frame(canvas_tools)
        tools_inner.bind('<Configure>', lambda e: canvas_tools.configure(scrollregion=canvas_tools.bbox('all')))
        canvas_tools.create_window((0, 0), window=tools_inner, anchor='nw')
        canvas_tools.configure(yscrollcommand=scrollbar_tools.set)
        canvas_tools.pack(side='left', fill='both', expand=True)
        scrollbar_tools.pack(side='right', fill='y')
        
        ttk.Button(tools_inner, text='🧪 Test', command=self._on_test, style='Feature.TButton').pack(fill=tk.X, pady=3, padx=5)
        ttk.Button(tools_inner, text='📅 Lịch Sự Kiện', command=self._on_lich_su_kien, style='Feature.TButton').pack(fill=tk.X, pady=3, padx=5)
        ttk.Button(tools_inner, text='📝 Register Uta World', command=self._on_register_uta, style='Feature.TButton').pack(fill=tk.X, pady=3, padx=5)
        
        # ===== Quest Tab =====
        quest_tab = ttk.Frame(nb, padding='5')
        nb.add(quest_tab, text='📜 Quest')
        
        canvas_quest = tk.Canvas(quest_tab, bg='#f0f0f0', highlightthickness=0)
        scrollbar_quest = ttk.Scrollbar(quest_tab, orient='vertical', command=canvas_quest.yview)
        quest_inner = ttk.Frame(canvas_quest)
        quest_inner.bind('<Configure>', lambda e: canvas_quest.configure(scrollregion=canvas_quest.bbox('all')))
        canvas_quest.create_window((0, 0), window=quest_inner, anchor='nw')
        canvas_quest.configure(yscrollcommand=scrollbar_quest.set)
        canvas_quest.pack(side='left', fill='both', expand=True)
        scrollbar_quest.pack(side='right', fill='y')
        
        ttk.Label(quest_inner, text='Tự động làm nhiệm vụ Chính', 
                  font=('Arial', 9), foreground='#666').pack(pady=(0, 10))
        ttk.Button(quest_inner, text='🎯 Làm Quest Chính', command=self._on_quest, 
                   style='Feature.TButton').pack(fill=tk.X, pady=5, padx=5)
        
        ttk.Separator(quest_inner, orient='horizontal').pack(fill=tk.X, pady=15)
        
        info_frame = ttk.LabelFrame(quest_inner, text='Hướng dẫn', padding='10')
        info_frame.pack(fill=tk.X, pady=(10, 0), padx=5)
        
        info_text = (
            '1. Mở game và resize về 1280x720\n'
            '2. Nhấn "Làm Quest Chính" để bắt đầu\n'
            '3. Script sẽ tự nhận dialog, click Skip/Next\n'
            '4. Nhấn "Dừng" để kết thúc'
        )
        ttk.Label(info_frame, text=info_text, font=('Arial', 8), 
                  foreground='#555', justify='left').pack(anchor='w')
    
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
    
    def _update_next_event(self):
        """Update next event display."""
        text = get_next_event_text()
        self.next_event_label.config(text=text)
        if self.root.winfo_exists():
            self.root.after(60000, self._update_next_event)
    
    def _toggle_scheduler(self):
        """Toggle the activity scheduler on/off."""
        if self._scheduler_running:
            stop_scheduler()
            self._scheduler_running = False
            self.scheduler_btn.config(text='⏰ Bật Lịch Tự Động', style='SchedulerOff.TButton')
            self.logger.info('Scheduler stopped')
        else:
            start_scheduler(
                status_callback=self._update_status,
                count=self._get_count()
            )
            self._scheduler_running = True
            self.scheduler_btn.config(text='⏰ Tắt Lịch Tự Động', style='Scheduler.TButton')
            self.logger.info('Scheduler started')
    
    def _on_stop(self):
        """Stop button clicked."""
        self.logger.info('Stop button clicked')
        state_stop()
        self._update_status('Đã dừng!')
        self.logger.info('Feature stopped')
    
    def _on_test(self):
        from features import feature_test
        self.logger.info('Test button clicked')
        self._run_feature(feature_test)
    
    def _on_change_name(self):
        from features import feature_change_win
        self.logger.info('Change name button clicked')
        feature_change_win()
    
    def _on_resize(self):
        """Resize button clicked."""
        self.logger.info('Resize button clicked')
        count = resize_all_games()
        messagebox.showinfo('Thông báo', f'Đã resize {count} cửa sổ game')
    
    def _on_enhance(self):
        from features import feature_enhance
        self.logger.info('Enhance clicked')
        self._run_feature(feature_enhance, self._get_count(), status_callback=self._update_status)
    
    def _on_rakhoi(self):
        from features import feature_rakhoi
        self.logger.info('Ra khoi clicked')
        self._run_feature(feature_rakhoi, self._get_count(), status_callback=self._update_status)
    
    def _on_nammoiphattai(self):
        from features import feature_nammoiphattai
        self.logger.info('Nam moi phat tai clicked')
        self._run_feature(feature_nammoiphattai, self._get_count(), status_callback=self._update_status)
    
    def _on_daily(self):
        from features import feature_daily
        self.logger.info('Daily clicked')
        self._run_feature(feature_daily, status_callback=self._update_status)
    
    def _on_anhhon(self):
        from features import feature_anhhon
        self.logger.info('Anh hon clicked')
        self._run_feature(feature_anhhon, self._get_count(), status_callback=self._update_status)
    
    def _on_tanconghaiquan(self):
        from features import feature_tanconghaiquan
        self.logger.info('Tan cong hai quan clicked')
        self._run_feature(feature_tanconghaiquan, status_callback=self._update_status)
    
    def _on_hoidapcothuong(self):
        from features import feature_hoidapcothuong
        self.logger.info('Hoi dap co thuong clicked')
        self._run_feature(feature_hoidapcothuong, status_callback=self._update_status)
    
    def _on_punk(self):
        from features import feature_punk
        self.logger.info('Punk clicked')
        self._run_feature(feature_punk, status_callback=self._update_status)
    
    def _on_kraken(self):
        from features import feature_kraken
        self.logger.info('Kraken clicked')
        self._run_feature(feature_kraken, status_callback=self._update_status)
    
    def _on_kaido(self):
        from features import feature_kaido
        self.logger.info('Kaido clicked')
        self._run_feature(feature_kaido, status_callback=self._update_status)
    
    def _on_quest(self):
        from features import feature_quest
        self.logger.info('Quest clicked')
        self._run_feature(feature_quest, status_callback=self._update_status)
    
    def _on_lich_su_kien(self):
        from features import feature_lich_su_kien
        self.logger.info('Lich su kien clicked')
        feature_lich_su_kien()
    
    def _on_haitacthongthai(self):
        from features import feature_haitacthongthai
        self.logger.info('Hai tac thong thai clicked')
        self._run_feature(feature_haitacthongthai, status_callback=self._update_status)
    
    def _on_tam_bao_chien(self):
        from features import feature_tam_bao_chien
        self.logger.info('Tam bao chien clicked')
        self._run_feature(feature_tam_bao_chien, status_callback=self._update_status)
    
    def _on_register_uta(self):
        from features import feature_register_uta
        self.logger.info('Register Uta World clicked')
        self._run_feature(feature_register_uta, status_callback=self._update_status)
    
    def _on_giftcode_dialog(self):
        """Open gift code input dialog."""
        dialog = tk.Toplevel(self.root)
        dialog.title('Nhập Gift Code')
        dialog.geometry('400x300')
        dialog.transient(self.root)
        dialog.grab_set()
        
        ttk.Label(dialog, text='Nhập gift code (mỗi dòng 1 code):', font=('Arial', 10)).pack(pady=10)
        
        text_frame = ttk.Frame(dialog)
        text_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        code_text = tk.Text(text_frame, height=8, width=40, font=('Consolas', 9))
        code_text.pack(fill=tk.BOTH, expand=True)
        
        btn_frame = ttk.Frame(dialog)
        btn_frame.pack(fill=tk.X, padx=10, pady=10)
        
        def submit_codes():
            codes = code_text.get('1.0', tk.END).strip()
            if not codes:
                messagebox.showwarning('Cảnh báo', 'Vui lòng nhập gift code!')
                return
            dialog.destroy()
            from features import feature_giftcode
            self._run_feature(feature_giftcode, codes, status_callback=self._update_status)
        
        ttk.Button(btn_frame, text='✅ Gửi', command=submit_codes).pack(side=tk.LEFT, padx=5, fill=tk.X, expand=True)
        ttk.Button(btn_frame, text='❌ Huỷ', command=dialog.destroy).pack(side=tk.LEFT, padx=5, fill=tk.X, expand=True)
    
    def on_close(self):
        """Window close event."""
        if get_is_running():
            if messagebox.askyesno('Xác nhận', 'Có tính năng đang chạy. Bạn có chắc muốn thoát?'):
                state_stop()
                if self._scheduler_running:
                    stop_scheduler()
                self.logger.info('Application closing')
                self.root.quit()
        else:
            if self._scheduler_running:
                stop_scheduler()
            self.logger.info('Application closing')
            self.root.quit()
    
    def run(self):
        """Start the GUI main loop."""
        self.logger.info('Starting GUI main loop')
        self.root.mainloop()
