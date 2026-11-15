# Execution & TDD Plan: Curación y Triaje de Ráfagas (`burst-quality-triage`)

## 1. Preparation & Setup

### Task 1.1: File & Module Architecture Plan [x]
* **Target Files:**
  * `Cull/Features/BurstTriage/Models/BurstTriageModels.swift` (Domain Entities)
  * `Cull/Services/BurstClustering/BurstClusteringServiceProtocol.swift`
  * `Cull/Services/BurstClustering/BurstClusteringService.swift`
  * `Cull/Services/ImageQuality/ImageQualityEvaluatorProtocol.swift`
  * `Cull/Services/ImageQuality/VisionQualityEvaluator.swift`
  * `Cull/Services/PhotoLibrary/PhotoLibraryServiceProtocol.swift`
  * `Cull/Services/PhotoLibrary/PhotoLibraryService.swift`
  * `Cull/Features/BurstTriage/ViewModels/BurstTriageViewModel.swift`
  * `Cull/Features/BurstTriage/Views/BurstTriageView.swift`
  * `Cull/Features/BurstTriage/Views/BurstClusterCardView.swift`
  * `CullTests/Services/BurstClusteringServiceTests.swift`
  * `CullTests/Services/ImageQualityEvaluatorTests.swift`
  * `CullTests/ViewModels/BurstTriageViewModelTests.swift`
* **Rules:** Granularidad de 1-2 archivos por tarea, estricto ciclo TDD (Rojo → Verde → Refactor), Swift Concurrency (`Sendable`, `@MainActor`, `actor`), cero código de producción generado durante esta fase de planificación.

### Task 1.2: Shared Test Doubles & Fixtures [x]
* **Target File:** `CullTests/Mocks/BurstTriageMocks.swift`
* **Scope:**
  * `MockPhotoLibraryService`: Controla autorizaciones (`Bool`), devuelve fixtures de `[PhotoAsset]`, simula obtención de `Data` y llamadas a `deleteAssets`.
  * `MockImageQualityEvaluator`: Actor/clase `Sendable` que devuelve `QualityAssessment` predeterminados sin ejecutar Vision.
  * `PhotoAssetFixture`: Generador de entidades de prueba con timestamps ajustables, flags de `isFavorite` y tamaños en bytes configurables.

---

## 2. Block 1: Domain Entities & Core Calculations

### Task 2.1 (Domain Models & Invariants Setup) [x]
* **Target File:** `CullTests/Models/BurstClusterTests.swift`
* **Test Intentions:**
  * `[x] testRecoverableByteSize_calculatesSumOfDiscardedItemsOnly` (`FR-8`)
  * `[x] testIsAllDiscarded_returnsTrue_whenDiscardIdsEqualsItemsCount` (`FR-10`)
  * `[x] testIsAllKept_returnsTrue_whenDiscardIdsIsEmpty` (`FR-11`)

### Task 2.2 (Domain Models Implementation) [x]
* **Target File:** `Cull/Features/BurstTriage/Models/BurstTriageModels.swift`
* **Scope:** Implementar `PhotoAsset`, `QualityAssessment`, `FaceAssessment`, `PhotoCandidate`, `ClusterReviewStatus` y `BurstCluster` (`Sendable`, inmutables, con propiedades calculadas para espacio recuperable `FR-8`).

### Task 2.3 (Refactor & Concurrency Audit) [x]
* Verificar conformidad con `Sendable` y strict concurrency checking.

---

## 3. Block 2: Burst Clustering Service

