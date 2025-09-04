// functions/core/anchors.js
// Anchors & model config loaders (robust + cached)
// Node 20 / ESM / Firebase Functions v2

import { db } from "../core/firebase_admin.js";
import {
  round,
  normalizeUnits,
  memoizeTtl,
} from "./ddc_utils.js";



// Cache TTLs (ms)
const MODEL_TTL = 10 * 60 * 1000; // 10 min
const ANCHOR_TTL = 5 * 60 * 1000; // 5 min

/**
 * loadModelConfig(modelVersion?)
 * Loads model config from reference/config (or sensible defaults).
 * Expected shape (example):
 * {
 *   version: "v1",
 *   scale_years: 12,
 *   pivot_risk: 0.35,
 *   groups: { recovery: 0.4, sleep: 0.3, activity: 0.3 },
 *   caps: { daily_va_abs: 1.0, total_va_abs: 10 },
 *   change_cooldown_sec: 0,
 * }
 */
export async function loadModelConfig(modelVersion = "v1") {
  return memoizeTtl("modelConfig", modelVersion, MODEL_TTL, async () => {
    try {
      // Primary location
      const ref = db.doc(`reference/config/models_${modelVersion}`);
      const snap = await ref.get();
      if (snap.exists) {
        const cfg = snap.data() || {};
        return normalizeModelConfig(cfg);
      }
      // Fallback (single doc)
      const single = await db.doc("reference/config/models").get();
      if (single.exists) {
        const obj = single.data() || {};
        const cfg = obj?.[modelVersion] || obj?.default || {};
        return normalizeModelConfig(cfg);
      }
    } catch {
      // ignore and use defaults
    }
    // Safe defaults (transparent)
    return normalizeModelConfig({
      version: "v1",
      scale_years: 12,
      pivot_risk: 0.35,
      groups: { recovery: 0.4, sleep: 0.3, activity: 0.3, affect: 0.0 },
      caps: { daily_va_abs: 1.0, total_va_abs: 10 },
      change_cooldown_sec: 0,
    });
  });
}

function normalizeModelConfig(cfg) {
  const v = String(cfg?.version || "v1");
  const scale_years = Number(cfg?.scale_years ?? 12) || 12;
  const pivot_risk = Number(cfg?.pivot_risk ?? 0.35) || 0.35;
  const groups = {
    recovery: Number(cfg?.groups?.recovery ?? 0.4),
    sleep: Number(cfg?.groups?.sleep ?? 0.3),
    activity: Number(cfg?.groups?.activity ?? 0.3),
    affect: Number(cfg?.groups?.affect ?? 0.0),
  };
  const caps = {
    daily_va_abs: Number(cfg?.caps?.daily_va_abs ?? 1.0),
    total_va_abs: Number(cfg?.caps?.total_va_abs ?? 10),
  };
  const change_cooldown_sec = Number(cfg?.change_cooldown_sec ?? 0) || 0;
  return {
    version: v,
    scale_years,
    pivot_risk,
    groups,
    caps,
    change_cooldown_sec,
  };
}

/**
 * loadAnchors(uid)
 * - Robust legacy fields (dob as Timestamp or ISO string)
 * - Safe unit normalization (height/weight)
 * - Latest-reading fetch logic preserved (for optional reference like vo2max/fitness age)
 * - Cached per-user to reduce read cost
 *
 * Returns:
 * {
 *   anchors_version: "a1",
 *   sex, dob, age_years,
 *   height_cm, weight_kg, waist_cm: null|number,
 *   extras: { vo2max_ml_kg_min?: number, fitness_age_years?: number }
 * }
 */
export async function loadAnchors(uid) {
  if (!uid) throw new Error("loadAnchors: missing uid");
  return memoizeTtl("anchors", uid, ANCHOR_TTL, async () => {
    // 1) Read user doc
    const userRef = db.doc(`users/${uid}`);
    const userSnap = await userRef.get();
    const u = userSnap.exists ? userSnap.data() || {} : {};

    // sex
    const sexRaw = (u.sex || u.gender || "").toString().toLowerCase();
    const sex =
      sexRaw === "male" || sexRaw === "m"
        ? "male"
        : sexRaw === "female" || sexRaw === "f"
        ? "female"
        : "unknown";

    // dob → age
    let dobIso = null;
    if (u.dob) {
      if (typeof u.dob === "string") {
        dobIso = u.dob;
      } else if (u.dob?.toDate) {
        dobIso = u.dob.toDate().toISOString();
      }
    } else if (u.birthdate) {
      dobIso = String(u.birthdate);
    }

    let age_years = null;
    if (dobIso) {
      try {
        const d = new Date(dobIso);
        if (Number.isFinite(d.getTime())) {
          const now = new Date();
          const diff = (now.getTime() - d.getTime()) / 86400000 / 365.2422;
          age_years = Math.max(0, round(diff, 2));
        }
      } catch {
        age_years = null;
      }
    }

    // height/weight/waist — normalize units
    const nu = normalizeUnits({
      height_cm: u.height_cm ?? u.height ?? null,
      weight_kg: u.weight_kg ?? u.weight ?? null,
    });
    const height_cm = nu.height_cm ?? null;
    const weight_kg = nu.weight_kg ?? null;
    let waist_cm = null;
    if (u.waist_cm != null) {
      const w = Number(u.waist_cm);
      waist_cm = Number.isFinite(w) ? round(w, 1) : null;
    } else if (u.waist_in != null) {
      const w = Number(u.waist_in) * 2.54;
      waist_cm = Number.isFinite(w) ? round(w, 1) : null;
    }

    // Optional extras (latest VO2max / fitness age) from user_daily last 30d
    // We keep this light (best-effort); failures don't break anchors.
    let vo2max_ml_kg_min = null;
    let fitness_age_years = null;
    try {
      const daysCol = db.collection(`users/${uid}/days`);
      // IDs are YYYY-MM-DD ⇒ lexical order; fetch last ~45 and scan
      const snap = await daysCol.orderBy("__name__", "desc").limit(45).get();
      for (const doc of snap.docs) {
        const d = doc.data() || {};
        if (vo2max_ml_kg_min == null && Number.isFinite(Number(d.vo2max_ml_kg_min))) {
          vo2max_ml_kg_min = Number(d.vo2max_ml_kg_min);
        }
        if (fitness_age_years == null && Number.isFinite(Number(d.fitness_age_years))) {
          fitness_age_years = Number(d.fitness_age_years);
        }
        if (vo2max_ml_kg_min != null && fitness_age_years != null) break;
      }
    } catch {
      // ignore
    }

    return {
      anchors_version: "a1",
      sex,
      dob: dobIso,
      age_years,
      height_cm,
      weight_kg,
      waist_cm,
      extras: {
        ...(vo2max_ml_kg_min != null ? { vo2max_ml_kg_min } : {}),
        ...(fitness_age_years != null ? { fitness_age_years } : {}),
      },
    };
  });
}

