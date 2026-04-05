# GUI Automation Skills - AHK2

## 1. GUI Structure Pattern

```autohotkey
; Khởi tạo GUI với tên và title
myGui := Gui("", "Auto VHT")
myGui.Icon := A_ScriptDir . "\resources\icon.ico"

; Thêm controls
myGui.AddText("x10 y10 w200 h30", "Label text")
myGui.AddEdit("w50 h30 vInputCount x100 y10", "default")
myGui.AddButton("w200 h30 x10 y130", "Button Text")

; Tab control
myTab := myGui.AddTab("x10 y105 w210 h310", ["Tab1", "Tab2", "Tab3"])
myTab.UseTab(1)  ; Chuyển sang tab 1
```

## 2. Event Handling

```autohotkey
; Button click event
btnName.OnEvent("Click", (*) => myFunction())

; Checkbox event
chkBox.OnEvent("Change", (*) => myFunction(chkBox.Value))

; GUI Close event
myGui.OnEvent("Close", (*) => ExitApp())
```

## 3. Control Types

| Control | Creation | Properties |
|---------|----------|------------|
| Text | `AddText` | .Value |
| Edit | `AddEdit` | .Value |
| Button | `AddButton` | OnEvent |
| Checkbox | `AddCheckbox` | .Value |
| DropDownList | `AddDropDownList` | .Add, .Choose |
| ListBox | `AddListBox` | .Add, .Choose |
| Slider | `AddSlider` | .Value |
| Progress | `AddProgress` | .Value |

## 4. Dynamic Updates

```autohotkey
; Cập nhật text
g_featureText.Value := "New text"

; Lấy giá trị input
value := g_inputCount.Value

; Enable/Disable button
btnSome.Button.Enabled := false
```

## 5. Common Coordinates

```
x10, y10           : Vị trí góc trên trái
w200, h30          : Kích thước width, height
x+10, y+10         : Offset từ vị trí hiện tại
vVariableName      : Biến liên kết với control
```

## 6. Tích hợp Feature vào GUI

```autohotkey
; Trong gui_main.ahk
btnFeature := myGui.AddButton("w200 h30 x10 y200", "Feature Name")
btnFeature.OnEvent("Click", (*) => _feature_myfeature())

; Trong features/myfeature.ahk
_feature_myfeature() {
    global isRunning, g_featureText
    isRunning := true
    g_featureText.text := "Tính năng: My Feature"
    
    ; Logic code here
    
    isRunning := false
}
```

## 7. Best Practices

1. Luôn có `isRunning` global flag để stop được
2. Update `g_featureText` để hiển thị trạng thái
3. Sử dụng tab để nhóm related features
4. Đặt tên biến có prefix `g_` cho GUI controls global
5. Include `#Requires AutoHotkey v2.0` đầu file
6. Không include utils ở feature file (đã có ở main)