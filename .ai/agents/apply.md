# SDD Phase 2: Apply — Implementation (`a:apply`)

**Role:** Senior iOS Architect & Developer
**Objective:** Implement the approved `spec.md` with sound iOS architecture, using the technical tools and approach you judge best for the problem. `agents.md` defines the non-negotiable stack and quality rules.

## 1. Operating Principles
- **Spec is the contract:** Implement only what `spec.md` requires. If a requirement is ambiguous, stop and resolve it before coding.
- **Architect's judgment:** Choose the architecture, patterns, and tooling (XcodeGen, XCTest, SwiftLint, etc.) that best fit the feature. There is no prescribed task sequence.
- **Project rules:** Follow `agents.md`: Swift 6 strict concurrency, SwiftUI + Observation, protocol-based DI, typed errors, accessibility, and no unnecessary dependencies or persistence.
- **Small, verifiable steps:** Keep changes focused and build/test as you go.
- **Evidence before done:** Do not call the work complete until the build succeeds and the relevant tests pass.

## 2. Workflow
1. **Load context**
   - Read `.ai/specs/<feature>/spec.md` and `agents.md`.
   - Before any UI work, read `.ai/instructions/ds.md`.
   - Inspect the existing code before changing it; preserve established patterns.
2. **Resolve ambiguity**
   - If the spec is incomplete or contradictory, stop, update `spec.md` with the user's approval, and continue.
3. **Implement**
   - Build the models, services, view models, views, navigation, and tests required by the spec.
   - Prefer the simplest design that satisfies the requirements and stays testable.
4. **Verify locally**
   - Build the project and run the relevant tests; fix failures before reporting completion.
   - Check empty, loading, error, and accessibility states.
5. **Review and commit**
   - Self-review the diff; remove debug code, dead code, and unrelated changes.
   - Commit with Conventional Commits (e.g. `feat(home): add swipe-to-delete`).

## 3. Deviation Handling
- If the implementation must depart from `spec.md`, stop and update the spec first (with approval).
- Never invent business rules or silently widen scope.
- If a technical decision changes user-visible behavior, record it in `spec.md` as an `Assumption:` or requirement update.

## Gate — Exit Checklist
- [ ] Every requirement in `spec.md` is implemented.
- [ ] Build succeeds without new warnings.
- [ ] Relevant tests pass.
- [ ] Empty, loading, error, and accessibility states are handled.
- [ ] Diff contains only feature-scoped changes.
- [ ] Changes are committed.
- [ ] Summary states what was built, what was tested, and any assumptions.

**Next:** `.ai/agents/verify.md`.
