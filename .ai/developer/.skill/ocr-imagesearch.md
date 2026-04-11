# OCR and ImageSearch Skill (AHK2)

## Mục tiêu
Xây pipeline nhận diện hybrid cho các UI không có control API.

## Quy trình chuẩn
1. Thu hẹp vùng tìm kiếm (region).
2. ImageSearch với nhiều template.
3. Click mục tiêu vừa tìm được.
4. OCR vùng text quan trọng.
5. Normalize text rồi so sánh điều kiện.
6. Retry có giới hạn + refresh khi fail.

## Pattern ImageSearch multi-template

```autohotkey
FindAnyImage(imagePaths, x1, y1, x2, y2) {
    foundX := 0, foundY := 0
    for imagePath in imagePaths {
        if ImageSearch(&foundX, &foundY, x1, y1, x2, y2, "*C0 " imagePath)
            return { ok: true, x: foundX, y: foundY, image: imagePath }
    }
    return { ok: false }
}
```

## Normalize OCR text

```autohotkey
NormalizeScoreText(rawText) {
    text := Trim(rawText)
    text := RegExReplace(text, "\s+", "")
    text := RegExReplace(text, "[^0-9]", "")
    return text
}
```

## Checklist chính xác
1. Dùng ảnh template cùng scale với app (100% DPI nếu có thể).
2. Ưu tiên region nhỏ để tăng tốc và giảm false positive.
3. OCR xong luôn normalize trước khi parse.
4. Retry tối đa N lần, tránh loop vô hạn.
5. Lưu screenshot khi fail để debug lần sau.
