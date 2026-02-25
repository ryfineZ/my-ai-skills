#!/usr/bin/env python3
"""Skill Security Guard

A lightweight, deterministic scanner for auditing AI skill packages.
Supports local directories and GitHub repositories.
"""

from __future__ import annotations

import argparse
import base64
import json
import math
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass
from enum import IntEnum
from pathlib import Path


class Severity(IntEnum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4

    def __str__(self) -> str:
        return self.name


@dataclass
class ScannableFile:
    path: str
    content: str


@dataclass
class Finding:
    rule_id: str
    title: str
    severity: Severity
    category: str
    file_path: str
    line_number: int
    detail: str
    recommendation: str
    snippet: str
    confidence: int

    def to_dict(self) -> dict:
        data = asdict(self)
        data["severity"] = str(self.severity)
        data["severity_value"] = int(self.severity)
        return data


TEXT_EXTENSIONS = {
    ".md",
    ".txt",
    ".yaml",
    ".yml",
    ".json",
    ".toml",
    ".ini",
    ".cfg",
    ".sh",
    ".bash",
    ".zsh",
    ".ps1",
    ".bat",
    ".cmd",
    ".py",
    ".js",
    ".ts",
    ".jsx",
    ".tsx",
    ".mjs",
    ".cjs",
    ".rb",
    ".go",
    ".rs",
    ".java",
    ".php",
    ".html",
    ".css",
    ".sql",
    ".xml",
    ".gradle",
}

ALWAYS_INCLUDE_FILES = {
    "SKILL.md",
    "skill.yaml",
    "plugin.json",
    "hooks.json",
    "package.json",
    "setup.py",
    "pyproject.toml",
    ".env",
}

SKIP_DIRS = {
    ".git",
    "node_modules",
    "venv",
    ".venv",
    "dist",
    "build",
    "__pycache__",
    ".mypy_cache",
    ".tox",
}

DOC_HINTS = {
    "pattern",
    "patterns",
    "detect",
    "detection",
    "scanner",
    "rule",
    "rules",
    "remediation",
    "false positive",
    "示例",
    "检测",
    "规则",
    "误报",
    "仅用于测试",
    "检测覆盖",
    "privilege escalation",
    "download and execute",
    "credential access",
    "data exfiltration",
    "supply chain hook",
}

PROMPT_PATTERNS = [
    (
        re.compile(r"(?i)ignore\s+(all\s+)?(previous|prior|earlier)\s+(instructions|rules|prompts)"),
        "Prompt override instruction detected",
        Severity.HIGH,
        "Remove override directives that bypass base instructions.",
        88,
    ),
    (
        re.compile(r"(?i)system\s+override|override\s+all\s+previous\s+instructions"),
        "System override pattern detected",
        Severity.HIGH,
        "Do not redefine global system behavior inside skill content.",
        90,
    ),
    (
        re.compile(r"(?i)unrestricted\s+(developer|admin|jailbreak)\s+mode"),
        "Unrestricted mode escalation language detected",
        Severity.HIGH,
        "Remove unrestricted/admin mode instructions.",
        86,
    ),
    (
        re.compile(r"(?i)do\s+not\s+(tell|inform|mention)\s+(the\s+)?user|keep\s+this\s+hidden"),
        "Concealment directive detected",
        Severity.HIGH,
        "Require transparent behavior and user-visible actions.",
        84,
    ),
    (
        re.compile(r"(?i)reveal\s+(the\s+)?system\s+(prompt|message|instructions)"),
        "System prompt extraction attempt detected",
        Severity.MEDIUM,
        "Disallow requests to leak system prompts.",
        72,
    ),
]

DOWNLOAD_EXEC_PATTERNS = [
    (
        re.compile(r"(?i)curl\s+[^\n|]*\|\s*(bash|sh|zsh|python|node)"),
        "curl pipe-to-exec pattern detected",
        95,
    ),
    (
        re.compile(r"(?i)wget\s+[^\n|]*\|\s*(bash|sh|python|node)"),
        "wget pipe-to-exec pattern detected",
        95,
    ),
    (
        re.compile(r"(?i)Invoke-WebRequest[^\n|]*\|\s*IEX"),
        "PowerShell download-and-execute pattern detected",
        95,
    ),
    (
        re.compile(r"(?i)\b(eval|exec)\b\s*\("),
        "Dynamic eval/exec call detected",
        82,
    ),
]

CREDENTIAL_PATTERNS = [
    (
        re.compile(r"(?i)osascript\s+.*(display|dialog|password)|security\s+find-(generic|internet)-password"),
        "Credential harvesting command detected",
        Severity.CRITICAL,
        "Remove any credential prompt or keychain extraction logic.",
        94,
    ),
    (
        re.compile(r"(?i)(cat|type|Get-Content|open|read)\s+[^\n]*(\.ssh/|\.aws/|\.gnupg/|\.kube/|id_rsa|id_ed25519)"),
        "Sensitive credential file access detected",
        Severity.CRITICAL,
        "Do not access private keys or local credential stores.",
        93,
    ),
    (
        re.compile(r"(?i)(cat|type|Get-Content|open|read)\s+[^\n]*(\.env|credentials\.json|secrets?\.|\.npmrc|\.pypirc|\.netrc)"),
        "Potential secret file access detected",
        Severity.HIGH,
        "Restrict file reads to minimal, justified paths.",
        82,
    ),
]

PERSISTENCE_PATTERNS = [
    (
        re.compile(r"(?i)crontab\s+(-e|-l|-)"),
        "Crontab persistence pattern detected",
        78,
    ),
    (
        re.compile(r"(?i)LaunchAgents|LaunchDaemons|launchctl\s+(load|bootstrap)"),
        "macOS launchd persistence pattern detected",
        80,
    ),
    (
        re.compile(r"(?i)systemctl\s+(enable|start)|/etc/systemd/system/"),
        "systemd persistence pattern detected",
        76,
    ),
    (
        re.compile(r"(?i)(>>|>)\s*[^\n]*(\.bashrc|\.zshrc|\.profile|\.bash_profile)"),
        "Shell profile modification pattern detected",
        80,
    ),
]

PRIVILEGE_PATTERNS = [
    (
        re.compile(r"(?i)\bsudo\s+"),
        "sudo usage detected",
        70,
    ),
    (
        re.compile(r"(?i)chmod\s+777\b|chmod\s+\+s\b|setuid|setgid"),
        "Privilege escalation chmod/setuid pattern detected",
        85,
    ),
    (
        re.compile(r"(?i)dscl\s+\.\s+-append\s+/Groups/admin"),
        "Admin group modification pattern detected",
        92,
    ),
]

NETWORK_CALL_RE = re.compile(
    r"(?i)(requests\.(post|put|get|delete)|httpx\.(post|put|get|delete)|urllib\.request\.(urlopen|Request)|fetch\s*\(|curl\s+|wget\s+|Invoke-RestMethod|Invoke-WebRequest)"
)
SENSITIVE_RE = re.compile(
    r"(?i)(\.ssh|\.aws|\.gnupg|\.kube|\.env|credentials|id_rsa|id_ed25519|api[_-]?key|token|secret)"
)
SENSITIVE_READ_RE = re.compile(r"(?i)(cat|type|read|open|copy|glob|Get-Content)")
EXTERNAL_URL_RE = re.compile(r"(?i)https?://([a-z0-9.-]+)")

BASE64_RE = re.compile(r"[A-Za-z0-9+/]{100,}={0,2}")
HIDDEN_CHAR_RE = re.compile(r"[\u200b\u200c\u200d\u2060\ufeff\u202a-\u202e\u2066-\u2069]")

MIN_ENTROPY_LEN = 120
ENTROPY_THRESHOLD = 6.2


def parse_repo(repo_arg: str) -> tuple[str, str]:
    raw = repo_arg.strip()
    if raw.startswith("https://github.com/") or raw.startswith("http://github.com/"):
        path = urllib.parse.urlparse(raw).path.strip("/")
        parts = path.split("/")
        if len(parts) >= 2:
            return parts[0], parts[1]
    if raw.startswith("github.com/"):
        parts = raw.replace("github.com/", "", 1).split("/")
        if len(parts) >= 2:
            return parts[0], parts[1]
    if "/" in raw:
        owner, repo = raw.split("/", 1)
        return owner, repo
    raise ValueError(f"无法解析仓库地址: {repo_arg}")


def github_get_json(url: str, token: str | None = None) -> dict:
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("User-Agent", "skill-security-guard/1.0")
    if token:
        req.add_header("Authorization", f"Bearer {token}")

    with urllib.request.urlopen(req, timeout=20) as resp:  # noqa: S310
        body = resp.read().decode("utf-8")
        return json.loads(body)


def is_text_candidate(path: str) -> bool:
    name = os.path.basename(path)
    if name in ALWAYS_INCLUDE_FILES:
        return True
    suffix = Path(path).suffix.lower()
    return suffix in TEXT_EXTENSIONS


def is_skipped_path(path: str) -> bool:
    parts = Path(path).parts
    return any(part in SKIP_DIRS for part in parts)


def load_local_files(root: str, max_files: int, max_file_size: int) -> tuple[list[ScannableFile], bool]:
    base = Path(root).expanduser().resolve()
    if not base.is_dir():
        raise ValueError(f"路径不存在或不是目录: {base}")

    files: list[ScannableFile] = []
    truncated = False

    for dirpath, dirnames, filenames in os.walk(base):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]

        for fname in filenames:
            full = Path(dirpath) / fname
            rel = str(full.relative_to(base))

            if is_skipped_path(rel):
                continue
            if not is_text_candidate(rel):
                continue

            try:
                if full.stat().st_size > max_file_size:
                    continue
                content = full.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue

            files.append(ScannableFile(path=rel, content=content))
            if len(files) >= max_files:
                truncated = True
                return files, truncated

    return files, truncated


