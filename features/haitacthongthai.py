"""
Hải tặc thông thái (Wise Pirate) feature.

Uses OCR to read questions and fuzzy-match against Question.ini database
to automatically select answers for the quiz event.

Ported from AHK features/haitacthongthai.ahk
"""

import os
import re
import time
import configparser
from pathlib import Path
from typing import Optional
from dataclasses import dataclass

from utils import get_logger, get_game_windows, resize_all_games, click_post, OCRReader, screenshot_region
from utils.state import set_running, stop as state_stop, get_is_running

logger = get_logger()

RESOURCES_DIR = Path(__file__).parent.parent / 'resources'
LOGS_DIR = Path(__file__).parent.parent / 'logs'
QUESTION_INI = RESOURCES_DIR / 'Question.ini'

# Option button config (x1, y1, x2, y2, click_x, click_y)
OPTION_CONFIG = {
    "A": {"ocr_x1": 290, "ocr_y1": 352, "ocr_x2": 974, "ocr_y2": 403, "click_x": 318, "click_y": 377},
    "B": {"ocr_x1": 290, "ocr_y1": 405, "ocr_x2": 974, "ocr_y2": 457, "click_x": 318, "click_y": 430},
    "C": {"ocr_x1": 290, "ocr_y1": 460, "ocr_x2": 974, "ocr_y2": 509, "click_x": 318, "click_y": 486},
    "D": {"ocr_x1": 290, "ocr_y1": 516, "ocr_x2": 974, "ocr_y2": 559, "click_x": 318, "click_y": 534},
}

CONFIRM_BUTTON = {"x": 907, "y": 584}

# Question OCR region
QUESTION_REGION = (294, 190, 977, 340)

# Similarity threshold for answer matching
SIMILARITY_THRESHOLD = 0.40
MATCH_THRESHOLD = 0.6


@dataclass
class MatchResult:
    """Result of fuzzy question matching."""
    score: float
    question: str = ""
    answer: str = ""


@dataclass
class AnswerResult:
    """Result of answer picking."""
    letter: str
    score: float


def _httt_log(msg: str) -> None:
    """Write to haitacthongthai log file."""
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    log_path = LOGS_DIR / "haitacthongthai.log"
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    try:
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(f"[{timestamp}] {msg}\n")
    except Exception as e:
        logger.error(f"Error writing HTTT log: {e}")


def _httt_reset_log() -> None:
    """Reset the HTTT log file."""
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    log_path = LOGS_DIR / "haitacthongthai.log"
    try:
        if log_path.exists():
            log_path.unlink()
    except Exception:
        pass


def _read_question(hwnd: int) -> str:
    """OCR the question text from the game window."""
    try:
        ocr = OCRReader()
        x1, y1, x2, y2 = QUESTION_REGION
        result = ocr.read_region(hwnd, x1, y1, x2, y2)
        return result
    except Exception as e:
        logger.error(f"Error reading question: {e}")
        return ""


def _read_options(hwnd: int) -> dict[str, str]:
    """OCR all option texts from the game window."""
    option_map = {}
    try:
        ocr = OCRReader()
        for letter, cfg in OPTION_CONFIG.items():
            text = ocr.read_region(hwnd, cfg["ocr_x1"], cfg["ocr_y1"], cfg["ocr_x2"], cfg["ocr_y2"])
            option_map[letter] = text
        _httt_log(f"OCR options | A=[{option_map.get('A', '')}] B=[{option_map.get('B', '')}] "
                   f"C=[{option_map.get('C', '')}] D=[{option_map.get('D', '')}]")
    except Exception as e:
        logger.error(f"Error reading options: {e}")
    return option_map


def _clean_question_text(text: str) -> str:
    """Clean up OCR question text."""
    q = text.strip()
    # Remove "thời gian trả lời còn..." suffix
    q = re.sub(r"(?i)thoi\s*gian\s*tra\s*loi\s*con.*$", "", q)
    q = re.sub(r"\s+", " ", q)
    return q.strip()


def _extract_answer_value(answer_text: str) -> str:
    """Extract the actual answer value from text like 'A: some answer'."""
    text = answer_text.strip()
    match = re.match(r"^[ABCDabcd]\s*[:\-\.)]\s*(.+)$", text)
    if match:
        return match.group(1).strip()
    return text


def _extract_option_value(option_text: str, letter: str) -> str:
    """Extract the actual option value from text like 'A: some option'."""
    text = option_text.strip().replace('\r', '')
    match = re.match(r"^" + letter + r"\s*[:\-\.)]\s*(.+)$", text)
    if match:
        return match.group(1).strip()
    match = re.match(r"^[ABCDabcd]\s*[:\-\.)]\s*(.+)$", text)
    if match:
        return match.group(1).strip()
    return text


