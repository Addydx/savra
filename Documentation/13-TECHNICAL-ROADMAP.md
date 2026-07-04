# 13 — Technical Roadmap

## Phase 0 — Foundation

* **Objetivo**: dejar listo el esqueleto del proyecto y las decisiones arquitectónicas base.
* **Dependencias**: ninguna.
* **Entregables**: estructura de carpetas (06), configuración de Firebase, DI container básico, modelos de dominio (`Domain/Models`) sin persistencia aún.
* **Criterios de aceptación**: el proyecto compila, corre en simulador con una pantalla vacía, y los modelos de dominio tienen tests unitarios básicos.
* **Riesgos**: subestimar el tiempo de configurar correctamente Firebase (reglas de seguridad desde el día 1).

## Phase 1 — Authentication

* **Objetivo**: flujo completo de autenticación funcionando.
* **Dependencias**: Phase 0.
* **Entregables**: Welcome, Create Account, Sign In, Email Verification, Forgot/Reset Password, Session Persistence, Sign Out, Delete Account.
* **Criterios de aceptación**: un usuario puede registrarse, verificar su email, cerrar y volver a abrir la app manteniendo sesión, y eliminar su cuenta.
* **Riesgos**: decisión pendiente sobre bloqueo por email no verificado (ver Decisions Required).

## Phase 2 — Meal Plans

* **Objetivo**: CRUD de `MealPlan` + generación de `MealOccurrence` con recurrencia.
* **Dependencias**: Phase 1 (necesita `userId`).
* **Entregables**: pantallas de creación/edición/pausa/eliminación de planes, `RecurrenceRule`, `GenerateOccurrencesUseCase`.
* **Criterios de aceptación**: crear un plan "Desayuno, todos los días, 8:00" genera correctamente ocurrencias en la ventana de 30 días.
* **Riesgos**: la ambigüedad fecha/hora (04-DOMAIN-MODEL §3) debe estar resuelta como decisión de producto antes de esta fase.

## Phase 3 — Notifications

* **Objetivo**: recordatorios locales funcionando end-to-end.
* **Dependencias**: Phase 2.
* **Entregables**: `NotificationSchedulerProtocol` + implementación, solicitud de permiso contextual, recálculo en edición/pausa/eliminación.
* **Criterios de aceptación**: editar un plan reprograma correctamente sin duplicar notificaciones (test manual + unit test de idempotencia).
* **Riesgos**: comportamiento ante cambio de zona horaria (validar en dispositivo real, no solo simulador).

## Phase 4 — Meal Logging

* **Objetivo**: la acción principal del producto: registrar comidas.
* **Dependencias**: Phase 2 (necesita `MealOccurrence` para vincular, aunque el registro no planeado puede probarse antes).
* **Entregables**: flujo completo de Record Meal, captura/selección de foto, búsqueda de alimentos (`LocalFoodCatalog` inicial), `SaveMealLogUseCase`.
* **Criterios de aceptación**: se puede registrar una comida con y sin foto, planeada y no planeada, y la occurrence vinculada pasa a `completed`.
* **Riesgos**: catálogo local de alimentos insuficiente al inicio — mitigar con `UserCreatedFoodCatalog` desde el día 1 de esta fase.

## Phase 5 — Dashboard

* **Objetivo**: pantalla principal con estado del día y calendario de constancia.
* **Dependencias**: Phase 4 (necesita datos reales de logs/occurrences).
* **Entregables**: Home con saludo, comidas de hoy, progreso, `DailyComplianceCalculator`, calendario visual.
* **Criterios de aceptación**: el calendario refleja correctamente días `achieved`/`incomplete`/`neutral` según la política definida en 04-DOMAIN-MODEL §6.
* **Riesgos**: rendimiento del cálculo de cumplimiento si se muestra un rango largo de semanas (mitigar con cálculo por rango visible, no todo el historial).

## Phase 6 — History

* **Objetivo**: historial paginado de registros pasados.
* **Dependencias**: Phase 4.
* **Entregables**: listado paginado por rango de fechas, sin descarga completa del historial.
* **Criterios de aceptación**: abrir el historial no descarga/carga más que el rango visible + un margen razonable.
* **Riesgos**: ninguno mayor; es la fase de menor riesgo técnico.

## Phase 7 — Offline and Sync

* **Objetivo**: cola de sincronización robusta y resolución de conflictos básica.
* **Dependencias**: todas las fases anteriores (hay algo que sincronizar).
* **Entregables**: `SyncEngine`, `SyncQueueEntry`, estrategia last-write-wins, estados de UI (offline/syncing/error/retry).
* **Criterios de aceptación**: crear/editar/eliminar datos sin conexión y verificar que se sincronizan correctamente al recuperar la red, sin duplicados ni pérdida de datos.
* **Riesgos**: es la fase de mayor riesgo técnico del proyecto completo; conviene empezar con tests de la cola desde el principio de esta fase, no al final.

## Phase 8 — Hardening

* **Objetivo**: seguridad, privacidad, accesibilidad y pulido general antes de una posible primera versión pública.
* **Dependencias**: todas las anteriores.
* **Entregables**: reglas de seguridad de Firestore/Storage revisadas, limpieza de metadata EXIF, revisión de accesibilidad (VoiceOver, Dynamic Type), manejo completo de estados de error.
* **Criterios de aceptación**: auditoría manual de las reglas de seguridad remota confirmando aislamiento total entre usuarios (11-SECURITY-AND-PRIVACY.md).
* **Riesgos**: dejar la seguridad remota para el final es riesgoso — se recomienda escribir las reglas de Firestore desde Phase 0/1 y solo endurecerlas aquí, no crearlas desde cero.
