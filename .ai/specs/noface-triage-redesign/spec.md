# Feature Specification: Rediseño de Depuración Sin Rostro (`noface-triage-redesign`)

## 1. Purpose
Modernizar la pantalla de **Depuración Sin Rostro (Paso 3 de 4)** en Cull. Permite al usuario revisar de forma ágil y estructurada aquellas fotos de su biblioteca donde no se detectan rostros humanos (comprobantes, vouchers, capturas, fotos borrosas, accidentales o tomas intencionales sin personas). La vista organiza las fotografías mediante un selector de categorías exclusivo por pestañas (`Utilitarias`, `Deficientes` y `Por Validar`), preselecciona automáticamente las fotos de alta prioridad para descarte, protege estrictamente las favoritas del carrete, presenta una cuadrícula de 3 columnas con etiquetas de peso, soporta inspección en pantalla completa por pulsación prolongada y consolida las fotos marcadas en un botón flotante que conduce al Paso 4 de confirmación final.

### Assumptions:
* **Assumption 1 (Filtro Exclusivo de Categorías):** Los chips superiores actúan como un selector de pestañas mutuamente excluyente: al seleccionar una categoría, la tarjeta descriptiva y la cuadrícula muestran únicamente las fotos pertenecientes a dicha categoría.
* **Assumption 2 (Preselección por Nivel de Prioridad):** Las fotos clasificadas como `Utilitarias` y `Deficientes` (Alta Prioridad) vienen preseleccionadas por defecto para descarte con indicador rojo. Las fotos `Por Validar` (Prioridad Media) aparecen visibles pero desmarcadas por defecto.
* **Assumption 3 (Inmunidad Estricta de Favoritas):** Las fotos marcadas como "Favoritas" en la biblioteca nativa de iOS quedan estrictamente excluidas de este módulo de análisis y no se muestran en ninguna categoría.
* **Assumption 4 (Cuadrícula de 3 Columnas):** La cuadrícula fotográfica organiza los elementos en 3 columnas homogéneas con espaciado consistente.
* **Assumption 5 (Comportamiento Dinámico del Botón de Selección Masiva):** Si todas las fotos de la categoría activa están marcadas, el botón muestra `Desmarcar todas`; si ninguna o solo una selección parcial está marcada, el botón muestra `Marcar todas`.
* **Assumption 6 (Etiqueta Inferior Genérica):** De acuerdo con la decisión explícita (Opción B), la etiqueta inferior de cada miniatura muestra el nombre de su categoría y el peso estimado del archivo (ej. `Utilitaria · 2.4 MB`).
* **Assumption 7 (Navegación al Paso 4):** El botón flotante inferior consolida la sumatoria de fotos marcadas a través de las tres categorías y navega a la pantalla de confirmación final (Paso 4).

---

## 2. User Stories

* **US-1 (Navegación por Pestañas de Categoría):** Como usuario, quiero alternar entre las pestañas Utilitarias, Deficientes y Por Validar con sus respectivos conteos para revisar ordenadamente cada tipo de foto sin rostros.
* **US-2 (Preselección Inteligente):** Como usuario, quiero que los comprobantes y fotos deficientes aparezcan preseleccionados para descarte, mientras que las fotos intencionales sin personas permanezcan desmarcadas hasta que yo decida eliminarlas.
* **US-3 (Selección Ágil en Cuadrícula de 3 Columnas):** Como usuario, quiero ver una cuadrícula compacta de 3 columnas para revisar muchas fotos rápidamente y marcar o desmarcar elementos individuales con un solo toque.
* **US-4 (Control Rápido de Marcado Masivo):** Como usuario, quiero un botón para desmarcar o marcar todas las fotos de la categoría activa con un solo toque.
* **US-5 (Inspección en Pantalla Completa):** Como usuario, quiero mantener presionada cualquier foto para abrirla en alta resolución y comprobar montos, nitidez o texto antes de descartarla.
* **US-6 (Consolidación y Avance al Paso 4):** Como usuario, quiero ver el total consolidado de fotos marcadas en el botón inferior y avanzar a la revisión final sin perder mis selecciones.

---

## 3. Functional Requirements

### Cabecera y Navegación
* **FR-1 (Botón de Retroceso):** El sistema DEBE incluir un botón `< Modo` en la parte superior izquierda que regrese al usuario al Paso 2 (Selector de Modo), conservando el rango temporal y estado.
* **FR-2 (Pill de Modo y Conteo Total):** La cabecera DEBE mostrar en la parte superior derecha un pill con un dot azul a la izquierda y el texto `Sin Rostro · X fotos`, donde `X` es la sumatoria de fotos analizadas en las 3 categorías.
* **FR-3 (Título y Descripción del Módulo):** La pantalla DEBE mostrar el título `Depuración Sin Rostro` y el texto explicativo: *"Las fotos con alta prioridad vienen preseleccionadas. Las de prioridad media esperan tu confirmación."*

