# ADR-002 — Authentication Provider

## Context

Se necesita registro, verificación de email, login, recuperación de contraseña, persistencia de sesión, logout y eliminación de cuenta, sin construir un backend de autenticación propio.

## Decision

Firebase Authentication (email/password provider).

## Alternatives Considered

Ver comparación completa en 07-AUTHENTICATION-ARCHITECTURE.md: Firebase, Supabase, AWS Amplify/Cognito, backend propio, Sign in with Apple en solitario. Firebase se elige por su integración nativa con Firestore/Storage (mismo ecosistema para DB e imágenes) y por ofrecer los flujos completos de fábrica.

## Consequences

* Menor tiempo de desarrollo inicial.
* Acoplamiento a Firebase para Auth, DB y Storage simultáneamente (mitigado por el patrón Repository que aísla el dominio de esta decisión).

## Risks

* Lock-in de plataforma; migración futura requeriría reescribir la capa `Infrastructure/Authentication` y `Data/Remote`, pero no debería afectar a `Domain` ni a `Features` si el aislamiento se respeta.
* Decisión pendiente de producto: si un usuario no verificado tiene acceso bloqueado o solo una advertencia (ver Decisions Required Before Coding en el índice general).

## Status

Proposed