def _normalize(text: str) -> str:
    """Normalize text for comparison."""
    value = text.strip().lower()
    value = re.sub(r"^[abcd]\s*[:\-\.)]\s*", "", value)
    value = re.sub(r"[^a-z0-9]+", "", value)
    return value


def _normalize_for_match(text: str) -> str:
    """Normalize text for fuzzy matching."""
    t = text.strip().lower()
    t = re.sub(r"(?i)thoi\s*gian\s*tra\s*loi\s*con.*$", "", t)
    t = re.sub(r"[^a-z0-9]+", " ", t)
    t = re.sub(r"\s+", " ", t)
    return t.strip()


def _extract_number_token(text: str) -> str:
    """Extract number from text for numeric comparison."""
    match = re.search(r"(\d+(?:[\.,]\d+)?)", text)
    if match:
        return match.group(1).replace(",", ".")
    return ""


def _levenshtein_similarity(s1: str, s2: str) -> float:
    """Calculate Levenshtein-based similarity ratio."""
    L1, L2 = len(s1), len(s2)
    if L1 == 0 or L2 == 0:
        return 0.0

    s1, s2 = s1.lower(), s2.lower()
    max_len = max(L1, L2)

    # Build distance matrix
    dist = [[0] * (L2 + 1) for _ in range(L1 + 1)]
    for i in range(L1 + 1):
        dist[i][0] = i
    for j in range(L2 + 1):
        dist[0][j] = j

    for i in range(1, L1 + 1):
        for j in range(1, L2 + 1):
            cost = 0 if s1[i - 1] == s2[j - 1] else 1
            dist[i][j] = min(
                dist[i - 1][j] + 1,
                dist[i][j - 1] + 1,
                dist[i - 1][j - 1] + cost
            )

    return 1.0 - (dist[L1][L2] / max_len)


def _token_overlap_score(a: str, b: str) -> float:
    """Calculate token overlap score between two normalized strings."""
    tokens_a = _split_tokens(a)
    tokens_b = _split_tokens(b)

    if not tokens_a or not tokens_b:
        return 0.0

    hit = 0
    for token in tokens_a:
        if _array_has_token(tokens_b, token):
            hit += 1

    return hit / len(tokens_a)


def _split_tokens(text: str) -> list[str]:
    """Split text into tokens (3+ char alphanumeric sequences)."""
    tokens = []
    if not text:
        return tokens

    i = 0
    while i < len(text):
        match = re.match(r"[a-z0-9]{3,}", text[i:])
        if match:
            tokens.append(match.group(0))
            i += len(match.group(0))
        else:
            i += 1
    return tokens


def _array_has_token(arr: list[str], token: str) -> bool:
    """Check if token exists in array (exact or substring match)."""
    for v in arr:
        if v == token:
            return True
        if token in v or v in token:
            return True
    return False


def _similarity(a: str, b: str) -> float:
    """Calculate similarity between two normalized strings."""
    num_a = _extract_number_token(a)
    num_b = _extract_number_token(b)

    if num_a or num_b:
        if num_a == num_b and num_a:
            return 1.0
        return 0.1

    if a == b:
        return 1.0

    return _levenshtein_similarity(a, b)


def _find_fuzzy_match(section: str, search_str: str, threshold: float = MATCH_THRESHOLD) -> MatchResult:
    """Find best fuzzy match for search string in Question.ini."""
    if not QUESTION_INI.exists():
        _httt_log(f"Question.ini not found at {QUESTION_INI}")
        return MatchResult(score=0.0)

    search_norm = _normalize_for_match(search_str)
    if not search_norm:
        return MatchResult(score=0.0)

    search_compact = search_norm.replace(" ", "")

    try:
        config = configparser.ConfigParser()
        config.read(QUESTION_INI, encoding='utf-8')

        if section not in config:
            _httt_log(f"Section [{section}] not found in Question.ini")
            return MatchResult(score=0.0)

        best_score = 0.0
        best_tie = -1.0
        matched_q = ""
        matched_a = ""
        candidates = []

        for key, value in config[section].items():
            file_q = key
            file_a = value
            file_norm = _normalize_for_match(file_q)
            file_compact = file_norm.replace(" ", "")

            char_score = _levenshtein_similarity(search_compact, file_compact)
            token_score = _token_overlap_score(search_norm, file_norm)
            blend_score = (char_score * 0.65 + token_score * 0.35)
            current_score = max(char_score, token_score, blend_score)
            tie_breaker = (token_score * 0.001) + (char_score * 0.0001)

            if current_score >= threshold:
                candidates.append({
                    "score": current_score,
                    "token": token_score,
                    "char": char_score,
                    "blend": blend_score,
                    "tie": tie_breaker,
                    "question": file_q,
                })

            if (current_score > best_score or
                    (abs(current_score - best_score) < 0.000001 and tie_breaker > best_tie)):
                best_score = current_score
                best_tie = tie_breaker
                matched_q = file_q
                matched_a = file_a

        # Log candidates
        if not candidates:
            _httt_log(f"Threshold candidates | >= {threshold} | none")
        else:
            _httt_log(f"Threshold candidates | >= {threshold} | count={len(candidates)}")
            for item in candidates:
                _httt_log(
                    f"Candidate | score={item['score']:.6f} | "
                    f"token={item['token']:.6f} | char={item['char']:.6f} | "
                    f"blend={item['blend']:.6f} | tie={item['tie']:.6f} | Q={item['question']}"
                )

        if best_score >= threshold:
            return MatchResult(score=best_score, question=matched_q, answer=matched_a)

        return MatchResult(score=0.0)

    except Exception as e:
        logger.error(f"Error finding fuzzy match: {e}")
        return MatchResult(score=0.0)