### Task 3.1 (Clustering Test Setup & Failing Tests) [x]
* **Target File:** `CullTests/Services/BurstClusteringServiceTests.swift`
* **Test Intentions:**
  * `[x] testClusterize_groupsPhotosWithin5SecondsInterval` (`FR-1`, `Assumption 1`)
  * `[x] testClusterize_separatesPhotosWithIntervalGreaterThan5Seconds` (`FR-1`, `EC-1`)
  * `[x] testClusterize_groupsNativeBurstWithSameIdentifierRegardlessOfTime` (`FR-1`)
  * `[x] testClusterize_designatesSinglePhotoWithHighestCompositeScoreAsKeeper` (`FR-4`, `Scenario 1`)
  * `[x] testClusterize_resolvesTiesBySelectingOldestPhoto` (`FR-5`, `Scenario 6`)
  * `[x] testClusterize_preselectsNonKeeperPhotosAsDiscardCandidates` (`FR-6`, `Scenario 1`)
  * `[x] testClusterize_neverPreselectsFavoritePhotosForDiscard` (`FR-7`, `Scenario 5`)
  * `[x] testClusterize_marksClusterAllKept_whenAllPhotosAreFavorites` (`FR-7`, `Assumption 4`)

### Task 3.2 (Clustering Implementation) [x]
* **Target Files:**
  * `Cull/Services/BurstClustering/BurstClusteringServiceProtocol.swift`
  * `Cull/Services/BurstClustering/BurstClusteringService.swift`
* **Scope:** Implementar el algoritmo de ordenamiento cronológico, ventana temporal móvil $\le 5.0$ s, agrupación por `burstIdentifier`, selección de keeper por puntaje compuesto/empates y exclusión de favoritas en `discardIds`.

### Task 3.3 (Refactor & Optimization) [x]
* Optimizar la pasada de agrupación en $O(N \log N)$ para ordenamiento y $O(N)$ para particionado lineal, evitando copias redundantes de memoria.

---

## 4. Block 3: Image Quality Evaluation (Vision Actor)

### Task 4.1 (Quality Evaluator Test Setup & Failing Tests) [x]
* **Target File:** `CullTests/Services/ImageQualityEvaluatorTests.swift`
* **Test Intentions:**
  * `[x] testEvaluateQuality_calculatesSharpnessScoreNormalized` (`FR-2`)
  * `[x] testEvaluateQuality_penalizesClosedEyesInFaceAssessment` (`FR-3`, `Scenario 2`)
  * `[x] testEvaluateQuality_calculatesCompositeScoreWithoutFaces_usingSharpnessAndExposure` (`FR-4`, `EC-5`)
  * `[x] testEvaluateQuality_handlesCorruptedImageDataGracefully_withoutCrashing` (`NFR-5`, `P4`)

### Task 4.2 (Vision Evaluator Implementation) [x]
* **Target Files:**
  * `Cull/Services/ImageQuality/ImageQualityEvaluatorProtocol.swift`
  * `Cull/Services/ImageQuality/VisionQualityEvaluator.swift`
* **Scope:** Implementar `actor VisionQualityEvaluator` utilizando `VNCalculateImageAestheticsRequest` y `VNDetectFaceCaptureQualityRequest` / `VNDetectFaceLandmarksRequest`. Aplicar `autoreleasepool` y downsampling de imágenes para asegurar $\le 120$ MB de RAM (`NFR-3`).

### Task 4.3 (Refactor & Performance Profiling) [x]
* Validar que la ejecución concurrente sobre un lote de imágenes use `withThrowingTaskGroup` con límite de concurrencia para cumplir con latencia $\le 1.5$ s (`NFR-2`).

---

## 5. Block 4: Photo Library Service (PhotoKit Abstraction)

### Task 5.1 (Photo Library Test Setup & Failing Tests) [x]
* **Target File:** `CullTests/Services/PhotoLibraryServiceTests.swift`
* **Test Intentions:**
  * `[x] testFetchRecentAssets_mapsPHAssetsToPhotoAssetModels` (`P7`)
  * `[x] testDeleteAssets_whenAuthorized_executesChangeRequest` (`FR-12`, `NFR-4`)
  * `[x] testDeleteAssets_whenUserCancelsSystemDialog_returnsFalseWithoutError` (`EC-6`, `P4`)

### Task 5.2 (Photo Library Implementation) [x]
* **Target Files:**
  * `Cull/Services/PhotoLibrary/PhotoLibraryServiceProtocol.swift`
  * `Cull/Services/PhotoLibrary/PhotoLibraryService.swift`
