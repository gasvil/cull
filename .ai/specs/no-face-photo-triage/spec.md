# Feature Specification: Depuración de Fotos Sin Rostros (`no-face-photo-triage`)

## 1. Purpose
Permitir al usuario identificar y depurar de forma rápida y segura la basura digital en su carrete que no contiene personas (vouchers, capturas de pantalla, fotos a documentos, tomas accidentales oscuras o fotos borrosas). El sistema aísla las fotografías sin rostros humanos dentro de un período seleccionado, las clasifica semánticamente en tres categorías de prioridad y preselecciona automáticamente el contenido descartable para su revisión, manteniendo las fotos intencionales desmarcadas por defecto y protegiendo de forma estricta cualquier fotografía marcada como favorita.

### Assumptions:
* **Assumption 1 (Segmentación Semántica Tripartita):** Las fotos sin rostros humanos se clasifican en tres categorías excluyentes:
  * **Utilitarias (Alta Prioridad):** Documentos, vouchers, recibos, comprobantes, texto predominante, capturas de pantalla o fotos a monitores.
  * **Deficientes (Alta Prioridad):** Fotos con desenfoque severo, movimiento fallido o subexposición extrema (fotos negras o accidentales en bolsillos/bolsos).
  * **Por Validar (Prioridad Media):** Fotos técnicamente nítidas sin rostros humanos que corresponden a tomas intencionales (mascotas, paisajes, comida, viajes, arquitectura).
* **Assumption 2 (Regla de Preselección Inicial):** Para maximizar la eficiencia y prevenir borrados accidentales:
  * Las fotos de las categorías **Utilitarias** y **Deficientes** aparecen **preseleccionadas para descarte** por defecto (el usuario puede desmarcar falsos positivos).
  * Las fotos de la categoría **Por Validar** aparecen visibles pero **desmarcadas por defecto** (requieren decisión humana activa para marcarse).
* **Assumption 3 (Inmunidad y Ocultamiento Absoluto de Favoritas):** Toda fotografía marcada como "Favorita" en la biblioteca del usuario queda completamente oculta y excluida de este módulo, garantizando cero riesgo de eliminación accidental.
* **Assumption 4 (Filtrado Temporal Previo):** El análisis de fotos sin rostros se ejecuta sobre una ventana temporal seleccionada por el usuario (un día específico, un rango de fechas o accesos rápidos: Hoy, Ayer, Últimos 7 días).
* **Assumption 5 (Cero Pérdida de Datos No Supervisada):** Ninguna foto se elimina sin confirmación explícita del usuario y toda eliminación se canaliza a través de la papelera recuperable nativa del sistema operativo.

---

## 2. User Stories

* **US-1 (Selección Temporal Previa):** Como usuario, quiero seleccionar un día específico o un rango de fechas antes de iniciar la búsqueda de fotos sin rostros para acotar la limpieza a un momento concreto.
* **US-2 (Aislamiento de Tomas Sin Personas):** Como usuario, quiero que la aplicación filtre y me muestre únicamente las fotos donde no aparezcan rostros humanos para separar mis recuerdos personales de las fotos utilitarias o accidentales.
* **US-3 (Categorización Semántica Visual):** Como usuario, quiero ver las fotos agrupadas en tres categorías claras ("Utilitarias", "Deficientes" y "Por Validar") para entender rápidamente por qué una foto es candidata a descarte.
* **US-4 (Preselección Segura y Rápida):** Como usuario, quiero que los comprobantes, capturas y fotos borrosas vengan preseleccionadas para descarte, mientras que las fotos de paisajes, mascotas o comida permanezcan desmarcadas, ahorrándome toques innecesarios.
* **US-5 (Blindaje de Fotos Favoritas):** Como usuario, quiero que mis fotos favoritas no aparezcan en esta vista de depuración para tener total tranquilidad de que mis tomas destacadas están a salvo.
* **US-6 (Revisión Granular y Espacio Recuperable):** Como usuario, quiero poder ver miniaturas reales, alternar selecciones individuales o masivas por categoría, conocer los megabytes que liberaré y confirmar el envío a la papelera en un solo flujo.

