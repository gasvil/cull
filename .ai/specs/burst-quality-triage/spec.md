# Feature Specification: Curación y Triaje de Ráfagas por Calidad (`burst-quality-triage`)

## 1. Purpose
Empoderar al usuario para recuperar espacio de almacenamiento y eliminar el desorden visual en su carrete mediante el triaje inteligente de ráfagas nativas y fotos tomadas manualmente en ráfaga rápida (tomas similares consecutivas). El sistema evalúa objetivamente la calidad técnica de cada toma para proponer la mejor foto, permitiendo al usuario una flexibilidad total: conservar una o varias tomas destacadas, mantener el lote completo sin cambios, o descartar el lote entero si todo el contenido es considerado basura digital.

### Assumptions:
* **Assumption 1 (Ventana de Agrupación Temporal y Ráfagas Manuales):** Dos o más fotos consecutivas se consideran candidatas a un mismo "Grupo de Similitud" si provienen de una ráfaga de hardware nativa o si fueron capturadas manualmente con un intervalo no mayor a 5.0 segundos entre sí y comparten alta correspondencia visual.
* **Assumption 2 (Ponderación de Calidad Compuesta):** La métrica de calidad es un índice normalizado de 0.0 a 1.0. Para fotos con rostros humanos detectados, se pondera: Nitidez (40%), Apertura de ojos/expresión facial (40%) y Exposición equilibrada (20%). Para fotos de paisajes u objetos sin rostros: Nitidez (70%) y Exposición equilibrada (30%).
* **Assumption 3 (Propuesta Inicial vs. Flexibilidad Total):** El sistema propone inicialmente la foto con el puntaje más alto como "Foto Conservada" (*Keeper*) y las demás como "Candidatas a Descarte". No obstante, el usuario puede seleccionar múltiples fotos para conservar, marcar todo el lote para descarte o conservar el lote íntegro.
* **Assumption 4 (Inmunidad y Tratamiento de Fotos Favoritas):** Las fotos marcadas previamente como "Favorita" en la biblioteca del usuario están protegidas contra descarte accidental. Si el usuario ejecuta la acción "Eliminar todo el lote", las fotos favoritas quedarán excluidas de la eliminación a menos que el usuario confirme explícitamente incluirlas tras una advertencia.
* **Assumption 5 (Cero Pérdida de Datos No Supervisada):** El sistema nunca eliminará fotos de forma silenciosa ni permanente; toda eliminación requiere la aprobación explícita del usuario y utilizará el mecanismo de papelera recuperable del sistema operativo.

---

## 2. User Stories

* **US-1 (Detección de Ráfagas Nativas y Manuales):** Como usuario que captura múltiples fotos seguidas de un mismo instante (ya sea por ráfaga continua o toques manuales sucesivos), quiero que la aplicación agrupe esas tomas automáticamente para analizarlas en conjunto.
* **US-2 (Evaluación Objetiva de Calidad):** Como usuario, quiero que el sistema me recomiende la mejor toma técnica basándose en nitidez y ojos abiertos para no perder tiempo comparando detalles mínimos.
* **US-3 (Selección Múltiple de Tomas Conservadas):** Como usuario, quiero poder conservar más de una foto del grupo cuando haya varias tomas con buenas expresiones o ángulos que me interese guardar, descartando únicamente las tomas sobrantes.
* **US-4 (Descarte Completo de Lotes Inútiles):** Como usuario, quiero poder descartar todo el lote con una sola acción cuando toda la ráfaga haya salido mal (accidental, borrosa o irrelevante).
* **US-5 (Conservación Total sin Cambios):** Como usuario, quiero poder omitir el triaje y conservar todo el grupo intacto con una sola acción cuando decida no purgar ninguna toma.
* **US-6 (Revisión y Aprobación Rápida con Espacio Recuperable):** Como usuario, quiero ver claramente la previsualización real de cada foto y el espacio total en megabytes que recuperaré antes de confirmar cualquier eliminación.
* **US-7 (Persistencia Eficiente del Análisis):** Como usuario, cuando salga y vuelva a entrar a la pantalla de Triaje de Ráfagas sin que hayan ingresado nuevas fotos al carrete, quiero ver el último análisis de inmediato sin esperar a que se procese todo nuevamente.
* **US-8 (Filtrado por Día o Rango de Fechas):** Como usuario, quiero poder seleccionar un día específico o un rango de fechas antes o durante el triaje, para analizar únicamente las fotos tomadas en ese período en lugar de procesar todo el carrete sin control.