def load_github_files(
    repo_arg: str,
    ref: str | None,
    token: str | None,
    max_files: int,
    max_file_size: int,
) -> tuple[list[ScannableFile], bool, str, str]:
    owner, repo = parse_repo(repo_arg)
    repo_info = github_get_json(f"https://api.github.com/repos/{owner}/{repo}", token)
    branch = ref or repo_info.get("default_branch") or "main"

    tree_url = (
        f"https://api.github.com/repos/{owner}/{repo}/git/trees/"
        f"{urllib.parse.quote(branch, safe='')}?recursive=1"
    )
    tree = github_get_json(tree_url, token)
    entries = tree.get("tree", [])

    selected_paths: list[str] = []
    for entry in entries:
        if entry.get("type") != "blob":
            continue
        path = entry.get("path", "")
        size = int(entry.get("size") or 0)

        if not path or is_skipped_path(path) or not is_text_candidate(path):
            continue
        if size > max_file_size:
            continue

        selected_paths.append(path)
        if len(selected_paths) >= max_files:
            break

    truncated = len(selected_paths) >= max_files and len(entries) > len(selected_paths)

    files: list[ScannableFile] = []
    for path in selected_paths:
        content_url = (
            f"https://api.github.com/repos/{owner}/{repo}/contents/"
            f"{urllib.parse.quote(path, safe='/')}?ref={urllib.parse.quote(branch, safe='')}"
        )
        data = github_get_json(content_url, token)
        if data.get("type") != "file":
            continue

        encoded = data.get("content", "")
        if not encoded:
            continue

        try:
            decoded = base64.b64decode(encoded, validate=False).decode("utf-8", errors="replace")
        except (ValueError, UnicodeDecodeError):
            continue

        files.append(ScannableFile(path=path, content=decoded))

    target = f"{owner}/{repo}@{branch}"
    return files, truncated, owner, target


