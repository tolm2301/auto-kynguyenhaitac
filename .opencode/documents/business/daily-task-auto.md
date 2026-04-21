# Business Workflow - Auto Nhiệm vụ hàng ngày

## Mục tiêu
Tự động xử lý **riêng biệt** feature **Auto Nhiệm vụ hàng ngày** trong màn `Tính năng -> Hàng ngày`, theo hướng nhận diện bằng **image search** kết hợp đọc số liệu bằng **OCR**.

## Phạm vi
- Chỉ mô tả flow của feature **Auto Nhiệm vụ hàng ngày**.
- Không gộp/không nhập vào daily workflow 24 task.
- Không bao gồm resume state, multi-worker, stop file, timing worker.

## Luồng nghiệp vụ (image search + OCR)
```text
vào Tính năng -> Hàng ngày
 -> image search xác nhận màn Daily sẵn sàng
 -> OCR đọc remaining_tasks
 -> nếu remaining_tasks == 0: claim reward ngay -> dừng
 -> image search nhận diện 3 task ở tab trên (top3 required)
 -> image search nhận diện task trong list hiện tại
 -> OCR đọc point (và số lần còn lại nếu UI có hiển thị)
 -> lọc task vừa 4 điểm, vừa thuộc top3 required
 -> nếu có: chọn task phù hợp và thực thi
 -> nếu không có: refresh danh sách task
 -> lặp refresh không giới hạn đến khi có task 4 điểm phù hợp trong top3
 -> quay lại bước đọc remaining_tasks
```

## Rule chính
- Luôn ưu tiên task **4 điểm**.
- Task được chọn **phải thuộc 3 task cần làm** đang hiển thị ở tab trên.
- `refresh` **không giới hạn số lần** cho đến khi có task **4 điểm** phù hợp và nằm trong top3.
- Khi `remaining_tasks == 0` thì **claim reward ngay** và kết thúc flow.
- OCR chỉ dùng để đọc số: `remaining_tasks`, `point`, và số lần còn lại (nếu UI hiển thị).
- Nhận diện task/top3 ưu tiên bằng image search (không dựa OCR text task).

## Resource ảnh đề xuất
- `resources/images/daily_task/ui/`: ảnh nút/anchor UI Daily (ready, refresh, claim, popup...).
- `resources/images/daily_task/tasks/`: template ảnh nhận diện từng loại task trong danh sách.
- `resources/images/daily_task/top3/`: template ảnh nhận diện 3 task required ở tab trên.

## Điều kiện hoàn thành
- Reward đã claim khi hết lượt.
- Flow dừng sạch sau khi claim.
- Không thực thi task ngoài tập 3 task cần làm.
- Feature vẫn vận hành độc lập, không phụ thuộc tài liệu/flow daily 24 task.