---

## 3. Functional Requirements

* **FR-1 (Selector de Período Temporal):** El sistema DEBE permitir al usuario definir la ventana de análisis mediante accesos rápidos (Hoy, Ayer, Últimos 7 días), un día específico en calendario o un rango de fechas personalizado antes de iniciar el escaneo.
* **FR-2 (Aislamiento de Fotos Sin Rostros):** El sistema DEBE excluir de este módulo cualquier fotografía en la que se detecte uno o más rostros humanos.
* **FR-3 (Exclusión Obligatoria de Favoritas):** El sistema DEBE excluir del módulo toda fotografía marcada como "Favorita" en la biblioteca del usuario. Ninguna foto favorita podrá ser mostrada ni seleccionada para eliminación en este flujo.
* **FR-4 (Clasificación de Fotos Utilitarias):** El sistema DEBE clasificar en la categoría "Utilitarias" las fotos sin rostros que contengan texto predominante, bordes de documentos/recibos, comprobantes de pago o características de captura de pantalla.
* **FR-5 (Clasificación de Fotos Deficientes):** El sistema DEBE clasificar en la categoría "Deficientes" las fotos sin rostros que presenten desenfoque severo, pérdida total de foco o subexposición extrema (luminancia casi nula).
* **FR-6 (Clasificación 'Por Validar'):** El sistema DEBE clasificar en la categoría "Por Validar" todas las fotos sin rostros que no califiquen como Utilitarias ni Deficientes (fotos nítidas de paisajes, animales, comida, objetos o arquitectura).
* **FR-7 (Preselección Diferenciada Inicial):** Al cargar los resultados del análisis:
  * El 100% de las fotos en "Utilitarias" y "Deficientes" DEBE aparecer preseleccionado como candidato a descarte.
  * El 100% de las fotos en "Por Validar" DEBE aparecer desmarcado por defecto.
* **FR-8 (Alternancia Individual de Selección):** El usuario DEBE poder marcar o desmarcar cualquier fotografía de forma individual tocando sobre ella en la cuadrícula.
* **FR-9 (Acciones Masivas por Categoría):** Cada categoría DEBE ofrecer controles rápidos para "Seleccionar todas" y "Deseleccionar todas" las fotos pertenecientes a dicha sección.
* **FR-10 (Cálculo Dinámico de Almacenamiento):** El sistema DEBE calcular y actualizar en tiempo real el tamaño acumulado en megabytes (MB) de todas las fotos actualmente seleccionadas para descarte en todas las categorías.
* **FR-11 (Confirmación de Depuración en Lote):** Al pulsar "Purgar seleccionadas", el sistema DEBE invocar el diálogo nativo de confirmación de la papelera del sistema operativo únicamente para los elementos seleccionados.
* **FR-12 (Caché y Restauración Inmediata de Análisis):** Al entrar a la sección de triaje, si los filtros temporales aplicados son idénticos a los del análisis anterior y el estado del carrete fotográfico para dicho período no ha cambiado (mismo conteo y firmas de activos), el sistema DEBE restaurar de forma inmediata el último resultado analizado en memoria, evitando mostrar un nuevo indicador de carga (spinner/loader) y suprimiendo ejecuciones redundantes de visión artificial.
* **FR-13 (Visualización Explícita de Categorías con Conteo Cero):** Toda categoría que no contenga fotos candidatas DEBE mantenerse visible en la interfaz, mostrando explícitamente en su cabecera un conteo de "0 fotos" (o indicador equivalente de conteo nulo) y deshabilitando sus acciones masivas.

---

## 4. Non-Functional Requirements