---

## 3. Functional Requirements

* **FR-1 (Agrupación de Ráfagas Nativas y Tomas Manuales):** El sistema DEBE agrupar en un "Grupo de Similitud" tanto secuencias de ráfaga nativa de la cámara como fotos consecutivas tomadas manualmente en un intervalo menor o igual a 5.0 segundos con alta correspondencia visual.
* **FR-2 (Evaluación de Nitidez):** El sistema DEBE calcular un índice numérico normalizado (0.0 a 1.0) que represente la nitidez y foco de los elementos principales de cada imagen del grupo.
* **FR-3 (Evaluación de Expresión y Ojos Abiertos):** En imágenes que contengan rostros humanos, el sistema DEBE evaluar si los sujetos tienen los ojos abiertos y penalizar el puntaje ante ojos cerrados o parpadeos.
* **FR-4 (Propuesta Inicial de la Mejor Toma):** El sistema DEBE calcular el puntaje global (0.0 a 1.0) y preseleccionar como "Foto Conservada" (*Keeper*) a la foto con el puntaje más alto del grupo.
* **FR-5 (Resolución de Empates):** Si dos o más fotos obtienen exactamente el mismo puntaje global, el sistema DEBE preseleccionar como conservada la primera foto capturada cronológicamente.
* **FR-6 (Preselección Inicial de Descarte):** El sistema DEBE marcar inicialmente el resto de fotos no recomendadas como "Candidatas a Descarte", excluyendo fotos protegidas por la regla de favoritos.
* **FR-7 (Protección de Elementos Favoritos):** Las fotos marcadas como favoritas en la biblioteca NUNCA DEBEN ser preseleccionadas automáticamente para descarte.
* **FR-8 (Cálculo Dinámico de Almacenamiento Recuperable):** El sistema DEBE calcular y actualizar en tiempo real la suma total en megabytes (MB) de las fotos marcadas actualmente para descarte.
* **FR-9 (Selección Múltiple de Fotos Conservadas):** La interfaz DEBE permitir al usuario marcar dos o más fotos del grupo como "Fotos Conservadas", retirándolas instantáneamente de la lista de candidatas a descarte.
* **FR-10 (Acción Rápida 'Eliminar Todo el Lote'):** El sistema DEBE ofrecer una acción explícita para marcar todas las fotos del lote (incluida la mejor valorada) como candidatas a descarte, requiriendo confirmación si contiene fotos favoritas.
* **FR-11 (Acción Rápida 'Mantener Todo el Lote'):** El sistema DEBE ofrecer una acción explícita para desmarcar todas las fotos de descarte y archivar el grupo como revisado sin enviar ninguna foto a la papelera.
* **FR-12 (Confirmación de Depuración en Lote):** Al pulsar la confirmación de descarte, el sistema DEBE invocar el diálogo nativo de papelera del sistema operativo únicamente para los elementos marcados para descarte.
* **FR-13 (Previsualización Visual de Miniaturas):** La interfaz DEBE renderizar la imagen real de cada fotografía del lote en tamaño miniatura optimizado para visualización rápida.
* **FR-14 (Reutilización del Análisis Previo / Cache Inteligente):** Al acceder a la pantalla de Triaje, el sistema DEBE comprobar si el conjunto de fotos recientes no ha cambiado (mismo conteo e identificadores más recientes). Si no hay cambios, DEBE restaurar inmediatamente los lotes previamente analizados sin re-ejecutar el análisis de calidad ni bloquear la interfaz.
* **FR-15 (Selector de Fecha y Rango de Análisis):** La pantalla de Triaje DEBE presentar un selector de período que permita elegir entre "Día específico" o "Rango de fechas" (con opciones rápidas como Hoy, Ayer, Últimos 7 días o Personalizado). El análisis de ráfagas DEBE ejecutarse exclusivamente sobre los activos capturados dentro de la ventana de fecha seleccionada.

