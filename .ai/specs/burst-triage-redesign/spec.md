# Feature Specification: Rediseño de Triaje de Ráfagas (`burst-triage-redesign`)

## 1. Purpose
Modernizar la experiencia de curación de ráfagas correspondiente al **Paso 3 de 4 (Vista de Triaje)** en la aplicación Cull. El objetivo es proporcionar al usuario una interfaz visual, ágil y de alta precisión para comparar tomas consecutivas o similares: una tarjeta por lote con visor prominente de la foto "Ganadora", un carrusel inferior con todas las tomas (indicador verde para tomas conservadas e indicador rojo para tomas a descartar), cambio de ganadora con un solo toque, inspección ampliada por pulsación prolongada, acciones masivas por lote ("Conservar todo" / "Eliminar todo"), y avance fluido mediante un botón flotante hacia la confirmación final (Paso 4).

### Assumptions:
* **Assumption 1 (Inclusión Total en Miniaturas):** El carrusel inferior de miniaturas incluye la totalidad de las tomas del grupo (incluida la ganadora actual) para permitir una visión integral y facilitar el cambio de ganadora inmediato con un solo toque.
* **Assumption 2 (Promoción de Ganadora con un Toque):** Al tocar cualquier miniatura con indicador rojo, dicha fotografía se convierte en la nueva foto destacada ("Ganadora") en el visor hero principal, pasando su indicador a verde y asignando el indicador rojo de descarte a la ganadora anterior.
* **Assumption 3 (Inspección Modal por Pulsación Prolongada):** Cualquier foto (tanto en el visor principal como en las miniaturas del carrusel) puede previsualizarse en alta resolución en un modal interactivo al mantenerla presionada.
* **Assumption 4 (Navegación al Paso 4):** El botón inferior `Continuar (N fotos marcadas) →` no realiza el borrado físico directo en la biblioteca, sino que transfiere las fotos marcadas a la pantalla de revisión y confirmación final (Paso 4 de 4).
* **Assumption 5 (Pill Superior Informativo):** El componente superior en formato pill muestra un dot de color a la izquierda seguido de `Ráfagas · X fotos` (donde X es el número de fotos procesadas en las ráfagas), actuando como un indicador visual de contexto no interactivo.
* **Assumption 6 (Identificador Cronológico Simplificado):** De acuerdo con la decisión explícita (Opción B), los nombres temáticos de escenas quedan fuera de alcance; las tarjetas se identifican cronológicamente (ej. `Ráfaga #1 · 11:24 AM`).

---

## 2. User Stories

* **US-1 (Comparación Visual de Ráfagas):** Como usuario, quiero ver la mejor toma recomendada de cada ráfaga en gran tamaño junto a las tomas alternativas para decidir con certeza qué foto conservar.
* **US-2 (Cambio Rápido de Ganadora):** Como usuario, quiero cambiar la foto ganadora pulsando directamente sobre cualquiera de las miniaturas inferiores para que mi toma preferida sea la conservada sin fricciones.
* **US-3 (Inspección Detallada por Gesto):** Como usuario, quiero mantener presionada cualquier foto para abrir un modal ampliado que me permita evaluar nitidez, expresiones y detalles antes de descartar.
* **US-4 (Control Rápido por Lote):** Como usuario, quiero disponer de opciones de menú para "Conservar todo" o "Eliminar todo" en una ráfaga con un solo toque para acelerar mi flujo de limpieza.
* **US-5 (Progreso y Avance a Confirmación):** Como usuario, quiero ver en un botón flotante el conteo consolidado de fotos marcadas para descarte y avanzar a la confirmación final del proceso.

---

## 3. Functional Requirements

### Cabecera y Navegación
* **FR-1 (Botón de Retroceso):** El sistema DEBE incluir un botón `< Modo` en la parte superior izquierda que regrese al usuario al Paso 2 (Selector de Modo), conservando el rango temporal previamente configurado.
* **FR-2 (Indicador de Modo y Volumen):** La cabecera DEBE mostrar un pill en la parte superior derecha con un dot de color a la izquierda, seguido del texto `Ráfagas · X fotos` (donde X es la cantidad total de fotos agrupadas en las ráfagas analizadas), como indicador contextual informativo.

### Tarjeta de Ráfaga
* **FR-3 (Identificación del Lote):** Cada tarjeta DEBE presentar un indicador verde, un título cronológico con el formato `Ráfaga #X · [Hora]` (ej. `Ráfaga #1 · 11:24 AM`) y un subtítulo que indique la fecha y la cantidad de tomas (ej. `16 Nov · 5 tomas`).
* **FR-4 (Menú Contextual de Lote):** La tarjeta DEBE incluir en su esquina superior derecha un botón de opciones (`⋮`) que despliegue las acciones:
  * **Conservar todo:** Establece todas las fotos del lote en estado conservado (indicadores verdes).
  * **Eliminar todo:** Marca todas las fotos del lote para eliminación (indicadores rojos).
