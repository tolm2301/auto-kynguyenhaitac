"""
Hỏi đáp có thưởng (Q&A with rewards) feature.

Chụp 1 lần toàn bộ dialog → OCR toàn bộ text → parse câu hỏi + đáp án
→ fuzzy match Question.ini → auto click đáp án.

Ported from AHK features/hoidapcothuong.ahk
"""

import re
import time
from pathlib import Path
from typing import Optional
from dataclasses import dataclass

from utils import get_logger, get_game_windows, resize_all_games, click_post, screenshot_region
from utils.state import set_running, stop as state_stop, get_is_running

logger = get_logger()

RESOURCES_DIR = Path(__file__).parent.parent / 'resources'
LOGS_DIR = Path(__file__).parent.parent / 'logs'
QUESTION_INI = RESOURCES_DIR / 'Question.ini'

# Tọa độ dialog "Hỏi đáp có thưởng" dạng x1, y1, x2, y2
DIALOG_REGION = (574, 148, 812, 280)

# Vùng câu hỏi (phần trên dialog)
QUESTION_REGION = (574, 148, 812, 184)

# Vùng đáp án A, B, C (bên phải hình nhân vật)
OPTION_REGIONS = {
    "A": {"x1": 622, "y1": 181, "x2": 888, "y2": 215, "click_x": 633, "click_y": 197},
    "B": {"x1": 622, "y1": 213, "x2": 888, "y2": 241, "click_x": 636, "click_y": 229},
    "C": {"x1": 622, "y1": 245, "x2": 815, "y2": 288, "click_x": 636, "click_y": 260},
}

# Nút "Xác định"
CONFIRM_BTN = {"x": 856, "y": 284}

# Ngưỡng fuzzy match (tiếng Việt nên cao hơn)
MATCH_THRESHOLD = 0.70
ANSWER_SIMILARITY_THRESHOLD = 0.40


@dataclass
class MatchResult:
    score: float
    question: str = ""
    answer: str = ""
    section: str = ""


@dataclass
class AnswerResult:
    letter: str
    score: float
    expected: str = ""


def _hoidap_log(msg: str) -> None:
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    log_path = LOGS_DIR / "hoidap.log"
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    try:
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(f"[{timestamp}] {msg}\n")
    except Exception as e:
        logger.error(f"Error writing hoidap log: {e}")


def _hoidap_reset_log() -> None:
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    log_path = LOGS_DIR / "hoidap.log"
    try:
        if log_path.exists():
            log_path.unlink()
    except Exception:
        pass


def _capture_and_ocr(hwnd: int) -> str:
    """
    Chụp 1 lần toàn bộ vùng dialog → OCR → trả về text gộp.
    Dùng tọa độ x1, y1, x2, y2.
    """
    try:
        x1, y1, x2, y2 = DIALOG_REGION
        w = x2 - x1
        h = y2 - y1
        
        img = screenshot_region(x1, y1, w, h, hwnd)
        if img is None:
            _hoidap_log("Chụp screenshot thất bại")
            return ""

        from utils.ocr import OCRReader
        ocr = OCRReader(languages=['vi', 'en'], gpu=True)
        results = ocr.read_text(img)

        if not results:
            _hoidap_log("OCR không đọc được text nào")
            return ""

        # Gộp tất cả text lại, mỗi dòng 1 entry
        lines = []
        for item in results:
            if isinstance(item, tuple) and len(item) >= 2:
                text = item[1] if isinstance(item[1], str) else str(item[1])
                lines.append(text.strip())

        full_text = '\n'.join(lines)
        _hoidap_log(f"OCR full text ({len(lines)} lines):\n{full_text}")
        return full_text

    except Exception as e:
        logger.error(f"Error capture+OCR: {e}")
        _hoidap_log(f"Error capture+OCR: {e}")
        return ""


