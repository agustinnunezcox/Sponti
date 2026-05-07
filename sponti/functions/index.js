const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// Strip BOM (U+FEFF) that PowerShell adds when piping secrets, and any surrounding whitespace
const cleanEnv = (key) => { let v = (process.env[key] || "").trim(); return v.charCodeAt(0) === 0xFEFF ? v.slice(1) : v; };

// fetch con timeout — evita que llamadas colgadas bloqueen toda la ejecución
async function fetchWithTimeout(url, options = {}, timeoutMs = 60_000) {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(id);
  }
}

const MAKE_SECRET = cleanEnv("MAKE_SECRET");

const getStripe = () => require("stripe")(cleanEnv("STRIPE_SECRET_KEY"));

// ─── Cities ───────────────────────────────────────────────────────────────────

const CITIES = [
  { name: "Santiago",          country: "CL", lat: -33.45, lon: -70.67, sportsdbCountry: "Chile" },
  { name: "Buenos Aires",      country: "AR", lat: -34.60, lon: -58.38, sportsdbCountry: "Argentina" },
  { name: "Madrid",            country: "ES", lat:  40.42, lon:  -3.70, sportsdbCountry: "Spain" },
  { name: "Barcelona",         country: "ES", lat:  41.39, lon:   2.15, sportsdbCountry: "Spain" },
  { name: "Lisboa",            country: "PT", lat:  38.72, lon:  -9.14, sportsdbCountry: "Portugal" },
  { name: "Londres",           country: "GB", lat:  51.51, lon:  -0.13, sportsdbCountry: "England" },
  { name: "París",             country: "FR", lat:  48.85, lon:   2.35, sportsdbCountry: "France" },
  { name: "Nueva York",        country: "US", lat:  40.71, lon: -74.01, sportsdbCountry: "United States" },
  { name: "Ciudad de México",  country: "MX", lat:  19.43, lon: -99.13, sportsdbCountry: "Mexico" },
  { name: "Tokio",             country: "JP", lat:  35.68, lon: 139.69, sportsdbCountry: "Japan" },
  { name: "Bangkok",           country: "TH", lat:  13.76, lon: 100.50, sportsdbCountry: "Thailand" },
  { name: "Sídney",            country: "AU", lat: -33.87, lon: 151.21, sportsdbCountry: "Australia" },
  { name: "Berlín",            country: "DE", lat:  52.52, lon:  13.41, sportsdbCountry: "Germany" },
  { name: "Roma",              country: "IT", lat:  41.90, lon:  12.50, sportsdbCountry: "Italy" },
  { name: "Ámsterdam",         country: "NL", lat:  52.37, lon:   4.90, sportsdbCountry: "Netherlands" },
];

// ─── API helpers ──────────────────────────────────────────────────────────────

async function getWeather(city, date) {
  const key = cleanEnv("OPENWEATHER_API_KEY");
  if (!key) return { description: "despejado", temp: 20, isOutdoor: true, icon: "Clear" };

  const todayStr = new Date().toISOString().split("T")[0];
  const badWeatherIcons = ["Rain", "Drizzle", "Thunderstorm", "Snow"];

  if (date === todayStr) {
    // Current weather for today
    const url = `https://api.openweathermap.org/data/2.5/weather?lat=${city.lat}&lon=${city.lon}&appid=${key}&units=metric`;
    const res = await fetchWithTimeout(url, {}, 15_000);
    if (!res.ok) throw new Error(`OpenWeatherMap ${res.status}`);
    const d = await res.json();
    const icon = d.weather[0].main;
    return {
      description: d.weather[0].description,
      temp: Math.round(d.main.temp),
      isOutdoor: !badWeatherIcons.includes(icon),
      icon,
    };
  }

  // 5-day forecast for future dates (3h intervals)
  const url = `https://api.openweathermap.org/data/2.5/forecast?lat=${city.lat}&lon=${city.lon}&appid=${key}&units=metric`;
  const res = await fetchWithTimeout(url, {}, 15_000);
  if (!res.ok) throw new Error(`OpenWeatherMap forecast ${res.status}`);
  const d = await res.json();

  // Pick the midday entry for the target date, or the first available entry
  const entry = d.list.find(e => e.dt_txt.startsWith(date + " 12:"))
    || d.list.find(e => e.dt_txt.startsWith(date));

  if (!entry) return { description: "despejado", temp: 20, isOutdoor: true, icon: "Clear" };

  const icon = entry.weather[0].main;
  return {
    description: entry.weather[0].description,
    temp: Math.round(entry.main.temp),
    isOutdoor: !badWeatherIcons.includes(icon),
    icon,
  };
}

