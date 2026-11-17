# Feature Specification: Rediseño de Home y Selector de Modo (`home-mode-selection`)

## 1. Purpose
Modernizar el punto de entrada de la aplicación mediante un flujo guiado de dos pasos (Paso 1: Selección de Período y Paso 2: Selector de Modo de Depuración). El usuario define primero la ventana temporal sobre la que desea realizar la curación (con opciones rápidas, conteo estimativo no bloqueante y rango personalizado) y随后 elige de forma unívoca el algoritmo de depuración (*Ráfagas* o *Sin Rostro*), iniciando el análisis visual con un solo toque y eliminando fricciones o configuraciones duplicadas.

### Assumptions:
* **Assumption 1 (Flujo Guiado Paso a Paso):** El proceso de apertura de la app sigue una arquitectura de asistente (*Wizard*): la pantalla principal corresponde al *Paso 1* (Selección de Período) y la siguiente al *Paso 2 de 4* (Selector de Modo), antes de pasar a la revisión de triaje (*Paso 3*) y confirmación (*Paso 4*).
* **Assumption 2 (Conteo Asíncrono No Bloqueante):** Para evitar cualquier retardo en la renderización del Home, el cálculo del volumen de fotos (ej. `~142 fotos`) se ejecuta de manera asíncrona sobre metadatos únicamente para la opción que se encuentre actualmente seleccionada, mostrando el valor de inmediato una vez resuelto.
* **Assumption 3 (Selección de Modo Excluyente):** La selección de algoritmo en el Paso 2 es estrictamente unívoca (mutuamente excluyente). El usuario escoge o *Ráfagas* o *Sin Rostro*, pero no ambos en la misma corrida.
* **Assumption 4 (Previsualización Ilustrativa):** Los elementos visuales en las tarjetas de modo (avatares con insignia "TOP", miniaturas de vouchers) son recursos visuales ilustrativos estáticos diseñados para comunicar el propósito de cada algoritmo sin consumir procesamiento previo a pulsar "Iniciar Análisis".
* **Assumption 5 (Persistencia de Filtro al Navegar):** El período seleccionado en la pantalla 1 se transmite de forma directa e inmutable al modo de análisis seleccionado en la pantalla 2.

---

## 2. User Stories

* **US-1 (Selección Temporal Intuitiva):** Como usuario, quiero elegir rápidamente entre períodos predefinidos (Hoy, Últimos 7 días, Este mes) o un rango personalizado en la pantalla de inicio para acotar la limpieza a las fotos que me interesan.
* **US-2 (Feedback de Volumen de Fotos):** Como usuario, quiero ver una estimación del número de fotos comprendidas en el período seleccionado sin que la pantalla tarde en cargar para dimensionar el alcance de la limpieza.
* **US-3 (Selección Clara de Algoritmo de Depuración):** Como usuario, quiero ver opciones claras y diferenciadas entre curar "Ráfagas" y depurar fotos "Sin Rostro" con explicaciones sencillas para saber exactamente qué tipo de fotos procesará el sistema.
* **US-4 (Continuidad Sin Repetición):** Como usuario, quiero que al pulsar "Iniciar Análisis" la aplicación comience a trabajar directamente sobre el período que ya elegí en el paso previo, sin volverme a preguntar fechas.
* **US-5 (Navegación Reversible):** Como usuario, quiero poder regresar del Paso 2 al Paso 1 con el botón "Atrás" para modificar el período seleccionado sin perder mi flujo.

---

## 3. Functional Requirements

### Pantalla 1: Home (Selección de Período)
* **FR-1 (Opciones Predefinidas de Período):** El sistema DEBE ofrecer cuatro opciones mutuamente excluyentes en formato de selector radial:
  * **Hoy:** Fotos de las últimas 24 horas.
  * **Últimos 7 días:** Semana en curso (preseleccionada por defecto).
  * **Este mes:** Mes y año en curso (ej. "Noviembre 2026").
  * **Personalizado:** Selección específica de fecha única o rango de fechas.