* **FR-5 (Visor Hero de la Foto Ganadora):** La tarjeta DEBE mostrar un visor de imagen prominente con la fotografía ganadora actual del grupo.
* **FR-6 (Insignias Sobre el Visor Hero):**
  * Sobre la esquina inferior izquierda del visor hero: Insignia destacada `☆ Ganadora (Conservar)` con fondo verde.
  * Sobre la esquina inferior derecha del visor hero: Insignia informativa `🖐 Mantén presionado` con fondo semi-transparente.
* **FR-7 (Resumen de Descarte del Lote):** Debajo del visor hero, la tarjeta DEBE mostrar a la izquierda el total de tomas alternativas (ej. `• 4 tomas alternativas`) y a la derecha el tamaño estimado que se liberará (ej. `Liberará ~16.8 MB`). Si no hay tomas a eliminar, reflejará estado conservado (0 B).

### Carrusel y Selección de Fotos
* **FR-8 (Carrusel Inferior Completo):** La tarjeta DEBE mostrar una fila horizontal con miniaturas de **todas** las tomas de la ráfaga (incluida la ganadora).
* **FR-9 (Distinción de Estados en Miniaturas):**
  * La foto ganadora (o conservada) DEBE mostrar un indicador circular verde.
  * Cada foto marcada para descarte DEBE mostrar un indicador circular rojo con checkmark (`✓`).
* **FR-10 (Promoción a Ganadora con un Toque):** Al tocar cualquier miniatura en el carrusel, el sistema DEBE actualizarla de inmediato como la foto ganadora del grupo, exhibiéndola en el visor hero principal, actualizando su indicador a verde y pasando la ganadora anterior a estado de descarte (indicador rojo).
* **FR-11 (Inspección Ampliada Modal):** Al mantener presionada cualquier fotografía (sea el visor hero o una miniatura del carrusel), el sistema DEBE desplegar un modal a pantalla completa con la imagen en alta definición y opción para cerrarlo.

### Botón de Continuación
* **FR-12 (Botón Flotante Dinámico):** El sistema DEBE presentar un botón flotante fijado en la parte inferior con la leyenda dinámica `Continuar (N fotos marcadas) →`, donde `N` es la sumatoria de todas las fotos con indicador rojo en todas las ráfagas del período.
* **FR-13 (Avance al Paso 4):** Al presionar el botón `Continuar`, el sistema DEBE navegar a la pantalla de revisión final (Paso 4), transfiriendo el listado de fotos marcadas para su posterior confirmación de borrado.

---

## 4. Non-Functional Requirements

* **NFR-1 (Rendimiento de Desplazamiento):** La lista de tarjetas DEBE mantener un desplazamiento a 60 fps / 120 fps en dispositivos compatibles, empleando carga asíncrona de miniaturas y reciclaje de vistas.
* **NFR-2 (Latencia de Interacción):** La alternancia de foto ganadora al tocar una miniatura DEBE ejecutarse en menos de 50 milisegundos en el hilo principal.
* **NFR-3 (Accesibilidad y VoiceOver):** Todas las fotos y controles interactivos DEBEN contar con etiquetas de accesibilidad comprensibles (ej. "Toma 1 de 5, Ganadora", "Toma 2 de 5, marcada para eliminar") y un área táctil mínima de 44 × 44 pt.
* **NFR-4 (Alineación con Sistema de Diseño):** Todos los componentes visuales (tarjetas, botones, tipografía, badges e iconos) DEBEN adherirse estrictamente a los tokens definidos en `ds.md` (`AppColor`, `AppFont`, `AppTheme`, `AppMotion`).

---

## 5. Edge Cases & Boundary Scenarios

* **EC-1 (Todas las fotos conservadas en una ráfaga):** Si el usuario selecciona "Conservar todo", todas las miniaturas lucen verdes, el visor hero mantiene la foto principal, el texto de ahorro muestra `0 B` y el botón flotante resta las tomas descartables del total.
* **EC-2 (Todas las fotos descartadas en una ráfaga):** Si el usuario selecciona "Eliminar todo", todas las miniaturas lucen rojas, la insignia `☆ Ganadora` se retira o se oculta del visor hero, y todas las tomas se suman al descarte global.
* **EC-3 (Ráfagas pequeñas de 2 tomas):** Si la ráfaga tiene exactamente 2 tomas, ambas aparecen en el carrusel; tocar la alternativa invierte de inmediato la ganadora y la descartable.
* **EC-4 (Ráfagas extensas de 30+ tomas):** El carrusel inferior DEBE desplazarse horizontalmente de forma suave sin desbordar el contenedor ni degradar el uso de memoria.
* **EC-5 (Falta de datos de tamaño de archivo):** Si un activo fotográfico no expone tamaño en bytes, el sistema DEBE estimar un valor representativo o excluirlo del cálculo numérico sin bloquear la interfaz.
* **EC-6 (Retroceso al Paso 2 y Regreso al Paso 3):** Si el usuario pulsa `< Modo` y vuelve a entrar a Ráfagas dentro del mismo período sin modificar las fotos, el estado de selecciones y ganadoras DEBE conservarse intacto.

