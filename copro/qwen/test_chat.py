import contextlib
import hashlib
import io
import unittest
from dataclasses import replace
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import Mock, patch

import chat


class ChatTests(unittest.TestCase):
    def setUp(self):
        def tokenize(data: bytes, **kwargs: bool) -> list[int]:
            return list(data)

        self.model = Mock(spec=chat.Llama)
        self.model.tokenize.side_effect = tokenize
        self.model.n_ctx.return_value = 2048
        self.system: chat.ChatCompletionRequestMessage = {"role": "system", "content": "Rispondi brevemente."}

    def test_argument_validation(self):
        for arguments in (
            ["--threads", "0"],
            ["--context", "128"],
            ["--context", "256", "--max-tokens", "256"],
            ["--max-tokens", "0"],
            ["--prompt", "   "],
            ["--model", "unknown"],
        ):
            with self.subTest(arguments=arguments), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as result:
                    chat.parse_args(arguments)
                self.assertEqual(result.exception.code, 2)

    def test_model_selection(self):
        self.assertEqual(chat.parse_args([]).model, "qwen2.5-coder-1.5b")
        self.assertEqual(set(chat.MODELS), {"qwen2.5-coder-1.5b", "qwen2.5-coder-7b", "qwen3-4b"})
        self.assertEqual(len({config.path for config in chat.MODELS.values()}), 3)
        for model_id in chat.MODELS:
            with self.subTest(model=model_id):
                self.assertEqual(chat.parse_args(["--model", model_id]).model, model_id)

    def test_main_loads_only_selected_model_on_cpu(self):
        for model_id, config in chat.MODELS.items():
            for exists in (True, False):
                with (
                    self.subTest(model=model_id, exists=exists),
                    patch.object(chat.Path, "is_file", return_value=exists),
                    patch.object(chat, "download_model") as download,
                    patch.object(chat, "Llama") as loader,
                    patch.object(chat, "reply") as reply,
                    contextlib.redirect_stdout(io.StringIO()),
                ):
                    self.assertEqual(chat.main(["--model", model_id, "--prompt", "Ciao"]), 0)
                    loader.assert_called_once()
                    self.assertEqual(loader.call_args.kwargs["model_path"], str(config.path))
                    self.assertEqual(loader.call_args.kwargs["n_gpu_layers"], 0)
                    self.assertFalse(loader.call_args.kwargs["offload_kqv"])
                    reply.assert_called_once()
                    loader.return_value.close.assert_called_once()
                    if exists:
                        download.assert_not_called()
                    else:
                        download.assert_called_once_with(config)

    def test_download_only_does_not_load_any_model(self):
        for model_id, config in chat.MODELS.items():
            with (
                self.subTest(model=model_id),
                patch.object(chat, "download_model") as download,
                patch.object(chat, "Llama") as loader,
            ):
                self.assertEqual(chat.main(["--model", model_id, "--download-only"]), 0)
                download.assert_called_once_with(config)
                loader.assert_not_called()

    def test_download_uses_selected_metadata_and_hash(self):
        payload = b"test model payload"
        with TemporaryDirectory() as folder:
            model_path = Path(folder) / "model.gguf"
            model_path.write_bytes(payload)
            for model_id, original in chat.MODELS.items():
                config = replace(original, sha256=hashlib.sha256(payload).hexdigest())
                with (
                    self.subTest(model=model_id),
                    patch.dict(chat.os.environ),
                    patch("huggingface_hub.hf_hub_download", return_value=str(model_path)) as download,
                    contextlib.redirect_stdout(io.StringIO()),
                ):
                    self.assertEqual(chat.download_model(config), model_path)
                    download.assert_called_once_with(
                        repo_id=config.repo,
                        filename=config.filename,
                        revision=config.revision,
                        local_dir=config.path.parent,
                        token=False,
                    )
                    with self.assertRaisesRegex(ValueError, "SHA256 non valido"):
                        chat.download_model(replace(config, sha256="0" * 64))

    def test_context_removes_complete_old_turns(self):
        latest: chat.ChatCompletionRequestMessage = {"role": "user", "content": "Ultima domanda"}
        messages: list[chat.ChatCompletionRequestMessage] = [
            self.system,
            {"role": "user", "content": "Domanda precedente" * 20},
            {"role": "assistant", "content": "Risposta precedente" * 20},
            latest,
        ]
        expected: list[chat.ChatCompletionRequestMessage] = [self.system, latest]
        prompt_length = len(chat.format_chatml(messages=expected).prompt.encode("utf-8"))
        self.model.n_ctx.return_value = prompt_length + 32
        tokens, _, removed = chat.fit_context(self.model, messages, 32)
        self.assertEqual(messages, expected)
        self.assertEqual(removed, 1)
        self.assertEqual(len(tokens) + 32, self.model.n_ctx())
        self.model.tokenize.assert_called_with(
            chat.format_chatml(messages=expected).prompt.encode("utf-8"),
            add_bos=False,
            special=True,
        )

    def test_short_context_keeps_history(self):
        messages: list[chat.ChatCompletionRequestMessage] = [self.system, {"role": "user", "content": "Ciao"}]
        original = list(messages)
        _, _, removed = chat.fit_context(self.model, messages, 32)
        self.assertEqual(messages, original)
        self.assertEqual(removed, 0)

    def test_oversized_request_does_not_change_history(self):
        history: list[chat.ChatCompletionRequestMessage] = [self.system]
        self.model.n_ctx.return_value = 32
        with self.assertRaisesRegex(ValueError, "troppo lunga"):
            chat.reply(self.model, history, "Domanda" * 100, 16)
        self.assertEqual(history, [self.system])
        self.model.create_completion.assert_not_called()

    def test_streaming_records_full_response(self):
        history: list[chat.ChatCompletionRequestMessage] = [self.system]
        chunks: list[dict[str, object]] = [
            {"choices": [{"text": "Ciao ", "finish_reason": None}]},
            {"choices": [{"text": "utente", "finish_reason": None}]},
            {"choices": [{"text": "", "finish_reason": "length"}]},
        ]
        self.model.create_completion.return_value = iter(chunks)
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            chat.reply(self.model, history, "Saluta", 32)
        self.assertEqual(history[-2], {"role": "user", "content": "Saluta"})
        self.assertEqual(history[-1], {"role": "assistant", "content": "Ciao utente"})
        self.assertIn("Qwen> Ciao utente", output.getvalue())
        self.assertIn("Raggiunto --max-tokens", output.getvalue())
        self.assertTrue(self.model.create_completion.call_args.kwargs["stream"])

    def test_empty_response_does_not_change_history(self):
        history: list[chat.ChatCompletionRequestMessage] = [self.system]
        self.model.create_completion.return_value = iter([])
        with contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(RuntimeError, "non ha prodotto testo"):
                chat.reply(self.model, history, "Ciao", 32)
        self.assertEqual(history, [self.system])


if __name__ == "__main__":
    unittest.main()