* **NFR-1 (Privacidad Estricta / 100% On-Device):** El análisis de rostros, detección de texto/documentos y cálculo de exposición y nitidez DEBE ejecutarse íntegramente de manera local sin conexión a redes ni servicios en la nube.
* **NFR-2 (Rendimiento de Procesamiento):** La detección y categorización completa para un lote de hasta 100 fotos del período DEBE completarse en un tiempo menor o igual a 3.0 segundos en dispositivos soportados.
* **NFR-3 (Límite de Consumo de Memoria):** Durante el análisis visual y extracción de características, el incremento en consumo de memoria RAM no DEBE superar los 120 MB sobre el nivel base de la aplicación.
* **NFR-4 (Seguridad y Reversibilidad):** Toda eliminación DEBE canalizarse a la papelera nativa recuperable de la plataforma. Queda prohibida cualquier destrucción permanente inmediata de archivos.
* **NFR-5 (Resiliencia ante Fallos de Imagen):** Si una foto del lote está dañada o no se puede decodificar, el sistema DEBE omitir ese activo individual sin abortar el procesamiento de las restantes fotos.

---

## 5. Edge Cases & Boundary Scenarios

* **EC-1 (Todas las Fotos Tienen Rostros):** Si todas las fotos del período seleccionado contienen personas, la vista debe mostrar un estado vacío informando: "No se encontraron fotos sin personas en este período".
* **EC-2 (Período Sin Fotos):** Si no existen fotos en el rango temporal seleccionado, el sistema debe indicar que el carrete no tiene tomas en esa fecha.
* **EC-3 (Todas las Fotos Sin Rostros Son Favoritas):** Si todas las fotos sin rostros del período son favoritas del usuario, el sistema no mostrará ninguna para descarte e informará que las fotos de esa fecha están protegidas como favoritas.
* **EC-4 (Categorías Vacías con Conteo Explícito Cero):** Si no se detectan fotos en una o dos categorías (por ejemplo, 0 fotos deficientes), dicha categoría DEBE permanecer visible mostrando explícitamente en su cabecera un resumen con conteo "0 fotos", deshabilitando sus botones de selección masiva y manteniendo una presentación predecible sin alterar las demás secciones (`FR-13`).
* **EC-5 (Cancelación en el Diálogo del Sistema):** Si el usuario cancela en el diálogo nativo de la papelera, la selección de fotos y el estado de la vista deben mantenerse idénticos sin aplicar ningún cambio destructivo.
* **EC-6 (Detección Ambigua o Parcial):** Si una foto tiene un sujeto de espaldas o un rostro en miniatura muy lejano no reconocible con confianza, debe clasificarse en "Por Validar" (desmarcada por defecto) para prevenir borrados accidentales de fotos familiares.
* **EC-7 (Reingreso con Filtro y Biblioteca Inalterados):** Si el usuario sale de la vista de depuración y reingresa manteniendo los mismos filtros de fecha y sin cambios en los activos de la biblioteca, no se debe mostrar indicador de carga ni ejecutar re-análisis; se debe cargar inmediatamente el resultado previo en memoria (`FR-12`).

---

## 6. Acceptance Criteria (BDD Format)

### Scenario 1: Clasificación y preselección inicial diferenciada
* **Given** un conjunto de 6 fotos sin rostros tomadas en el día de hoy
* **And** 2 fotos corresponden a comprobantes de pago ("Utilitarias")
* **And** 1 foto es totalmente negra tomada por accidente ("Deficientes")
* **And** 3 fotos son paisajes y una mascota ("Por Validar")
* **When** el sistema completa el análisis de la fecha
* **Then** las 2 fotos utilitarias y la foto deficiente DEBEN estar preseleccionadas para descarte (`FR-4`, `FR-5`, `FR-7`)
* **And** las 3 fotos de paisajes y mascota DEBEN mostrarse en la cuadrícula pero desmarcadas (`FR-6`, `FR-7`)
* **And** el espacio total recuperable DEBE corresponder exclusivamente al tamaño acumulado de las 3 fotos preseleccionadas (`FR-10`).

### Scenario 2: Ocultamiento estricto de fotos favoritas
* **Given** una foto de un documento y una foto de un paisaje en el período seleccionado
* **And** ambas fotos carecen de rostros humanos
* **And** la foto del documento fue marcada como "Favorita" en la biblioteca
* **When** se ejecuta el análisis del período
* **Then** la foto del documento favorita NUNCA DEBE aparecer en ninguna categoría de la vista (`FR-3`, `Assumption 3`)
* **And** solo la foto del paisaje debe listarse en la categoría "Por Validar".

