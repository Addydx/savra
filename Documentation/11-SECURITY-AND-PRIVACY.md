# 11 — Security and Privacy

## Aislamiento de usuarios

* Todas las colecciones remotas se estructuran bajo `users/{uid}/...`, y las reglas de seguridad de Firestore/Storage restringen lectura/escritura a `request.auth.uid == uid`.
* Localmente, todas las queries de SwiftData filtran explícitamente por `userId` del usuario autenticado actual — no se confía únicamente en las reglas remotas.
* `FoodItem` con `source == userCreated` incluye `ownerUserId` y se filtra en las búsquedas para que un usuario nunca vea alimentos personalizados de otro.

## Sesiones

* El SDK de Firebase Auth gestiona el ciclo de vida del token (refresh automático). La app no debe implementar su propio almacenamiento de tokens.
* Al cerrar sesión, se limpia el `AppSessionStore` en memoria y se cancelan listeners activos de Firestore para evitar fugas de datos entre sesiones (ej. si un segundo usuario inicia sesión en el mismo dispositivo).

## Secretos

* Ninguna clave de API sensible se almacena hardcodeada en el binario más allá de las claves públicas de configuración de Firebase (`GoogleService-Info.plist`), que están diseñadas para ser públicas y protegidas por las reglas de seguridad del backend, no por ocultamiento.

## Fotografías

* Las fotos se asocian siempre a un `userId` y se almacenan bajo una ruta con prefijo `users/{uid}/...` en Storage, con reglas de seguridad equivalentes a las de Firestore.

## Datos personales

* Los únicos datos personales identificables recolectados son: nombre, email, y fotos de comida (que podrían indirectamente revelar hábitos/ubicación si se analiza metadata EXIF). Se recomienda **eliminar metadata EXIF de ubicación** al comprimir la imagen (ver 10-IMAGE-ARCHITECTURE.md), como medida de privacidad simple y de bajo coste.

## Permisos solicitados

```text
Notificaciones          -- solicitado en el momento de activar el primer recordatorio (no al abrir la app)
Cámara                   -- solicitado en el momento de tocar "Tomar foto"
Galería (Photos)         -- solicitado en el momento de tocar "Elegir foto" (usar PHPickerViewController, que no requiere permiso completo de galería en iOS moderno)
```

## Eliminación de datos (Delete Account)

Ver también 07-AUTHENTICATION-ARCHITECTURE.md. Al eliminar la cuenta:

1. Se eliminan localmente todos los datos del usuario (SwiftData).
2. Se encola/ejecuta el borrado remoto en cascada de `MealPlan`, `MealOccurrence`, `MealLog`, `MealPhoto`, `FoodItem` (userCreated) y archivos en Storage.
3. Se elimina el usuario de Firebase Auth como último paso (para que, si algo falla antes, el usuario pueda reintentar la eliminación en vez de quedar en un estado inconsistente sin poder volver a autenticarse).
