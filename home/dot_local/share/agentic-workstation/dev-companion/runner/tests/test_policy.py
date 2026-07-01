"""Unit tests for :mod:`policy`.

Run them from inside the runner directory:

    python3 -m unittest tests.test_policy

These tests do not require any LLM provider to be installed: they only exercise
parsing, merging, validation, and filtering against fake provider stubs.
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from policy import KNOWN_PROVIDERS, LLMPolicy, PolicyError, merge_policies  # noqa: E402


class _FakeProvider:
    def __init__(self, name: str, priority: int = 100, available: bool = True) -> None:
        self.name = name
        self.model = f"{name}/model-default"
        self._priority = priority
        self._available = available

    def get_priority(self) -> int:
        return self._priority

    def is_available(self) -> bool:
        return self._available

    def get_model_name(self) -> str:
        return self.model


def _providers() -> list[_FakeProvider]:
    return [
        _FakeProvider("opencode", priority=1),
        _FakeProvider("ollama", priority=2),
        _FakeProvider("anthropic", priority=10),
        _FakeProvider("openai", priority=20),
    ]


class PolicyEnvLoadingTests(unittest.TestCase):
    def test_empty_env_yields_empty_policy(self) -> None:
        policy = LLMPolicy.from_env(env={})
        self.assertIsNone(policy.allowlist)
        self.assertEqual(policy.denylist, ())
        self.assertFalse(policy.strict)
        self.assertEqual(policy.sources, ())

    def test_allowlist_normalized_lowercase_and_ordered(self) -> None:
        policy = LLMPolicy.from_env(env={
            "DOTS_WORKSTATION_DEVCOMPANION_LLM_ALLOWLIST": "Anthropic, OpenCode",
        })
        self.assertEqual(policy.allowlist, ("anthropic", "opencode"))
        self.assertIn("env", policy.sources)

    def test_strict_truthy(self) -> None:
        for value in ("1", "true", "TRUE", "yes", "on"):
            policy = LLMPolicy.from_env(env={"DOTS_WORKSTATION_DEVCOMPANION_LLM_STRICT": value})
            self.assertTrue(policy.strict, value)
        for value in ("0", "false", "no", "", "maybe"):
            policy = LLMPolicy.from_env(env={"DOTS_WORKSTATION_DEVCOMPANION_LLM_STRICT": value})
            self.assertFalse(policy.strict, value)

    def test_unknown_provider_warning(self) -> None:
        policy = LLMPolicy.from_env(env={
            "DOTS_WORKSTATION_DEVCOMPANION_LLM_ALLOWLIST": "anthropic,cursor",
        })
        self.assertIn("anthropic", policy.allowlist or ())
        joined = " ".join(policy.warnings)
        self.assertIn("cursor", joined)


class PolicyFileLoadingTests(unittest.TestCase):
    def test_missing_file_is_empty(self) -> None:
        policy = LLMPolicy.from_file("/nonexistent/path.json")
        self.assertIsNone(policy.allowlist)
        self.assertEqual(policy.sources, ())

    def test_json_file_loaded(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "policy.json"
            path.write_text(
                json.dumps({
                    "allowlist": ["anthropic"],
                    "strict": True,
                }),
                encoding="utf-8",
            )
            policy = LLMPolicy.from_file(path)
        self.assertEqual(policy.allowlist, ("anthropic",))
        self.assertTrue(policy.strict)
        self.assertTrue(policy.sources and policy.sources[0].startswith("file:"))


class PolicyJobLoadingTests(unittest.TestCase):
    def test_bool_llm_value_is_ignored(self) -> None:
        # Legacy "llm: true/false" should be treated as "no overrides".
        self.assertEqual(LLMPolicy.from_job(True), LLMPolicy.empty())
        self.assertEqual(LLMPolicy.from_job(False), LLMPolicy.empty())

    def test_provider_alias_for_pin(self) -> None:
        policy = LLMPolicy.from_job({"provider": "anthropic", "model": "claude-x"})
        self.assertEqual(policy.pinned_provider, "anthropic")
        self.assertEqual(policy.pinned_model, "claude-x")


class PolicyMergeTests(unittest.TestCase):
    def test_job_subset_allowed(self) -> None:
        base = LLMPolicy(allowlist=("anthropic", "openai"))
        job = LLMPolicy(allowlist=("anthropic",), sources=("job",))
        merged = merge_policies(base, job, _validate_restriction=True)
        self.assertEqual(merged.allowlist, ("anthropic",))

    def test_job_widening_raises(self) -> None:
        base = LLMPolicy(allowlist=("anthropic",))
        job = LLMPolicy(allowlist=("anthropic", "openai"), sources=("job",))
        with self.assertRaises(PolicyError):
            merge_policies(base, job, _validate_restriction=True)

    def test_job_pin_outside_global_allowlist(self) -> None:
        base = LLMPolicy(allowlist=("anthropic",))
        job = LLMPolicy(pinned_provider="openai", sources=("job",))
        with self.assertRaises(PolicyError):
            merge_policies(base, job, _validate_restriction=True)

    def test_job_pin_in_denylist(self) -> None:
        base = LLMPolicy(denylist=("opencode",))
        job = LLMPolicy(pinned_provider="opencode", sources=("job",))
        with self.assertRaises(PolicyError):
            merge_policies(base, job, _validate_restriction=True)

    def test_strict_can_only_escalate(self) -> None:
        base = LLMPolicy(strict=True)
        job = LLMPolicy(strict=False, sources=("job",))
        merged = merge_policies(base, job, _validate_restriction=True)
        self.assertTrue(merged.strict)
        self.assertTrue(any("strict" in w for w in merged.warnings))

    def test_denylist_is_additive(self) -> None:
        base = LLMPolicy(denylist=("ollama",))
        job = LLMPolicy(denylist=("opencode",))
        merged = merge_policies(base, job, _validate_restriction=True)
        self.assertEqual(set(merged.denylist), {"ollama", "opencode"})


class PolicyFilterTests(unittest.TestCase):
    def test_no_policy_uses_intrinsic_priority(self) -> None:
        policy = LLMPolicy.empty()
        ordered = policy.filter(_providers())
        names = [p.name for p in ordered]
        self.assertEqual(names, ["opencode", "ollama", "anthropic", "openai"])

    def test_allowlist_overrides_intrinsic_order(self) -> None:
        policy = LLMPolicy(allowlist=("anthropic", "opencode"))
        ordered = policy.filter(_providers())
        names = [p.name for p in ordered]
        self.assertEqual(names, ["anthropic", "opencode"])

    def test_denylist_drops_provider(self) -> None:
        policy = LLMPolicy(denylist=("opencode", "ollama"))
        ordered = policy.filter(_providers())
        names = [p.name for p in ordered]
        self.assertEqual(names, ["anthropic", "openai"])

    def test_pinned_provider_isolates_choice(self) -> None:
        policy = LLMPolicy(pinned_provider="anthropic", pinned_model="claude-x")
        ordered = policy.filter(_providers())
        self.assertEqual([p.name for p in ordered], ["anthropic"])
        self.assertEqual(ordered[0].model, "claude-x")

    def test_pinned_provider_in_denylist_returns_empty(self) -> None:
        policy = LLMPolicy(pinned_provider="opencode", denylist=("opencode",))
        self.assertEqual(policy.filter(_providers()), [])


class PolicyAuditTests(unittest.TestCase):
    def test_audit_dict_is_json_serializable(self) -> None:
        policy = LLMPolicy(
            allowlist=("anthropic",),
            denylist=("opencode",),
            pinned_provider="anthropic",
            pinned_model="claude-x",
            strict=True,
            sources=("env", "job"),
            warnings=("env: allowlist contains unknown provider 'cursor'",),
        )
        encoded = json.dumps(policy.to_audit())
        decoded = json.loads(encoded)
        self.assertEqual(decoded["allowlist"], ["anthropic"])
        self.assertEqual(decoded["denylist"], ["opencode"])
        self.assertEqual(decoded["pinned_provider"], "anthropic")
        self.assertTrue(decoded["strict"])


class PolicyKnownProvidersTests(unittest.TestCase):
    def test_known_providers_set(self) -> None:
        self.assertEqual(
            set(KNOWN_PROVIDERS),
            {"opencode", "ollama", "anthropic", "openai"},
        )


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
