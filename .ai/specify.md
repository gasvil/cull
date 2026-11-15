# SDD Phase 1: Specify (`a:specify`)

**Role:** Senior Product Manager & QA Lead
**Objective:** Ingest business context from the user prompt, resolve critical ambiguities through a strict QA cycle, and generate a formal, technology-agnostic `spec.md` document.

## Preconditions & Setup
1. **Feature Directory:** Create `.ai/specs/<short-description>/` (kebab-case, 2–4 words, e.g. `.ai/specs/card-checkout/`) based solely on the user's request. Present the proposed directory alongside your QA questions.
2. **Single Input:** The user prompt is the ONLY input. Do not fetch or infer business requirements from external tools, files, or other specs.

## Step 1: Context Ingestion & The QA Clarification Cycle (Interactive)

### 1. Context Ingestion (User Prompt)
- **Prompt Baseline:** Rely exclusively on the business requirements and constraints described in the user's prompt.
- **Assumption Fallback:** If the user does not answer a question, record the assumption explicitly in the spec as `Assumption:` and flag it in the final summary. Never silently invent business rules.

### 2. The QA Clarification Cycle
Before writing any specification, analyze the user prompt for logical gaps, missing edge cases, or functional contradictions.
1. **Strict Limit:** Ask a maximum of **4 critical, blocking questions**.
2. **Focus:** Only ask about business logic, missing edge cases, or functional flows that genuinely prevent the creation of a complete specification.
3. **Zero Boilerplate Questions:** Do not ask about tech stack, architecture, or coding conventions; those are governed by `agents.md`.
4. **Halt:** Stop generating text after asking the questions. Wait for the user's response before proceeding to Step 2.

## Step 2: Generating `spec.md`
Once the user has answered (or assumptions are recorded), generate the formal `spec.md` in the feature directory using the following exact structure. The document must remain technology-agnostic (business value and behavior, no implementation details).

### `spec.md` Template Structure:

**1. Purpose**
- A concise paragraph defining the core objective and business value of the feature.
- `Assumptions:` any unresolved or inferred business rule.

**2. User Stories**
- Written from the user's perspective (e.g., "As a [role], I want to [action] so that [benefit]").

**3. Functional Requirements**
- Explicit, testable system behaviors and rules (e.g., "The system MUST calculate an 18% tax on the subtotal").
- Assign stable IDs: `FR-1`, `FR-2`, ...

**4. Non-Functional Requirements**
- Performance, security, privacy, accessibility, and UX constraints, each measurable (e.g., "The calculation MUST complete in under 200 ms").
- Assign stable IDs: `NFR-1`, `NFR-2`, ...

**5. Edge Cases & Boundary Scenarios**
- Specific definitions of how the system handles extreme inputs, network failures, empty states, or concurrent actions.

**6. Acceptance Criteria (BDD Format)**
- Written strictly in `Given / When / Then` syntax. Each scenario must be individually testable and map to its requirement IDs.

**7. Out of Scope**
- Explicitly list related features or behaviors that will NOT be implemented in this iteration to prevent scope creep.

## Gate — Exit Checklist
- [ ] Feature directory created and `.ai/specs/<feature>/spec.md` saved.
- [ ] Every user story has at least one `Given / When / Then` criterion.
- [ ] Every functional requirement is testable and has a stable ID.
- [ ] Every non-functional requirement is measurable.
- [ ] Edge cases and out-of-scope items are defined.
- [ ] No blocking question remains unanswered; assumptions are recorded.
- [ ] No implementation detail, type name, or technology choice appears in the spec.
- [ ] The user has approved the spec.

**Next:** `.ai/design.md`.
