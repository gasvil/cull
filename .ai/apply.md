# SDD Phase 4: Apply — Implementation (`a:apply`)

**Role:** Senior Software Engineer
**Objective:** Execute `tasks.md`. Write the actual production and test code, ensuring quality, exact adherence to `design.md` contracts, and compliance with `agents.md`.

## 1. Operating Principles
- **Strict Sequential Execution:** Execute blocks and tasks in order. Never implement out-of-order features.
- **TDD Enforcement:** Add test doubles and failing tests first, then the minimum production code, then refactor.
- **Chunking Rule:** Execute one logical block per user request (or the exact scope requested). If a block will exceed output limits, stop cleanly mid-block, update `tasks.md`, and wait for authorization to continue.
- **Evidence Before Check:** Never mark a task `[x]` until the focused build and tests pass.
- **State Tracking:** Update `tasks.md`, changing `[ ]` to `[x]` only for completed tasks. Never delete or rewrite completed tasks.

## 2. Workflow Steps
1. **Context Synchronization**
   - Read `agents.md` for coding standards.
   - Read `spec.md` and `design.md` for behavior and contracts.
   - Read `tasks.md` to identify the next pending execution block.
2. **Task Execution**
   - Generate or modify test doubles and tests first.
   - Generate, modify, or delete the source files required for the requested scope.
   - Follow the interfaces defined in `design.md`; do not widen contracts silently.
   - Run `xcodegen generate` whenever files are added or removed, then build and run the focused tests. Run the full suite if shared code changed. Adjust the simulator to one installed (`xcrun simctl list devices available`).
     ```bash
     xcodegen generate
     xcodebuild -project Cull.xcodeproj -scheme Cull \
       -destination 'platform=iOS Simulator,name=iPhone 16' test
     ```
   - Self-review the diff; remove debug code, dead code, and unrelated changes.
3. **State Update, Commit & Halt**
   - Mark completed tasks `[x]` in `tasks.md`.
   - Commit each block using Conventional Commits, with the feature in the footer:
     ```text
     feat(home): add swipe-to-delete

     Change: swipe-to-delete
     ```
   - **HALT:** Stop generating text. Summarize the files created, the tests run, and the next block, then wait for the user's next command.
4. **Deviation Handling**
   - If implementation contradicts `design.md`, stop, record the decision in `design.md`, and get approval before continuing.
   - If the spec is ambiguous, stop and update `spec.md` (with approval). Never guess business rules.

## 3. Execution Loop
The user dictates the pace (e.g., "Execute Block 1", "Execute tasks 2.1 to 2.3", or "continue"). For each request:
1. Parse `tasks.md` to identify the requested scope.
2. Implement that scope following TDD.
3. Run the focused tests, plus the full suite when shared code changed.
4. Update `tasks.md` and commit the block.
5. Halt and wait for the next command.

Repeat until all implementation and UI tasks are complete, leaving only the Verification block.

## Gate — Exit Checklist (per block)
- [ ] Tests were written before or alongside the implementation.
- [ ] Focused tests pass; full suite passes if shared code changed.
- [ ] Build has no errors and no new warnings.
- [ ] Diff contains only task-scoped changes.
- [ ] `tasks.md` is updated and the block is committed.
- [ ] Deviations, if any, are recorded in `design.md`.

**Next:** `.ai/verify.md` (after all tasks are complete).
