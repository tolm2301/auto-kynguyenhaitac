#!/usr/bin/env python3
import argparse
import glob
import inspect
import os
import sys
import time
import traceback


def _now_ms() -> int:
    return int(time.time() * 1000)


def _ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def _write_text(path: str, content: str) -> None:
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write(content)
    os.replace(tmp, path)


def _append_log(path: str, message: str) -> None:
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    line = f"{ts} {message}\n"
    _ensure_dir(os.path.dirname(path))
    with open(path, "a", encoding="utf-8") as f:
        f.write(line)


def _parse_kv_file(path: str) -> dict:
    out = {}
    with open(path, "r", encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line or "=" not in line:
                continue
            key, value = line.split("=", 1)
            out[key.strip()] = value.strip()
    return out


def _result_text(ok: bool, text: str, err: str, elapsed_ms: int) -> str:
    return (
        f"OK={1 if ok else 0}\n"
        f"ELAPSED_MS={max(0, int(elapsed_ms))}\n"
        f"ERR=\n{err}\n--ERR_END--\n"
        f"TEXT=\n{text}\n--TEXT_END--\n"
    )


def _extract_text_from_paddle(result_obj) -> str:
    if not result_obj:
        return ""

    lines = []

    def _collect(node) -> None:
        if node is None:
            return

        if isinstance(node, str):
            text = node.strip()
            if text:
                lines.append(text)
            return

        if isinstance(node, dict):
            for key in ("text", "rec_text", "rec_texts", "texts", "transcription"):
                if key in node:
                    _collect(node.get(key))

            for key in ("ocr_res", "dt_polys", "rec_scores", "boxes", "results"):
                if key in node:
                    _collect(node.get(key))
            return

        if isinstance(node, (list, tuple)):
            # PaddleOCR 2.x row: [box, (text, score)]
            if len(node) >= 2 and isinstance(node[1], (list, tuple)) and len(node[1]) >= 1 and isinstance(node[1][0], str):
                text = (node[1][0] or "").strip()
                if text:
                    lines.append(text)
                return

            for item in node:
                _collect(item)
            return

        # PaddleOCR 3.x result object thường có dict/json export
        to_dict = getattr(node, "to_dict", None)
        if callable(to_dict):
            try:
                _collect(to_dict())
                return
            except Exception:
                pass

        to_json = getattr(node, "json", None)
        if callable(to_json):
            try:
                _collect(to_json())
                return
            except Exception:
                pass

    _collect(result_obj)

    return "\n".join(lines).strip()


def _run_ocr(ocr_engine, image_path: str):
    # Ưu tiên API cũ trước để giữ tương thích với prototype hiện tại.
    try:
        return ocr_engine.ocr(image_path, cls=False)
    except Exception as ex1:
        # PaddleOCR 3.x không còn hỗ trợ cls/show_log kiểu cũ.
        msg = str(ex1)
        if ("Unknown argument" not in msg) and ("unexpected keyword" not in msg) and ("cls" not in msg):
            raise

    # Fallback cho PaddleOCR 3.x
    if hasattr(ocr_engine, "predict"):
        return ocr_engine.predict(image_path)

    return ocr_engine.ocr(image_path)


def _process_one_request(req_path: str, ocr_engine, log_file: str) -> None:
    req = _parse_kv_file(req_path)
    request_id = req.get("REQUEST_ID", os.path.basename(req_path))
    image_path = req.get("IMAGE_PATH", "")
    response_path = req.get("RESPONSE_PATH", "")

    if not response_path:
        base = os.path.splitext(os.path.basename(req_path))[0].replace("req_", "")
        response_path = os.path.join(os.path.dirname(req_path), "..", "responses", f"resp_{base}.resp")
        response_path = os.path.abspath(response_path)

    started = _now_ms()
    ok = False
    text = ""
    err = ""

    try:
        if not image_path:
            raise RuntimeError("Missing IMAGE_PATH in request")
        if not os.path.exists(image_path):
            raise RuntimeError(f"Image not found: {image_path}")

        ocr_result = _run_ocr(ocr_engine, image_path)
        text = _extract_text_from_paddle(ocr_result)
        ok = True
    except Exception as ex:
        err = f"{type(ex).__name__}: {ex}"
        _append_log(log_file, f"[ERROR] request={request_id} err={err}")
        _append_log(log_file, traceback.format_exc())

    elapsed_ms = _now_ms() - started
    _write_text(response_path, _result_text(ok=ok, text=text, err=err, elapsed_ms=elapsed_ms))

    try:
        os.remove(req_path)
    except OSError:
        pass

    preview = text[:120].replace("\n", " | ")
    _append_log(
        log_file,
        f"[INFO] request={request_id} ok={1 if ok else 0} elapsedMs={elapsed_ms} image={image_path} preview={preview}",
    )


def _load_paddle(lang: str, log_file: str):
    started = _now_ms()
    from paddleocr import PaddleOCR

    sig = inspect.signature(PaddleOCR.__init__)
    available = set(sig.parameters.keys())

    kwargs = {}

    # PaddleOCR 2.x style
    if "lang" in available:
        kwargs["lang"] = "vi"   # nhẹ hơn và hợp chữ Latin/tiếng Việt hơn "vi" trong nhiều case

    if "use_angle_cls" in available:
        kwargs["use_angle_cls"] = False

    if "show_log" in available:
        kwargs["show_log"] = False

    if "det_limit_side_len" in available:
        kwargs["det_limit_side_len"] = 640

    if "det_limit_type" in available:
        kwargs["det_limit_type"] = "max"

    if "rec_batch_num" in available:
        kwargs["rec_batch_num"] = 2

    # PaddleOCR 3.x style
    if "text_detection_model_name" in available:
        kwargs["text_detection_model_name"] = "PP-OCRv4_mobile_det"

    if "text_recognition_model_name" in available:
        kwargs["text_recognition_model_name"] = "latin_PP-OCRv3_mobile_rec"

    if "use_doc_orientation_classify" in available:
        kwargs["use_doc_orientation_classify"] = False

    if "use_doc_unwarping" in available:
        kwargs["use_doc_unwarping"] = False

    if "use_textline_orientation" in available:
        kwargs["use_textline_orientation"] = False

    ocr_engine = PaddleOCR(**kwargs)
    elapsed = _now_ms() - started
    _append_log(log_file, f"[INFO] PaddleOCR loaded elapsedMs={elapsed} kwargs={kwargs}")
    return ocr_engine


def run_server(args) -> int:
    ipc_dir = os.path.abspath(args.ipc_dir)
    req_dir = os.path.join(ipc_dir, "requests")
    resp_dir = os.path.join(ipc_dir, "responses")
    ready_file = os.path.abspath(args.ready_file)
    log_file = os.path.abspath(args.log_file)

    _ensure_dir(ipc_dir)
    _ensure_dir(req_dir)
    _ensure_dir(resp_dir)

    _append_log(log_file, f"[INFO] Worker start pid={os.getpid()} ipc={ipc_dir}")

    try:
        ocr_engine = _load_paddle(args.lang, log_file)
    except Exception as ex:
        _append_log(log_file, f"[ERROR] Paddle load failed: {type(ex).__name__}: {ex}")
        _append_log(log_file, traceback.format_exc())
        _write_text(ready_file, f"READY=0\nPID={os.getpid()}\nERR={type(ex).__name__}: {ex}\n")
        return 2

    _write_text(ready_file, f"READY=1\nPID={os.getpid()}\nLANG={args.lang}\n")

    _append_log(log_file, "[INFO] Worker ready, waiting requests")

    while True:
        try:
            req_files = sorted(glob.glob(os.path.join(req_dir, "req_*.req")))
            if not req_files:
                time.sleep(args.poll_interval_ms / 1000.0)
                continue

            for req_path in req_files:
                _process_one_request(req_path, ocr_engine, log_file)
        except KeyboardInterrupt:
            _append_log(log_file, "[INFO] Worker interrupted, exiting")
            break
        except Exception as ex:
            _append_log(log_file, f"[ERROR] Main loop: {type(ex).__name__}: {ex}")
            _append_log(log_file, traceback.format_exc())
            time.sleep(0.3)

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Background PaddleOCR worker (file-based IPC)")
    parser.add_argument("--server", action="store_true", help="Run in background server mode")
    parser.add_argument("--ipc-dir", default=os.path.join(os.getenv("TEMP", "."), "auto_kynguyenhaitac_ocr"))
    parser.add_argument("--ready-file", default=os.path.join(os.getenv("TEMP", "."), "auto_kynguyenhaitac_ocr", "worker.ready"))
    parser.add_argument("--log-file", default=os.path.join("logs", "ocr_worker_py.log"))
    parser.add_argument("--lang", default="vi")
    parser.add_argument("--poll-interval-ms", type=int, default=50)
    args = parser.parse_args()

    if not args.server:
        print("Use --server mode for this worker prototype", file=sys.stderr)
        return 1

    return run_server(args)


if __name__ == "__main__":
    raise SystemExit(main())