### Selector de Pestañas de Categoría
* **FR-4 (Chips de Categoría Mutuamente Excluyentes):** El sistema DEBE presentar tres chips de filtro superior:
  * **Utilitarias:** Badge circular rojo con el conteo de fotos de la categoría.
  * **Deficientes:** Badge circular rojo con el conteo de fotos de la categoría.
  * **Por Validar:** Badge circular neutro con el conteo de fotos de la categoría.
* **FR-5 (Estado Activo de Pestaña):** Al tocar un chip, este DEBE pasar a estado activo destacado y actualizar la vista inferior para mostrar únicamente las fotos de dicha categoría, conservando intacto el estado de las otras categorías. Al iniciar la vista, `Utilitarias` DEBE ser la pestaña activa por defecto.

### Tarjeta Descriptiva de la Categoría Activa
* **FR-6 (Tarjeta de Resumen de Categoría):** La pantalla DEBE mostrar una tarjeta informativa correspondiente a la pestaña activa:
  * Icono semántico distintivo en un contenedor circular tonal.
  * Título de la categoría junto a su badge de prioridad:
    * `Utilitarias` y `Deficientes`: Badge `ALTA PRIORIDAD` con fondo carmine coral y texto blanco.
    * `Por Validar`: Badge `PRIORIDAD MEDIA` con fondo ámbar/azul y texto contrastante.
  * Descripción del tipo de contenido comprendido (ej. *"Comprobantes, vouchers, texto o notas"*).
  * Botón de acción masiva a la derecha (`FR-7`).
* **FR-7 (Acción Masiva 'Desmarcar todas' / 'Marcar todas'):**
  * Si todas las fotos de la categoría activa están marcadas, el botón DEBE mostrar `Desmarcar todas` en color rojo. Al pulsarlo, desmarca todas las fotos de esta categoría.
  * Si ninguna o solo una selección parcial de fotos está marcada, el botón DEBE mostrar `Marcar todas`. Al pulsarlo, marca todas las fotos de esta categoría.

### Cuadrícula Fotográfica
* **FR-8 (Cuadrícula de 3 Columnas):** Las fotos de la categoría activa DEBEN disponerse en una cuadrícula vertical de 3 columnas homogéneas con espaciado consistente.
* **FR-9 (Preselección de Inicio):**
  * En `Utilitarias` y `Deficientes`, las fotos DEBEN iniciar con su indicador rojo de descarte activo.
  * En `Por Validar`, las fotos DEBEN iniciar desmarcadas por defecto.
* **FR-10 (Indicador de Selección):** Cada miniatura DEBE mostrar en su esquina superior derecha un círculo rojo con checkmark (`✓`) cuando esté seleccionada para descarte, y un indicador desmarcado cuando no lo esté.
* **FR-11 (Alternancia por Toque Simple):** Al pulsar una foto, el sistema DEBE alternar su estado de selección individual en menos de 50 ms y actualizar el contador global.
* **FR-12 (Etiqueta de Metadatos Inferior):** Cada miniatura DEBE exhibir en su parte inferior una etiqueta semi-transparente con la categoría y el peso del archivo (ej. `Utilitaria · 2.4 MB`).
* **FR-13 (Inspección en Pantalla Completa):** Al mantener presionada cualquier foto de la cuadrícula, el sistema DEBE desplegar el modal interactivo de inspección en alta resolución con zoom gestual y botón de cierre.
* **FR-14 (Inmunidad de Favoritas):** Las fotos marcadas como favoritas en la biblioteca de fotos DEBEN quedar excluidas por completo del análisis y de la interfaz.

### Botón Flotante de Continuación
* **FR-15 (Botón Flotante Consolidado):** Botón fijado en la parte inferior con la leyenda dinámica `Continuar (N fotos marcadas) →`, donde `N` es la sumatoria de todas las fotos seleccionadas para descarte entre las 3 categorías.
* **FR-16 (Avance al Paso 4):** Al presionar el botón `Continuar`, el sistema DEBE navegar a la pantalla de confirmación final (Paso 4) transmitiendo los identificadores de todas las fotos marcadas.

---

## 4. Non-Functional Requirements

* **NFR-1 (Rendimiento de Cuadrícula):** La cuadrícula de 3 columnas DEBE mantener un desplazamiento a 60 fps / 120 fps en dispositivos compatibles, empleando reciclaje de celdas y miniaturas downsampleadas en memoria.
* **NFR-2 (Latencia de Interacción):** La alternancia de pestañas y el cambio de selección individual DEBEN completarse en menos de 50 milisegundos.
* **NFR-3 (Accesibilidad y Áreas Táctiles):** Todas las celdas y botones DEBEN tener un área de interacción mínima de 44 × 44 pt y etiquetas para lectores de pantalla (ej. "Voucher, Utilitaria, 2.4 MB, marcado para eliminar").
* **NFR-4 (Conformidad con Sistema de Diseño):** La interfaz DEBE apegarse a los tokens de `AppColor`, `AppFont`, `AppTheme` y `AppMotion` especificados en `ds.md`.