def is_doc_context(file_path: str, line: str) -> bool:
    normalized_path = file_path.replace("\\", "/")
    suffix = Path(file_path).suffix.lower()
    text = line.lower()

    # Rule-definition context inside scanner scripts/configs.
    if "re.compile(" in text or "pattern detected" in text or "rule_id=" in text:
        return True
    if suffix in {".py", ".js", ".ts", ".tsx", ".jsx"} and "detected" in text and ("\"" in line or "'" in line):
        return True

    if suffix in {".md", ".txt", ".rst"}:
        base = os.path.basename(normalized_path)
        if base != "SKILL.md":
            return True
        if normalized_path.startswith("references/") or normalized_path.startswith("docs/"):
            return True
        if base in {"README.md", "CHANGELOG.md", "LICENSE", "LICENSE.md"}:
            return True
        return any(hint in text for hint in DOC_HINTS)
    return False


def entropy(text: str) -> float:
    if not text:
        return 0.0
    freq: dict[str, int] = {}
    for ch in text:
        freq[ch] = freq.get(ch, 0) + 1
    total = len(text)
    return -sum((count / total) * math.log2(count / total) for count in freq.values())


def find_line_number(lines: list[str], token: str) -> int:
    for idx, line in enumerate(lines, start=1):
        if token in line:
            return idx
    return 1