async function getSportsEventsGlobal(date) {
  const key = cleanEnv("SPORTSDB_API_KEY");
  // eventsday.php requires a paid TheSportsDB key — skip if not configured
  if (!key || key === "3" || key === "not_set") return [];
  const url = `https://www.thesportsdb.com/api/v1/json/${key}/eventsday.php?d=${date}`;
  const res = await fetchWithTimeout(url, {}, 15_000);
  if (!res.ok) throw new Error(`TheSportsDB ${res.status}`);
  const d = await res.json();
  return d.events || [];
}

async function getFreeEvents(city, date) {
  const key = cleanEnv("PREDICTHQ_API_KEY");
  if (!key || key === "not_set") return [];

  const params = new URLSearchParams({
    "start.gte": `${date}T00:00:00`,
    "start.lte": `${date}T23:59:59`,
    "within": `50km@${city.lat},${city.lon}`,
    "category": "festivals,community,performing-arts,expos",
    "limit": "5",
  });

  const res = await fetchWithTimeout(`https://api.predicthq.com/v1/events/?${params}`, {
    headers: { Authorization: `Bearer ${key}` },
  }, 15_000);
  if (!res.ok) throw new Error(`PredictHQ ${res.status}`);
  const d = await res.json();
  return d.results || [];
}

async function generatePlansWithGPT(city, weather, sportsEvents, freeEvents, date) {
  const key = cleanEnv("OPENAI_API_KEY");
  if (!key) throw new Error("OPENAI_API_KEY not set");

  const citySports = sportsEvents
    .filter(e =>
      e.strCity?.toLowerCase().includes(city.name.toLowerCase()) ||
      e.strCountry === city.sportsdbCountry
    )
    .slice(0, 4);

  const prompt = `
Ciudad: ${city.name}. Fecha: ${date}.
Clima: ${weather.description}, ${weather.temp}°C. ¿Outdoor recomendado? ${weather.isOutdoor ? "SÍ" : "NO — llueve o mal tiempo, propón planes de interior"}.

PARTIDOS DEPORTIVOS EN ${city.name.toUpperCase()} HOY:
${citySports.length
    ? citySports.map(e => `- ${e.strEvent} (${e.strTime || "hora por confirmar"}, ${e.strLeague})`).join("\n")
    : "Ninguno"}

EVENTOS GRATUITOS Y CULTURALES:
${freeEvents.length
    ? freeEvents.map(e => `- ${e.title} (${e.start})`).join("\n")
    : "Ninguno"}

Genera un array JSON con los siguientes planes (incluye TODOS los que apliquen):

TIPO 1 — Por cada partido deportivo: 1 plan para ver el partido juntos en un bar.
TIPO 2 — 2 o 3 actividades espontáneas creativas acordes al clima:
  - Si hace buen tiempo → outdoor: subir un cerro, picnic, bici, kayak, running, asado, partido en la cancha del barrio, surf, senderismo, rollers, etc.
  - Si llueve o mal tiempo → indoor: escape room, museo, bowling, café de juegos de mesa, karaoke, cine en casa colectivo, taller de cocina, etc.
TIPO 3 — Por cada evento gratuito: 1 plan para asistir juntos.

Cada plan debe tener EXACTAMENTE estos campos:
{
  "title": "texto corto y atractivo (máx 50 caracteres)",
  "description": "1-2 frases naturales explicando el plan y dónde quedar",
  "category": "football | sports | outdoor | food | culture | music | drinks",
  "city": "${city.name}",
  "location": "punto de encuentro genérico y concreto (ej: 'Entrada del Parque Central', 'Metro Sol', 'Plaza Mayor', 'Puerto deportivo')",
  "time": "ISO 8601 con fecha ${date} y hora local razonable para el plan (ej: ${date}T17:00:00Z)",
  "price": 0,
  "status": "pending",
  "joinedCount": 0,
  "minPeople": 3,
  "joinedUsers": []
}

Responde ÚNICAMENTE con el array JSON. Sin texto, sin markdown, sin comentarios.`;

  const res = await fetchWithTimeout("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4.1-mini",
      messages: [
        {
          role: "system",
          content: "Eres un asistente que genera planes sociales creativos para una app. Respondes SIEMPRE con JSON válido y nada más.",
        },
        { role: "user", content: prompt },
      ],
      max_tokens: 2500,
      temperature: 0.85,
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`OpenAI ${res.status}: ${err}`);
  }

  const d = await res.json();
  const raw = d.choices[0].message.content
    .trim()
    .replace(/^```json\n?/, "")
    .replace(/^```\n?/, "")
    .replace(/```$/, "")
    .trim();

  return JSON.parse(raw);
}

// ─── WhatsApp ─────────────────────────────────────────────────────────────────

async function sendWhatsAppMessage(toPhone, plan, planId) {
  const token         = cleanEnv("WHATSAPP_TOKEN");
  const phoneNumberId = cleanEnv("WHATSAPP_PHONE_NUMBER_ID");

  // Normalise to E.164 digits only (WhatsApp rejects spaces, dashes, +)
  const phone = toPhone.replace(/[^\d]/g, "");

  const eventDate = plan.time instanceof Object && plan.time.toDate
    ? plan.time.toDate()
    : new Date(plan.time);

  const dateStr = eventDate.toLocaleDateString("es-ES", {
    weekday: "long", day: "numeric", month: "long", timeZone: "UTC",
  });
  const timeStr = eventDate.toLocaleTimeString("es-ES", {
    hour: "2-digit", minute: "2-digit", timeZone: "UTC",
  });

  const body =
    `🎉 ¡Tu plan *${plan.title}* está confirmado!\n\n` +
    `📅 ${dateStr} a las ${timeStr}\n` +
    `📍 ${plan.location}\n\n` +
    `Ya sois ${plan.joinedCount} personas confirmadas. Únete aquí:\n` +
    `👉 https://sponti.app/plan/${planId}`;

  const res = await fetchWithTimeout(
    `https://graph.facebook.com/v19.0/${phoneNumberId}/messages`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to: phone,
        type: "text",
        text: { preview_url: false, body },
      }),
    },
    15_000
  );

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`WhatsApp ${res.status}: ${err}`);
  }
  return await res.json();
}

