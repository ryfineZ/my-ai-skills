from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_CHUNK_LIMIT = 900
SENTENCE_BOUNDARY_RE = re.compile(r"(?<=[。！？；!?;])")
SUPPORTED_TEXT_SUFFIXES = {".txt", ".md"}


@dataclass
class Chunk:
    chunk_id: str
    paragraph_index: int
    chunk_index: int
    text: str
    char_count: int


def read_source_text(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix in SUPPORTED_TEXT_SUFFIXES:
        return path.read_text(encoding="utf-8")
    if suffix == ".docx":
        try:
            from docx import Document  # type: ignore[import]
        except ImportError as exc:  # pragma: no cover - import guard
            raise SystemExit("Missing dependency python-docx for .docx support.") from exc
        document = Document(str(path))
        paragraphs = [p.text.strip() for p in document.paragraphs if p.text.strip()]
        return "\n\n".join(paragraphs)
    raise SystemExit(f"Unsupported file type: {path.suffix}")


def split_text_to_paragraphs(text: str) -> list[str]:
    normalized = text.replace("\r\n", "\n").replace("\r", "\n")
    paragraphs: list[str] = []
    current: list[str] = []
    for raw_line in normalized.split("\n"):
        line = raw_line.rstrip()
        if not line.strip():
            if current:
                paragraphs.append("\n".join(current).strip())
                current = []
            continue
        current.append(line)
    if current:
        paragraphs.append("\n".join(current).strip())
    return paragraphs


def split_paragraph_to_chunks(paragraph: str, chunk_limit: int) -> list[str]:
    compact = re.sub(r"\s+", " ", paragraph).strip()
    if not compact:
        return []
    if len(compact) <= chunk_limit:
        return [compact]

    sentences = _split_into_sentences(compact)
    chunks: list[str] = []
    current = ""
    for sentence in sentences:
        sentence = sentence.strip()
        if not sentence:
            continue
        if len(sentence) > chunk_limit:
            if current:
                chunks.append(current)
                current = ""
            chunks.extend(_split_long_sentence(sentence, chunk_limit))
            continue

        candidate = sentence if not current else f"{current}{sentence}"
        if len(candidate) <= chunk_limit:
            current = candidate
        else:
            if current:
                chunks.append(current)
            current = sentence
    if current:
        chunks.append(current)
    return chunks


def build_chunks(text: str, chunk_limit: int) -> list[Chunk]:
    chunks: list[Chunk] = []
    for paragraph_index, paragraph in enumerate(split_text_to_paragraphs(text)):
        for chunk_index, chunk_text in enumerate(split_paragraph_to_chunks(paragraph, chunk_limit)):
            chunks.append(
                Chunk(
                    chunk_id=f"p{paragraph_index}_c{chunk_index}",
                    paragraph_index=paragraph_index,
                    chunk_index=chunk_index,
                    text=chunk_text,
                    char_count=len(chunk_text),
                )
            )
    return chunks


def suggested_output_path(input_path: Path, variant: str) -> Path:
    suffix = input_path.suffix.lower()
    if suffix in SUPPORTED_TEXT_SUFFIXES:
        return input_path.with_name(f"{input_path.stem}.deai-{variant}{suffix}")
    return input_path.with_name(f"{input_path.stem}.deai-{variant}.txt")


def metadata_path_for(output_path: Path) -> Path:
    return output_path.with_name(f"{output_path.name}.metadata.json")


def inspect_input(input_path: Path, variant: str, chunk_limit: int) -> dict:
    resolved = input_path.expanduser().resolve()
    if not resolved.exists():
        raise SystemExit(f"File not found: {resolved}")

    text = read_source_text(resolved)
    chunks = build_chunks(text, chunk_limit)
    output_path = suggested_output_path(resolved, variant)
    metadata_path = metadata_path_for(output_path)
    return {
        "source_path": str(resolved),
        "variant": variant,
        "chunk_limit": chunk_limit,
        "output_path": str(output_path),
        "metadata_path": str(metadata_path),
        "chunk_count": len(chunks),
        "chunks": [asdict(chunk) for chunk in chunks],
    }


def write_result(input_path: Path, variant: str, chunk_count: int) -> dict:
    resolved = input_path.expanduser().resolve()
    if not resolved.exists():
        raise SystemExit(f"File not found: {resolved}")

    output_path = suggested_output_path(resolved, variant)
    metadata_path = metadata_path_for(output_path)
    content = sys.stdin.read()
    if not content.strip():
        raise SystemExit("No result content provided on stdin.")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content, encoding="utf-8")

    metadata = {
        "source_path": str(resolved),
        "output_path": str(output_path),
        "metadata_path": str(metadata_path),
        "variant": variant,
        "chunk_count": chunk_count,
        "written_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    }
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    return metadata


def _split_into_sentences(text: str) -> list[str]:
    parts = SENTENCE_BOUNDARY_RE.split(text)
    sentences = [part.strip() for part in parts if part and part.strip()]
    return sentences or [text]


def _split_long_sentence(sentence: str, chunk_limit: int) -> list[str]:
    fragments = re.split(r"(?<=[，、：:,])", sentence)
    chunks: list[str] = []
    current = ""
    for fragment in fragments:
        fragment = fragment.strip()
        if not fragment:
            continue
        candidate = fragment if not current else f"{current}{fragment}"
        if len(candidate) <= chunk_limit:
            current = candidate
            continue
        if current:
            chunks.append(current)
            current = ""
        if len(fragment) <= chunk_limit:
            current = fragment
            continue
        for index in range(0, len(fragment), chunk_limit):
            chunks.append(fragment[index:index + chunk_limit])
    if current:
        chunks.append(current)
    return chunks


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Shared file workflow helper for de-ai skills")
    subparsers = parser.add_subparsers(dest="command", required=True)

    inspect_parser = subparsers.add_parser("inspect", help="Inspect and chunk a source file")
    inspect_parser.add_argument("input_path", type=Path)
    inspect_parser.add_argument("--variant", required=True, choices=["stable", "optimized"])
    inspect_parser.add_argument("--chunk-limit", type=int, default=DEFAULT_CHUNK_LIMIT)

    write_parser = subparsers.add_parser("write", help="Write final result and metadata")
    write_parser.add_argument("input_path", type=Path)
    write_parser.add_argument("--variant", required=True, choices=["stable", "optimized"])
    write_parser.add_argument("--chunk-count", type=int, required=True)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "inspect":
        payload = inspect_input(args.input_path, args.variant, args.chunk_limit)
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return

    if args.command == "write":
        payload = write_result(args.input_path, args.variant, args.chunk_count)
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return

    parser.error("Unknown command")


if __name__ == "__main__":
    main()