def _parse_ocr_text(full_text: str) -> dict:
    """
    Parse OCR text để lấy câu hỏi và các đáp án.
    OCR thường đọc sai chính tả và KHÔNG có prefix A:, B:, C:
    nên phải parse linh hoạt theo cấu trúc: dòng chứa "câu" = question, các dòng còn lại = options.

    Ví dụ OCR output:
        IUi DArcuinuuna
        Câu hói: Ban đâu đinh do Ussop là
        Đầu bếp
        Thuyền phó
    """
    result = {
        'question': '',
        'options': {'A': '', 'B': '', 'C': ''},
    }

    lines = [l.strip() for l in full_text.replace('\r', '').split('\n') if l.strip()]

    # --- Tìm câu hỏi: dòng đầu tiên chứa "câu" (linh hoạt chính tả) ---
    question_idx = -1
    for i, line in enumerate(lines):
        # Match: "câu", "cau", "cau hoi", "câu hói", "cau hoi", v.v.
        if re.search(r"(?i)c[âa]u", line):
            question_idx = i
            # Lấy phần sau "câu hỏi:" hoặc "câu hói:" hoặc "cau hoi:"
            result['question'] = re.sub(r"(?i)c[âa]u\s*h[óoi]\s*[:\-]?\s*", "", line).strip()
            break

    if question_idx < 0:
        _hoidap_log(f"Không tìm thấy dòng câu hỏi trong {len(lines)} lines")
        return result

    # --- Các dòng còn lại (sau dòng câu hỏi) là đáp án A, B, C ---
    answer_lines = []
    for i in range(question_idx + 1, len(lines)):
        line = lines[i]
        # Lọc bỏ các dòng rác / UI text
        if re.search(r"(?i)xác\s*định|nhận\s*thưởng|xem.*thưởng|trả\s*lời|lần|t\.?g\s*hd|túi|cường\s*cấp|đáp\s*án", line):
            continue
        if len(line) < 2:
            continue
        answer_lines.append(line)

    # Gán theo thứ tự A, B, C
    letters = ['A', 'B', 'C']
    for i, line in enumerate(answer_lines):
        if i < len(letters):
            result['options'][letters[i]] = line.strip()

    _hoidap_log(f"Parsed | Q=[{result['question']}] A=[{result['options']['A']}] B=[{result['options']['B']}] C=[{result['options']['C']}]")
    return result


def _clean_question(text: str) -> str:
    q = text.strip()
    q = re.sub(r"(?i)thoi\s*gian\s*tra\s*loi\s*con.*$", "", q)
    q = re.sub(r"\s+", " ", q)
    return q.strip()


def _normalize_for_match(text: str) -> str:
    """Normalize text cho fuzzy matching."""
    t = text.strip().lower()
    t = re.sub(r"(?i)thoi\s*gian\s*tra\s*loi\s*con.*$", "", t)
    # Fix OCR errors
    t = re.sub(r"(?<=[a-z])[06](?=[a-z])", "o", t)
    t = re.sub(r"(?<=[a-z])1(?=[a-z])", "i", t)
    t = re.sub(r"(?<=[a-z])5(?=[a-z])", "s", t)
    t = re.sub(r"(?<=[a-z])4(?=[a-z])", "a", t)
    t = re.sub(r"[^a-z0-9]+", " ", t)
    t = re.sub(r"\s+", " ", t)
    return t.strip()


def _levenshtein_similarity(s1: str, s2: str) -> float:
    L1, L2 = len(s1), len(s2)
    if L1 == 0 or L2 == 0:
        return 0.0
    s1, s2 = s1.lower(), s2.lower()
    max_len = max(L1, L2)
    dist = [[0] * (L2 + 1) for _ in range(L1 + 1)]
    for i in range(L1 + 1):
        dist[i][0] = i
    for j in range(L2 + 1):
        dist[0][j] = j
    for i in range(1, L1 + 1):
        for j in range(1, L2 + 1):
            cost = 0 if s1[i - 1] == s2[j - 1] else 1
            dist[i][j] = min(dist[i - 1][j] + 1, dist[i][j - 1] + 1, dist[i - 1][j - 1] + cost)
    return 1.0 - (dist[L1][L2] / max_len)


def _token_overlap_score(a: str, b: str) -> float:
    tokens_a = _split_tokens(a)
    tokens_b = _split_tokens(b)
    if not tokens_a or not tokens_b:
        return 0.0
    hit = sum(1 for t in tokens_a if _array_has_token(tokens_b, t))
    return hit / len(tokens_a)


def _split_tokens(text: str) -> list[str]:
    tokens = []
    i = 0
    while i < len(text):
        m = re.match(r"[a-z0-9]{3,}", text[i:])
        if m:
            tokens.append(m.group(0))
            i += len(m.group(0))
        else:
            i += 1
    return tokens


def _array_has_token(arr: list[str], token: str) -> bool:
    for v in arr:
        if v == token or token in v or v in token:
            return True
    return False


