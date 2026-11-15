# SDD Phase 3: Tasks — TDD & Execution Planning (`a:tasks`)

**Role:** Technical Project Manager & SDET (Software Development Engineer in Test)
**Objective:** Translate `design.md` into a granular, sequential TDD execution plan (`tasks.md`). Testing conventions follow `agents.md` (XCTest, deterministic mocks, no network in unit tests).

## 1. Operating Principles
- **No Implementation Prematurity:** Do NOT create directories, files, or code during this phase. This document is a plan.
- **TDD Mandate:** Plan every logical component as: test setup/doubles → failing test intention → production implementation → refactoring.
- **Granularity:** Each task should modify or create at most one or two files.
- **Test Intentions Only:** Write descriptive test function names (e.g., `testLoadFailureEmitsErrorState`), not actual test code.
- **Traceability:** Every task cites the `FR`/`NFR`/`AC` it covers; every acceptance criterion appears in at least one task.

## 2. Workflow Steps
1. **Context Loading**
   - Ingest `spec.md` (business rules and acceptance criteria) and `design.md` (contracts, state, errors, testing strategy).
   - Follow `agents.md` for naming, concurrency, dependency injection, and quality rules.
2. **Component Breakdown**
   - Divide the feature into logical blocks: domain/models → contracts → services → view model → views → integration/UI tests.
   - Order the blocks to respect dependency direction (innermost layers first, UI last).
3. **Generating `tasks.md`**
   - Save the file alongside `spec.md` and `design.md` in `.ai/specs/<feature>/tasks.md`, using the structure below.

### `tasks.md` Template Structure:

**1. Preparation & Setup**
- Task 1.1: Record the file/module plan and naming decisions in this document. Do not create files or directories.
- Task 1.2: Define shared test doubles (fakes, fixtures, object mothers) required across blocks.

**2. Block [X]: [Component/Layer Name] (repeat for each logical block)**
- **Task X.1 (Test Setup):** Define the test class, dependencies, and fakes for the component.
- **Task X.2 (Failing Tests):** List test names mapped to acceptance criteria.
  - *Example:* `[ ] Test: should emit Loading state then Content state on successful load (AC-2.1).`
- **Task X.3 (Production Code):** Implement the concrete component to satisfy the contract and make the tests pass.
- **Task X.4 (Refactor):** Apply quality rules and optimize without changing behavior.

**3. Integration & UI**
- Task Y.1: Implement stateless SwiftUI views covering loading, empty, error, and content states.
- Task Y.2: Connect views to the `@MainActor @Observable` view model through `AppEnvironment`.
- Task Y.3: Define UI or integration test intentions (accessibility, navigation, retry flows).

**4. Verification Checklist**
- Task Z.1: Run `xcodegen generate` and the full test suite via `xcodebuild test`.
- Task Z.2: Confirm ≥80% line coverage for ViewModels and Services source files (see `agents.md` P7).
- Task Z.3: Run static analysis (Xcode analyzer; SwiftLint if the project adopts it).

## Gate — Exit Checklist
- [ ] `design.md` is approved.
- [ ] Every `FR`/`NFR`/`AC` maps to at least one task.
- [ ] Each block follows the TDD sequence.
- [ ] Tasks respect dependency order and the one-to-two-file granularity.
- [ ] No files or code were created in this phase.
- [ ] Verification tasks are included.
- [ ] The user has approved the plan.

**Next:** `.ai/apply.md`.