def add_line_pattern_findings(
    findings: list[Finding],
    sf: ScannableFile,
    patterns: list[tuple[re.Pattern[str], str, Severity, str, int]],
    rule_prefix: str,
    category: str,
) -> None:
    for idx, line in enumerate(sf.content.splitlines(), start=1):
        for pattern, title, severity, recommendation, confidence in patterns:
            if not pattern.search(line):
                continue
            if is_doc_context(sf.path, line) and severity >= Severity.HIGH:
                continue

            findings.append(
                Finding(
                    rule_id=f"{rule_prefix}_{idx}",
                    title=title,
                    severity=severity,
                    category=category,
                    file_path=sf.path,
                    line_number=idx,
                    detail=title,
                    recommendation=recommendation,
                    snippet=line.strip()[:220],
                    confidence=confidence,
                )
            )


def detect_download_exec(sf: ScannableFile, findings: list[Finding]) -> None:
    for idx, line in enumerate(sf.content.splitlines(), start=1):
        for pattern, title, confidence in DOWNLOAD_EXEC_PATTERNS:
            if not pattern.search(line):
                continue
            if is_doc_context(sf.path, line):
                continue
            findings.append(
                Finding(
                    rule_id=f"DOWNLOAD_EXEC_{idx}",
                    title=title,
                    severity=Severity.CRITICAL,
                    category="code_execution",
                    file_path=sf.path,
                    line_number=idx,
                    detail=title,
                    recommendation="禁止下载后直接执行，改为固定版本和哈希校验。",
                    snippet=line.strip()[:220],
                    confidence=confidence,
                )
            )


def detect_supply_chain_hooks(sf: ScannableFile, findings: list[Finding]) -> None:
    name = os.path.basename(sf.path)
    lines = sf.content.splitlines()

    if name == "package.json":
        try:
            pkg = json.loads(sf.content)
        except json.JSONDecodeError:
            return

        scripts = pkg.get("scripts", {})
        if not isinstance(scripts, dict):
            return

        suspicious_re = re.compile(r"(?i)(curl|wget|bash|sh\s+-c|powershell|iex|node\s+-e|python\s+-c|eval)")
        for hook in ("preinstall", "install", "postinstall", "prepare"):
            if hook not in scripts:
                continue
            cmd = str(scripts.get(hook, ""))
            sev = Severity.CRITICAL if suspicious_re.search(cmd) else Severity.HIGH
            conf = 92 if sev == Severity.CRITICAL else 76
            line_number = find_line_number(lines, f'"{hook}"')

            findings.append(
                Finding(
                    rule_id=f"SUPPLY_CHAIN_{hook}",
                    title=f"npm lifecycle hook '{hook}' detected",
                    severity=sev,
                    category="supply_chain",
                    file_path=sf.path,
                    line_number=line_number,
                    detail=f"Install hook command: {cmd[:180]}",
                    recommendation="审计 install 钩子，避免运行不透明脚本。",
                    snippet=cmd[:220],
                    confidence=conf,
                )
            )

    if name == "setup.py":
        if re.search(r"(?i)cmdclass\s*=", sf.content):
            line_number = find_line_number(lines, "cmdclass")
            findings.append(
                Finding(
                    rule_id="SUPPLY_CHAIN_SETUPPY_CMDCLASS",
                    title="setup.py cmdclass hook detected",
                    severity=Severity.HIGH,
                    category="supply_chain",
                    file_path=sf.path,
                    line_number=line_number,
                    detail="Custom install command classes may run arbitrary code during installation.",
                    recommendation="确认 setup.py 安装逻辑是否必要并可审计。",
                    snippet=lines[line_number - 1].strip()[:220] if line_number <= len(lines) else "",
                    confidence=72,
                )
            )


