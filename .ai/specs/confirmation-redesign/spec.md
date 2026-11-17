# Feature Specification: Rediseño de Pantalla de Confirmación y Cierre (`confirmation-redesign`)

## 1. Purpose
Modernizar la experiencia del **Paso 4 de 4 (Revisión Final y Depuración)** en Cull. Este módulo consolida el resumen de la limpieza antes de la eliminación definitiva, proporcionando una arquitectura de tres fases con máxima seguridad, claridad visual y satisfacción de usuario:
1. **Pantalla de Confirmación:** Exhibe el impacto total de almacenamiento recuperable, el conteo de fotos marcadas, metadatos del período analizado, tipo de depuración (`Tomas redundantes` o `Fotos sin rostro`), destino en la papelera del sistema y sello de privacidad local en el dispositivo. El botón `Depurar ahora` se deshabilita automáticamente si hay 0 fotos marcadas.
2. **Modal de Advertencia Destructiva:** Al presionar `Depurar ahora`, se despliega un modal explícito de confirmación que detalla la cantidad de fotos, el ahorro en MB y el recordatorio de 30 días de recuperación en el álbum "Eliminado recientemente" de Fotos, con las opciones `Eliminar definitivamente` y `Cancelar`.
3. **Pantalla de Depuración Completada (Éxito):** Tras confirmar el borrado mediante PhotoKit, la aplicación presenta una vista de celebración con el espacio liberado (`+X.X MB libres`), métricas de calidad de fotos conservadas (`Calidad 100%`), barra de memoria recuperada, consejo de mantenimiento y el botón de acción principal `↻ Listo • Nueva depuración` para volver al inicio.

### Assumptions:
* **Assumption 1 (Flujo en Tres Fases):** El proceso de cierre consta de Pantalla de Confirmación → Modal de Advertencia Destructiva → Pantalla de Depuración Completada.
* **Assumption 2 (Ejecución y Resiliencia ante Cancelación):** Al pulsar `Eliminar definitivamente` en el modal, se ejecuta la llamada a PhotoKit. Si el usuario acepta el diálogo nativo del sistema operativo, se transiciona a la pantalla de éxito. Si cancela el diálogo nativo o pulsa `Cancelar` en el modal, este se descarta y el usuario permanece en la pantalla de Confirmación con su estado intacto.
* **Assumption 3 (Rótulo Dinámico de Depuración):** La tarjeta de resumen exhibe `Tomas redundantes` cuando el flujo proviene del modo Ráfagas, y `Fotos sin rostro` cuando proviene del modo Sin Rostro.
* **Assumption 4 (Persistencia de Estado al Retroceder):** Al pulsar `< Revisar`, el sistema regresa a la pantalla de triaje del Paso 3 manteniendo intactas las fotos marcadas y conservadas.
* **Assumption 5 (Deshabilitación con 0 Fotos):** Si no hay fotos marcadas para eliminar (0 fotos y 0 B), el botón `Depurar ahora` aparece deshabilitado e inactivo.

---

## 2. User Stories

* **US-1 (Claridad del Impacto Previo al Borrado):** Como usuario, quiero ver de forma prominente cuánto espacio en disco voy a recuperar y cuántas fotos se eliminarán antes de tomar la decisión final.
* **US-2 (Confirmación Segura y Reversible):** Como usuario, quiero ver un modal de advertencia que me recuerde que las fotos van al álbum "Eliminado recientemente" por 30 días para sentir total tranquilidad.
* **US-3 (Celebración y Métricas de Éxito):** Como usuario, quiero ver una pantalla de finalización satisfactoria que confirme el éxito de la operación y el espacio liberado en mi dispositivo.
* **US-4 (Retorno sin Pérdida de Cambios):** Como usuario, quiero poder regresar al Paso 3 con `< Revisar` para modificar selecciones de última hora sin que se reinicie mi trabajo.
* **US-5 (Reinicio del Ciclo de Curación):** Como usuario, quiero un botón para comenzar una nueva depuración directamente desde la pantalla de éxito.

---

## 3. Functional Requirements

### Fase 1: Pantalla de Confirmación (Paso 4)
* **FR-1 (Cabecera de Navegación):** La barra superior DEBE exhibir el botón `< Revisar` a la izquierda (que regresa al Paso 3 manteniendo selecciones) y la leyenda contextual `Confirmación` a la derecha.
* **FR-2 (Visualización Hero de Espacio Recuperable):** El sistema DEBE mostrar un contenedor tonal con icono representativo de papelera, una etiqueta superior en color carmine coral `ESPACIO RECUPERABLE` y el titular en tipografía display grande: `Liberarás [X.X MB / GB]`.
* **FR-3 (Mensaje Explicativo de Fotos y Destino):** DEBE incluir un texto descriptivo con el conteo resaltado: `[N] fotos se eliminarán de este dispositivo y se moverán al álbum "Eliminado recientemente" de Fotos.`
* **FR-4 (Tarjeta de Metadatos de la Depuración):** La pantalla DEBE mostrar una tarjeta informativa con:
  * **Período analizado:** Nombre del período configurado en el Paso 1 (ej. `Últimos 7 días`, `Hoy`, etc.).
  * **Tipo de depuración:** `Tomas redundantes` (para Ráfagas) o `Fotos sin rostro` (para Sin Rostro).
  * **Destino:** `Papelera del sistema`.
