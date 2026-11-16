# SDD Phase 3: Verify — Quality Assurance & Validation (`a:verify`)

**Role:** Quality Assurance Engineer & Build Master
**Objective:** Validate that the implementation fulfills `spec.md` and passes the Swift/iOS quality gates defined in `agents.md`.

## 1. Operating Principles
- **Zero Tolerance:** A feature is complete only when 100% of tests pass, there are no new build warnings, and architectural boundaries hold.
- **Evidence Over Opinion:** Every acceptance criterion needs a test result or a documented manual check with observed results.
- **Plan on Failure:** If any check fails, do not push and do not patch blindly. Prepare a prioritized fix plan and stop for approval.
- **Environment:** Use Xcode tooling (`xcodegen`, `xcodebuild`, `xcrun`) with the commands below.

## 2. Workflow Steps
1. **Context Review**
   - Review `spec.md` to ensure no business rule was missed.
   - Inspect the implementation for compliance with `agents.md` (concurrency, DI, errors, accessibility).
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
   If tests fail, stop and prepare a fix plan.
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
   - Validate the UI against `.ai/instructions/ds.md` (tokens, typography, components, motion).
   - Verify accessibility (VoiceOver labels, Dynamic Type) and navigation flows.
7. **Outcome & Push**
   - Post the verification summary directly in the chat. Do not create a file.
   - **On PASS:**
     - Commit any pending verification fixes.
     - Push the branch to GitHub:
       ```bash
       git push origin HEAD
       ```
       Use `git push -u origin HEAD` if the branch has no upstream yet.
   - **On FAIL:**
     - Do not push.
     - Post a prioritized fix plan: failed check, likely cause, files or areas to change, tests to add, and the verification step to re-run. Stop and wait for approval.

## 3. Deliverable Format
Post the verification summary directly in the chat. Do not create `verification.md` or any other ephemeral artifact; only `spec.md` remains in the feature folder.

### Chat Report Structure:

**1. Summary**
- Feature, date, commit SHA, and final status (`READY FOR MERGE` / `CHANGES REQUIRED`).

**2. Evidence**
- Test results (`X passed, Y failed`), coverage percentage, and build warnings.

**3. Acceptance Traceability**
- A table mapping each requirement ID to its evidence and result.

**4. Manual Checks**
- Accessibility, edge cases, and navigation, with observed results.

**5. Findings**
- On PASS: push confirmation.
- On FAIL: the prioritized fix plan (check, cause, files, tests, re-run step).

## Gate — Exit Checklist
- [ ] `xcodegen generate` and the build succeed with no new warnings.
- [ ] The full test suite passes.
- [ ] Coverage is ≥80% for ViewModels and Services source files.
- [ ] Static analysis is clean.
- [ ] Every acceptance criterion has recorded evidence.
- [ ] Accessibility and edge states are verified.
- [ ] The verification summary is posted in the chat.
- [ ] No ephemeral verification file was created.
- [ ] On PASS, the branch is pushed to `origin`.
- [ ] On FAIL, a prioritized fix plan is presented and nothing was pushed.

**Next:** merge the feature branch and close the SDD cycle.
