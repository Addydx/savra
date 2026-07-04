# 03 — User Flows

## Autenticación

```mermaid
flowchart TD
    Start([Abrir app]) --> HasSession{¿Sesión válida guardada?}
    HasSession -- Sí --> Home[Home]
    HasSession -- No --> Welcome[Welcome]
    Welcome --> SignIn[Sign In]
    Welcome --> CreateAccount[Create Account]
    CreateAccount --> Verify[Email Verification]
    Verify -- verificado --> Home
    Verify -- no verificado --> Reminder[Recordatorio de verificar / reenviar correo]
    SignIn -- credenciales válidas --> Home
    SignIn --> Forgot[Forgot Password]
    Forgot --> Reset[Reset Password]
    Reset --> SignIn
    Home --> SignOut[Sign Out]
    SignOut --> Welcome
    Home --> DeleteAccount[Delete Account]
    DeleteAccount --> Welcome
```

## Creación de plan de alimentación

```mermaid
flowchart TD
    A[Plans tab] --> B[+ Nuevo plan]
    B --> C[Nombre + emoji opcional]
    C --> D{¿Definir fecha?}
    D -- No --> E{¿Definir hora?}
    D -- Sí --> F[Seleccionar fecha]
    F --> G[Mostrar opción de repetición]
    G --> H{Tipo de repetición}
    H --> H1[Una sola vez]
    H --> H2[Todos los días]
    H --> H3[Días específicos]
    H1 --> E
    H2 --> E
    H3 --> E
    E -- Sí --> I[Seleccionar hora]
    I --> J{¿Activar notificación?}
    J -- Sí --> K[Solicitar permiso si es la primera vez]
    J -- No --> L[Guardar plan]
    K --> L
    E -- No --> L
    L --> M[Generar MealOccurrence futuras según recurrencia]
```

## Recurrencia (generación de ocurrencias)

```mermaid
flowchart LR
    Plan[MealPlan activo] --> Rule{recurrenceRule}
    Rule -- once --> O1[1 MealOccurrence]
    Rule -- daily --> O2[MealOccurrence por cada día en ventana de generación]
    Rule -- specificDays --> O3[MealOccurrence solo en días seleccionados dentro de la ventana]
    O1 --> Store[(Persistir occurrences)]
    O2 --> Store
    O3 --> Store
```

## Recordatorio (ciclo de vida de una notificación)

```mermaid
flowchart TD
    A[MealOccurrence creada/actualizada] --> B{¿notificationsEnabled y hora definida?}
    B -- No --> C[No programar notificación]
    B -- Sí --> D[Calcular fecha/hora local con TimeZone actual]
    D --> E[Cancelar notificación previa con mismo identificador si existía]
    E --> F[Programar nueva notificación local]
    F --> G{¿Usuario edita/pausa/elimina el plan?}
    G -- Sí --> H[Recalcular: cancelar + reprogramar u omitir]
    H --> D
    G -- No --> I[Notificación dispara en su momento]
```

## Registro de comida (Record Meal)

```mermaid
flowchart TD
    A[Record Meal] --> B{¿Vincular a comida planeada?}
    B -- Sí --> C[Seleccionar MealOccurrence pendiente de hoy]
    B -- No --> D[Comida no planeada]
    C --> E{¿Añadir foto?}
    D --> E
    E -- Tomar foto --> F[Cámara]
    E -- Elegir foto --> G[Galería]
    E -- Sin foto --> H[Continuar]
    F --> I[Buscar alimentos]
    G --> I
    H --> I
    I --> J[Añadir uno o varios FoodItem]
    J --> K[Revisar registro]
    K --> L[Guardar MealLog]
    L --> M{¿Vinculado a MealOccurrence?}
    M -- Sí --> N[Marcar MealOccurrence como completed]
    M -- No --> O[No afecta ocurrencias]
    N --> P[Recalcular cumplimiento del día]
    O --> P
```

## Cumplimiento diario

```mermaid
flowchart TD
    A[Abrir Dashboard / Calendario] --> B[Obtener MealOccurrence del día]
    B --> C{¿Existen ocurrencias planeadas?}
    C -- No --> D[Día neutro: sin emoji de cumplimiento]
    C -- Sí --> E{¿Todas las obligatorias en estado completed?}
    E -- Sí --> F[Día cumplido: mostrar emoji]
    E -- No --> G[Día no cumplido / en progreso: mostrar marcador vacío o parcial]
```

## Historial

```mermaid
flowchart TD
    A[History tab] --> B[Cargar MealLog del rango de fechas visible]
    B --> C{¿Usuario hace scroll / cambia de mes?}
    C -- Sí --> D[Cargar siguiente rango bajo demanda]
    C -- No --> E[Mostrar lista actual]
    D --> E
```
