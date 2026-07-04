# 01 — MVP Scope

## Criterio de clasificación

Algo entra en el MVP únicamente si es indispensable para completar el ciclo `Planificar → Recordar → Registrar → Cumplir → Visualizar` con una sola persona usando la app de forma individual, offline-first, sin backend propio complejo.

## MVP

```text
Autenticación (email/password + verificación + recuperación)
Crear / editar / pausar / eliminar MealPlan
Recurrencia simple (una vez / diario / días específicos)
Notificaciones locales opcionales
Dashboard con comidas del día y progreso
Calendario de constancia (basado en cálculo, no en dato guardado)
Registrar MealLog (planeado o no planeado)
Fotografía opcional en el registro
Búsqueda de alimentos (catálogo local mínimo + alimentos creados por el usuario)
Historial simple de comidas registradas
Aislamiento de datos por usuario
Funcionamiento offline con sincronización posterior
```

## Post-MVP (siguiente after el lanzamiento inicial, pero ya planeado conceptualmente)

```text
Edición avanzada de recurrencia (excepciones puntuales a una regla recurrente)
Estadísticas de constancia (rachas, porcentajes semanales/mensuales)
Múltiples fotos por registro
Catálogo remoto de alimentos (API externa)
Exportación de datos (CSV / JSON)
Widgets de iOS (Home Screen / Lock Screen)
```

## Future (visión a largo plazo, no diseñar todavía en detalle)

```text
Análisis de imágenes con IA (MealImageAnalysisService real)
Apple Watch
Recomendaciones no médicas basadas en patrones propios del usuario
Gamificación ligera (rachas visuales, no puntos/niveles complejos)
Sincronización familiar / compartir plan con otra persona (no red social pública)
```

## Out of Scope (explícitamente descartado por ahora, no se diseña ni se deja gancho)

```text
Conteo completo de calorías y macronutrientes
Recomendaciones médicas o nutricionales personalizadas
Red social pública (seguir usuarios, feed, likes)
Planes creados por nutricionistas certificados dentro de la app
Reconocimiento automático de alimentos sin supervisión del usuario
Gamificación compleja (niveles, monedas, logros)
Estadísticas avanzadas tipo BI
```

> Nota: "Out of Scope" no significa "prohibido para siempre", significa que no se diseña arquitectura para ello ahora. Si en el futuro se decide incluirlo, requerirá su propio análisis.
