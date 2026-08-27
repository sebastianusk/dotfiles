---
name: deep-debug
description: Root-cause investigation for difficult, recurring, multi-component, or poorly understood failures
---

# Deep Debug

Use this workflow when normal debugging has not produced a clear answer.

## 1. Establish the failure

- Reproduce it reliably when possible.
- Read the complete error/output.
- Separate observed facts from assumptions.

## 2. Trace the source

Follow the failing state, value, or behavior backward.

Ask:
- Where was the bad state first introduced?
- What supplied it?
- What assumptions exist at each boundary?

For multi-component systems, gather evidence at component boundaries before changing implementation.

## 3. Compare

Find a known-working equivalent when available.

Identify concrete differences between working and failing paths.

## 4. Form one hypothesis

State one specific explanation for the failure.

Choose the smallest experiment that can prove or disprove it.

Run the experiment.

## 5. Fix

Once the cause is supported by evidence:

- make the smallest change that addresses the root cause;
- run the narrowest verification that demonstrates the fix;
- check for directly related regressions.

## 6. Reconsider when stuck

If multiple materially different fixes have failed, revisit the underlying assumptions or architecture instead of accumulating more fixes.

Report what is known, what was disproven, and what remains uncertain.