* **FR-5 (Insignia de Seguridad y Privacidad):** Debajo de la tarjeta DEBE mostrarse el indicador `🔒 Procesado 100% en el dispositivo` en tipografía monospaced.
* **FR-6 (Botón 'Depurar ahora'):** Botón inferior fijado con fondo carmine coral (`AppColor.cull`), icono de papelera y texto `Depurar ahora`.
* **FR-7 (Estado Deshabilitado del Botón):** Si `N == 0` (cero fotos marcadas), el botón `Depurar ahora` DEBE mostrarse en estado deshabilitado (opacidad al 40% y no interactivo).

### Fase 2: Modal de Advertencia Destructiva
* **FR-8 (Despliegue del Modal de Advertencia):** Al pulsar `Depurar ahora`, el sistema DEBE desplegar un modal de advertencia centrado sobre un fondo atenuado:
  * Icono de advertencia en contenedor circular suave.
  * Título: `¿Eliminar [N] fotos seleccionadas?`
  * Subtítulo explicativo: `Esta acción liberará [X.X MB] de almacenamiento. Las fotos podrán recuperarse en el álbum "Eliminado recientemente" durante 30 días.`
  * Botón de confirmación destructiva: `🗑 Eliminar definitivamente` en texto rojo destacado.
  * Botón de cancelación: `Cancelar` en tarjeta separada.
* **FR-9 (Acción de Cancelación):** Al pulsar `Cancelar`, el modal DEBE cerrarse de inmediato sin realizar modificaciones en la biblioteca ni en el estado de la app.
* **FR-10 (Invocación de Eliminación en PhotoKit):** Al pulsar `Eliminar definitivamente`, el sistema DEBE solicitar a PhotoKit la eliminación de los identificadores de fotos seleccionados. Si el usuario cancela en el diálogo nativo de iOS, el modal se descarta permaneciendo en la pantalla de Confirmación.

### Fase 3: Pantalla de Depuración Completada
* **FR-11 (Transición a Pantalla de Éxito):** Tras una confirmación exitosa en PhotoKit, el sistema DEBE presentar la pantalla de Depuración Completada.
* **FR-12 (Cabecera de Marca):** Logotipo `Cull` con icono circular verde a la izquierda y badge pill `Completado` en verde a la derecha.
* **FR-13 (Hero de Celebración):**
  * Icono circular grande con check verde (`✓`) en doble anillo tonal.
  * Etiqueta superior verde: `¡BIBLIOTECA OPTIMIZADA!`.
  * Titular display: `+[X.X MB] libres`.
  * Subtítulo: `Se eliminaron exitosamente [N] fotos [redundantes / sin rostro] de tu almacenamiento.`
* **FR-14 (Tarjeta de Métricas de Conservación):**
  * Fila 1: `Estado de fotos conservadas` con indicador `✓ Calidad 100%`.
  * Fila 2: Subtítulos `Memoria del carrete` y `Espacio recuperado` acompañados de una barra de progreso que ilustra el espacio liberado.
  * Fila 3: `Disponible en papelera: 30 días`.
* **FR-15 (Callout de Consejo de Mantenimiento):** Tarjeta suave con icono de foco/destello y el texto: `Revisa tus fotos semanalmente para mantener tu galería libre de [ráfagas accidentales / fotos descartables].`
* **FR-16 (Botón 'Listo • Nueva depuración'):** Botón principal inferior `↻ Listo • Nueva depuración` en fondo dark slate (`AppColor.primary`) y texto blanco. Al pulsarlo, el sistema DEBE reiniciar la navegación y regresar a la pantalla de inicio (Home / Paso 1).

---

## 4. Non-Functional Requirements

* **NFR-1 (Seguridad y Privacidad):** La eliminación definitiva DEBE depender obligatoriamente de la autorización final del usuario mediante la API de PhotoKit del sistema.
* **NFR-2 (Conformidad con Sistema de Diseño):** Todos los componentes visuales (tipografías, colores, bordes de 1 pt, radios continuos y espaciados) DEBEN apegarse a `ds.md` (`AppColor`, `AppFont`, `AppTheme`).
* **NFR-3 (Accesibilidad y VoiceOver):** Los botones, diálogos y textos deben contar con etiquetas de accesibilidad explícitas y áreas mínimas de contacto de 44 × 44 pt.
* **NFR-4 (Rendimiento de Transición):** Las transiciones entre la confirmación, el modal y la pantalla de éxito deben ser fluidas (<200 ms) sin saltos visuales ni bloqueos del hilo principal.