### Scenario 3: Deselección manual de falso positivo en Utilitarias
* **Given** una foto de un póster artístico clasificada automáticamente en "Utilitarias" y preseleccionada para descarte
* **When** el usuario toca la foto para desmarcarla
* **Then** la foto debe quedar deseleccionada (`FR-8`)
* **And** el espacio total a recuperar DEBE reducirse descontando el tamaño de esa foto (`FR-10`).

### Scenario 4: Selección manual activa en categoría 'Por Validar'
* **Given** 2 fotos de paisajes repetidos listadas en "Por Validar" y desmarcadas por defecto
* **When** el usuario toca una de las tomas repetidas para marcarla para eliminación
* **Then** esa foto debe quedar seleccionada para descarte (`FR-8`)
* **And** el espacio total a recuperar DEBE incrementarse sumando el tamaño de esa foto (`FR-10`).

### Scenario 5: Acción rápida de selección masiva por sección
* **Given** una sección "Por Validar" con 5 fotos desmarcadas
* **When** el usuario pulsa "Seleccionar todas" en la cabecera de esa sección
* **Then** las 5 fotos de la sección deben pasar a estado seleccionado (`FR-9`)
* **And** el espacio total recuperable debe actualizarse en tiempo real (`FR-10`).

### Scenario 6: Confirmación de depuración y envío a papelera nativa
* **Given** 4 fotos seleccionadas para descarte en total
* **When** el usuario presiona "Purgar seleccionadas" y confirma en el diálogo nativo del sistema
* **Then** las 4 fotos deben ser enviadas a la papelera nativa del sistema operativo (`FR-11`, `NFR-4`)
* **And** las fotos eliminadas deben desaparecer de la cuadrícula
* **And** si no quedan más fotos en el período, la vista debe mostrar el estado completado (`EC-1`).

### Scenario 7: Cancelación del diálogo nativo por el usuario
* **Given** 3 fotos seleccionadas para descarte
* **When** el usuario pulsa "Purgar seleccionadas" y luego presiona "Cancelar" en el diálogo del sistema
* **Then** ninguna foto debe ser eliminada (`EC-5`, `NFR-4`)
* **And** la cuadrícula debe conservar las 3 fotos seleccionadas sin alteración (`EC-5`).

### Scenario 8: Presentación de categorías vacías con conteo explícito cero
* **Given** un período analizado donde se detectan 4 fotos utilitarias, 2 por validar y 0 fotos deficientes
* **When** se presentan los resultados del análisis en la vista
* **Then** la sección "Deficientes" DEBE mostrarse visible en la interfaz (`FR-13`, `EC-4`)
* **And** la cabecera de la sección "Deficientes" DEBE indicar explícitamente "0 fotos" (`FR-13`)
* **And** los botones o controles de acción de dicha categoría vacía deben permanecer deshabilitados.

### Scenario 9: Restauración inmediata de caché ante filtros y carrete inalterados
* **Given** un análisis completado previamente para el rango temporal seleccionado
* **And** el usuario navega fuera de la pantalla de depuración y regresa manteniendo exactamente los mismos parámetros de filtro
* **And** la biblioteca de fotos no ha recibido nuevas fotos ni eliminaciones en dicho rango
* **When** se inicializa o accede a la vista de depuración
* **Then** el sistema DEBE restaurar de inmediato el último análisis en memoria (`FR-12`, `EC-7`)
* **And** NO DEBE mostrar un spinner ni indicador de carga prolongado
* **And** no se deben re-ejecutar solicitudes redundantes de visión artificial.

---

## 7. Out of Scope

* Eliminación automática en segundo plano sin revisión humana obligatoria.
* Detección o agrupamiento de ráfagas continuas temporales (responsabilidad del módulo `burst-quality-triage`).
* Asignación de fecha de caducidad automática o temporizadores de vida útil (responsabilidad de la futura especificación `Lifecycle / TTL`).
* Modificación o destrucción permanente de fotos que eluda la papelera nativa de iOS.
* Sincronización o interacción con almacenamiento en la nube.