async function savePlan(plan) {
  const doc = {
    ...plan,
    time: Timestamp.fromDate(new Date(plan.time)),
    createdAt: Timestamp.now(),
  };
  const ref = await db.collection("Plans").add(doc);
  return ref.id;
}

// ─── Core: generate plans for all cities ─────────────────────────────────────

// Delete plans whose event time is in the past (time < start of today)
async function deletePastPlans() {
  const startOfToday = new Date();
  startOfToday.setUTCHours(0, 0, 0, 0);

  const snapshot = await db.collection("Plans")
    .where("time", "<", Timestamp.fromDate(startOfToday))
    .get();

  if (snapshot.empty) {
    console.log("No past plans to delete");
    return 0;
  }

  let batch = db.batch();
  let count = 0;
  const commits = [];

  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
    count++;
    if (count % 500 === 0) {
      commits.push(batch.commit());
      batch = db.batch();
    }
  }
  if (count % 500 !== 0) commits.push(batch.commit());

  await Promise.all(commits);
  console.log(`Deleted ${count} past plans`);
  return count;
}

// Returns the ISO date string (YYYY-MM-DD) for today + offsetDays
function dateOffset(offsetDays) {
  const d = new Date();
  d.setUTCHours(0, 0, 0, 0);
  d.setUTCDate(d.getUTCDate() + offsetDays);
  return d.toISOString().split("T")[0];
}

// Generate plans for all cities on a specific date
async function generateForDate(dateStr, results) {
  let sportsEvents = [];
  try {
    sportsEvents = await getSportsEventsGlobal(dateStr);
    console.log(`[${dateStr}] Sports events: ${sportsEvents.length}`);
  } catch (e) {
    results.errors.push({ date: dateStr, source: "TheSportsDB", error: e.message });
  }

  for (const city of CITIES) {
    try {
      console.log(`[${dateStr}] Processing ${city.name}...`);

      const [weather, freeEvents] = await Promise.all([
        getWeather(city, dateStr).catch(e => {
          results.errors.push({ date: dateStr, city: city.name, source: "OpenWeatherMap", error: e.message });
          return { description: "despejado", temp: 20, isOutdoor: true, icon: "Clear" };
        }),
        getFreeEvents(city, dateStr).catch(e => {
          results.errors.push({ date: dateStr, city: city.name, source: "PredictHQ", error: e.message });
          return [];
        }),
      ]);

      const plans = await generatePlansWithGPT(city, weather, sportsEvents, freeEvents, dateStr);

      for (const plan of plans) {
        const id = await savePlan(plan);
        results.created++;
        results.plans.push({ id, title: plan.title, city: plan.city, date: dateStr });
      }

      console.log(`[${dateStr}] ${city.name}: ${plans.length} plans created`);
    } catch (e) {
      console.error(`[${dateStr}] Error processing ${city.name}:`, e);
      results.errors.push({ date: dateStr, city: city.name, source: "generation", error: e.message });
    }
  }
}