def detect_exfiltration_chain(sf: ScannableFile, findings: list[Finding]) -> None:
    lines = sf.content.splitlines()
    sensitive_line: tuple[int, str] | None = None
    network_line: tuple[int, str] | None = None

    for idx, line in enumerate(lines, start=1):
        if is_doc_context(sf.path, line):
            continue

        if SENSITIVE_RE.search(line) and SENSITIVE_READ_RE.search(line):
            sensitive_line = sensitive_line or (idx, line)
        if NETWORK_CALL_RE.search(line):
            network_line = network_line or (idx, line)

        if NETWORK_CALL_RE.search(line):
            match = EXTERNAL_URL_RE.search(line)
            if match:
                host = match.group(1).lower()
                if host not in {"localhost", "127.0.0.1"} and not host.endswith(".local"):
                    findings.append(
                        Finding(
                            rule_id=f"NETWORK_EXTERNAL_{idx}",
                            title="External network endpoint detected",
                            severity=Severity.MEDIUM,
                            category="network_access",
                            file_path=sf.path,
                            line_number=idx,
                            detail=f"External host: {host}",
                            recommendation="确认外部域名属于可信清单，并记录用途。",
                            snippet=line.strip()[:220],
                            confidence=62,
                        )
                    )

    if sensitive_line and network_line:
        findings.append(
            Finding(
                rule_id=f"EXFIL_CHAIN_{sensitive_line[0]}_{network_line[0]}",
                title="Sensitive-read + network-send chain detected",
                severity=Severity.HIGH,
                category="data_exfiltration",
                file_path=sf.path,
                line_number=sensitive_line[0],
                detail=(
                    f"Sensitive read near line {sensitive_line[0]} and network call near line {network_line[0]} "
                    "in the same file."
                ),
                recommendation="移除敏感数据外传链路，必要时做脱敏与显式审批。",
                snippet=sensitive_line[1].strip()[:220],
                confidence=83,
            )
        )


def detect_base64_and_entropy(sf: ScannableFile, findings: list[Finding]) -> None:
    name = os.path.basename(sf.path)
    if name in {"package-lock.json", "yarn.lock", "pnpm-lock.yaml", "poetry.lock", "Cargo.lock"}:
        return

    for idx, line in enumerate(sf.content.splitlines(), start=1):
        stripped = line.strip()

        if HIDDEN_CHAR_RE.search(line):
            findings.append(
                Finding(
                    rule_id=f"HIDDEN_CHAR_{idx}",
                    title="Hidden Unicode control characters detected",
                    severity=Severity.MEDIUM,
                    category="obfuscation",
                    file_path=sf.path,
                    line_number=idx,
                    detail="Zero-width or bidi control character may hide malicious intent.",
                    recommendation="移除隐藏字符并人工复核该行语义。",
                    snippet=repr(stripped[:220]),
                    confidence=78,
                )
            )

        for match in BASE64_RE.finditer(line):
            blob = match.group(0)
            try:
                decoded = base64.b64decode(blob, validate=False)
                text = decoded.decode("utf-8", errors="ignore").lower()
            except ValueError:
                continue

            suspicious = any(word in text for word in ("curl", "wget", "bash", "exec", "eval", "powershell"))
            sev = Severity.HIGH if suspicious else Severity.MEDIUM
            conf = 84 if suspicious else 56
            findings.append(
                Finding(
                    rule_id=f"BASE64_{idx}",
                    title="Long Base64 payload detected",
                    severity=sev,
                    category="obfuscation",
                    file_path=sf.path,
                    line_number=idx,
                    detail=f"Detected Base64 blob length={len(blob)}",
                    recommendation="解码并审计 payload，确认无隐藏执行逻辑。",
                    snippet=stripped[:220],
                    confidence=conf,
                )
            )

        if len(stripped) >= MIN_ENTROPY_LEN:
            h = entropy(stripped)
            has_cjk = any("\u4e00" <= c <= "\u9fff" for c in stripped[:80])
            local_threshold = 6.5 if (Path(sf.path).suffix.lower() in {".md", ".txt"} or has_cjk) else ENTROPY_THRESHOLD
            if h > local_threshold:
                findings.append(
                    Finding(
                        rule_id=f"HIGH_ENTROPY_{idx}",
                        title="High-entropy line detected",
                        severity=Severity.MEDIUM,
                        category="obfuscation",
                        file_path=sf.path,
                        line_number=idx,
                        detail=f"Shannon entropy={h:.2f}",
                        recommendation="检查是否为混淆、压缩或加密载荷。",
                        snippet=stripped[:220],
                        confidence=58,
                    )
                )


