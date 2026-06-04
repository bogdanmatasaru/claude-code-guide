---
name: write-tests
description: Write focused tests for a given file or function and run them until they pass. Use when asked to add or improve test coverage. Pass the target as an argument, e.g. /write-tests src/auth.ts.
allowed-tools: Bash(npm test:*) Bash(npx vitest:*) Bash(npx jest:*) Bash(pytest:*) Bash(uv run pytest:*) Bash(go test:*)
---

# Write Tests

Target: **$ARGUMENTS** (a file path, function, or behavior). If empty, ask what to test.

## Steps

1. **Understand the code.** Read the target and its direct dependencies. Identify the
   public behavior, inputs, outputs, and error paths.
2. **Detect the test setup.** Match the project's existing framework and conventions —
   look at neighboring test files for the runner (Vitest/Jest/pytest/go test), assertion
   style, file naming, and mocking approach. Do not introduce a new framework.
3. **Write tests** covering:
   - The happy path.
   - Edge cases: empty/null inputs, boundaries, large/invalid input.
   - Error handling: does it throw/return the right thing when it should?
   - One behavior per test; name tests by the behavior they assert.
4. **Run them** with the project's test command. Iterate until green.
5. If a test reveals a real bug in the code under test, **stop and report it** rather than
   weakening the test to make it pass.

## Rules

- Test observable behavior, not implementation details.
- Prefer real objects; mock only true external boundaries (network, clock, filesystem).
- Keep tests deterministic — no real network, no sleeps, no reliance on wall-clock time.
- Don't delete or skip existing tests to get a green run.