async function runDailyPlanGeneration() {
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);

  const results = {
    date: today.toISOString().split("T")[0],
    created: 0, deleted: 0, skipped: 0, errors: [], plans: [],
  };

  // 1. Delete plans whose event time has already passed
  try {
    results.deleted = await deletePastPlans();
  } catch (e) {
    console.error("Error deleting past plans:", e);
    results.errors.push({ source: "cleanup", error: e.message });
  }

  // 2. For each of the next 7 days, generate plans if none exist yet
  for (let offset = 0; offset < 7; offset++) {
    const dayStart = new Date(today);
    dayStart.setUTCDate(today.getUTCDate() + offset);
    const dayEnd = new Date(dayStart);
    dayEnd.setUTCDate(dayStart.getUTCDate() + 1);
    const dateStr = dayStart.toISOString().split("T")[0];

    try {
      const existing = await db.collection("Plans")
        .where("time", ">=", Timestamp.fromDate(dayStart))
        .where("time", "<",  Timestamp.fromDate(dayEnd))
        .limit(1)
        .get();

      if (!existing.empty) {
        console.log(`[${dateStr}] Already has plans — skipping`);
        results.skipped++;
        continue;
      }

      console.log(`[${dateStr}] No plans found — generating for all cities`);
      await generateForDate(dateStr, results);
    } catch (e) {
      console.error(`[${dateStr}] Error checking/generating:`, e);
      results.errors.push({ date: dateStr, source: "generation", error: e.message });
    }
  }

  return results;
}

// ─── Endpoint: createPlan (llamado por Make.com para un plan individual) ───────

exports.createPlan = onRequest(
  { region: "europe-west1", cors: false, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

    const { secret, ...planData } = req.body;
    if (MAKE_SECRET && secret !== MAKE_SECRET) return res.status(401).json({ error: "Unauthorized" });

    const required = ["title", "description", "category", "city", "location", "time"];
    for (const f of required) {
      if (!planData[f]) return res.status(400).json({ error: `Missing field: ${f}` });
    }

    let eventTime;
    try {
      eventTime = typeof planData.time === "number"
        ? Timestamp.fromMillis(planData.time)
        : Timestamp.fromDate(new Date(planData.time));
    } catch {
      return res.status(400).json({ error: "Invalid time format" });
    }

    const plan = {
      title: String(planData.title),
      description: String(planData.description),
      category: String(planData.category),
      city: String(planData.city),
      location: String(planData.location),
      time: eventTime,
      price: Number(planData.price ?? 5),
      status: planData.status || "pending",
      joinedCount: Number(planData.joinedCount ?? 0),
      minPeople: Number(planData.minPeople ?? 3),
      joinedUsers: Array.isArray(planData.joinedUsers) ? planData.joinedUsers : [],
      createdAt: Timestamp.now(),
      ...(planData.sourceApi && { sourceApi: String(planData.sourceApi) }),
      ...(planData.eventId && { eventId: String(planData.eventId) }),
    };

    try {
      const ref = await db.collection("Plans").add(plan);
      return res.status(201).json({ success: true, planId: ref.id });
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: "Failed to save plan" });
    }
  }
);

// ─── Endpoint: generateDailyPlans (trigger manual desde Make.com) ─────────────

exports.generateDailyPlans = onRequest(
  {
    region: "europe-west1",
    invoker: "public",
    timeoutSeconds: 3600,
    memory: "512MiB",
    secrets: ["MAKE_SECRET", "OPENAI_API_KEY", "OPENWEATHER_API_KEY", "PREDICTHQ_API_KEY", "SPORTSDB_API_KEY"],
  },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

    const secret = req.body?.secret || req.headers["x-sponti-secret"];
    if (MAKE_SECRET && secret !== MAKE_SECRET) return res.status(401).json({ error: "Unauthorized" });

    try {
      const results = await runDailyPlanGeneration();
      return res.status(200).json({ success: true, ...results });
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: e.message });
    }
  }
);