---

## 6. Acceptance Criteria (BDD Format)

### Scenario 1: Presentación inicial de tarjetas de ráfagas con foto ganadora recomendada
* **Given** que el usuario completó la selección de período y seleccionó el modo "Ráfagas"
* **When** se presenta la pantalla de Triaje de Ráfagas (Paso 3)
* **Then** la cabecera muestra el botón `< Modo` y el pill informativo con dot izquierdo `Ráfagas · X fotos` (`FR-1`, `FR-2`)
* **And** cada tarjeta exhibe el título cronológico `Ráfaga #X · [Hora]` y el subtítulo con fecha y número de tomas (`FR-3`)
* **And** el visor hero exhibe la foto mejor calificada con la insignia `☆ Ganadora (Conservar)` y la insignia `🖐 Mantén presionado` (`FR-5`, `FR-6`)
* **And** el carrusel inferior contiene todas las tomas del grupo: la ganadora con indicador verde y las alternativas con indicador rojo (`FR-8`, `FR-9`)
* **And** el botón inferior muestra el total consolidado de fotos marcadas: `Continuar (N fotos marcadas) →` (`FR-12`).

### Scenario 2: Promoción de foto ganadora con un solo toque
* **Given** una tarjeta de ráfaga con la foto A en el visor hero (indicador verde) y la foto B en el carrusel (indicador rojo)
* **When** el usuario pulsa sobre la miniatura de la foto B
* **Then** la foto B se muestra inmediatamente en el visor hero principal
* **And** la foto B adquiere el indicador circular verde
* **And** la foto A pasa al carrusel con indicador rojo de descarte
* **And** el total general de fotos marcadas en el botón inferior se actualiza coherentemente (`FR-10`).

### Scenario 3: Inspección modal en pantalla completa por pulsación prolongada
* **Given** una tarjeta de ráfaga visible en pantalla
* **When** el usuario mantiene presionada la imagen del visor hero o cualquier miniatura del carrusel
* **Then** el sistema presenta un modal a pantalla completa con la imagen en alta resolución (`FR-11`)
* **And** al pulsar el control de cierre, el modal se oculta regresando al triaje sin alterar las selecciones activas.

### Scenario 4: Acción rápida "Conservar todo" desde el menú contextual
* **Given** una tarjeta de ráfaga con tomas marcadas en rojo para descarte
* **When** el usuario abre el menú contextual `⋮` y pulsa "Conservar todo"
* **Then** todas las miniaturas de la ráfaga adoptan el indicador verde (`FR-4`)
* **And** el indicador de espacio a liberar de la tarjeta se actualiza a estado conservado
* **And** las fotos descartables de este grupo se restan del total del botón inferior.

### Scenario 5: Acción rápida "Eliminar todo" desde el menú contextual
* **Given** una tarjeta de ráfaga con una foto ganadora conservada
* **When** el usuario abre el menú contextual `⋮` y pulsa "Eliminar todo"
* **Then** todas las miniaturas de la ráfaga adoptan el indicador rojo de descarte (`FR-4`)
* **And** la insignia `☆ Ganadora` se retira del visor hero
* **And** la totalidad de las fotos de la ráfaga se suma al contador del botón inferior `Continuar`.

### Scenario 6: Navegación al Paso 4 de Confirmación
* **Given** que el usuario ha revisado las ráfagas y tiene fotos marcadas para eliminar
* **When** pulsa el botón flotante `Continuar (N fotos marcadas) →`
* **Then** la aplicación navega a la pantalla del Paso 4 (Revisión Final) transmitiendo las fotos marcadas para confirmar su eliminación (`FR-13`).

---

## 7. Out of Scope

* Clasificación semántica de escenas o lugares (ej. "Parque", "Atardecer") mediante modelos de Vision o Geocoding (pospuesto según decisión explícita Opción B).
* Ejecución física o invocación del diálogo nativo de borrado de iOS dentro del Paso 3 (delegado al Paso 4 de confirmación).
* Modificación de metadatos o edición de imagen dentro del visor de triaje.
* Alternancia interactiva entre modos de depuración desde el pill superior `Modo: Ráfagas`.