def detect_unrestricted_bash(sf: ScannableFile, findings: list[Finding]) -> None:
    if os.path.basename(sf.path) != "SKILL.md":
        return

    frontmatter_match = re.match(r"^---\n(.*?)\n---", sf.content, re.DOTALL)
    if not frontmatter_match:
        return

    frontmatter = frontmatter_match.group(1)
    if not re.search(r"(?i)allowed-tools\s*:\s*\[[^\]]*\bBash\b", frontmatter):
        return

    line_num = find_line_number(sf.content.splitlines(), "allowed-tools")
    findings.append(
        Finding(
            rule_id="BROAD_BASH_PERMISSION",
            title="Skill requests Bash capability",
            severity=Severity.MEDIUM,
            category="permission_scope",
            file_path=sf.path,
            line_number=line_num,
            detail="Bash capability can execute arbitrary commands if scope is not constrained.",
            recommendation="明确 Bash 命令白名单和执行边界。",
            snippet="allowed-tools includes Bash",
            confidence=66,
        )
    )


def dedupe_findings(findings: list[Finding]) -> list[Finding]:
    seen: set[tuple[str, str, int, str]] = set()
    deduped: list[Finding] = []
    for finding in findings:
        key = (finding.rule_id, finding.file_path, finding.line_number, finding.snippet)
        if key in seen:
            continue
        seen.add(key)
        deduped.append(finding)
    return deduped


def scan_files(files: list[ScannableFile]) -> list[Finding]:
    findings: list[Finding] = []

    prompt_patterns_expanded = [
        (pattern, title, severity, recommendation, confidence)
        for pattern, title, severity, recommendation, confidence in PROMPT_PATTERNS
    ]
    credential_patterns_expanded = [
        (pattern, title, severity, recommendation, confidence)
        for pattern, title, severity, recommendation, confidence in CREDENTIAL_PATTERNS
    ]
    persistence_patterns_expanded = [
        (
            pattern,
            title,
            Severity.HIGH,
            "确认无持久化副作用，不允许修改系统启动项。",
            confidence,
        )
        for pattern, title, confidence in PERSISTENCE_PATTERNS
    ]
    privilege_patterns_expanded = [
        (
            pattern,
            title,
            Severity.HIGH,
            "移除提权命令，改为最小权限执行。",
            confidence,
        )
        for pattern, title, confidence in PRIVILEGE_PATTERNS
    ]

    for sf in files:
        add_line_pattern_findings(
            findings,
            sf,
            prompt_patterns_expanded,
            rule_prefix="PROMPT_INJECTION",
            category="prompt_injection",
        )
        detect_download_exec(sf, findings)
        add_line_pattern_findings(
            findings,
            sf,
            credential_patterns_expanded,
            rule_prefix="CREDENTIAL_ACCESS",
            category="credential_access",
        )
        add_line_pattern_findings(
            findings,
            sf,
            persistence_patterns_expanded,
            rule_prefix="PERSISTENCE",
            category="persistence",
        )
        add_line_pattern_findings(
            findings,
            sf,
            privilege_patterns_expanded,
            rule_prefix="PRIV_ESC",
            category="privilege_escalation",
        )
        detect_supply_chain_hooks(sf, findings)
        detect_exfiltration_chain(sf, findings)
        detect_base64_and_entropy(sf, findings)
        detect_unrestricted_bash(sf, findings)

    findings = dedupe_findings(findings)
    findings.sort(key=lambda x: (-int(x.severity), x.file_path, x.line_number, x.rule_id))
    return findings


def severity_counts(findings: list[Finding]) -> dict[str, int]:
    counts = {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0}
    for f in findings:
        counts[str(f.severity)] += 1
    return counts


def verdict_from_counts(counts: dict[str, int]) -> str:
    if counts["CRITICAL"] > 0:
        return "BLOCK"
    if counts["HIGH"] > 0:
        return "REVIEW"
    if counts["MEDIUM"] > 0 or counts["LOW"] > 0:
        return "CAUTION"
    return "SAFE"


def format_text_report(mode: str, target: str, files_scanned: int, findings: list[Finding], truncated: bool) -> str:
    counts = severity_counts(findings)
    verdict = verdict_from_counts(counts)

    lines = []
    lines.append("")
    lines.append("=" * 70)
    lines.append("  SKILL SECURITY GUARD REPORT")
    lines.append(f"  Mode: {mode}")
    lines.append(f"  Target: {target}")
    lines.append(f"  Files scanned: {files_scanned}{' (truncated)' if truncated else ''}")
    lines.append("=" * 70)
    lines.append("")
    lines.append(
        f"  Summary: CRITICAL={counts['CRITICAL']} | HIGH={counts['HIGH']} | "
        f"MEDIUM={counts['MEDIUM']} | LOW={counts['LOW']}"
    )
    lines.append(f"  Verdict: {verdict}")
    lines.append("")

    if not findings:
        lines.append("  [SAFE] No known risky patterns detected.")
        lines.append("")
        return "\n".join(lines)

    for finding in findings:
        lines.append(f"  [{finding.severity}] {finding.rule_id}")
        lines.append(f"    File: {finding.file_path}:{finding.line_number}")
        lines.append(f"    Detail: {finding.detail}")
        lines.append(f"    Recommendation: {finding.recommendation}")
        lines.append(f"    Confidence: {finding.confidence}%")
        if finding.snippet:
            lines.append(f"    Snippet: {finding.snippet}")
        lines.append("")

    lines.append("=" * 70)
    return "\n".join(lines)


