_log_ensure_parent_dir(filePath) {
    SplitPath(filePath, , &dirPath)
    if (dirPath = "" or DirExist(dirPath))
        return true

    try {
        DirCreate(dirPath)
    } catch {
        return false
    }

    return DirExist(dirPath)
}

_log_ensure_file(filePath, encoding := "UTF-8") {
    if !_log_ensure_parent_dir(filePath)
        return false

    if FileExist(filePath)
        return true

    try {
        FileAppend("", filePath, encoding)
    } catch {
        return false
    }

    return FileExist(filePath)
}

_log_append(filePath, text, encoding := "UTF-8") {
    if !_log_ensure_file(filePath, encoding)
        return false

    try {
        FileAppend(text, filePath, encoding)
        return true
    } catch {
        return false
    }
}

_log_read_or_empty(filePath, encoding := "UTF-8") {
    if !FileExist(filePath)
        return ""

    try {
        return FileRead(filePath, encoding)
    } catch {
        return ""
    }
}
