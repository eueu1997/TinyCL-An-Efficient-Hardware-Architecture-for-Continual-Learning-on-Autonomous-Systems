from __future__ import annotations

import argparse
import hashlib
import os
import sys
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path
from typing import cast

from llama_cpp import Llama
from llama_cpp.llama_chat_format import format_chatml
from llama_cpp.llama_types import (
    ChatCompletionRequestMessage,
    CreateCompletionStreamResponse,
)


ROOT = Path(__file__).resolve().parent


@dataclass(frozen=True)
class ModelConfig:
    label: str
    repo: str
    filename: str
    revision: str
    sha256: str
    size_bytes: int

    @property
    def path(self) -> Path:
        return ROOT / "models" / self.filename


DEFAULT_MODEL = "qwen2.5-coder-1.5b"
MODELS = {
    DEFAULT_MODEL: ModelConfig(
        label="Qwen2.5-Coder-1.5B-Instruct",
        repo="Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF",
        filename="qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
        revision="f86cb2c1fa58255f8052cc32aeede1b7482d4361",
        sha256="cc324af070c2ecbfd324a30884d2f951a7ff756aba85cb811a6ec436933bb046",
        size_bytes=1117320768,
    ),
    "qwen2.5-coder-7b": ModelConfig(
        label="Qwen2.5-Coder-7B-Instruct",
        repo="Qwen/Qwen2.5-Coder-7B-Instruct-GGUF",
        filename="qwen2.5-coder-7b-instruct-q4_k_m.gguf",
        revision="13fb94bfda8c8cf22497dc57b78f391a9acb426a",
        sha256="509287f78cb4d4cf6b3843734733b914b2c158e43e22a7f4bf5e963800894d3c",
        size_bytes=4683073536,
    ),
    "qwen3-4b": ModelConfig(
        label="Qwen3-4B-Instruct-2507",
        repo="unsloth/Qwen3-4B-Instruct-2507-GGUF",
        filename="Qwen3-4B-Instruct-2507-Q4_K_M.gguf",
        revision="a06e946bb6b655725eafa393f4a9745d460374c9",
        sha256="3605803b982cb64aead44f6c1b2ae36e3acdb41d8e46c8a94c6533bc4c67e597",
        size_bytes=2497281120,
    ),
}
SYSTEM_PROMPT = (
    "You are Qwen, a helpful coding assistant. "
    "Rispondi in italiano, salvo diversa richiesta. "
    "Dichiara le incertezze e non affermare di aver eseguito codice o simulazioni."
)
HELP = "/exit: esci | /reset: nuova chat | /multi: testo su piu righe | /help: aiuto"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Chat locale con tre modelli Qwen Q4_K_M, solo CPU.")
    parser.add_argument("--model", choices=MODELS, default=DEFAULT_MODEL, help=f"Modello da usare (default: {DEFAULT_MODEL}).")
    parser.add_argument("--download-only", action="store_true", help="Scarica e verifica il modello, poi esci.")
    parser.add_argument("--prompt", help="Esegui una singola richiesta, poi esci.")
    parser.add_argument("--context", type=int, default=2048, help="Token totali di contesto (default: 2048).")
    parser.add_argument("--max-tokens", type=int, default=256, help="Massimo di token per risposta (default: 256).")
    parser.add_argument("--threads", type=int, default=min(4, os.cpu_count() or 1), help="Thread CPU (default: massimo 4).")
    parser.add_argument("--system", default=SYSTEM_PROMPT, help="Istruzioni di sistema.")
    args = parser.parse_args(argv)
    if not 256 <= args.context <= 32768:
        parser.error("--context deve essere compreso tra 256 e 32768.")
    if not 1 <= args.max_tokens < args.context:
        parser.error("--max-tokens deve essere positivo e minore di --context.")
    if args.threads < 1:
        parser.error("--threads deve essere positivo.")
    if args.prompt is not None and not args.prompt.strip():
        parser.error("--prompt non puo essere vuoto.")
    return args