---

## 5. Edge Cases & Boundary Scenarios

* **EC-1 (Categoría con 0 fotos):** Si una categoría no contiene fotos, el chip refleja `0`, la tarjeta muestra `0 fotos` y la cuadrícula presenta un mensaje explicativo vacío sin bloquear la alternancia a otras pestañas.
* **EC-2 (Todas las fotos desmarcadas globalmente):** Si el usuario desmarca todas las fotos de las 3 categorías, el botón flotante refleja `Continuar (0 fotos marcadas) →` o `Continuar →` sin inhabilitar la navegación.
* **EC-3 (Selección Parcial en Categoría):** Si el usuario desmarca 1 de 4 fotos en una categoría, el botón de lote cambia inmediatamente a `Marcar todas`.
* **EC-4 (Retención de Estado al Cambiar de Pestaña):** Cambiar de pestaña y regresar no debe alterar las selecciones individuales previamente configuradas por el usuario.
* **EC-5 (Biblioteca Sin Ninguna Foto Sin Rostro):** Si ninguna foto del período clasifica sin rostro o todas son favoritas, se muestra la vista de estado vacío ("Carrete al Día") con opción para modificar el período temporal.

---

## 6. Acceptance Criteria (BDD Format)

### Scenario 1: Despliegue inicial de la pantalla con pestaña 'Utilitarias' activa
* **Given** que el usuario completó la selección de período y eligió el modo "Sin Rostro"
* **When** se presenta la pantalla de Depuración Sin Rostro (Paso 3)
* **Then** la cabecera muestra `< Modo` y el pill informativo `Sin Rostro · X fotos` (`FR-1`, `FR-2`)
* **And** los chips superiores muestran las categorías `Utilitarias`, `Deficientes` y `Por Validar` con sus respectivos conteos (`FR-4`)
* **And** la pestaña `Utilitarias` aparece activa por defecto (`FR-5`)
* **And** la tarjeta descriptiva muestra el badge `ALTA PRIORIDAD` y el botón `Desmarcar todas` (`FR-6`, `FR-7`)
* **And** las fotos de `Utilitarias` se despliegan en cuadrícula de 3 columnas preseleccionadas para eliminar (`FR-8`, `FR-9`)
* **And** el botón inferior muestra el consolidado de fotos marcadas: `Continuar (N fotos marcadas) →` (`FR-15`).

### Scenario 2: Cambio de pestaña a 'Por Validar' y estado desmarcado
* **Given** que el usuario se encuentra en la pantalla de Depuración Sin Rostro
* **When** pulsa sobre el chip `Por Validar`
* **Then** la pestaña `Por Validar` pasa a estado activo
* **And** la tarjeta descriptiva muestra el badge `PRIORIDAD MEDIA` y el botón `Marcar todas`
* **And** las fotos de `Por Validar` se muestran desmarcadas por defecto en la cuadrícula de 3 columnas (`FR-9`)
* **And** las selecciones previas de `Utilitarias` y `Deficientes` se conservan intactas (`EC-4`).

### Scenario 3: Alternancia de selección individual en miniatura
* **Given** una foto marcada para descarte en la cuadrícula
* **When** el usuario pulsa sobre la foto
* **Then** la foto se desmarca y retira su checkmark rojo (`FR-11`)
* **And** el contador del botón flotante inferior resta 1 foto
* **And** el botón de lote de la categoría cambia a `Marcar todas` (`FR-7`, `EC-3`).

### Scenario 4: Acción de marcado masivo con selección parcial
* **Given** una categoría donde 2 fotos están marcadas y 2 están desmarcadas
* **When** el usuario pulsa sobre el botón `Marcar todas`
* **Then** todas las fotos de dicha categoría pasan a estar marcadas para descarte con su checkmark rojo
* **And** el botón cambia a `Desmarcar todas`
* **And** el contador global del botón inferior se actualiza sumando las fotos recién marcadas.

### Scenario 5: Inspección en pantalla completa por pulsación prolongada
* **Given** una foto visible en la cuadrícula de 3 columnas
* **When** el usuario mantiene presionada la miniatura
* **Then** se presenta el modal de inspección en alta resolución con zoom gestual (`FR-13`)
* **And** al cerrar el modal, el usuario regresa a la cuadrícula manteniendo su selección activa.

### Scenario 6: Navegación al Paso 4 de Confirmación
* **Given** que el usuario ha revisado las categorías y tiene fotos marcadas para eliminar
* **When** pulsa el botón flotante `Continuar (N fotos marcadas) →`
* **Then** la aplicación navega a la pantalla del Paso 4 transmitiendo las fotos marcadas para su confirmación (`FR-16`).

---

## 7. Out of Scope

* Extracción completa u OCR de texto para lectura o indexación fuera del triaje.
* Reclasificación manual de fotos entre categorías por parte del usuario.
* Invocación de la eliminación nativa dentro del Paso 3 (delegada al Paso 4).
* Modificación de metadatos o edición gráfica de las imágenes.
