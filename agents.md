# Cull - Guía de Arquitectura y Reglas de Desarrollo (agents.md)

Este documento define el contexto técnico, la arquitectura, los patrones de diseño y los pilares de ingeniería que rigen todo el desarrollo del proyecto **Cull**. Cualquier agente o desarrollador que trabaje en esta base de código debe seguir rigurosamente estas directrices.

---

## 1. Stack Tecnológico

* **Plataforma Objetivo**: iOS 17.0+ (Optimizado para Swift 6)
* **Lenguaje**: Swift 6 (Strict Concurrency Checking, `Sendable`, `Actor`, `@MainActor`)
* **Framework de UI**: SwiftUI (Declarativo reactivo)
* **Gestor de Estado**: Observation Framework (`@Observable`)
* **Concurrencia**: Swift Concurrency (`async` / `await` / `Task` / `Actor`), sin uso de GCD obsoleto (`DispatchQueue`)
* **Navegación**: `NavigationStack` desacoplado mediante rutas tipadas (`Hashable`)
* **Gestión de Proyecto**: `XcodeGen` (`project.yml`) para generación determinística del proyecto sin conflictos de merge en `.xcodeproj`
* **Persistencia**: *Bajo demanda*. No agregar SwiftData, CoreData ni SQLite hasta que las reglas funcionales lo requieran explícitamente. El estado en memoria debe diseñarse desacoplado para permitir conectar persistencia sin alterar vistas ni ViewModels.

---

## 2. Patrones de Diseño y Principios de Software

Todos los componentes deben regirse por los siguientes principios:

* **SOLID**:
  * *Single Responsibility Principle (SRP)*: Cada clase, struct o función tiene una única razón para cambiar.
  * *Open/Closed Principle (OCP)*: Código abierto a extensión, cerrado a modificación directa mediante protocolos.
  * *Liskov Substitution Principle (LSP)*: Cualquier implementación de un protocolo debe poder sustituirse sin alterar el comportamiento esperado.
  * *Interface Segregation Principle (ISP)*: Protocolos pequeños y específicos; no forzar a un tipo a implementar métodos que no usa.
  * *Dependency Inversion Principle (DIP)*: Los módulos de alto nivel dependen de abstracciones (protocolos), no de implementaciones concretas.
* **KISS (Keep It Simple, Stupid)**: Preferir la solución más simple y directa que resuelva el problema sin sobreingeniería.
* **DRY (Don't Repeat Yourself)**: Centralizar la lógica de negocio y configuraciones en una única fuente de verdad.
* **YAGNI (You Aren't Gonna Need It)**: No construir funcionalidades, abstracciones ni infraestructura anticipada hasta que exista una necesidad demostrada.
* **Boy Scout Rule**: Deja el código más limpio de lo que lo encontraste. Refactoriza pequeñas deudas técnicas en cada iteración.
* **POLA (Principle of Least Astonishment)**: La API y el comportamiento del código deben ser predecibles e intuitivos para otros desarrolladores.
* **High Cohesion & Low Coupling**: Módulos internamente cohesivos con dependencias mínimas y explícitas entre sí.
* **Law of Demeter (LoD)**: Principio de menor conocimiento: una unidad solo debe comunicarse con sus amigos directos, nunca encadenar llamadas a través de múltiples capas (`a.b.c.doSomething()`).
* **Separation of Concerns (SoC)**: Clara distinción de responsabilidades entre Vistas (renderizado), ViewModels (estado y orquestación de UI) y Servicios (fuentes de datos y APIs).

---

## 3. Pilares de Ingeniería

### **P1 - Security (Zero Trust & Secure by Design)**
* Nunca almacenar secretos, credenciales o tokens en código fuente o archivos de texto plano.
* Utilizar `Keychain` para información sensible cuando sea requerida.
* Proteger datos personales (PII) cumpliendo con las pautas de privacidad de Apple.
* Validar y sanear rigurosamente cualquier entrada externa antes de procesarla.

### **P2 - DevEx (Developer Experience)**
* Código reusable, exports limpios, rutas doradas (*golden paths*) y configuración intuitiva.
* Documentación técnica rigurosa usando **Swift DocC** (`///`) con descripciones claras de parámetros, retornos y errores lanzados.
* Estructura del proyecto predecible y organizada por *features*.

### **P3 - Efficiency (Low Latency & Minimal Footprint)**
* Sin reflexión innecesaria en tiempo de ejecución.
* Estructuras de datos inmutables (`struct`) por defecto para aprovechar optimizaciones en el stack y evitar sobrecostes de retención de memoria.
* Renderizado óptimo en SwiftUI: `@Observable` solo notifica a las vistas que leen propiedades mutadas.

### **P4 - Resilience (Design for Failure)**
* Toda entrada inválida debe lanzar errores fuertemente tipados (`enum AppError: Error, LocalizedError`).
* Degradación elegante frente a fallos; nunca permitir que un error de tiempo de ejecución descontrole la aplicación o cause un *crash* al usuario.
* Manejo estricto de casos límite (*edge cases*) y estados vacíos (*empty states*).

### **P5 - Observability (Context & Diagnostics)**
* Propagación limpia de errores y contexto de ejecución.
* Soporte para inyección de loggers (`os.Logger` nativo de Apple) sin acoplamientos rígidos a herramientas de telemetría de terceros.

### **P6 - Governance (Quality Gates & Consistency)**
* Control estricto de dependencias a través de SPM y `project.yml`.
* Formato consistente y linting limpio.
* Convenciones semánticas para commits y control de versiones.

### **P7 - Quality (Decoupled, Modular & Tested)**
* Arquitectura modular desacoplada mediante inyección de dependencias por protocolos.
* Cobertura de pruebas unitarias sobre ViewModels, Servicios y Modelos de dominio.
* `Mocks` limpios y deterministas para testing y SwiftUI Previews.

---

## 4. Estructura del Proyecto

```text
Cull/
├── App/
│   ├── CullApp.swift              # Punto de entrada (@main)
│   └── AppEnvironment.swift       # Contenedor de dependencias raíz
├── Core/
│   ├── Navigation/                # Enrutamiento tipado (AppRouter, AppRoute)
│   ├── Theme/                     # Design System (Colores, Espaciado, Tipografía)
│   ├── Errors/                    # Definición de AppError y contratos de error
│   └── Extensions/                # Extensiones utilitarias
├── Features/                      # Módulos funcionales
│   └── [FeatureName]/
│       ├── Views/                 # Vistas SwiftUI
│       ├── ViewModels/            # ViewModels (@Observable, @MainActor)
│       └── Models/                # Entidades de dominio
├── Services/                      # Protocolos e implementaciones de servicios
└── Resources/                     # Assets (AppIcon, Colores) e Info.plist
CullTests/                         # Suite de pruebas unitarias
```
