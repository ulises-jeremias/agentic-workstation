"""Unit tests for :mod:`llm_dispatcher`.

We patch each provider's ``is_available`` so the tests pass on machines without
``opencode``, ``ollama``, ``ANTHROPIC_API_KEY`` or ``OPENAI_API_KEY``.
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from llm_dispatcher import LLMDispatcher  # noqa: E402
from policy import LLMPolicy  # noqa: E402


def _make_available(*providers_available: str):
    """Patch ``is_available`` on every provider so only the listed names report
    True. Returns a list of ``mock.patch`` objects already started."""
    targets = {
        "opencode": "providers.opencode_provider.OpenCodeProvider.is_available",
        "ollama": "providers.ollama_provider.OllamaProvider.is_available",
        "anthropic": "providers.anthropic_provider.AnthropicProvider.is_available",
        "openai": "providers.openai_provider.OpenAIProvider.is_available",
    }
    patches = []
    for name, target in targets.items():
        patcher = mock.patch(target, return_value=name in providers_available)
        patcher.start()
        patches.append(patcher)
    return patches


class DispatcherSelectionTests(unittest.TestCase):
    def setUp(self) -> None:
        self._patches: list[mock._patch] = []

    def tearDown(self) -> None:
        for patcher in self._patches:
            patcher.stop()

    def test_default_picks_first_available_by_priority(self) -> None:
        self._patches = _make_available("anthropic", "opencode")
        dispatcher = LLMDispatcher()
        provider = dispatcher.get_available_provider()
        assert provider is not None
        # OpenCode has priority 1, so it should win over Anthropic (10) by default.
        self.assertEqual(provider.name, "opencode")

    def test_allowlist_skips_opencode_in_favor_of_anthropic(self) -> None:
        self._patches = _make_available("anthropic", "opencode")
        policy = LLMPolicy(allowlist=("anthropic",))
        dispatcher = LLMDispatcher(policy=policy)
        provider = dispatcher.get_available_provider()
        assert provider is not None
        self.assertEqual(provider.name, "anthropic")

    def test_strict_no_provider_returns_policy_violation_error(self) -> None:
        # Only OpenCode is "available", but policy forbids it.
        self._patches = _make_available("opencode")
        policy = LLMPolicy(allowlist=("anthropic",), strict=True)
        dispatcher = LLMDispatcher(policy=policy)
        response, error = dispatcher.generate(prompt="hello")
        self.assertIsNone(response)
        self.assertEqual(error, LLMDispatcher.POLICY_VIOLATION)

    def test_non_strict_no_provider_returns_no_provider(self) -> None:
        self._patches = _make_available("opencode")
        policy = LLMPolicy(allowlist=("anthropic",), strict=False)
        dispatcher = LLMDispatcher(policy=policy)
        response, error = dispatcher.generate(prompt="hello")
        self.assertIsNone(response)
        self.assertEqual(error, "no_provider")

    def test_pinned_provider_unavailable_under_strict_fails_closed(self) -> None:
        self._patches = _make_available("opencode")
        policy = LLMPolicy(pinned_provider="anthropic", strict=True)
        dispatcher = LLMDispatcher(policy=policy)
        response, error = dispatcher.generate(prompt="hello")
        self.assertIsNone(response)
        self.assertEqual(error, LLMDispatcher.POLICY_VIOLATION)

    def test_list_candidates_reports_filtered_set(self) -> None:
        self._patches = _make_available("anthropic", "opencode", "openai")
        policy = LLMPolicy(allowlist=("anthropic", "openai"))
        dispatcher = LLMDispatcher(policy=policy)
        names = [c["name"] for c in dispatcher.list_candidates()]
        self.assertEqual(names, ["anthropic", "openai"])

    def test_list_all_providers_reports_in_policy_flag(self) -> None:
        self._patches = _make_available("anthropic")
        policy = LLMPolicy(allowlist=("anthropic",))
        dispatcher = LLMDispatcher(policy=policy)
        snapshot = {p["name"]: p for p in dispatcher.list_all_providers()}
        self.assertTrue(snapshot["anthropic"]["in_policy"])
        self.assertFalse(snapshot["opencode"]["in_policy"])

    def test_pinned_model_overrides_default(self) -> None:
        self._patches = _make_available("anthropic")
        policy = LLMPolicy(pinned_provider="anthropic", pinned_model="claude-3-7-sonnet")
        dispatcher = LLMDispatcher(policy=policy)
        provider = dispatcher.get_available_provider()
        assert provider is not None
        self.assertEqual(provider.get_model_name(), "claude-3-7-sonnet")


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
