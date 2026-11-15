# SDD Phase 5: Verify — Quality Assurance & Validation (`a:verify`)

**Role:** Quality Assurance Engineer & Build Master
**Objective:** Validate that the implementation fulfills `spec.md`, matches `design.md`, and passes the Swift/iOS quality gates defined in `agents.md`.

## 1. Operating Principles
- **Zero Tolerance:** A feature is complete only when 100% of tests pass, there are no new build warnings, and architectural boundaries hold.
- **Evidence Over Opinion:** Every acceptance criterion needs a test result or a documented manual check with observed results.
- **Auto-Correction Loop:** If a check fails, diagnose the error, return to an "Apply" mindset to fix the code, and re-run from the failing step. If the fix changes behavior or a contract, update `spec.md`/`design.md` first (with approval).
- **Environment:** Use Xcode tooling (`xcodegen`, `xcodebuild`, `xcrun`) with the commands below.

## 2. Workflow Steps
1. **Context & Execution Plan Review**
   - Review `spec.md` to ensure no business rule was missed.
   - Review `design.md` for contract and isolation compliance.
   - Confirm every implementation task in `tasks.md` is marked `[x]`.
2. **Project Regeneration & Build**
   ```bash
   xcodegen generate
   xcodebuild -project Cull.xcodeproj -scheme Cull \
     -destination 'platform=iOS Simulator,name=iPhone 16' \
     -derivedDataPath build/DerivedData build
   ```
   Fail on any error or new warning. Adjust the simulator to one installed (`xcrun simctl list devices available`).
3. **Automated Testing**
   ```bash
   xcodebuild -project Cull.xcodeproj -scheme Cull \
     -destination 'platform=iOS Simulator,name=iPhone 16' \
     -derivedDataPath build/DerivedData \
     -enableCodeCoverage YES -resultBundlePath build/TestResults.xcresult test
   ```
   If tests fail, diagnose the failure, fix the implementation, and re-run from this step.
4. **Coverage Validation**
   ```bash
   xcrun xccov view --report build/TestResults.xcresult
   ```
   Require **≥80% line coverage for ViewModels and Services source files** (see `agents.md` P7). UI views are excluded.
5. **Static Analysis & Architecture**
   - Run the Xcode analyzer (`xcodebuild analyze`) and SwiftLint `--strict` if the project adopts it.
   - Resolve formatting issues, code smells, and boundary violations (for example, views calling services directly, GCD usage, or force unwraps).
6. **Acceptance & Manual Checks**
   - Walk through every acceptance criterion, including loading, empty, error, and offline states.
   - Verify accessibility (VoiceOver labels, Dynamic Type) and navigation flows.
7. **Final Report & Cleanup**
   - Write `verification.md` in the feature folder with the evidence.
   - Mark the final Verification tasks in `tasks.md` as completed.
   - Post the chat summary.
   - **On PASS:** delete every `.md` file in the feature folder except `spec.md`, keeping only the living specification:
     ```bash
     find .ai/specs/<feature> -maxdepth 1 -type f -name '*.md' ! -name 'spec.md' -delete
     ```
   - **On FAIL:** keep `design.md`, `tasks.md`, and `verification.md` so the fix loop retains context.

## 3. Deliverable Format
Write `.ai/specs/<feature>/verification.md` as working evidence and post a short summary in the chat. On PASS it is removed during cleanup; only `spec.md` survives.

### `verification.md` Template Structure:

**1. Summary**
- Feature, date, commit SHA, and final status (`READY FOR MERGE` / `CHANGES REQUIRED`).

**2. Evidence**
- Test results (`X passed, Y failed`), coverage percentage, and build warnings.

**3. Acceptance Traceability**
- A table mapping each requirement ID to its evidence and result.

**4. Manual Checks**
- Accessibility, edge cases, and navigation, with observed results.

**5. Findings**
- Blocking issues and non-blocking follow-ups, each with an owner or change ID.

## Gate — Exit Checklist
- [ ] `xcodegen generate` and the build succeed with no new warnings.
- [ ] The full test suite passes.
- [ ] Coverage is ≥80% for ViewModels and Services source files.
- [ ] Static analysis is clean.
- [ ] Every acceptance criterion has recorded evidence.
- [ ] Accessibility and edge states are verified.
- [ ] `verification.md` was written and the chat summary posted.
- [ ] On PASS, `design.md`, `tasks.md`, and `verification.md` are deleted; only `spec.md` remains.
- [ ] The final status is recorded in the report.

**Next:** merge the feature branch and close the SDD cycle.
