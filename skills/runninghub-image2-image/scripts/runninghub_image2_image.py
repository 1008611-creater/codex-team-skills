import argparse
import json
import os
import sys
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen


LOW_ENDPOINT = "/openapi/v2/rhart-image-g-2/image-to-image"
QUERY_ENDPOINT = "/openapi/v2/query"


def configure_stdio() -> None:
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")


def load_dotenv(prefer_keys: set[str] | None = None) -> None:
    prefer_keys = prefer_keys or set()
    cwd = Path.cwd().resolve()
    loaded_keys: set[str] = set()
    for base in [cwd, *cwd.parents, Path(__file__).resolve().parents[1]]:
        env_file = base / ".env"
        if not env_file.exists():
            continue
        for raw_line in env_file.read_text(encoding="utf-8", errors="replace").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if not key or key in loaded_keys:
                continue
            loaded_keys.add(key)
            if key not in os.environ or key in prefer_keys:
                os.environ[key] = value


def read_prompt(args: argparse.Namespace) -> str:
    if args.prompt_file:
        return Path(args.prompt_file).read_text(encoding="utf-8", errors="replace").strip()
    if args.prompt:
        return args.prompt.strip()
    raise ValueError("Provide --prompt or --prompt-file.")


def read_image_urls(args: argparse.Namespace) -> list[str]:
    urls: list[str] = list(args.image_url or [])
    if args.image_urls_file:
        lines = Path(args.image_urls_file).read_text(encoding="utf-8", errors="replace").splitlines()
        urls.extend(line.strip() for line in lines if line.strip() and not line.strip().startswith("#"))
    urls = list(dict.fromkeys(urls))
    if not urls:
        raise ValueError("Provide at least one --image-url or --image-urls-file.")
    invalid = [url for url in urls if not url.startswith(("http://", "https://"))]
    if invalid:
        raise ValueError("RunningHub v2 imageUrls requires public http/https URLs, not local paths: " + ", ".join(invalid))
    return urls


def post_json(url: str, payload: dict, api_key: str, timeout: int) -> dict:
    try:
        import requests

        response = requests.post(
            url,
            json=payload,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Accept": "application/json",
                "User-Agent": "codex-runninghub-image2-image/1.0",
            },
            timeout=timeout,
        )
        response.raise_for_status()
        try:
            return response.json()
        except ValueError:
            return {"raw": response.text}
    except ImportError:
        pass

    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = Request(
        url,
        data=body,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "codex-runninghub-image2-image/1.0",
        },
        method="POST",
    )
    with urlopen(request, timeout=timeout) as response:
        text = response.read().decode("utf-8", errors="replace")
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {"raw": text}


def extract_task_id(response: dict) -> str | None:
    candidates = [response]
    data = response.get("data")
    if isinstance(data, dict):
        candidates.append(data)
    for item in candidates:
        for key in ("taskId", "task_id", "id"):
            value = item.get(key)
            if isinstance(value, (str, int)):
                return str(value)
    return None


def find_image_urls(value) -> list[str]:
    urls: list[str] = []
    if isinstance(value, str):
        lower = value.lower()
        if value.startswith(("http://", "https://")) and any(ext in lower for ext in (".png", ".jpg", ".jpeg", ".webp")):
            urls.append(value)
    elif isinstance(value, list):
        for item in value:
            urls.extend(find_image_urls(item))
    elif isinstance(value, dict):
        for item in value.values():
            urls.extend(find_image_urls(item))
    return list(dict.fromkeys(urls))


def looks_finished(response: dict) -> bool:
    status_text = json.dumps(response, ensure_ascii=False).lower()
    if find_image_urls(response):
        return True
    return any(word in status_text for word in ("success", "succeeded", "completed", "finish"))