def _find_best_match(search_str: str, threshold: float = MATCH_THRESHOLD) -> MatchResult:
    """Tìm best fuzzy match trong Question.ini (tất cả sections)."""
    if not QUESTION_INI.exists():
        _hoidap_log(f"Question.ini not found at {QUESTION_INI}")
        return MatchResult(score=0.0)

    search_norm = _normalize_for_match(search_str)
    if not search_norm:
        return MatchResult(score=0.0)
    search_compact = search_norm.replace(" ", "")

    best_score = 0.0
    best_tie = -1.0
    matched_q = ""
    matched_a = ""
    matched_section = ""
    candidates = []

    try:
        current_section = ""
        with open(QUESTION_INI, 'r', encoding='utf-8') as f:
            for row in f:
                row = row.strip()
                if not row:
                    continue
                sec_match = re.match(r"^\[(.+)\]$", row)
                if sec_match:
                    current_section = sec_match.group(1).strip()
                    continue
                pos = row.find('=')
                if pos == -1:
                    continue
                file_q = row[:pos].strip()
                file_a = row[pos + 1:].strip()
                if not file_q or not file_a:
                    continue

                file_norm = _normalize_for_match(file_q)
                file_compact = file_norm.replace(" ", "")

                char_score = _levenshtein_similarity(search_compact, file_compact)
                token_score = _token_overlap_score(search_norm, file_norm)
                blend_score = (char_score * 0.65 + token_score * 0.35)
                current_score = max(char_score, token_score, blend_score)
                tie_breaker = (token_score * 0.001) + (char_score * 0.0001)

                if current_score >= threshold:
                    candidates.append({
                        "score": current_score, "token": token_score,
                        "char": char_score, "blend": blend_score,
                        "tie": tie_breaker, "section": current_section, "question": file_q,
                    })

                if (current_score > best_score or
                        (abs(current_score - best_score) < 0.000001 and tie_breaker > best_tie)):
                    best_score = current_score
                    best_tie = tie_breaker
                    matched_q = file_q
                    matched_a = file_a
                    matched_section = current_section

        if candidates:
            _hoidap_log(f"Candidates (>= {threshold}): {len(candidates)}")
            for c in candidates[:5]:
                _hoidap_log(f"  score={c['score']:.4f} | {c['section']} | Q={c['question']}")
        else:
            _hoidap_log(f"No candidates >= {threshold}")

        if best_score >= threshold:
            return MatchResult(score=best_score, question=matched_q, answer=matched_a, section=matched_section)
        return MatchResult(score=0.0)

    except Exception as e:
        logger.error(f"Error finding match: {e}")
        return MatchResult(score=0.0)


def _normalize_answer(text: str) -> str:
    value = text.strip().lower()
    value = re.sub(r"^[abc]\s*[:\-\.]\s*", "", value)
    value = re.sub(r"[^a-z0-9]+", "", value)
    return value


def _extract_answer_value(text: str) -> str:
    text = text.strip()
    m = re.match(r"^[ABCabc]\s*[:\-\.]\s*(.+)$", text)
    return m.group(1).strip() if m else text


def _extract_answer_letter(text: str) -> str:
    text = text.strip()
    m = re.match(r"^([ABCabc])\s*[:\-\.]", text)
    return m.group(1).upper() if m else ""


def _extract_option_value(text: str, letter: str) -> str:
    text = text.replace('\r', '').strip()
    m = re.match(r"^" + letter + r"\s*[:\-\.]\s*(.+)$", text)
    if m:
        return m.group(1).strip()
    m = re.match(r"^[ABCabc]\s*[:\-\.]\s*(.+)$", text)
    if m:
        return m.group(1).strip()
    return text


def _answer_similarity(expected: str, candidate: str) -> float:
    """So sánh đáp án expected với option candidate."""
    # Numeric comparison
    num_a = re.search(r"(\d+(?:[\.,]\d+)?)", expected)
    num_b = re.search(r"(\d+(?:[\.,]\d+)?)", candidate)
    if num_a or num_b:
        na = num_a.group(1).replace(",", ".") if num_a else ""
        nb = num_b.group(1).replace(",", ".") if num_b else ""
        if na == nb and na:
            return 1.0
        return 0.1

    if expected == candidate:
        return 1.0

    # Substring bonus
    if candidate in expected or expected in candidate:
        min_len = min(len(expected), len(candidate))
        max_len = max(len(expected), len(candidate))
        return 0.9 + (min_len / max_len) * 0.1

    return _levenshtein_similarity(expected, candidate)


