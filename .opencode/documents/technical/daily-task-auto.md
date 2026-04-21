# Daily Task Auto (`Auto Nhiệm vụ hàng ngày`)

## Mục tiêu
Tự động làm nhiệm vụ hàng ngày theo rule ưu tiên 4 điểm, chỉ nhận task nằm trong 3 nhiệm vụ cần làm, và tự claim reward khi hết lượt (`remaining_tasks == 0`) với định hướng:
- **Image search** để nhận diện task/top3/UI.
- **OCR** chỉ để đọc số liệu (`remaining_tasks`, `point`, số lần còn lại nếu có hiển thị).

## Scope
- Áp dụng cho flow trong màn `Tính năng -> Hàng ngày`.
- Tập trung vào đọc UI + quyết định chọn task + refresh + claim reward.
- Không mô tả logic automation code chi tiết ngoài nghiệp vụ/thiết kế.
- Tài liệu này là feature độc lập, không thuộc tài liệu daily workflow 24 task/resume/multi-worker.

## Asset plan (`resources/images/...`)
```text
resources/images/daily_task/
  ui/
    daily_ready_*.png
    refresh_btn_*.png
    claim_btn_*.png
    reward_popup_*.png
  tasks/
    task_<task_key>_*.png
    task_<task_key>_alt_*.png
  top3/
    top3_<task_key>_*.png
    top3_<task_key>_alt_*.png
```

Nguyên tắc asset:
- Mỗi `task_key` có nhiều template (light/dark, active/inactive, scale khác nhau).
- Task trong list và task ở top3 để **2 nhóm template riêng** (`tasks/` và `top3/`) nhằm tăng độ chính xác matching.
- UI control quan trọng (refresh/claim/popup) có ít nhất 2 template fallback.

## Cấu trúc dữ liệu / config UI (gom ở đầu file)
> Bắt buộc: mọi tọa độ click, vùng quét OCR, điểm nhận diện UI phải nằm trong config tập trung; không hardcode rải rác trong flow xử lý.

```ahk
; MAP: toàn bộ anchor/toạ độ/vùng quét (không hardcode trong flow)
DAILY_TASK_UI := Map(
    "menu", Map(
        "featureButton", [0, 0],
        "dailyTabButton", [0, 0]
    ),
    "scanRegion", Map(
        "remainingTasks", [0, 0, 0, 0],
        "top3TaskRow", [0, 0, 0, 0],        ; image search top3
        "candidateTaskList", [0, 0, 0, 0],  ; image search task list
        "pointOnTaskCard", [0, 0, 0, 0],    ; OCR số điểm
        "remainingCountOnTaskCard", [0, 0, 0, 0], ; OCR số lần còn lại (optional)
        "rewardClaimButton", [0, 0, 0, 0],
        "refreshButton", [0, 0, 0, 0]
    ),
    "anchors", Map(
        "dailyScreenReady", [0, 0],
        "rewardPopup", [0, 0]
    )
)

; ARRAY: ưu tiên điểm task (feature hiện tại dùng 4 điểm là chính)
DAILY_TASK_PRIORITY_POINTS := [4]

; MAP-as-SET: tập task cần làm (lấy từ 3 tab trên)
; ví dụ: requiredTaskSet[taskKey] := true
requiredTaskSet := Map()

; SET task hợp lệ cho feature này
ALLOWED_TASK_KEYS := Map(
    "task_key_1", true,
    "task_key_2", true
)

; ARRAY/MAP: fallback template/image theo từng điểm nhận diện
DAILY_TASK_IMAGE_TEMPLATES := Map(
    "dailyScreenReady", ["daily_ready_1.png", "daily_ready_2.png"],
    "refreshButton", ["refresh_a.png", "refresh_b.png"],
    "claimButton", ["claim_a.png", "claim_b.png"],
    "rewardPopup", ["reward_popup_a.png", "reward_popup_b.png"]
)

; MAP: task template theo task_key cho list và top3
TASK_TEMPLATE_MAP := Map(
    "task_key_1", Map(
        "list", ["tasks/task_key_1_1.png", "tasks/task_key_1_2.png"],
        "top3", ["top3/task_key_1_1.png", "top3/task_key_1_2.png"]
    )
)
```

## Input UI cần đọc
| Input | Nguồn | Mục đích |
|---|---|---|
| `daily_screen_ready` | image search anchor UI | guard trước khi thao tác |
| `remaining_tasks` | OCR vùng số còn lượt | biết còn lượt hay đã hoàn thành |
| `top3_required_tasks` | image search 3 task ở tab trên | tạo tập task hợp lệ để lọc |
| `task_list_items` | image search task trong list | nhận diện `task_key` candidate |
| `point` | OCR trên task card | xác nhận task 4 điểm |
| `remaining_count_on_card` (optional) | OCR trên task card | đọc số lần còn lại nếu UI có hiển thị |
| `reward_claimable` | image search nút/trạng thái nhận thưởng | claim và kết thúc |

