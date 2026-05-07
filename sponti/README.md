# Sponti

App mobile de planes sociales espontáneos. Los usuarios exploran planes del día en su ciudad, se unen con un grupo mínimo de personas y pagan solo si se alcanza el quorum.

**Stack:** Flutter · Firebase (Firestore, Cloud Functions, Secret Manager) · Stripe · Meta WhatsApp Business API · OpenAI · OpenWeatherMap · PredictHQ

---

## Arquitectura

```
sponti/
├── lib/
│   ├── auth/          # AuthGate + constante kUserId
│   ├── models/        # Plan model (Firestore serialization)
│   ├── screens/       # UI screens
│   ├── services/      # PlanService, PaymentService
│   ├── theme/         # AppTheme
│   └── widgets/       # DarkField, PlanCard, SpontiLogo
└── functions/         # Firebase Cloud Functions (Node.js 20)
```

---

## Firebase Cloud Functions

Proyecto: `sponti-44aa0` · Región: `europe-west1`

| Función | Tipo | Descripción |
|---|---|---|
| `generateDailyPlansScheduled` | Scheduled (07:00 UTC) | Genera planes para 15 ciudades usando OpenAI |
| `generateDailyPlans` | HTTP POST | Trigger manual (requiere `MAKE_SECRET`) |
| `createPlan` | HTTP POST | Crea un plan individual (Make.com) |
| `onPlanQuorumReached` | Firestore trigger | Captura pagos Stripe + envía WhatsApp al confirmar quorum |
| `createPaymentIntent` | HTTP POST | Autoriza pago Stripe (capture_method: manual) |
| `confirmJoinPlan` | HTTP POST | Registra usuario en el plan tras autorizar pago |

### Generación diaria de planes

Cada día a las 07:00 UTC la función:
1. Elimina todos los planes con `createdAt` anterior a la medianoche UTC de hoy
2. Obtiene eventos deportivos globales (TheSportsDB)
3. Para cada una de las 15 ciudades, en paralelo: clima (OpenWeatherMap) + eventos gratuitos (PredictHQ)
4. Genera planes con GPT-4.1-mini y los guarda en la colección `Plans`

Ciudades: Santiago · Buenos Aires · Madrid · Barcelona · Lisboa · Londres · París · Nueva York · Ciudad de México · Tokio · Bangkok · Sídney · Berlín · Roma · Ámsterdam

### Notificaciones WhatsApp

Cuando `joinedCount >= minPeople` en un plan:
1. Se capturan los PaymentIntents autorizados de todos los participantes
2. El plan pasa a `status: "confirmed"`
3. Se envía un mensaje WhatsApp a cada participante vía Meta WhatsApp Business API con nombre del plan, fecha, hora, ubicación y link `https://sponti.app/plan/{planId}`

El número de teléfono se lee de `Users/{userId}.phone` (formato E.164, ej: `+56912345678`).

---

## Secrets requeridos (Firebase Secret Manager)

| Secret | Descripción |
|---|---|
| `OPENAI_API_KEY` | GPT-4.1-mini para generación de planes |
| `OPENWEATHER_API_KEY` | Clima por ciudad |
| `PREDICTHQ_API_KEY` | Eventos gratuitos y culturales |
| `SPORTSDB_API_KEY` | Eventos deportivos (key `3` = free tier, sin eventos del día) |
| `MAKE_SECRET` | Autenticación del endpoint HTTP de Make.com |
| `STRIPE_SECRET_KEY` | Captura de pagos |
| `WHATSAPP_TOKEN` | Bearer token de Meta WhatsApp Business API |
| `WHATSAPP_PHONE_NUMBER_ID` | ID del número de teléfono de negocio en Meta |

---

## Firestore — estructura de colecciones

### `Plans/{planId}`
```
title, description, category, city, location
time: Timestamp
price: number
status: "pending" | "capturing" | "confirmed"
joinedCount: number
minPeople: number
joinedUsers: string[]          // userIds
payments: { [userId]: { paymentIntentId, count, amount } }
captureResults: [...]          // tras confirmar quorum
createdAt: Timestamp
confirmedAt: Timestamp?
```

### `Users/{userId}`
```
name: string
email: string
city: string
phone: string                  // E.164, ej: "+56912345678" — usado para WhatsApp
stripeCustomerId: string?
interests: string[]
```

---

## Setup local

### Requisitos
- Flutter SDK ≥ 3.11.5
- Node.js 20
- Firebase CLI (`npm install -g firebase-tools`)

### Flutter
```bash
flutter pub get
flutter run
```

### Firebase Functions
```bash
cd functions
npm install
firebase deploy --only functions --project sponti-44aa0
```

### Ver logs del scheduled trigger
```bash
firebase functions:log --only generateDailyPlansScheduled --project sponti-44aa0
```

---

## Flujo de usuario

```
OnboardingScreen
  → WelcomeScreen
  → RegisterScreen   (nombre, email, contraseña, ciudad, teléfono WhatsApp)
  → InterestsScreen  (guarda interests + datos en users/{userId})
  → HomeScreen       (lista de planes del día filtrada por ciudad)
       → PlanDetailScreen → unirse (Stripe) → confirmJoinPlan
ProfileScreen        (muestra y permite editar el teléfono WhatsApp)
```

---

## Notas importantes

- **WhatsApp Business API:** Los mensajes iniciados por el negocio fuera de la ventana de 24h requieren plantillas aprobadas en Meta Business Manager. En modo de prueba funciona con números verificados en la cuenta.
- **Node.js 20 deprecado:** Deadline de migración a Node.js 22 — **30 octubre 2026**.
- `kUserId = 'user_test_01'` es el ID hardcodeado mientras no haya Firebase Auth real.
