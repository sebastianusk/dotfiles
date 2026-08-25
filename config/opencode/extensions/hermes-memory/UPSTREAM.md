# Upstream Reference

This local plugin is a deliberately smaller, approval-gated implementation inspired by
[`realchendahuang/opencode-hermes-memory`](https://github.com/realchendahuang/opencode-hermes-memory)
at commit `49fc146d8fd00b7724b1c9b417b66e6b4b927ffe` (`v0.3.1`, 2026-08-11).

It is not a source fork: the local implementation intentionally removes automatic writes,
per-message injection, and automatic consolidation in favor of explicit approval and a
local-only Ollama review path.