---

## 4. Non-Functional Requirements

* **NFR-1 (Privacidad Estricta / Zero-Cloud):** El 100% del procesamiento, análisis visual, detección facial y agrupamiento DEBE ejecutarse localmente en el dispositivo sin conexiones de red ni envío de telemetría o imágenes.
* **NFR-2 (Rendimiento y Latencia de Evaluación):** La evaluación completa de calidad para un grupo de hasta 10 fotos DEBE completarse en un tiempo menor o igual a 1.5 segundos en dispositivos soportados.
* **NFR-3 (Límite de Consumo de Memoria):** Durante el procesamiento por lotes, el incremento de consumo de memoria RAM no DEBE superar los 120 MB sobre el nivel base de la aplicación.
* **NFR-4 (Seguridad y Reversibilidad):** Ninguna operación de descarte podrá eludir la papelera recuperable nativa del sistema operativo.
* **NFR-5 (Resiliencia ante Fallos de Entrada):** Si una imagen individual está corrupta o no puede ser decodificada, el sistema DEBE ignorar esa imagen individual y continuar procesando el resto del grupo sin interrumpir la operación.

---

## 5. Edge Cases & Boundary Scenarios

* **EC-1 (Grupo con Foto Única):** Si una foto aislada no tiene tomas similares en su ventana temporal ni pertenece a una ráfaga, no formará ningún grupo de triaje.
* **EC-2 (Todas las Fotos Defectuosas):** Si todas las fotos de una ráfaga presentan baja calidad extrema, el sistema recomienda la menos defectuosa pero destaca visualmente la opción de "Eliminar Todo el Lote".
* **EC-3 (Acción 'Eliminar Todo' con Fotos Favoritas en el Grupo):** Si el grupo contiene una o más fotos favoritas y el usuario pulsa "Eliminar Todo el Lote", el sistema debe advertir que el grupo contiene fotos favoritas y conservarlas a menos que el usuario confirme explícitamente eliminarlas también.
* **EC-4 (Acción 'Mantener Todo el Lote'):** Cuando el usuario selecciona "Mantener Todo", el sistema no invoca la papelera, establece el espacio a liberar en 0 MB y remueve el grupo de la lista pendiente.
* **EC-5 (Fotos sin Rostros / Objetos Inanimados):** El motor transiciona limpiamente a evaluar únicamente nitidez y exposición sin arrojar errores por ausencia de rostros.
* **EC-6 (Cancelación en el Diálogo del Sistema):** Si el usuario cancela en el diálogo de confirmación del sistema operativo, el estado del grupo debe mantenerse idéntico sin aplicar cambios.

---

## 6. Acceptance Criteria (BDD Format)

### Scenario 1: Triaje estándar con recomendación automática
* **Given** un grupo de 5 fotos consecutivas tomadas manualmente en un lapso de 2.5 segundos
* **And** la foto #2 tiene la mayor nitidez y ojos abiertos con un puntaje de 0.94
* **When** el motor de triaje presenta el grupo
* **Then** la foto #2 DEBE ser preseleccionada como "Foto Conservada" (`FR-4`)
* **And** las fotos #1, #3, #4 y #5 DEBEN ser marcadas como "Candidatas a Descarte" (`FR-6`)
* **And** el espacio a recuperar DEBE corresponder al tamaño acumulado de las fotos #1, #3, #4 y #5 (`FR-8`).