// ─── Scheduled trigger: cada día a las 07:00 UTC (sin necesidad de Make.com) ──

exports.generateDailyPlansScheduled = onSchedule(
  {
    schedule: "0 7 * * *",
    timeZone: "UTC",
    region: "europe-west1",
    memory: "512MiB",
    timeoutSeconds: 1800,
    secrets: ["OPENAI_API_KEY", "OPENWEATHER_API_KEY", "PREDICTHQ_API_KEY", "SPORTSDB_API_KEY"],
  },
  async () => {
    console.log("generateDailyPlansScheduled: starting");
    try {
      const results = await runDailyPlanGeneration();
      if (results.errors.length > 0) {
        console.warn("Generation errors:", JSON.stringify(results.errors));
      }
      console.log("Daily generation complete:", JSON.stringify({ created: results.created, cities: results.plans.map(p => p.city) }));
    } catch (e) {
      console.error("FATAL: generateDailyPlansScheduled crashed:", e.message, e.stack);
      throw e;
    }
  }
);

// ─── Stripe: createPaymentIntent ─────────────────────────────────────────────
// Autoriza $5 × count al unirse — NO se captura hasta que haya quorum.
// Soporta pago individual (count=1) y grupal (count=N, cobro único de $5×N).

exports.createPaymentIntent = onRequest(
  {
    region: "europe-west1",
    invoker: "public",
    cors: true,
    secrets: ["STRIPE_SECRET_KEY"],
  },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

    const { userId, planId, count = 1 } = req.body;
    if (!userId || !planId) return res.status(400).json({ error: "Missing userId or planId" });

    const peopleCount = Math.max(1, Math.min(10, parseInt(count) || 1));

    const planRef = db.collection("Plans").doc(planId);
    const planDoc = await planRef.get();
    if (!planDoc.exists) return res.status(404).json({ error: "Plan not found" });

    const plan = planDoc.data();
    if ((plan.joinedUsers || []).includes(userId)) {
      return res.status(400).json({ error: "Already joined" });
    }

    try {
      const stripe = getStripe();

      // Obtener o crear Stripe customer para este usuario
      const userRef = db.collection("Users").doc(userId);
      const userDoc = await userRef.get();
      let customerId = userDoc.exists ? userDoc.data().stripeCustomerId : null;

      if (!customerId) {
        const customer = await stripe.customers.create({ metadata: { userId } });
        customerId = customer.id;
        await userRef.set({ stripeCustomerId: customerId }, { merge: true });
      }

      // capture_method: "manual" → autoriza pero NO cobra hasta capturar
      const paymentIntent = await stripe.paymentIntents.create({
        amount: 500 * peopleCount,
        currency: "usd",
        customer: customerId,
        capture_method: "manual",
        automatic_payment_methods: { enabled: true },
        description: `Sponti — ${plan.title} (${peopleCount} persona${peopleCount > 1 ? "s" : ""})`,
        metadata: { planId, userId, count: String(peopleCount) },
      });

      return res.status(200).json({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: paymentIntent.amount,
        count: peopleCount,
      });
    } catch (e) {
      console.error("createPaymentIntent error:", e);
      return res.status(500).json({ error: e.message });
    }
  }
);

// ─── Stripe: confirmJoinPlan ──────────────────────────────────────────────────
// Llamado tras que el usuario autorizó el PaymentIntent en el app.
// Registra al usuario (y sus acompañantes) en el plan sin cobrar.

