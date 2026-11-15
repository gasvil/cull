# SDD Phase 2: Design — Technical Architecture (`a:design`)

**Role:** Solution Architect
**Objective:** Translate functional specifications (`spec.md`) into robust, modular, and decoupled Swift 6 / SwiftUI designs. Resolve project-specific conventions from `agents.md` (iOS 17+, SwiftUI, Observation, strict concurrency).

## 1. Operating Principles
- **No Implementation Prematurity:** Generating production source code or test implementations during the design phase is **strictly FORBIDDEN**.
- **Project Rules First:** Read `agents.md` before making any technical decision. It defines the stack, concurrency model, dependency injection, error handling, and quality bars.
- **Contract-First Design:** Model all boundary interactions via typed protocols, request/response models, and state machines before determining concrete implementations.
- **Spec Traceability:** Every design element must cite the `FR`/`NFR` it serves. No speculative architecture.

## 2. Workflow Steps
1. **Context Loading & Target Identification**
   - Ingest `spec.md` from the feature workspace.
   - Identify the target area: `Features/<Name>`, `Core/`, or `Services/`. If the user did not specify it, propose the most logical location and ask for confirmation.
2. **Component & Boundary Modeling**
   - Define responsibilities and unidirectional dependencies (`View` → `ViewModel` → protocol → implementation).
   - Model domain entities, protocols, state, and isolation with Swift 6 semantics (`struct`, `enum`, `Sendable`, `@MainActor`, `@Observable`).
3. **Generating `design.md`**
   - Save the file alongside `spec.md` in `.ai/specs/<feature>/design.md`, using the structure below adapted to Cull.

### `design.md` Template Structure:

**1. Architectural Context & Strategy**
- Target location (`Features/<Name>`, `Core/`, `Services/`) and the patterns applied from `agents.md`.
- Summary of the architectural approach and dependency direction.

**2. Component Boundaries & Unidirectional Flow**
- A Mermaid diagram (`graph TD`) illustrating the flow from the SwiftUI View through the ViewModel/contract down to the domain and service layers.
- Responsibilities, public entry points, and layer boundaries.

**3. Interface Contracts & Data Models**
- **Domain Models & States:** Immutable Swift entities and state hierarchies (`struct`, `enum`), `Sendable` where isolation requires it.
- **Public Contract:** Protocols, methods, inputs, outputs, `async`/throws behavior, and actor isolation.
- **Integration / DTO Models:** Boundary schemas, mappers, and storage entities only if the spec requires persistence.

**4. Error Handling & Resilience Strategy**
- **Validation Errors:** Fail-fast rejection of invalid input.
- **Operational Failures:** Typed `AppError` cases, mapping at boundaries, fallback/degradation policies, and user-facing recovery. No raw errors reach the UI.

**5. Testing Strategy**
- Map each acceptance criterion to a test level (XCTest unit/integration/UI), the test double required, and the observable outcome.
- Test intentions only; no test code in this phase.

**6. Architectural Trade-offs & Alternatives**
- **Selected Approach:** Reasoning for the chosen design, explicitly linked to `agents.md` constraints.
- **Rejected Alternatives:** Why alternative designs were dismissed.

## Gate — Exit Checklist
- [ ] `spec.md` is approved and has no blocking questions.
- [ ] Target location and dependency direction are defined.
- [ ] Every `FR`/`NFR` maps to a component or is explicitly deferred.
- [ ] Protocols and domain models are defined with Swift 6 isolation semantics.
- [ ] Error taxonomy and user-facing recovery are defined.
- [ ] Testing strategy maps every acceptance criterion to a test level.
- [ ] No production or test code was generated.
- [ ] The user has approved the design.

**Next:** `.ai/tasks.md`.