### Scenario 2: Selección de múltiples fotos conservadas (Multi-keeper)
* **Given** un grupo de 4 fotos de una misma escena donde la foto #1 es la mejor toma recomendada
* **And** las fotos #2, #3 y #4 están marcadas para descarte
* **When** el usuario selecciona además la foto #3 para conservarla
* **Then** tanto la foto #1 como la foto #3 DEBEN quedar marcadas como "Fotos Conservadas" (`FR-9`)
* **And** únicamente las fotos #2 y #4 DEBEN permanecer marcadas como candidatas a descarte (`FR-9`)
* **And** el espacio a recuperar DEBE recalcularse descontando el tamaño de la foto #3 (`FR-8`).

### Scenario 3: Descarte de todo el lote (Eliminar todo)
* **Given** una ráfaga accidental de 6 fotos desenfocadas
* **When** el usuario presiona la acción "Eliminar todo el lote"
* **Then** las 6 fotos (incluyendo la mejor evaluada) DEBEN ser marcadas para descarte (`FR-10`)
* **And** el espacio a recuperar DEBE reflejar el tamaño total de las 6 fotos (`FR-8`)
* **When** el usuario confirma la operación
* **Then** el sistema DEBE solicitar al sistema operativo el envío de las 6 fotos a la papelera (`FR-12`).

### Scenario 4: Conservación de todo el lote (Mantener todo)
* **Given** un grupo de 3 fotos de un evento especial donde el usuario desea conservar todas las tomas
* **When** el usuario presiona la acción "Mantener todo el lote"
* **Then** ninguna foto debe permanecer marcada para descarte (`FR-11`)
* **And** el espacio a recuperar DEBE mostrar 0 MB (`FR-8`, `EC-4`)
* **And** el grupo DEBE archivarse como resuelto sin solicitar eliminación al sistema operativo (`EC-4`).

### Scenario 5: Protección de favoritas al ejecutar "Eliminar todo"
* **Given** un grupo de 4 fotos donde la foto #4 es favorita del usuario
* **When** el usuario presiona "Eliminar todo el lote"
* **Then** el sistema DEBE advertir la presencia de una foto favorita (`EC-3`)
* **And** la foto #4 NO DEBE ser enviada a la papelera a menos que el usuario confirme explícitamente incluir favoritas (`Assumption 4`, `EC-3`).

### Scenario 6: Resolución determinista de empates de calidad
* **Given** 2 fotos idénticas con un puntaje de calidad empatado en 0.8800
* **When** se define la recomendación inicial
* **Then** la foto con fecha de captura más antigua DEBE ser la recomendada inicialmente como conservada (`FR-5`).

### Scenario 7: Reutilización de análisis sin nuevas fotos
* **Given** un análisis completado previamente con 2 grupos de ráfagas
* **And** el usuario sale de la pantalla de triaje y regresa sin que se hayan capturado nuevas fotos en el carrete
* **When** la pantalla de triaje inicia su carga
* **Then** el sistema DEBE presentar de inmediato los grupos analizados previamente sin volver a mostrar el estado de análisis completo (`FR-14`)
* **And** no debe re-analizar las imágenes con el motor de visión (`US-7`).

### Scenario 8: Filtrado por fecha específica o rango
* **Given** una biblioteca de fotos con capturas en múltiples días
* **When** el usuario selecciona un día específico en el selector de fechas
* **Then** el motor de búsqueda DEBE consultar únicamente las fotos capturadas entre el inicio y fin de ese día (`FR-15`)
* **And** los lotes de ráfagas analizados deben corresponder exclusivamente a esa fecha seleccionada (`US-8`).

---

## 7. Out of Scope

* Ejecución automática en segundo plano mediante tareas programadas (corresponde a *Daily Digest*).
* Detección y vencimiento de fotos utilitarias o comprobantes (corresponde a *Lifecycle / TTL*).
* Sincronización o interacción con almacenamiento en la nube.
* Modificación destructiva permanente que eluda la papelera nativa de fotos.