def download_model(config: ModelConfig) -> Path:
    os.environ["HF_HUB_DISABLE_TELEMETRY"] = "1"
    os.environ["HF_HUB_DISABLE_XET"] = "1"
    os.environ.setdefault("HF_HOME", str(ROOT / ".cache" / "huggingface"))
    from huggingface_hub import hf_hub_download

    print(f"Download/verifica {config.label} Q4_K_M ({config.size_bytes / 1e9:.2f} GB)...", flush=True)
    model_path = Path(hf_hub_download(
        repo_id=config.repo,
        filename=config.filename,
        revision=config.revision,
        local_dir=config.path.parent,
        token=False,
    ))
    with model_path.open("rb") as model_stream:
        checksum = hashlib.file_digest(model_stream, "sha256").hexdigest()
    if checksum != config.sha256:
        raise ValueError(f"Hash SHA256 non valido per {model_path}. Rimuovi il file e riprova.")
    print(f"SHA256 verificato. Modello: {model_path}", flush=True)
    return model_path


def fit_context(
    model: Llama,
    messages: list[ChatCompletionRequestMessage],
    max_tokens: int,
) -> tuple[list[int], str | list[str], int]:
    removed = 0
    while True:
        formatted = format_chatml(messages=messages)
        tokens = model.tokenize(formatted.prompt.encode("utf-8"), add_bos=False, special=True)
        if len(tokens) + max_tokens <= model.n_ctx():
            return tokens, formatted.stop or [], removed
        if len(messages) <= 2:
            raise ValueError("Richiesta troppo lunga: riduci il testo o --max-tokens, oppure aumenta --context.")
        del messages[1:3]
        removed += 1


def reply(
    model: Llama,
    history: list[ChatCompletionRequestMessage],
    text: str,
    max_tokens: int,
) -> None:
    messages: list[ChatCompletionRequestMessage] = [*history, {"role": "user", "content": text}]
    prompt_tokens, stop, removed = fit_context(model, messages, max_tokens)
    if removed:
        print(f"[Contesto: rimosse {removed} coppie di messaggi meno recenti.]")
    stream = cast(Iterator[CreateCompletionStreamResponse], model.create_completion(
        prompt=prompt_tokens,
        stop=stop,
        max_tokens=max_tokens,
        temperature=0.7,
        top_p=0.8,
        top_k=20,
        repeat_penalty=1.05,
        stream=True,
    ))
    fragments: list[str] = []
    finish_reason = None
    print("Qwen> ", end="", flush=True)
    for chunk in stream:
        choice = chunk["choices"][0]
        fragment = choice["text"]
        fragments.append(fragment)
        print(fragment, end="", flush=True)
        if choice["finish_reason"] is not None:
            finish_reason = choice["finish_reason"]
    print()
    answer = "".join(fragments).strip()
    if not answer:
        raise RuntimeError("Il modello non ha prodotto testo. Prova /reset o una richiesta diversa.")
    messages.append({"role": "assistant", "content": answer})
    history[:] = messages
    if finish_reason == "length":
        print("[Raggiunto --max-tokens; puoi chiedere di continuare.]")


def read_message() -> str:
    text = input("Tu> ").strip()
    if text != "/multi":
        return text
    print("Incolla il testo; termina con /end su una riga separata.")
    lines: list[str] = []
    while True:
        line = input("... ")
        if line.strip() == "/end":
            return "\n".join(lines).strip()
        lines.append(line)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    config = MODELS[args.model]
    if args.download_only or not config.path.is_file():
        download_model(config)
    if args.download_only:
        return 0
    print(f"Caricamento {config.label} Q4_K_M su CPU: {args.threads} thread, contesto {args.context} token...", flush=True)
    model = Llama(
        model_path=str(config.path),
        n_gpu_layers=0,
        offload_kqv=False,
        n_ctx=args.context,
        n_threads=args.threads,
        n_threads_batch=args.threads,
        n_batch=min(128, args.context),
        use_mmap=True,
        verbose=False,
    )
    history: list[ChatCompletionRequestMessage] = [{"role": "system", "content": args.system}]
    try:
        if args.prompt is not None:
            reply(model, history, args.prompt, args.max_tokens)
            return 0
        print(HELP)
        while True:
            try:
                text = read_message()
            except EOFError:
                print()
                return 0
            if not text:
                continue
            if text in {"/exit", "/quit"}:
                return 0
            if text == "/reset":
                history[:] = [{"role": "system", "content": args.system}]
                model.reset()
                print("Cronologia azzerata.")
                continue
            if text == "/help":
                print(HELP)
                continue
            try:
                reply(model, history, text, args.max_tokens)
            except (ValueError, RuntimeError) as error:
                print(f"Errore: {error}", file=sys.stderr)
    finally:
        model.close()


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\nChat interrotta.")
        raise SystemExit(130)
    except (OSError, ValueError, RuntimeError) as error:
        print(f"Errore: {error}", file=sys.stderr)
        raise SystemExit(1)