def _pick_answer(answer_text: str, option_map: dict[str, str]) -> AnswerResult:
    """Pick the best answer option based on fuzzy matching."""
    expected = _normalize(_extract_answer_value(answer_text))
    best_letter = ""
    best_score = -1.0
    second_score = -1.0
    score_log = ""

    for letter in ["A", "B", "C", "D"]:
        if letter not in option_map:
            continue

        option_value = _extract_option_value(option_map[letter], letter)
        option_norm = _normalize(option_value)
        if not option_norm:
            continue

        score = _similarity(expected, option_norm)
        score_log += f"{letter}={score:.3f} "

        if score > best_score:
            second_score = best_score
            best_score = score
            best_letter = letter
        elif score > second_score:
            second_score = score

    gap = best_score - second_score
    _httt_log(
        f"Answer score | expected={expected} | {score_log.strip()} | "
        f"best={best_score:.3f} second={second_score:.3f} gap={gap:.3f} pick={best_letter}"
    )

    if not best_letter:
        return AnswerResult(letter="", score=best_score)

    if best_score < SIMILARITY_THRESHOLD:
        _httt_log(f"Độ tin cậy thấp (best_score={best_score:.3f}), bỏ qua câu hỏi")
        return AnswerResult(letter="", score=best_score)

    return AnswerResult(letter=best_letter, score=best_score)


def _click_answer(hwnd: int, answer_letter: str) -> bool:
    """Click the answer option and confirm button."""
    if answer_letter not in OPTION_CONFIG:
        return False

    cfg = OPTION_CONFIG[answer_letter]
    click_post(hwnd, cfg["click_x"], cfg["click_y"])
    time.sleep(0.5)
    click_post(hwnd, CONFIRM_BUTTON["x"], CONFIRM_BUTTON["y"])
    time.sleep(0.5)
    return True


def _process_single_window(hwnd: int) -> None:
    """Process the quiz for a single game window."""
    # Read question
    question_text = _read_question(hwnd)
    question_text = _clean_question_text(question_text)

    if not question_text.strip():
        _httt_log("OCR câu hỏi rỗng")
        return

    _httt_log(f"Question OCR: {question_text}")

    # Find matching question in database
    best_match = _find_fuzzy_match("Haitacthongthai", question_text, 0.4)

    if best_match.score <= 0:
        _httt_log(f"Không match câu hỏi | OCR Q: {question_text}")
        return

    # Read options
    option_map = _read_options(hwnd)

    # Pick answer
    result = _pick_answer(best_match.answer, option_map)

    if not result.letter:
        _httt_log(f"Không xác định đáp án | Q: {best_match.question}")
        return

    # Click answer
    if _click_answer(hwnd, result.letter):
        _httt_log(f"Đã trả lời {result.letter} | Q={best_match.question} | A={best_match.answer}")


def feature_haitacthongthai(status_callback=None) -> bool:
    """
    Feature: Hải tặc thông thái (Wise Pirate Quiz).

    Reads questions via OCR, matches against Question.ini database,
    and automatically selects answers for all game windows.
    """
    _httt_reset_log()
    resize_all_games()
    hwnds = get_game_windows()

    if not hwnds:
        logger.error("Không tìm thấy cửa sổ game")
        state_stop()
        return False

    if status_callback:
        status_callback("Tính năng đang chạy: Hải tặc thông thái")

    set_running("Hải tặc thông thái", None, status_callback)
    logger.info(f"Starting Hải tặc thông thái for {len(hwnds)} windows")

    try:
        for hwnd in hwnds:
            if not get_is_running():
                return True
            _process_single_window(hwnd)
            time.sleep(1)
    except Exception as e:
        logger.error(f"Hải tặc thông thái error: {e}")
        _httt_log(f"Error: {e}")
    finally:
        state_stop()

    logger.info("Feature haitacthongthai completed")
    return True