def _pick_answer(answer_text: str, option_map: dict[str, str]) -> AnswerResult:
    """Chọn đáp án A/B/C tốt nhất."""
    expected = _normalize_answer(_extract_answer_value(answer_text))
    fallback_letter = _extract_answer_letter(answer_text)

    if not expected:
        return AnswerResult(letter="", score=0.0, expected=expected)

    best_letter = ""
    best_score = -1.0
    second_score = -1.0
    detail = ""
    has_any = False

    for letter in ["A", "B", "C"]:
        if letter not in option_map:
            continue
        opt = _extract_option_value(option_map[letter], letter)
        opt_norm = _normalize_answer(opt)
        if not opt_norm:
            continue
        has_any = True
        score = _answer_similarity(expected, opt_norm)
        detail += f"{letter}={score:.3f} "
        if score > best_score:
            second_score = best_score
            best_score = score
            best_letter = letter
        elif score > second_score:
            second_score = score

    gap = best_score - second_score
    _hoidap_log(f"Answer | expected={expected} | {detail.strip()} | best={best_score:.3f} gap={gap:.3f} pick={best_letter}")

    if not has_any and fallback_letter:
        _hoidap_log(f"Fallback INI letter={fallback_letter}")
        return AnswerResult(letter=fallback_letter, score=0.0, expected=expected)

    if not best_letter:
        return AnswerResult(letter="", score=0.0, expected=expected)

    if best_score < ANSWER_SIMILARITY_THRESHOLD:
        if fallback_letter:
            _hoidap_log(f"Low confidence, fallback INI letter={fallback_letter}")
            return AnswerResult(letter=fallback_letter, score=best_score, expected=expected)
        _hoidap_log("Low confidence, skip")
        return AnswerResult(letter="", score=best_score, expected=expected)

    return AnswerResult(letter=best_letter, score=best_score, expected=expected)


def _click_answer(hwnd: int, letter: str) -> bool:
    if letter not in OPTION_REGIONS:
        return False
    cfg = OPTION_REGIONS[letter]
    click_post(hwnd, cfg["click_x"], cfg["click_y"])
    time.sleep(0.5)
    # click_post(hwnd, CONFIRM_BTN["x"], CONFIRM_BTN["y"])
    # time.sleep(0.5)
    return True


def _auto_answer(hwnd: int) -> None:
    """
    Flow:
    1. Chụp 1 lần toàn dialog → OCR
    2. Parse câu hỏi + đáp án
    3. Fuzzy match Question.ini
    4. So sánh đáp án INI với OCR options → pick A/B/C
    5. Click
    """
    # Bước 1: Chụp + OCR (1 lần duy nhất)
    full_text = _capture_and_ocr(hwnd)
    if not full_text:
        _hoidap_log("OCR thất bại, không có text")
        return

    # Bước 2: Parse
    parsed = _parse_ocr_text(full_text)
    question = _clean_question(parsed['question'])
    if not question:
        _hoidap_log("Không parse được câu hỏi")
        return

    # Bước 3: Fuzzy match
    best = _find_best_match(question, MATCH_THRESHOLD)
    if best.score <= 0:
        _hoidap_log(f"Không match (>= {MATCH_THRESHOLD}) | Q: {question}")
        return

    _hoidap_log(f"MATCH | score={best.score:.3f} | [{best.section}] Q={best.question} | A={best.answer}")

    # Bước 4: Pick answer từ OCR options
    result = _pick_answer(best.answer, parsed['options'])
    if not result.letter:
        _hoidap_log(f"Không xác định đáp án | Q: {question}")
        return

    # Bước 5: Click
    if _click_answer(hwnd, result.letter):
        _hoidap_log(f"Đã trả lời {result.letter} | score={result.score:.3f}")


def feature_hoidapcothuong(status_callback=None) -> bool:
    """
    Feature: Hỏi đáp có thưởng.
    Chụp 1 lần → OCR → fuzzy match → auto click.
    """
    _hoidap_reset_log()
    resize_all_games()
    hwnds = get_game_windows()

    if not hwnds:
        logger.error("Không tìm thấy cửa sổ game")
        state_stop()
        return False

    if status_callback:
        status_callback("Tính năng đang chạy: Hỏi đáp có thưởng")

    set_running("Hỏi đáp có thưởng", None, status_callback)
    logger.info(f"Starting Hỏi đáp có thưởng for {len(hwnds)} windows")

    try:
        hwnd = hwnds[0]
        _auto_answer(hwnd)
    except Exception as e:
        logger.error(f"Hỏi đáp có thưởng error: {e}")
        _hoidap_log(f"Error: {e}")
    finally:
        state_stop()

    logger.info("Feature hoidapcothuong completed")
    return True


def stop():
    state_stop()
    logger.info('Feature stop requested')
