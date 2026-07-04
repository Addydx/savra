# 02 — Functional Requirements

Convención de IDs: `FR-<AREA>-<NNN>`. Cada requisito indica su prioridad (`MVP` / `Post-MVP`).

## Autenticación (AUTH)

| ID | Requisito | Prioridad |
|---|---|---|
| FR-AUTH-001 | El usuario puede crear una cuenta con email y contraseña. | MVP |
| FR-AUTH-002 | El sistema envía un correo de verificación tras el registro. | MVP |
| FR-AUTH-003 | El usuario no puede usar funciones core sin verificar su email (regla a confirmar, ver ADR-002). | MVP |
| FR-AUTH-004 | El usuario puede iniciar sesión con email y contraseña. | MVP |
| FR-AUTH-005 | El usuario puede solicitar recuperación de contraseña. | MVP |
| FR-AUTH-006 | El usuario puede restablecer su contraseña mediante un enlace/código. | MVP |
| FR-AUTH-007 | La sesión persiste entre lanzamientos de la app hasta que el usuario cierre sesión explícitamente o el token expire. | MVP |
| FR-AUTH-008 | El usuario puede cerrar sesión. | MVP |
| FR-AUTH-009 | El usuario puede eliminar su cuenta y solicitar el borrado de sus datos. | MVP |

## Planes de comida (MEALPLAN)

| ID | Requisito | Prioridad |
|---|---|---|
| FR-MEALPLAN-001 | El usuario puede crear un `MealPlan` con nombre, emoji opcional, fecha opcional, hora opcional. | MVP |
| FR-MEALPLAN-002 | El usuario puede definir una recurrencia: una vez, todos los días, o días específicos de la semana. | MVP |
| FR-MEALPLAN-003 | El usuario puede activar notificaciones para un `MealPlan` que tenga hora definida. | MVP |
| FR-MEALPLAN-004 | El usuario puede pausar un `MealPlan` sin eliminarlo (deja de generar `MealOccurrence` y notificaciones futuras). | MVP |
| FR-MEALPLAN-005 | El usuario puede editar un `MealPlan`; los cambios solo afectan ocurrencias futuras, nunca las ya completadas. | MVP |
| FR-MEALPLAN-006 | El usuario puede eliminar un `MealPlan`; se cancelan notificaciones futuras y ocurrencias `scheduled` no completadas. | MVP |

## Registro de comidas (MEALLOG)

| ID | Requisito | Prioridad |
|---|---|---|
| FR-MEALLOG-001 | El usuario puede registrar una comida vinculada a una `MealOccurrence` planeada. | MVP |
| FR-MEALLOG-002 | El usuario puede registrar una comida no planeada (sin `MealOccurrence`). | MVP |
| FR-MEALLOG-003 | El usuario puede añadir una fotografía opcional (cámara o galería) o continuar sin foto. | MVP |
| FR-MEALLOG-004 | El usuario puede buscar y añadir uno o varios alimentos/ingredientes al registro. | MVP |
| FR-MEALLOG-005 | El usuario puede crear un alimento personalizado si no lo encuentra en el catálogo. | MVP |
| FR-MEALLOG-006 | El usuario puede revisar el registro antes de guardarlo. | MVP |
| FR-MEALLOG-007 | Al guardar un `MealLog` vinculado, la `MealOccurrence` correspondiente se marca como `completed`. | MVP |

## Dashboard (DASHBOARD)

| ID | Requisito | Prioridad |
|---|---|---|
| FR-DASHBOARD-001 | El Home muestra un saludo, la fecha actual y las comidas planeadas para hoy con su estado. | MVP |
| FR-DASHBOARD-002 | El Home muestra el progreso del día (ej. "2 de 3 completadas"). | MVP |
| FR-DASHBOARD-003 | El Home expone la acción "Record Meal" de forma prominente. | MVP |
| FR-DASHBOARD-004 | El Home muestra el calendario de constancia (últimas semanas) con emoji calculado por día. | MVP |

## Recordatorios (NOTIF)

| ID | Requisito | Prioridad |
|---|---|---|
| FR-NOTIF-001 | El sistema solicita permiso de notificaciones en el momento en que el usuario activa el primer recordatorio (no al abrir la app por primera vez). | MVP |
| FR-NOTIF-002 | El sistema programa notificaciones locales para cada `MealOccurrence` futura con hora y notificación activada. | MVP |
| FR-NOTIF-003 | El sistema recalcula/reprograma notificaciones cuando se edita, pausa o elimina un `MealPlan`. | MVP |
| FR-NOTIF-004 | El sistema evita notificaciones duplicadas ante recálculos repetidos. | MVP |

## Historial (HISTORY)

| ID | Requisito | Prioridad |
|---|---|---|
| FR-HISTORY-001 | El usuario puede ver un listado paginado/cargado por rango de fechas de sus `MealLog` pasados. | MVP |
| FR-HISTORY-002 | El historial no requiere descargar todos los registros del usuario en cada apertura. | MVP |

## Cumplimiento (COMPLIANCE)

| ID | Requisito | Prioridad |
|---|---|---|
| FR-COMPLIANCE-001 | El sistema calcula si un día fue "cumplido" en función del estado de las `MealOccurrence` de ese día, sin persistir el resultado como fuente de verdad. | MVP |
| FR-COMPLIANCE-002 | Un día sin comidas planeadas no se marca como cumplido ni incumplido (estado neutro). | MVP |

> Todos los requisitos aquí listados corresponden al MVP; no se listan requisitos de Post-MVP/Future en detalle porque aún no están diseñados a este nivel (ver 01-MVP-SCOPE.md).