* **FR-2 (Indicador de Selección Activa):** La opción seleccionada DEBE destacarse visualmente con un borde de contraste prominente y un indicador radial activo, mientras que las restantes se muestran en estado inactivo.
* **FR-3 (Selector de Fecha Personalizada):** Al seleccionar la opción "Personalizado", el sistema DEBE desplegar un control interactivo que permita al usuario escoger un día puntual o definir fecha de inicio y fecha de fin.
* **FR-4 (Conteo Estimativo Asíncrono):** Para la opción que se encuentre seleccionada, el sistema DEBE consultar en segundo plano el número total de activos fotográficos coincidentes y mostrarlo en el subtítulo (ej. `· ~142 fotos`) sin bloquear la interactividad de la vista.
* **FR-5 (Acceso al Paso Siguiente):** El botón "Siguiente →" DEBE permanecer activo y accesible en la parte inferior, navegando a la pantalla de Selector de Modo con el rango temporal resuelto.

### Pantalla 2: Selector de Modo
* **FR-6 (Identificador de Progreso del Flujo):** La barra superior DEBE exhibir un botón de retroceso ("< Atrás") y la leyenda "Paso 2 de 4".
* **FR-7 (Tarjetas de Selección de Modo):** El sistema DEBE presentar dos tarjetas de modo mutuamente excluyentes:
  * **Modo Ráfagas:** Título "Ráfagas", etiqueta "SMART PICK", icono representativo, texto explicativo y previsualización gráfica de tomas consecutivas destacando la mejor foto ("TOP").
  * **Modo Sin Rostro:** Título "Sin Rostro", etiqueta "3 CATEGORÍAS", icono representativo, texto explicativo y previsualización gráfica de fotos utilitarias y deficientes.
* **FR-8 (Preselección de Modo Recomendado):** Al ingresar al Paso 2, el modo "Ráfagas" DEBE aparecer seleccionado por defecto.
* **FR-9 (Alternancia Excluyente de Modo):** Al tocar cualquiera de las tarjetas de modo, esta DEBE pasar a estado seleccionado (mostrando el checkmark activo y borde destacado) y deseleccionar la otra tarjeta.
* **FR-10 (Lanzamiento Directo de Análisis):** Al pulsar "Iniciar Análisis ⚡", el sistema DEBE iniciar de inmediato el análisis del módulo seleccionado utilizando el período establecido en el Paso 1, navegando a la interfaz de triaje correspondiente sin solicitar fechas nuevamente.

---

## 4. Non-Functional Requirements

* **NFR-1 (Cero Latencia en Carga del Home):** La pantalla de inicio DEBE renderizarse en menos de 100 milisegundos sin esperar operaciones de conteo o accesos de disco pesados.
* **NFR-2 (Resolución de Metadatos Rápida):** La consulta del conteo estimativo de fotos para la opción seleccionada DEBE realizarse mediante consultas indexadas de PhotoKit (`fetchLimit = 0` o conteo de activos) sin decodificar imágenes en memoria.
* **NFR-3 (Conformidad con Sistema de Diseño):** Todos los componentes visuales (botones, tarjetas, bordes tonales, tipografía y badges) DEBEN consumir estrictamente los tokens de `AppColor`, `AppFont`, `AppTheme` y `AppMotion` definidos en `ds.md`.
* **NFR-4 (Accesibilidad y Áreas Táctiles):** Todas las opciones de selección radial y tarjetas de modo DEBEN contar con un área de interacción mínima de 44 × 44 pt y etiquetas semánticas claras para lectores de pantalla.

---

## 5. Edge Cases & Boundary Scenarios