exports.confirmJoinPlan = onRequest(
  {
    region: "europe-west1",
    invoker: "public",
    cors: true,
    secrets: ["STRIPE_SECRET_KEY"],
  },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

    const { paymentIntentId, planId, userId } = req.body;
    if (!paymentIntentId || !planId || !userId) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    try {
      const stripe = getStripe();
      const pi = await stripe.paymentIntents.retrieve(paymentIntentId);

      // El status tras autorizar con capture_method:manual es "requires_capture"
      if (pi.status !== "requires_capture") {
        return res.status(400).json({ error: `PaymentIntent status: ${pi.status}` });
      }
      if (pi.metadata.planId !== planId || pi.metadata.userId !== userId) {
        return res.status(403).json({ error: "Metadata mismatch" });
      }

      const peopleCount = parseInt(pi.metadata.count) || 1;
      const planRef = db.collection("Plans").doc(planId);

      let newJoinedCount;
      await db.runTransaction(async (tx) => {
        const planDoc = await tx.get(planRef);
        if (!planDoc.exists) throw new Error("Plan not found");

        const plan = planDoc.data();
        if ((plan.joinedUsers || []).includes(userId)) throw new Error("Already joined");

        // payments: { userId → { paymentIntentId, count, amount } }
        const payments = {
          ...(plan.payments || {}),
          [userId]: { paymentIntentId, count: peopleCount, amount: pi.amount },
        };

        const newJoinedUsers = [...(plan.joinedUsers || []), userId];
        // joinedCount sube por el número de personas que incluye este pago
        newJoinedCount = (plan.joinedCount || 0) + peopleCount;

        tx.update(planRef, {
          joinedUsers: newJoinedUsers,
          joinedCount: newJoinedCount,
          payments,
        });
      });

      return res.status(200).json({ success: true, joinedCount: newJoinedCount, count: peopleCount });
    } catch (e) {
      if (e.message === "Already joined") return res.status(200).json({ success: true, alreadyJoined: true });
      console.error("confirmJoinPlan error:", e);
      return res.status(500).json({ error: e.message });
    }
  }
);

// ─── Firestore trigger: capturar pagos al llegar al quorum ───────────────────
// Cuando joinedCount >= minPeople → captura todos los PaymentIntents autorizados.
// Si el plan expira sin quorum → cancélalos (el usuario nunca es cobrado).

exports.onPlanQuorumReached = onDocumentUpdated(
  {
    document: "Plans/{planId}",
    region: "europe-west1",
    secrets: ["STRIPE_SECRET_KEY", "WHATSAPP_TOKEN", "WHATSAPP_PHONE_NUMBER_ID"],
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const minPeople = after.minPeople || 3;
    const quorumJustReached = before.joinedCount < minPeople && after.joinedCount >= minPeople;
    const notYetProcessed = after.status !== "confirmed" && after.status !== "capturing";

    if (!quorumJustReached || !notYetProcessed) return;

    const planId = event.params.planId;
    console.log(`Quorum reached for plan ${planId} — capturing payments`);

    // Marcar como en proceso para evitar doble captura
    await db.collection("Plans").doc(planId).update({ status: "capturing" });

    const stripe = getStripe();
    const payments = after.payments || {};
    const captureResults = [];

    for (const [userId, paymentData] of Object.entries(payments)) {
      const { paymentIntentId, count, amount } = paymentData;
      try {
        const captured = await stripe.paymentIntents.capture(paymentIntentId);
        captureResults.push({
          userId,
          count,
          amount,
          status: captured.status,
          paymentIntentId,
        });
        console.log(`Captured $${amount / 100} from ${userId} (${count} personas)`);
      } catch (e) {
        console.error(`Capture failed for ${userId}:`, e.message);
        captureResults.push({ userId, count, amount, status: "failed", error: e.message });
      }
    }

    await db.collection("Plans").doc(planId).update({
      status: "confirmed",
      captureResults,
      confirmedAt: Timestamp.now(),
    });

    console.log(`Plan ${planId} confirmed. Results:`, captureResults);

    // ── WhatsApp notifications ────────────────────────────────────────────────
    const confirmedPlan = { ...after, joinedCount: after.joinedCount };
    const whatsappResults = [];

    for (const userId of after.joinedUsers || []) {
      try {
        const userDoc = await db.collection("Users").doc(userId).get();
        const phone = userDoc.exists ? userDoc.data().phone : null;

        if (!phone) {
          console.warn(`WhatsApp: no phone for user ${userId}`);
          whatsappResults.push({ userId, status: "no_phone" });
          continue;
        }

        await sendWhatsAppMessage(phone, confirmedPlan, planId);
        whatsappResults.push({ userId, status: "sent" });
        console.log(`WhatsApp sent to ${userId}`);
      } catch (e) {
        console.error(`WhatsApp failed for ${userId}:`, e.message);
        whatsappResults.push({ userId, status: "failed", error: e.message });
      }
    }

    console.log(`WhatsApp notifications:`, JSON.stringify(whatsappResults));
  }
);