def poll_result(base_url: str, task_id: str, api_key: str, timeout: int, poll_interval: int, request_timeout: int) -> dict:
    deadline = time.time() + timeout
    last_response: dict = {}
    while time.time() < deadline:
        last_response = post_json(f"{base_url.rstrip('/')}{QUERY_ENDPOINT}", {"taskId": task_id}, api_key, request_timeout)
        if looks_finished(last_response):
            return last_response
        time.sleep(poll_interval)
    return {"timeout": True, "taskId": task_id, "lastResponse": last_response}


def safe_filename(url: str, index: int) -> str:
    name = Path(urlparse(url).path).name or f"runninghub-image2-image-{index}.png"
    if "." not in name:
        name = f"{name}.png"
    return name


def download_urls(urls: list[str], output_dir: Path, request_timeout: int) -> list[str]:
    output_dir.mkdir(parents=True, exist_ok=True)
    saved: list[str] = []
    for index, url in enumerate(urls, start=1):
        try:
            import requests

            response = requests.get(
                url,
                headers={"User-Agent": "codex-runninghub-image2-image/1.0"},
                timeout=request_timeout,
            )
            response.raise_for_status()
            data = response.content
        except ImportError:
            request = Request(url, headers={"User-Agent": "codex-runninghub-image2-image/1.0"})
            with urlopen(request, timeout=request_timeout) as response:
                data = response.read()
        path = output_dir / safe_filename(url, index)
        if path.exists():
            path = output_dir / f"{path.stem}-{index}{path.suffix}"
        path.write_bytes(data)
        saved.append(str(path))
    return saved


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Submit RunningHub Image G 2.0 image-to-image jobs.")
    parser.add_argument("--prompt")
    parser.add_argument("--prompt-file")
    parser.add_argument("--image-url", action="append")
    parser.add_argument("--image-urls-file")
    parser.add_argument("--aspect-ratio", default="9:16")
    parser.add_argument("--channel", choices=["low"], default="low")
    parser.add_argument("--resolution", choices=["1k", "2k", "4k"], default="4k")
    parser.add_argument("--base-url", default=os.getenv("RUNNINGHUB_BASE_URL", "https://www.runninghub.cn"))
    parser.add_argument("--api-key-env", default="RUNNINGHUB_API_KEY")
    parser.add_argument("--wait", action="store_true")
    parser.add_argument("--poll-interval", type=int, default=5)
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--request-timeout", type=int, default=60)
    parser.add_argument("--download-dir")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> int:
    configure_stdio()
    args = parse_args()
    load_dotenv(prefer_keys={args.api_key_env})

    try:
        prompt = read_prompt(args)
        image_urls = read_image_urls(args)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    endpoint = LOW_ENDPOINT
    payload = {
        "prompt": prompt,
        "imageUrls": image_urls,
        "aspectRatio": args.aspect_ratio,
        "resolution": args.resolution,
    }

    url = f"{args.base_url.rstrip('/')}{endpoint}"
    if args.dry_run:
        print(json.dumps({"url": url, "payload": payload, "authEnv": args.api_key_env}, ensure_ascii=False, indent=2))
        return 0

    api_key = os.getenv(args.api_key_env, "").strip()
    if not api_key:
        print(f"Missing {args.api_key_env}. Set it in .env or the environment.", file=sys.stderr)
        return 2

    try:
        submit_response = post_json(url, payload, api_key, args.request_timeout)
        result = {"submit": submit_response}
        task_id = extract_task_id(submit_response)
        if args.wait and task_id:
            query_response = poll_result(args.base_url, task_id, api_key, args.timeout, args.poll_interval, args.request_timeout)
            result["query"] = query_response
            urls = find_image_urls(query_response)
            if args.download_dir and urls:
                result["downloaded"] = download_urls(urls, Path(args.download_dir), args.request_timeout)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        print(f"HTTP error {exc.code}", file=sys.stderr)
        print(body, file=sys.stderr)
        return 1
    except (URLError, TimeoutError, OSError) as exc:
        print(f"Request failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
