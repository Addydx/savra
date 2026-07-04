# 12 — Testing Strategy

## Prioridad de pruebas (de mayor a menor valor/riesgo)

### 1. Reglas de recurrencia (`RecurrenceRule` → generación de `MealOccurrence`)

Es lógica pura, fácil de testear exhaustivamente y con alto riesgo de bugs sutiles (días específicos, ventana de generación, límites de mes/año). Tests unitarios puros sobre `GenerateOccurrencesUseCase`, sin mocks de red ni base de datos (usar un repositorio en memoria).

### 2. Política de cumplimiento diario (`DailyComplianceCalculator`)

Servicio de dominio puro. Casos clave a cubrir:

```text
- día sin occurrences → neutral
- día con occurrences, todas completed → achieved
- día con occurrences, alguna scheduled/skipped/missed → incomplete
- occurrence con isRequired = false no bloquea achieved
- MealLog no planeado no afecta el cálculo
```

### 3. Transiciones de estado de `MealOccurrence`

Verificar que las transiciones inválidas (ej. `completed → scheduled` directo) no sean posibles desde el dominio, y que `SaveMealLogUseCase` transicione correctamente `scheduled/missed → completed`.

### 4. Sincronización

* Tests de la cola de sync: encolar, procesar en orden, backoff en fallos, resolución de conflictos last-write-wins.
* Se recomienda un `FakeRemoteDataSource` para simular latencia, fallos de red y conflictos de forma determinista, sin depender de Firebase real en tests unitarios.

### 5. Repositorios

* Tests de integración (con SwiftData en memoria) para verificar que las queries devuelven los datos correctos filtrados por usuario y por rango de fechas (aislamiento, ver 11).

### 6. Autenticación

* Tests de la capa `Infrastructure/Authentication` usando el emulador de Firebase Auth (o mocks del SDK) para verificar los flujos de registro/verificación/reset sin depender de servicios reales en CI.

### 7. Flujo crítico de registrar comida (end-to-end / UI test)

Al menos un test de UI (XCTest UI o similar) que cubra el camino feliz completo: seleccionar comida planeada → continuar sin foto → añadir un alimento → guardar → verificar que el dashboard refleja el cambio. Este es el flujo más importante del producto (la acción principal), por lo que merece cobertura end-to-end aunque el resto de la suite sea mayormente unitaria.

## Qué NO se prioriza en el MVP

* Cobertura exhaustiva de UI snapshot testing para cada pantalla (se puede introducir más adelante si el equipo crece).
* Tests de carga/performance (no hay volumen de datos que lo justifique todavía).
