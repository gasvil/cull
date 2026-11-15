# Cull — Architecture Guide and Development Rules (agents.md)

This document defines the technical context, architecture, design patterns, and engineering pillars that govern all development of the **Cull** project. Any agent or developer working in this codebase must follow these guidelines rigorously.

---

## 1. Technology Stack

* **Target Platform:** iOS 17.0+ (optimized for Swift 6)
* **Language:** Swift 6 (Strict Concurrency Checking, `Sendable`, `Actor`, `@MainActor`)
* **UI Framework:** SwiftUI (declarative, reactive)
* **State Management:** Observation Framework (`@Observable`)
* **Concurrency:** Swift Concurrency (`async` / `await` / `Task` / `Actor`); no legacy GCD (`DispatchQueue`)
* **Navigation:** `NavigationStack` decoupled through typed routes (`Hashable`)
* **Project Management:** `XcodeGen` (`project.yml`) for deterministic project generation without merge conflicts in `.xcodeproj`
* **Persistence:** *On demand*. Do not add SwiftData, CoreData, or SQLite until the functional rules explicitly require it. In-memory state must be designed decoupled so that persistence can be attached without changing views or view models.

---

## 2. Design Patterns and Software Principles

Apply **SOLID** (SRP, OCP, LSP, ISP, DIP), **KISS**, **DRY**, **YAGNI**, the **Boy Scout Rule**, **POLA**, **High Cohesion & Low Coupling**, the **Law of Demeter**, and **Separation of Concerns**.

---

## 3. Engineering Pillars

### **P1 - Security (Zero Trust & Secure by Design)**
* Never store secrets, credentials, or tokens in source code or plain-text files.
* Use `Keychain` for sensitive information when required.
* Protect personal data (PII) in compliance with Apple's privacy guidelines.
* Rigorously validate and sanitize any external input before processing it.

### **P2 - DevEx (Developer Experience)**
* Reusable code, clean exports, golden paths, and intuitive configuration.
* Rigorous technical documentation using **Swift DocC** (`///`) with clear descriptions of parameters, return values, and thrown errors.
* Predictable conventions and consistent organization.

### **P3 - Efficiency (Low Latency & Minimal Footprint)**
* No unnecessary runtime reflection.
* Immutable data structures (`struct`) by default to leverage stack optimizations and avoid retention/memory overhead.
* Optimal SwiftUI rendering: `@Observable` only notifies the views that read mutated properties.

### **P4 - Resilience (Design for Failure)**
* Every invalid input must throw strongly typed errors (`enum AppError: Error, LocalizedError`).
* Graceful degradation on failure; never let a runtime error take the app out of control or crash for the user.
* Strict handling of edge cases and empty states.

### **P5 - Observability (Context & Diagnostics)**
* Clean propagation of errors and execution context.
* Support for logger injection (Apple's native `os.Logger`) without rigid coupling to third-party telemetry tools.

### **P6 - Governance (Quality Gates & Consistency)**
* Strict dependency control through SPM and `project.yml`.
* Consistent formatting and clean linting.
* Semantic conventions for commits and version control.

### **P7 - Quality (Decoupled, Modular & Tested)**
* Decoupled modular architecture through protocol-based dependency injection.
* Unit test coverage for ViewModels, Services, and domain models.
* Minimum **80% line coverage** for ViewModels and Services source files (UI views excluded).
* Clean, deterministic mocks for testing and SwiftUI Previews.

---

## 4. Spec-Driven Development

All work follows the workflow defined in `.ai/`: `specify.md` → `apply.md` → `verify.md`. Per-feature artifacts live in `.ai/specs/<feature>/`.

The SDD phases are invoked with magic words in the user prompt. When one appears, load the corresponding file before acting and follow its gate:

| Magic word | Loads |
|------------|-------|
| `a:specify` | `.ai/specify.md` |
| `a:apply` | `.ai/apply.md` |
| `a:verify` | `.ai/verify.md` |

`spec.md` is always retained as the living specification. `verification.md` is a working artifact and is deleted from the feature folder after a successful verification.