## Decision rules
1. Vào `Tính năng -> Hàng ngày`, xác nhận màn hình đúng bằng anchor.
2. OCR đọc `remaining_tasks`:
   - nếu `== 0` -> claim reward -> stop.
   - nếu `> 0` -> tiếp tục.
3. Image search nhận diện 3 nhiệm vụ ở tab trên -> build `requiredTaskSet`.
4. Image search quét danh sách task hiện tại để lấy `taskKey`, sau đó OCR vùng điểm/remaining của card; chỉ lấy task thoả đồng thời:
   - `point == 4`
   - `taskKey ∈ requiredTaskSet`
5. Nếu có >=1 task hợp lệ: chọn task theo thứ tự xuất hiện (hoặc tie-break config), thực thi task.
6. Nếu không có task hợp lệ: bấm refresh, đọc lại từ bước 2.
7. Refresh **không giới hạn** cho tới khi có task 4 điểm phù hợp trong top3 hoặc `remaining_tasks == 0`.

## Tiêu chí khớp image search
- Chỉ match trong đúng `scanRegion` tương ứng (`top3TaskRow`, `candidateTaskList`, `refreshButton`, `rewardClaimButton`).
- Mỗi key dùng nhiều template fallback; ưu tiên template theo trạng thái UI hiện tại trước.
- Một kết quả chỉ được chấp nhận khi:
  - confidence đạt ngưỡng config (ví dụ `>= 0.88`), và
  - vị trí không lệch ngoài vùng hợp lệ của card/tab.
- Nếu cùng `task_key` match nhiều vị trí, chọn vị trí có confidence cao nhất rồi verify lại bằng OCR điểm.
- Nếu fail liên tiếp vượt ngưỡng retry: log template đã thử + region + screenshot ngắn hạn để debug.

## State machine
```text
INIT
 -> OPEN_DAILY
  -> READ_REMAINING (OCR)
     -> (remaining == 0) CLAIM_REWARD -> DONE
     -> (remaining > 0) READ_TOP3 (ImageSearch)
  -> SCAN_TASK_LIST (ImageSearch + OCR point)
     -> (found point=4 AND in top3 set) EXECUTE_TASK -> READ_REMAINING
     -> (not found) REFRESH -> READ_REMAINING
  -> ERROR (timeout/ocr fail vượt ngưỡng) -> RETRY/STOP theo policy
```

## Pseudo-flow chuẩn
```text
start
  ensure daily screen ready
  loop:
    remaining = OCR read remaining_tasks
    if remaining == 0:
      claim reward
      return success

    top3 = imageSearch top3 tasks
    requiredSet = toSet(top3)

    list = imageSearch current task cards => task keys
    enrich list by OCR(point, optional remaining_count)
    candidate = first item where item.point == 4 and item.key in requiredSet

    if candidate exists:
      execute candidate
      wait UI stable + verify consumed progress
      continue

    click refresh
    wait refresh done
    continue
```

## Edge cases
- OCR đọc sai `remaining_tasks`/`point` (rỗng/ký tự lỗi): retry theo ngưỡng, log raw text + normalized text.
- Image search không nhận ra top3 vì đổi skin/theme: dùng template fallback và profile ảnh theo theme.
- Top 3 task trùng/alias khác nhau giữa top3 và list: map alias -> `task_key` chuẩn trước khi so khớp.
- Refresh lag hoặc button bị che popup: close popup, verify lại anchor rồi refresh lại.
- Có task 4 điểm nhưng không thuộc top3: bắt buộc bỏ qua, không click.
- Task đúng top3 nhưng OCR point không đọc được: tạm bỏ qua card đó trong vòng lặp hiện tại, refresh/scan lại.
- Claim reward xuất hiện chậm khi `remaining_tasks == 0`: polling ngắn có timeout.

## Tiêu chí hoàn thành
- Flow luôn đi qua `Tính năng -> Hàng ngày` trước khi xử lý.
- Khi còn lượt, chỉ thực thi task vừa 4 điểm vừa thuộc top3 required tasks.
- Refresh lặp vô hạn hợp lệ (không giới hạn vòng) cho đến khi có task 4 điểm phù hợp trong top3.
- Khi `remaining_tasks == 0`, reward được claim và flow dừng sạch.
- OCR chỉ dùng cho số liệu (`remaining_tasks`, `point`, optional remaining count trên card); nhận diện task/top3 dùng image search.
- Tất cả toạ độ/vùng OCR/anchor/template map nằm trong config tập trung đầu file (Map/Array/Set), không hardcode trong logic xử lý.
