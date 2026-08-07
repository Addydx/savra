# Prompt para Claude Code — Registro de comidas, constancia y logros

Pégalo tal cual en Claude Code, dentro del repo (`cd` a la raíz de `savra`). Está dividido en 4 fases; puedes pedirle a Claude Code que las haga todas en un solo run o una por una (recomendado: una por una, con build/test entre cada fase).

---

## Contexto para Claude Code

Estás trabajando en **Savra**, una app iOS (SwiftUI + SwiftData, Swift 5, iOS 17+) para registrar comidas y seguir planes alimenticios. Arquitectura Clean Architecture por capas en `Savra/Savra/`: `Domain` (modelos puros, sin imports de SwiftUI/SwiftData/Firebase), `Data` (SwiftData + repos), `Infrastructure` (Firebase, imágenes, notificaciones), `Features` (MVVM: `ViewModels/` + `Views/` por feature), `Core` (DI, extensions, helpers).

Antes de tocar nada, lee:
- `Documentation/04-DOMAIN-MODEL.md`, `05-DATA-MODEL.md`, `06-APPLICATION-ARCHITECTURE.md`
- `Documentation/IMPLEMENTATION_STATUS.md` (está desactualizado — Features/MealLogging, Dashboard, History y MealPlans ya existen y funcionan; actualízalo al final con lo que implementes)
- Código actual: `Savra/Savra/Features/MealLogging/`, `Savra/Savra/Features/Dashboard/`, `Savra/Savra/Domain/Models/DayComplianceStatus.swift`, `Savra/Savra/Domain/Services/DailyComplianceCalculator.swift`

No rompas los tests existentes en `SavraTests`. Después de cada fase corre:
```
xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test
```

---

## FASE 1 — Arreglar el flujo de registro de comidas

Bugs y huecos encontrados en `Features/MealLogging/`:

1. **`MealLoggingFlowView.swift` (paso `addPhoto`)**: el botón inferior siempre dice "Continuar sin foto" y siempre llama a `continueWithoutPhoto()`, incluso cuando el usuario ya seleccionó una foto (`viewModel.photoData != nil`). El label es engañoso. Corrígelo: si hay foto seleccionada, el botón debe decir "Continuar" (o similar) y mantener la foto; si no hay foto, debe decir "Continuar sin foto".

2. **Falta cantidad/porción por alimento**: `MealLogItem` ya tiene `quantity: Double?` y `unit: String?`, pero `FoodSearchView.swift` y `MealLoggingViewModel.saveMealLog()` los guardan siempre como `nil`. Añade en la lista de alimentos seleccionados (en `FoodSearchView` o en `MealLogReviewView`) un control para ingresar cantidad + unidad por alimento (stepper numérico + picker o texto libre de unidad: "g", "ml", "porción", "taza", etc.). Persiste esos valores en `saveMealLog()`.

3. **`eatenAt` no es editable**: en `MealLogReviewView.swift` la fecha/hora se muestra como texto fijo (`detailRow(label: "Fecha"...)`, `detailRow(label: "Hora"...)`). Reemplázalo por un `DatePicker` compacto para que el usuario pueda corregir cuándo comió (útil si registra la comida más tarde).

4. **Rendimiento en `DashboardViewModel.loadToday()`** (`Features/Dashboard/ViewModels/DashboardViewModel.swift`, líneas ~58-78): dentro del loop de 30 días vuelve a llamar `container.mealPlanRepository.fetchActive(for:)` en cada iteración, repitiendo la misma llamada 30 veces sin necesidad. Refactoriza para hacer el fetch de planes una sola vez fuera del loop y reutilizarlo. Esto también es la base de rendimiento para la Fase 2 (que necesita rangos más largos, ej. 1 año).

5. Revisa que el estado `errorMessage` en `MealLoggingViewModel` realmente se muestre en cada paso del flujo, no solo en `MealLogReviewView` (por ejemplo si falla la carga de imagen).

**Criterio de aceptación**: el flujo completo (seleccionar plan → foto opcional → buscar alimentos con cantidad/unidad → revisar con fecha editable → guardar) funciona sin botones con labels incorrectos, sin llamadas redundantes al repo, y compila sin warnings nuevos.

---

## FASE 2 — Calendario de constancia estilo GitHub (contribution graph)

Existe ya `Features/Dashboard/Views/ComplianceCalendarView.swift`, pero es solo una grilla de 4 semanas con círculos de 3 colores (verde/naranja/gris), alimentada por `DayComplianceStatus` (enum de 3 casos: `.neutral`, `.achieved`, `.incomplete`) desde `Domain/Services/DailyComplianceCalculator.swift`.

Objetivo: reemplazarlo por un heatmap real estilo GitHub contributions:

1. **Modelo de intensidad**: el `DayComplianceStatus` binario no alcanza para un heatmap con niveles. Añade un nuevo tipo (ej. `DayComplianceLevel` con 5 niveles: `none, low, medium, high, perfect`, calculado como % de ocurrencias requeridas completadas ese día) o extiende `DailyComplianceCalculator` para devolver ese porcentaje además del status actual (no rompas los usos existentes de `DayComplianceStatus` si otras pantallas dependen de él — puedes hacer que el nuevo cálculo derive del mismo dato).

2. **Vista**: crea (o reescribe) una vista tipo grid de semanas (columnas) × días de la semana (filas, 7 filas), con celdas cuadradas pequeñas y esquinas redondeadas mínimas (no círculos), color según nivel (usa `Color.accentColor` con distintas opacidades, o una escala verde tipo GitHub), separadores/labels de mes arriba de cada bloque de semanas que empieza mes nuevo, y una leyenda "Menos ⬜⬜⬜⬜⬜ Más" al pie. Soporta scroll horizontal para ver hasta 12 meses hacia atrás.