def min_severity_from_name(name: str) -> Severity:
    mapping = {
        "low": Severity.LOW,
        "medium": Severity.MEDIUM,
        "high": Severity.HIGH,
        "critical": Severity.CRITICAL,
    }
    return mapping[name.lower()]


def exit_code_from_findings(findings: list[Finding]) -> int:
    max_sev = Severity.LOW
    for f in findings:
        if f.severity > max_sev:
            max_sev = f.severity

    if not findings:
        return 0
    if max_sev >= Severity.CRITICAL:
        return 3
    if max_sev >= Severity.HIGH:
        return 2
    return 1


def run_scan(args: argparse.Namespace) -> int:
    min_sev = min_severity_from_name(args.min_severity)

    if args.mode == "local":
        files, truncated = load_local_files(args.path, args.max_files, args.max_file_size)
        target = str(Path(args.path).expanduser().resolve())
        mode = "local"
    else:
        files, truncated, _, target = load_github_files(
            args.repo,
            args.ref,
            args.token,
            args.max_files,
            args.max_file_size,
        )
        mode = "github"

    findings = [f for f in scan_files(files) if f.severity >= min_sev]
    counts = severity_counts(findings)
    verdict = verdict_from_counts(counts)

    report = {
        "mode": mode,
        "target": target,
        "files_scanned": len(files),
        "truncated": truncated,
        "min_severity": str(min_sev),
        "summary": {
            "severity_counts": counts,
            "findings_total": len(findings),
            "verdict": verdict,
        },
        "findings": [f.to_dict() for f in findings],
    }

    if args.json_output:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(format_text_report(mode, target, len(files), findings, truncated))

    return exit_code_from_findings(findings)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Scan AI skill packages for common security risks (local or GitHub)."
    )
    parser.add_argument(
        "--json",
        action="store_true",
        dest="json_output",
        help="Output JSON report.",
    )
    parser.add_argument(
        "--min-severity",
        choices=["low", "medium", "high", "critical"],
        default="low",
        help="Minimum severity to report.",
    )
    parser.add_argument("--max-files", type=int, default=500, help="Maximum files to scan.")
    parser.add_argument(
        "--max-file-size",
        type=int,
        default=1_000_000,
        help="Maximum bytes per file.",
    )

    sub = parser.add_subparsers(dest="mode", required=True)

    local_parser = sub.add_parser("local", help="Scan a local skill directory.")
    local_parser.add_argument("--path", required=True, help="Path to local skill directory.")

    github_parser = sub.add_parser("github", help="Scan a GitHub repo without cloning.")
    github_parser.add_argument("--repo", required=True, help="GitHub repo: owner/repo or URL.")
    github_parser.add_argument("--ref", help="Branch/tag/commit. Default: repository default branch.")
    github_parser.add_argument(
        "--token",
        help="GitHub token. Optional. If omitted, use GITHUB_TOKEN env if available.",
    )

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.mode == "github" and not getattr(args, "token", None):
        env_token = os.environ.get("GITHUB_TOKEN")
        if env_token:
            args.token = env_token

    try:
        return run_scan(args)
    except ValueError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 4
    except urllib.error.HTTPError as exc:
        message = exc.read().decode("utf-8", errors="replace") if hasattr(exc, "read") else str(exc)
        print(f"[ERROR] GitHub API request failed: HTTP {exc.code} - {message}", file=sys.stderr)
        return 4
    except urllib.error.URLError as exc:
        print(f"[ERROR] Network error: {exc}", file=sys.stderr)
        return 4
    except Exception as exc:  # noqa: BLE001
        print(f"[ERROR] Scanner failed: {exc}", file=sys.stderr)
        return 4


if __name__ == "__main__":
    raise SystemExit(main())