---

## 5. Edge Cases & Boundary Scenarios

* **EC-1 (0 fotos seleccionadas):** Si el usuario accede a la pantalla con 0 fotos marcadas, el titular refleja `Liberarás 0 B`, el subtítulo indica `0 fotos se eliminarán...` y el botón `Depurar ahora` permanece deshabilitado.
* **EC-2 (Cancelación del prompt nativo de iOS):** Si el usuario confirma en el modal de la app pero declina el diálogo del sistema operativo, el modal se oculta y la pantalla conserva las fotos marcadas sin pasar a la pantalla de éxito.
* **EC-3 (Error de I/O o permiso revocado durante el borrado):** Si PhotoKit arroja un error inesperado, el sistema muestra una notificación de error clara y mantiene el estado intacto para reintentar.
* **EC-4 (Retorno con `< Revisar`):** Al presionar `< Revisar`, la vista de triaje previa no reinicia su análisis ni pierde ninguna de las selecciones realizadas.

---

## 6. Acceptance Criteria (BDD Format)

### Scenario 1: Presentación de la pantalla de confirmación con fotos marcadas
* **Given** que el usuario marcó 8 fotos redundantes con un peso total de 30.4 MB en el Paso 3
* **When** navega a la pantalla de Confirmación (Paso 4)
* **Then** la cabecera muestra `< Revisar` y `Confirmación` (`FR-1`)
* **And** el titular exhibe `Liberarás 30.4 MB` (`FR-2`)
* **And** el texto explicativo indica `8 fotos se eliminarán de este dispositivo...` (`FR-3`)
* **And** la tarjeta de metadatos muestra el período, tipo de depuración (`Tomas redundantes`) y destino (`Papelera del sistema`) (`FR-4`)
* **And** el botón `Depurar ahora` está activo y habilitado (`FR-6`).

### Scenario 2: Estado inactivo ante 0 fotos marcadas
* **Given** que el usuario llega a Confirmación con 0 fotos seleccionadas
* **When** se presenta la pantalla
* **Then** el titular exhibe `Liberarás 0 B`
* **And** el botón `Depurar ahora` aparece deshabilitado con opacidad reducida (`FR-7`, `EC-1`).

### Scenario 3: Apertura y cancelación del modal de advertencia destructiva
* **Given** la pantalla de Confirmación con fotos marcadas
* **When** el usuario pulsa `Depurar ahora`
* **Then** se despliega el modal centrado con el mensaje `¿Eliminar 8 fotos seleccionadas?` y el botón `Eliminar definitivamente` (`FR-8`)
* **When** el usuario pulsa `Cancelar`
* **Then** el modal se descarta inmediatamente permaneciendo en la pantalla de Confirmación sin ejecutar ningún borrado (`FR-9`).

### Scenario 4: Confirmación exitosa y transición a pantalla de depuración completada
* **Given** el modal de advertencia desplegado
* **When** el usuario pulsa `Eliminar definitivamente`
* **And** confirma el diálogo nativo de PhotoKit de iOS
* **Then** los activos fotográficos son eliminados hacia la papelera del sistema (`FR-10`)
* **And** la aplicación transiciona a la pantalla de "Depuración Completada" (`FR-11`)
* **And** la pantalla exhibe `¡BIBLIOTECA OPTIMIZADA!`, `+30.4 MB libres` y la tarjeta de métricas (`FR-13`, `FR-14`).

### Scenario 5: Cancelación del diálogo nativo de iOS
* **Given** el modal de advertencia desplegado
* **When** el usuario pulsa `Eliminar definitivamente`
* **And** presiona "Cancelar" en el diálogo nativo del sistema de iOS
* **Then** el modal se descarta
* **And** el usuario permanece en la pantalla de Confirmación con sus fotos marcadas intactas (`EC-2`).

### Scenario 6: Reinicio del flujo desde la pantalla de éxito
* **Given** que el usuario se encuentra en la pantalla de Depuración Completada
* **When** pulsa el botón `↻ Listo • Nueva depuración`
* **Then** la aplicación navega directamente a la pantalla de inicio (Home) restableciendo la pila de navegación (`FR-16`).

### Scenario 7: Retorno al Paso 3 mediante `< Revisar`
* **Given** que el usuario está en la pantalla de Confirmación
* **When** pulsa `< Revisar`
* **Then** regresa a la vista de triaje previa (Paso 3)
* **And** las fotos seleccionadas previamente se conservan exactamente en su estado original (`FR-1`, `EC-4`).

---

## 7. Out of Scope

* Vaciado forzoso o vaciado automático del álbum "Eliminado recientemente" (fuera de los permisos de la sandbox de iOS).
* Programación de recordatorios o notificaciones locales recurrentes.
* Modificación de opciones de compresión o calidad de las imágenes conservadas.