* **Scope:** Implementar la integración con `PHPhotoLibrary` y `PHAssetChangeRequest.deleteAssets` (papelera nativa recuperable `NFR-4`).

### Task 5.3 (Refactor) [x]
* Asegurar que todas las llamadas asíncronas respeten Swift Concurrency y propaguen errores tipados `AppError`.

---

## 6. Block 5: View Model & State Management

### Task 6.1 (ViewModel Test Setup & Failing Tests)
* **Target File:** `CullTests/ViewModels/BurstTriageViewModelTests.swift`
* **Test Intentions:**
  * `[ ] testLoadAndAnalyze_whenPermissionGranted_emitsLoadedWithClusters` (`US-1`, `US-2`)
  * `[ ] testLoadAndAnalyze_whenPermissionDenied_emitsUnauthorizedError` (`P4`)
  * `[ ] testToggleKeeper_addsPhotoToKeepers_andRemovesFromDiscards` (`FR-9`, `Scenario 2`)
  * `[ ] testDiscardAll_marksAllPhotosInClusterForDiscard` (`FR-10`, `Scenario 3`)
  * `[ ] testKeepAll_clearsDiscards_andMarksClusterReviewedKept` (`FR-11`, `Scenario 4`)
  * `[ ] testConfirmDiscards_invokesService_andRemovesClusterFromQueueOnSuccess` (`FR-12`)
  * `[ ] testConfirmDiscards_whenCancelledInDialog_preservesClusterState` (`EC-6`)

### Task 6.2 (ViewModel Implementation)
* **Target File:** `Cull/Features/BurstTriage/ViewModels/BurstTriageViewModel.swift`
* **Scope:** Implementar `BurstTriageViewModel` (`@Observable @MainActor`) orquestando `PhotoLibraryServiceProtocol`, `BurstClusteringServiceProtocol` y `ImageQualityEvaluatorProtocol`. Gestionar selecciones multi-keeper, eliminar todo, mantener todo y cálculos dinámicos de espacio recuperable.

### Task 6.3 (Refactor)
* Verificar inyección de dependencias por inicializador (DIP) y cumplimiento estricto de la Ley de Deméter (LoD).

---

## 7. Block 6: Presentation (SwiftUI Views & Navigation)

### Task 7.1: UI Components Implementation
* **Target Files:**
  * `Cull/Features/BurstTriage/Views/BurstClusterCardView.swift`
  * `Cull/Features/BurstTriage/Views/BurstTriageView.swift`
* **Scope:**
  * Renderizado reactivo de la tarjeta de ráfaga: miniatura destacada de la mejor toma, insignia de calidad ("Mejor toma"), tomas descartables con checkboxes de selección manual, selector de "Eliminar todo" y "Mantener todo".
  * Barra superior e inferior con megabytes recuperables totales y botón de acción principal "Purgar seleccionadas".
  * Manejo de estados: `loading` con barra de progreso, `empty` ("Carrete optimizado, sin ráfagas pendientes"), `error` con vista de recuperación.

### Task 7.2: Integration into App Navigation
* **Target Files:**
  * `Cull/Core/Navigation/AppRoute.swift`
  * `Cull/App/CullApp.swift`
* **Scope:** Vincular `BurstTriageView` como destino en la pila de navegación principal (`AppRoute.burstTriage`).

---

## 8. Block 7: Verification & Quality Gates

### Task 8.1: Project Generation & Build
* Ejecutar `xcodegen generate` para sincronizar nuevos archivos y fuentes con `Cull.xcodeproj`.

### Task 8.2: Automated Test Suite & Coverage Bar
* Ejecutar la suite completa mediante `xcodebuild test`.
* Verificar cobertura $\ge 80\%$ en `BurstTriageViewModel`, `BurstClusteringService` y `VisionQualityEvaluator` (`agents.md` P7).

### Task 8.3: Quality & Concurrency Audit
* Ejecutar análisis estático con `SWIFT_STRICT_CONCURRENCY=complete` para garantizar cero advertencias de carreras de datos.
