Kịch bản: Phát triển Module Auto Questing cho Kỷ Nguyên Hải Tặc
1. Vai trò của AI (Role)
"Bạn là một Senior Python Developer chuyên về Game Automation. Bạn có kinh nghiệm về Clean Architecture, Domain-Driven Design (DDD) và xử lý ảnh bằng OpenCV, PyWin32, EasyOCR."

2. Bối cảnh & Cấu trúc (Context)
"Tôi đang phát triển tool auto cho game 'Kỷ Nguyên Hải Tặc'. Cấu trúc dự án hiện có:

utils/window.py: Chứa hàm click(x, y), screenshot().

utils/ocr.py: Wrapper cho EasyOCR.

features/: Nơi đặt logic các tính năng.

resources/: Chứa ảnh template (.png)."

3. Mô tả Logic Nghiệp vụ (Business Logic)
"Hãy viết module features/questing.py để thực hiện chuỗi hành động sau:

A. Trạng thái Tab Nhiệm vụ (Right Panel):

Sử dụng OCR để quét vùng tọa độ Tab nhiệm vụ (bên phải màn hình).

Nếu thấy text chứa [Chính] và (Có thể hoàn thành) -> Click vào tọa độ đó để nhân vật tự tìm NPC trả nhiệm vụ.

Nếu thấy text chứa [Chính] nhưng không có chữ 'hoàn thành' -> Click để nhân vật đi làm nhiệm vụ.

B. Trạng thái Hội thoại (Dialogue handling):

Ưu tiên 1: Nếu phát hiện nút 'Bỏ Qua' (dùng ImageSearch/Template Matching) -> Click ngay.

Ưu tiên 2: Nếu thấy nút 'Tiếp theo' hoặc dấu mũi tên vàng hội thoại -> Click.

Ưu tiên 3: Nếu hiện bảng 'Hoàn thành NV' (có nút nhận thưởng Beri, Exp) -> Click nút 'Hoàn thành'.

C. Xử lý kẹt (Anti-Stuck):

Nếu sau 5 giây không có thay đổi màn hình, thực hiện click vào Tab nhiệm vụ để reset trạng thái di chuyển."

4. Yêu cầu Kỹ thuật (Technical Requirements)
Dùng OpenCV (Template Matching): Để tìm chính xác các nút bấm có icon cố định. Thiết lập ngưỡng threshold=0.8.

Dùng EasyOCR + RapidFuzz: Để xử lý text Tiếng Việt không dấu/có dấu từ tab nhiệm vụ.

Thiết kế theo Class: Cấu trúc module phải có class QuestManager, các hàm xử lý phải tách biệt (ví dụ: check_dialog(), check_task_panel(), execute()).

Logging: Log lại mọi hành động (ví dụ: [INFO] Phát hiện nút Bỏ qua, đang thực hiện click...).

Non-blocking: Đảm bảo code có thể chạy trong một vòng lặp while mà không làm treo GUI."

🛠️ Gợi ý thêm cho ông về cách tổ chức File Ảnh (Resources)
Để AI viết code chạy được ngay, ông nên chuẩn bị sẵn các file ảnh nhỏ (crop từ màn hình game) và đặt tên như sau để AI dễ gọi:

btn_skip.png: Nút Bỏ Qua.

btn_next.png: Nút Tiếp Theo/Mũi tên vàng.

btn_finish_quest.png: Nút Hoàn Thành trong bảng nhận thưởng.

icon_main_quest.png: Icon chữ [Chính] nếu OCR không ổn định.


Kịch bản Bổ sung: Xử lý Hội thoại & Click Vùng Trống
1. Thêm Logic Nhận diện "Màn hình Hội thoại"
"Ngoài việc tìm nút, Agent cần nhận diện xem game có đang trong trạng thái hội thoại hay không.

Dấu hiệu: Xuất hiện khung text ở cạnh dưới màn hình (thường có màu tối/nâu đặc trưng) hoặc màn hình bị làm mờ xung quanh nhân vật NPC.

Hành động: Nếu không tìm thấy nút 'Bỏ qua' (Skip) hay 'Tiếp theo' (Next), nhưng OCR vẫn đọc được text trong vùng hội thoại -> Thực hiện Safe Click."

2. Định nghĩa "Vùng Safe Click" (Vùng 100%)
"Hãy thiết lập một tọa độ điểm gọi là SAFE_CLICK_ZONE.

Vị trí: Thường là vùng trống ở giữa màn hình hoặc phía trên khung hội thoại một chút (để tránh click nhầm vào các nút chức năng khác).

Phím tắt: Thêm option gửi phím Esc thông qua post_message.py để thoát nhanh các thông báo hoặc popup phần thưởng như trong ảnh image_0a9636.jpg."

3. Logic "Click để tiếp tục" (Smart Wait)
"Viết một hàm handle_dialogue_flow() với kịch bản sau:

Kiểm tra ảnh template btn_skip.png -> Có thì click.

Không có skip, kiểm tra btn_next.png -> Có thì click.

Nếu cả 2 đều không có, nhưng màn hình đang đứng yên (pixel không đổi) và đang trong mode làm quest:

Thực hiện win.post_click(SAFE_X, SAFE_Y) (Click vùng trống).

Hoặc win.post_key(VK_ESCAPE) (Gửi phím Esc).

Nghỉ (Sleep) khoảng 0.5s - 1s để tránh click quá nhanh làm lag game."