* **EC-1 (Biblioteca Sin Permisos):** Si el usuario aún no ha otorgado acceso a fotos, la vista de inicio debe solicitarlo de forma transparente o mostrar un estado que invite a conceder permisos antes de consultar conteos.
* **EC-2 (Período Personalizado Inválido):** Si en el modo personalizado la fecha de inicio es posterior a la fecha de fin, el sistema debe invertir o ajustar automáticamente las fechas para garantizar un rango coherente.
* **EC-3 (Período con Cero Fotos):** Si el conteo del período seleccionado resulta en 0 fotos, el sistema debe reflejar `· 0 fotos` sin deshabilitar la navegación, permitiendo al usuario decidir si cambiar de fecha o continuar.
* **EC-4 (Retroceso y Conservación de Estado):** Si el usuario navega del Paso 2 al Paso 1 con el botón "Atrás", el período previamente elegido y las fechas personalizadas deben mantenerse intactos.
* **EC-5 (Cambio Rápido de Opción de Fecha):** Si el usuario cambia rápidamente entre opciones de fecha, las consultas asíncronas de conteo anteriores deben cancelarse para evitar mostrar datos desactualizados en la opción activa.

---

## 6. Acceptance Criteria (BDD Format)

### Scenario 1: Carga inicial de Home con opción por defecto y conteo asíncrono
* **Given** que el usuario abre la aplicación Cull
* **When** se presenta la pantalla de inicio (Paso 1)
* **Then** la vista DEBE desplegarse de inmediato sin demoras (`NFR-1`)
* **And** la opción "Últimos 7 días" DEBE estar seleccionada por defecto con su borde e indicador radial activo (`FR-1`, `FR-2`)
* **And** el sistema DEBE consultar en segundo plano el conteo de fotos de los últimos 7 días y exhibir el resultado (ej. `· ~142 fotos`) sin bloquear la interfaz (`FR-4`, `NFR-2`).

### Scenario 2: Selección de opción personalizada y despliegue de controles
* **Given** el usuario se encuentra en el Paso 1
* **When** pulsa sobre la opción "Personalizado"
* **Then** la opción "Personalizado" pasa a estado activo
* **And** la opción previa se desmarca
* **And** se despliega el control interactivo de fecha/rango (`FR-3`)
* **And** al ajustar las fechas, el conteo se actualiza para el rango especificado.

### Scenario 3: Navegación al Paso 2 (Selector de Modo)
* **Given** que el usuario ha seleccionado un período ("Hoy")
* **When** pulsa el botón "Siguiente →"
* **Then** la aplicación navega a la pantalla "Selector de Modo" (`FR-5`)
* **And** la cabecera muestra "< Atrás" y la leyenda "Paso 2 de 4" (`FR-6`)
* **And** la tarjeta "Ráfagas" aparece seleccionada por defecto (`FR-8`).

### Scenario 4: Alternancia de modo a 'Sin Rostro'
* **Given** el usuario está en el Paso 2 con "Ráfagas" seleccionada
* **When** pulsa sobre la tarjeta "Sin Rostro"
* **Then** la tarjeta "Sin Rostro" adquiere el checkmark y borde de selección (`FR-9`)
* **And** la tarjeta "Ráfagas" pierde el checkmark y su borde destacado (`Assumption 3`).

### Scenario 5: Inicio directo del análisis con el período heredado
* **Given** que el usuario seleccionó el período "Últimos 7 días" en el Paso 1
* **And** seleccionó el modo "Sin Rostro" en el Paso 2
* **When** pulsa el botón "Iniciar Análisis ⚡"
* **Then** el sistema inicia directamente el escaneo del módulo de depuración sin rostros para la ventana de los últimos 7 días (`FR-10`)
* **And** NO vuelve a presentar selectores de fechas intermedios (`US-4`).

### Scenario 6: Navegación de regreso al Paso 1
* **Given** el usuario se encuentra en el Paso 2
* **When** pulsa "< Atrás"
* **Then** regresa a la pantalla de selección de período (Paso 1)
* **And** el período y las opciones seleccionadas previamente se conservan sin reiniciarse (`EC-4`).

---

## 7. Out of Scope

* Selección de álbumes o carpetas específicas del sistema (delimitado a selección temporal según indicación explícita del usuario).
* Ejecución simultánea o combinada de ambos algoritmos en un solo lote.
* Pre-análisis o cálculo de rostros/ráfagas previo a pulsar el botón "Iniciar Análisis".
* Modificación de la pantalla de bienvenida o onboarding inicial de la plataforma.