3. **Interacción**: tap en una celda muestra un tooltip/popover con la fecha y detalle (ej. "3/3 comidas completadas").

4. **Datos**: para no repetir el problema de rendimiento de la Fase 1, calcula el rango completo (ej. 365 días) con una sola pasada: trae los planes activos una vez, trae las ocurrencias persistidas del rango completo de una vez (si el repo no soporta fetch por rango, añade ese método a `MealOccurrenceRepository` y su implementación SwiftData), y computa localmente por día.

5. Colócalo en `DashboardView` (o en una pantalla nueva "Progreso"/"Constancia" si el Dashboard se satura) con un selector simple de rango (3 meses / 6 meses / 1 año).

**Criterio de aceptación**: heatmap con niveles de color, meses etiquetados, scroll fluido, sin recomputar todo en cada frame, y sin degradar el tiempo de carga del Dashboard.

---

## FASE 3 — Rachas y logros (feature nueva, no existe nada hoy)

Confirmé que no hay ningún código de streaks/achievements en el proyecto (`Domain`, `Data`, `Features` no tienen nada relacionado). Se construye desde cero, siguiendo la arquitectura por capas existente.

1. **Domain** (`Domain/Models/`):
   - `Achievement.swift`: definición estática de logros (id, título, descripción, ícono SF Symbol, tipo de condición). Tipos sugeridos: racha de registro diario (3, 7, 14, 30, 100 días), racha de adherencia a plan (todos los `MealOccurrence` requeridos completados N días seguidos), "semana perfecta" (7/7 días `achieved` en una semana calendario), hito de volumen total (ej. 50 comidas registradas).
   - `Streak.swift`: value object con `currentStreak: Int`, `longestStreak: Int`, `lastActiveDate: Date?`, por tipo de racha (registro vs. adherencia a plan).
   - `UnlockedAchievement.swift`: relación usuario-logro-fecha de desbloqueo.

2. **Domain/Services**: `StreakCalculator.swift` — servicio puro (sin imports de infraestructura, igual que `DailyComplianceCalculator`) que, dado el historial de días con `DayComplianceStatus`/nivel, calcula racha actual y máxima. Debe reutilizar el cálculo por día que ya hiciste en la Fase 2 para no duplicar lógica.

3. **Domain/RepositoryProtocols** + **Data/RepositoryImplementations**: `AchievementRepository` protocolo + implementación SwiftData para persistir logros desbloqueados. Sigue el mismo patrón que `SwiftDataMealLogRepository.swift`.

4. **Evaluación de logros**: al guardar un registro de comida (`MealLoggingViewModel.saveMealLog()`) o al completar todas las ocurrencias requeridas del día, dispara una evaluación de logros pendientes (nuevo `AchievementEvaluator` en Domain o en un UseCase) y, si se desbloquea alguno nuevo, expón un evento para que la UI muestre una celebración.

5. **UI**:
   - Widget de racha actual en `DashboardView` (ícono de flama 🔥 + número de días, estilo Duolingo/GitHub streak).
   - Pantalla nueva "Logros" (`Features/Achievements/` con `ViewModels/` y `Views/`, siguiendo el patrón de las demás features) con grid de badges (desbloqueados a color, bloqueados en gris con candado y progreso "3/7 días").
   - Toast/modal de celebración al desbloquear un logro nuevo (confetti simple con `SwiftUI` o `SF Symbols` animados, sin dependencias externas).

6. Actualiza `AppContainer` (`Core/DI/`) para inyectar el nuevo repositorio.

**Criterio de aceptación**: registrar comidas varios días seguidos incrementa la racha visible en el Dashboard; romper la racha la reinicia; los logros se desbloquean y persisten entre sesiones (SwiftData); hay tests unitarios de `StreakCalculator` en `SavraTests` (racha continua, racha rota, racha con un solo día, etc.), siguiendo el estilo de `DailyComplianceCalculatorTests.swift`.

---

## FASE 4 — Rediseño visual de los formularios de registro

Con los cambios funcionales de la Fase 1 ya integrados, mejora el diseño de `Features/MealLogging/Views/`:

1. Jerarquía visual más clara por paso (tipografía, espaciado, uso consistente de `Color(.systemGray6)` vs. superficies elevadas — ya usan ese patrón, mantenlo consistente en los controles nuevos de cantidad/unidad y el date picker).
2. Indicador de progreso del flujo (ej. barra de pasos 1/4, 2/4... en la toolbar o debajo del título) ya que ahora son 4 pasos.
3. Estados vacíos e interacciones con feedback (haptics en acciones clave: añadir alimento, guardar, desbloquear logro — usa `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator`).
4. Transiciones suaves entre pasos (`.transition` + `.animation` en el `switch` de `MealLoggingFlowView`).
5. Revisa contraste y tamaños táctiles (mínimo 44x44pt) en los nuevos controles de cantidad/unidad.

**Criterio de aceptación**: el flujo se siente cohesivo, con feedback claro en cada acción, sin regresiones de accesibilidad (Dynamic Type, VoiceOver en los botones nuevos).

---

## Al terminar cada fase

- Corre build + tests (comandos arriba).
- Actualiza `Documentation/IMPLEMENTATION_STATUS.md`: mueve lo completado de "Pending" a "Completed", documenta la fase.
- Si tomas decisiones de arquitectura no triviales (ej. cómo modelar `Achievement`), considera si amerita un ADR nuevo (`ADR-009-...md`) siguiendo el formato de los existentes en `Documentation/`.
