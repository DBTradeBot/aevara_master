// Vitality v1 — One-file pipeline (dynamic sensitivity + fixed baseline)
// Node 20 / ESM / Firebase Functions v2

import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { db, FieldValue } from "../core/firebase_admin.js";
import { FieldPath } from "firebase-admin/firestore";

// Guards & leases
import { verifyAppCheckOrScheduler } from "../core/app_check.js";
import { acquireDayLease, heartbeatDayLease, releaseDayLease } from "../core/leases.js";

// Vendor coverage (bounded, priority-first)
import { ensureThirtyDayCoverageForUid } from "../vendor/fitbit_fetch.js";

// Model config + anchors (read-only)
import { loadModelConfig, loadAnchors, computeSlowAnchorsContrib } from "../core/anchors.js";

/* ───────── Tunables & version ───────── */

const REGION = "us-central1";
const DEFAULT_TZ = "America/Los_Angeles";

// Finalize / visible caps
const FINALIZE_HOUR_LOCAL = 3;            // finalize at D+1 03:00 local
const DAILY_DELTA_CAP_YEARS = 1.25;       // ±1.25y/day post-ramp
const DAILY_DELTA_CAP_RAMP  = 0.60;       // ±0.60y/day in ramp
const TOTAL_DELTA_CAP_FROM_BASELINE = 10; // ±10y vs baseline post-ramp

// Early ramp & DOB-blend
const RAMP_DAYS = 30;
const RAMP_MIN_FACTOR = 0.30;
const TOTAL_CAP_RAMP_0_14 = 2.0;
const TOTAL_CAP_RAMP_15_29 = 3.0;

// Core inputs blending
const EMA7_ALPHA = 2 / (7 + 1);
const TODAY_WEIGHT = 0.70;
const EMA_WEIGHT = 0.30;

// Confidence policy
const CONF_MAX = 95;
const CONF_CORE = {
  recovery: { hrv: 0.21, rhr: 0.14 }, // 0.35
  sleep:    { dur: 0.30 },            // 0.30
  activity: { steps: 0.20 },          // 0.20
}; // 0.85 total
const CONF_EXTRAS_BONUS_MAX = 0.15; // +15 from slow anchors presence only

// Context dampeners (capped together at -15)
const CTX_PENALTIES = { illness: 10, travel: 7, menstrual_phase: 5 };
const CTX_PENALTY_CAP = 15;

// Dynamic sensitivity defaults (can be overridden via model config)
const DY_TARGET_SPAN_YEARS_DEFAULT = 8; // map ~p95-p5 risk to ~8y
const DY_MIN_SCALE = 10;
const DY_MAX_SCALE = 20;
const DY_NEUTRAL_RISK_DEFAULT = 0.22;
const DY_PIVOT_SHRINK = 0.5; // toward neutral
const DY_PIVOT_MIN = 0.18;
const DY_PIVOT_MAX = 0.28;

const ENV = {
  BACKFILL_RECENT_N: Math.max(0, Number(process.env.BACKFILL_RECENT_N ?? 4)),
  COOLDOWN_MINUTES:  Math.max(0, Number(process.env.VITALITY_COOLDOWN_MINUTES ?? 0)),
  SYNC_SHARED_SECRET: (process.env.SYNC_SHARED_SECRET || process.env.SYNC_SECRET || "").trim(),
};

export const COMPUTE_ENGINE_VERSION = "2025-09-14-dyn-pivot-scale-021";

/* ───────── Utils ───────── */

function isDateKey(s){ return typeof s==="string" && /^\d{4}-\d{2}-\d{2}$/.test(s); }
function parseDateKey(s){ const [y,m,d]=s.split("-").map(Number); return new Date(Date.UTC(y,m-1,d)); }
function toKey(dtUTC){ const y=dtUTC.getUTCFullYear(); const m=String(dtUTC.getUTCMonth()+1).padStart(2,"0"); const d=String(dtUTC.getUTCDate()).padStart(2,"0"); return `${y}-${m}-${d}`; }
function prevDateKey(key){ try{ const d=parseDateKey(key); d.setUTCDate(d.getUTCDate()-1); return toKey(d);}catch{return null;} }
function dateKeyInTZ(date, tz){ const f=new Intl.DateTimeFormat("en-CA",{timeZone:tz,year:"numeric",month:"2-digit",day:"2-digit"}); return f.format(date); }
function isTodayLocal(dateKey, tz){ return dateKeyInTZ(new Date(), tz)===dateKey; }
function formatLocal(date, tz){ return new Intl.DateTimeFormat("en-GB",{timeZone:tz,year:"numeric",month:"2-digit",day:"2-digit",hour:"2-digit",minute:"2-digit",second:"2-digit"}).format(date); }
function round(x,n=0){ const p=Math.pow(10,n); return Math.round(Number(x)*p)/p; }
function clamp(x,lo,hi){ return Math.min(hi, Math.max(lo,x)); }
function clamp01(x){ return clamp(Number(x),0,1); }
function numOrNull(v){ const n=Number(v); return Number.isFinite(n)? n:null; }
function isNum(v){ return Number.isFinite(Number(v)); }
function uniqSortKeys(arr){ const out=Array.from(new Set((arr||[]).filter(isDateKey))); out.sort(); return out; }
function median(arr){ const a=arr.slice().sort((x,y)=>x-y); if(!a.length) return null; const m=Math.floor(a.length/2); return a.length%2? a[m] : (a[m-1]+a[m])/2; }
function pTile(arr, p){ if(!arr?.length) return null; const a=arr.slice().sort((x,y)=>x-y); const idx=(a.length-1)*p; const lo=Math.floor(idx); const hi=Math.ceil(idx); if(lo===hi) return a[lo]; return a[lo]+(a[hi]-a[lo])*(idx-lo); }
function isFirestoreTimestamp(x){ return !!(x && typeof x.toDate==="function"); }

/* ───────── Profile helpers ───────── */

async function readUserProfile(uid){
  try{
    const snap=await db.doc(`users/${uid}`).get();
    if(!snap.exists) return null;
    const d=snap.data()||{};
    let dobDate=null;
    const rawDob=d.dob_iso||d.dob||d.birthdate_iso||d.birthdate||null;
    if(isFirestoreTimestamp(rawDob)) dobDate=rawDob.toDate();
    else if(rawDob){ const t=new Date(String(rawDob)); if(Number.isFinite(t.getTime())) dobDate=t; }
    return {
      dobDate,
      tz: d.tz || d.timezone || DEFAULT_TZ,
      gender: d.gender ?? null,
      height_cm: isNum(d.height_cm)? Number(d.height_cm): null,
      weight_kg: isNum(d.weight_kg)? Number(d.weight_kg): null,
      waist_cm:  isNum(d.waist_cm)?  Number(d.waist_cm):  null,
      baseline_vitality_age_years: isNum(d.baseline_vitality_age_years)? Number(d.baseline_vitality_age_years): null,
      work_schedule: d.work_schedule ?? null,
      activity_level: d.activity_level ?? null,
    };
  }catch{return null;}
}
function computeChronoAgeOn(dobDate, dateKey){
  if(!dobDate || !Number.isFinite(dobDate.getTime?.() ?? NaN)) return { age_years:null };
  const ref=parseDateKey(dateKey)||new Date();
  const ageMs=ref - new Date(Date.UTC(dobDate.getUTCFullYear(), dobDate.getUTCMonth(), dobDate.getUTCDate()));
  return { age_years: round(ageMs/(365.2425*24*3600*1000), 2) };
}
function computeAnthro(p){
  const h=isNum(p?.height_cm)?Number(p.height_cm):null;
  const w=isNum(p?.weight_kg)?Number(p.weight_kg):null;
  const wc=isNum(p?.waist_cm)? Number(p.waist_cm): null;
  const bmi=(isNum(h)&&isNum(w)&&h>0)? round(w/Math.pow(h/100,2),2): null;
  const whtr=(isNum(wc)&&isNum(h)&&h>0)? round(wc/h,3): null;
  return { height_cm:h, weight_kg:w, waist_cm:wc, bmi, waist_to_height:whtr };
}

/* ───────── Vendors → inputs.used (with manual overrides) ───────── */

function srcObj(provider, field, iso){ return { provider, field, sampled_at_utc: iso || null }; }

async function mergeDailyFromVendors(uid, dateKey, { allowZerosToday=false, tz=DEFAULT_TZ } = {}){
  if(!isDateKey(dateKey)) throw new Error("mergeDailyFromVendors: invalid dateKey");
  const dayRef=db.doc(`users/${uid}/days/${dateKey}`);
  const baseSnap=await dayRef.get();
  const base=baseSnap.exists?(baseSnap.data()||{}):{};

  const manual=base?.inputs?.manual||{};
  const lastMetric={ ...(base?.last_metric_sample_utc||{}) };
  const sources={ ...(base?.sources||{}) };

  const isToday=isTodayLocal(dateKey, tz);
  const zeroToNull=(v)=> (Number(v)===0 && !(allowZerosToday && isToday)) ? null : v;

  const rs=await db.collection(`users/${uid}/sync_days`).where("date_local","==",dateKey).get();

  const acc={ sleep_total_hours:null, hrv_rmssd_ms:null, rhr_bpm:null, steps_count:null, distance_km:null, calories_out:null, mvpa_minutes:null };
  const accSrc={ sleep_total_hours:null, hrv_rmssd_ms:null, rhr_bpm:null, steps_count:null, distance_km:null, calories_out:null, mvpa_minutes:null };
  const providerRank={ apple:6, oura:5, whoop:4, garmin:3, fitbit:2, googlefit:1 };

  const touchLast=(metric, iso)=>{ const s=String(iso||""); if(!s) return; const prev=String(lastMetric[metric]||""); if(!prev || s>prev) lastMetric[metric]=s; };
  const accept=(metric,value,provider,field,iso)=>{
    const v=numOrNull(value); if(v==null) return;
    const curV=acc[metric], curSrc=accSrc[metric];
    if(curV==null){ acc[metric]=v; accSrc[metric]={provider,field,iso}; }
    else{
      const curRank=providerRank[String(curSrc.provider||"")]||0;
      const newRank=providerRank[String(provider||"")]||0;
      if(newRank>curRank){ acc[metric]=v; accSrc[metric]={provider,field,iso}; }
      else if(newRank===curRank){
        const prevIso=String(curSrc.iso||""); const nextIso=String(iso||"");
        if(nextIso && (!prevIso || nextIso>prevIso)){ acc[metric]=v; accSrc[metric]={provider,field,iso}; }
      }
    }
    touchLast(metric, iso);
  };

  for(const doc of rs.docs){
    const r=doc.data()||{}; const provider=String(r?.provider||"unknown");

    accept("sleep_total_hours", r?.sleep_total_hours, provider, "sleep_total_hours", r?.last_sleep_total_hours_utc);
    accept("hrv_rmssd_ms",      r?.hrv_rmssd_ms,      provider, "rmssd_ms",          r?.last_hrv_rmssd_ms_utc);
    accept("rhr_bpm",           r?.rhr_bpm,           provider, "rhr_bpm",           r?.last_rhr_bpm_utc);

    accept("steps_count",  zeroToNull(r?.steps_count),  provider, "steps",              r?.last_steps_count_utc);
    accept("distance_km",  zeroToNull(r?.distance_km),  provider, "distance_km",        r?.last_distance_km_utc);
    accept("calories_out", zeroToNull(r?.calories_out), provider, "calories_out",       r?.last_calories_out_utc);
    accept("mvpa_minutes", r?.zone_minutes_total ?? r?.mvpa_minutes, provider, "mvpa_minutes", r?.last_zone_minutes_total_utc || r?.last_mvpa_minutes_utc);
  }

  // Manual overrides
  const used={ ...acc };
  for(const k of Object.keys(used)){
    if(manual?.[k]!=null && manual[k] !== ""){ used[k]=numOrNull(manual[k]); accSrc[k]={ provider:"manual", field:k, iso:lastMetric?.[k]||null }; }
  }

  const newSources={ ...sources };
  for(const k of Object.keys(used)){ const s=accSrc[k]; if(s) newSources[k]=srcObj(s.provider, s.field, s.iso); }

  const now=new Date();
  const write={
    date_local: dateKey,
    tz,
    updated_at_utc: now.toISOString(),
    updated_at_local: formatLocal(now, tz),
    inputs: { ...(base?.inputs||{}), used: { ...(base?.inputs?.used||{}), ...used }, manual: { ...(base?.inputs?.manual||{}) } },
    sources: newSources,
    last_metric_sample_utc: { ...(base?.last_metric_sample_utc||{}), ...lastMetric },
  };
  await dayRef.set(write,{merge:true});
  const snap=await dayRef.get();
  return snap.data()||{};
}

/* ───────── Activity policy (night-shift aware without live drift) ───────── */

function isLocalTimeInRange(hhmm, startHHMM, endHHMM){
  if(typeof hhmm!=="string"||hhmm.length<5) return false;
  const val=Number(hhmm.replace(":","")); const a=Number(startHHMM.replace(":","")); const b=Number(endHHMM.replace(":",""));
  return Number.isFinite(val)&&val>=a&&val<=b;
}

// Best-effort inference: prefer lag_yesterday; if user hints night shift, we still use D-1,
// but if we can read a recent sleep window on D-1, we surface it for transparency only.
async function maybeInferYesterdayActivityWindow(uid, dMinus1Key){
  try{
    const snap=await db.doc(`users/${uid}/days/${dMinus1Key}`).get();
    const d=snap.exists?(snap.data()||{}):{};
    // If upstream sync writes sleep_main_{start,end}_utc on day docs, surface it.
    const win=d?.sleep_main_window_utc || null;
    if(win?.from && win?.to) return { from: String(win.from), to: String(win.to) };
  }catch{}
  return null;
}

async function resolveActivityInputs(uid, dateKey, { policy="lag_yesterday", tz=DEFAULT_TZ, userProfile=null } = {}){
  const mid=null; // future: sleep midpoint if stored
  const isMidDaytime=isLocalTimeInRange(mid||"", "09:00","17:00");
  const workSchedule=(userProfile?.work_schedule||"").toLowerCase();

  let preferred;
  if(policy==="same_day") preferred=dateKey;
  else if(policy==="lag_yesterday") preferred=prevDateKey(dateKey);
  else preferred=(workSchedule==="night"||isMidDaytime)? dateKey : prevDateKey(dateKey);

  const alt=preferred===dateKey? prevDateKey(dateKey): dateKey;

  const readDay=async (key)=>{
    const snap=await db.doc(`users/${uid}/days/${key}`).get();
    const d=snap.exists?(snap.data()||{}):{};
    const used=d?.inputs?.used||{};
    const N=(x)=> (Number.isFinite(Number(x))? Number(x): null);
    return {
      steps_count:   N(used.steps_count),
      calories_out:  N(used.calories_out),
      distance_km:   N(used.distance_km),
      mvpa_minutes:  N(used.mvpa_minutes),
      last_metric_sample_utc: d?.last_metric_sample_utc || {}
    };
  };

  try{ await mergeDailyFromVendors(uid, preferred, { allowZerosToday:true, tz }); }catch{}
  try{ await mergeDailyFromVendors(uid, alt,       { allowZerosToday:true, tz }); }catch{}

  const prefVals=await readDay(preferred);
  const isEmpty=(v)=> !(Number.isFinite(Number(v)) && Number(v)>0);
  const prefEmpty = isEmpty(prefVals.steps_count) && isEmpty(prefVals.calories_out) && isEmpty(prefVals.distance_km) && isEmpty(prefVals.mvpa_minutes);

  let finalFrom=preferred, vals=prefVals;
  if(prefEmpty){
    const altVals=await readDay(alt);
    const altEmpty = isEmpty(altVals.steps_count) && isEmpty(altVals.calories_out) && isEmpty(altVals.distance_km) && isEmpty(altVals.mvpa_minutes);
    if(!altEmpty){ finalFrom=alt; vals=altVals; }
  }

  const policyUsed=(finalFrom===dateKey)?"same_day":"lag_yesterday";
  let activity_window_from_utc=null, activity_window_to_utc=null;
  if(policyUsed==="lag_yesterday"){
    const win=await maybeInferYesterdayActivityWindow(uid, finalFrom);
    if(win){ activity_window_from_utc=win.from; activity_window_to_utc=win.to; }
  }
  return { ...vals, provenance: { activity_policy: policyUsed, from_date: finalFrom, activity_window_from_utc, activity_window_to_utc } };
}

/* ───────── Scoring helpers ───────── */

function average(list){ const vals=list.filter(x=>Number.isFinite(x)); return vals.length? vals.reduce((s,x)=>s+x,0)/vals.length : null; }
function sigmoid(x){ return 1/(1+Math.exp(-x)); }
function asymSigmoid(x, center=7.5, leftW=1.6, rightW=2.2){ const k=x<center?(1/leftW):(1/rightW); return clamp01(sigmoid((x-center)*k)); }
function stepsPctHumane(steps){ if(!isNum(steps)) return null; const s=Number(steps); return clamp01(1 - Math.exp(-s/6500)); }
function mvpaPctHumane(min){ if(!isNum(min)) return null; const m=Number(min); return clamp01(1 - Math.exp(-m/30)); }

function computeGroups(inputs){
  const baseHrv=isNum(inputs.ema7_hrv)? Number(inputs.ema7_hrv): 50;
  const baseRhr=isNum(inputs.ema7_rhr)? Number(inputs.ema7_rhr): 65;
  let hrvP=null, rhrP=null;

  if(isNum(inputs.hrv_rmssd_ms) && inputs.hrv_rmssd_ms>0 && baseHrv>0){
    const z=(Math.log(inputs.hrv_rmssd_ms) - Math.log(baseHrv)) / 0.35; // ~35% ~1SD
    hrvP=clamp01(sigmoid(z));
  }
  if(isNum(inputs.rhr_bpm) && baseRhr>0){
    const z=(baseRhr - inputs.rhr_bpm)/6.0;
    rhrP=clamp01(sigmoid(z));
  }
  let recovery=(hrvP==null && rhrP==null) ? null : average([hrvP,rhrP]);
  if(recovery!=null) recovery=Math.max(0.05, recovery);

  // Sleep
  let sleepP=null;
  if(isNum(inputs.sleep_total_hours)) sleepP=Math.max(0.05, asymSigmoid(Number(inputs.sleep_total_hours),7.5,1.6,2.2));

  // Activity: steps + mvpa; calories fallback is mild credit
  let steps=isNum(inputs.steps_count)? Number(inputs.steps_count): null;
  if(!isNum(steps) && isNum(inputs.distance_km)){ const strideM=1.35; steps=Math.round(Number(inputs.distance_km)*1000/strideM); }
  let stepsP=stepsPctHumane(steps);
  let mvpaMin=isNum(inputs.mvpa_minutes)? Number(inputs.mvpa_minutes): null;
  let mvpaP=mvpaPctHumane(mvpaMin);

  let activity=null;
  if(stepsP==null && mvpaP==null){
    if(isNum(inputs.calories_out)){
      const cal=Number(inputs.calories_out);
      const calP=clamp01(1 - Math.exp(-Math.max(0, cal-1800)/600));
      activity=calP>0? Math.max(0.05, calP*0.5): null;
    }
  } else if(mvpaMin==null || mvpaMin===0){
    activity=stepsP;
  } else {
    activity=(isNum(stepsP)&&isNum(mvpaP))? (0.7*stepsP + 0.3*mvpaP): (stepsP ?? mvpaP);
  }
  if((mvpaMin==null || mvpaMin===0) && isNum(steps)){ if(steps>=7500 && isNum(activity)) activity=Math.max(activity, 0.40); }

  return { recovery, sleep: sleepP, activity, affect: null };
}

function aggregateRisk(groups, weights){
  const parts=[];
  for(const k of ["recovery","sleep","activity"]){
    const g=groups[k]; const w=Number(weights[k]??0);
    if(Number.isFinite(g) && w>0) parts.push({v:g,w});
  }
  if(!parts.length) return null;
  let score01=parts.reduce((s,x)=>s+x.v*x.w,0)/parts.reduce((s,x)=>s+x.w,0);
  if(parts.length===1) score01 = 0.7*score01 + 0.3*0.5; // neutral prior when only one core present
  return round(clamp01(1 - score01), 3);
}

function toVitalityDeltaYears(risk, { pivot_risk, scale_years }){
  if(!Number.isFinite(risk)||!Number.isFinite(pivot_risk)||!Number.isFinite(scale_years)) return null;
  return round((risk - pivot_risk)*scale_years, 2);
}

function blendTodayWithEMA(prev,today){
  if(!Number.isFinite(today)) return Number.isFinite(prev)? prev: null;
  if(!Number.isFinite(prev))  return today;
  return round(EMA_WEIGHT*prev + TODAY_WEIGHT*today, 3);
}
function updateEMA7(prevMap, inputs){
  const e={ ...(prevMap||{}) };
  const upd=(k,v)=>{ const x=Number(v); if(!Number.isFinite(x)) return; const p=Number(e?.[k]); e[k]=Number.isFinite(p)? round(p + EMA7_ALPHA*(x-p),3): round(x,3); };
  upd("hrv_rmssd_ms", inputs.hrv_rmssd_ms);
  upd("rhr_bpm",      inputs.rhr_bpm);
  upd("sleep_total_hours", inputs.sleep_total_hours);
  upd("steps_count",  inputs.steps_count);
  upd("mvpa_minutes", inputs.mvpa_minutes);
  return e;
}

/* ───────── Confidence helpers (with context dampeners) ───────── */

function daysBetweenKeys(aKey,bKey){
  if(!isDateKey(aKey)||!isDateKey(bKey)) return null;
  const a=parseDateKey(aKey); const b=parseDateKey(bKey);
  return Math.round((a-b)/(24*3600*1000));
}
function staleDaysForMetric(lastIso, dateKey, tz){
  if(!lastIso) return Infinity;
  const k=dateKeyInTZ(new Date(String(lastIso)), tz);
  if(!isDateKey(k)) return Infinity;
  const d=daysBetweenKeys(dateKey, k);
  return Math.max(0, Number.isFinite(d)? d: Infinity);
}
function computeExtrasPresenceFromAnchors(anchorsMerged){
  const hasCRF   = Number.isFinite(Number(anchorsMerged?.crf?.vo2max_ml_kg_min));
  const hasAnthro= Number.isFinite(Number(anchorsMerged?.anthro?.bmi)) ||
                   Number.isFinite(Number(anchorsMerged?.anthro?.whtr));
  const hasBP    = Number.isFinite(Number(anchorsMerged?.bp?.sys)) ||
                   Number.isFinite(Number(anchorsMerged?.bp?.dia));
  const hasGlu   = Number.isFinite(Number(anchorsMerged?.glucose?.mg_dl));
  const parts=[hasCRF, hasAnthro, hasBP, hasGlu];
  const count=parts.reduce((s,x)=>s+(x?1:0),0);
  const denom=parts.length||1;
  return clamp01(count/denom);
}

function applyContextDampeners(basePts, dayContext){
  if(!dayContext) return basePts;
  let penalty=0;
  if(dayContext.illness===true) penalty += CTX_PENALTIES.illness;
  if(dayContext.travel===true) penalty  += CTX_PENALTIES.travel;
  if(dayContext.menstrual_phase){ penalty += CTX_PENALTIES.menstrual_phase; }
  penalty = Math.min(CTX_PENALTY_CAP, penalty);
  return Math.max(0, basePts - penalty);
}

/**
 * confidence0to100_v1:
 * - Core completeness + freshness → up to 85 pts.
 * - Lagged steps (D-1) count as fresh for confidence when policy is "lag_yesterday".
 * - Extras bonus up to +15 from slow anchors presence.
 * - Optional context dampeners up to -15.
 * - Hard cap 95.
 */
function confidence0to100_v1({ inputs, lastMetricUtc, dateKey, tz, isProvisional, activity_policy, activity_from_date, anchorsExtrasPresence, context }){
  const core = {
    sleep: { present: isNum(inputs?.sleep_total_hours), staleDays: staleDaysForMetric(lastMetricUtc?.sleep_total_hours, dateKey, tz) },
    steps: { present: isNum(inputs?.steps_count),       staleDays: staleDaysForMetric(lastMetricUtc?.steps_count,       dateKey, tz) },
    rhr:   { present: isNum(inputs?.rhr_bpm),           staleDays: staleDaysForMetric(lastMetricUtc?.rhr_bpm,           dateKey, tz) },
    hrv:   { present: isNum(inputs?.hrv_rmssd_ms),      staleDays: staleDaysForMetric(lastMetricUtc?.hrv_rmssd_ms,      dateKey, tz) },
  };

  if(core.steps.present && activity_policy==="lag_yesterday" && isDateKey(activity_from_date) && activity_from_date===prevDateKey(dateKey)){
    core.steps.staleDays = 0;
  }

  const fresh = {
    sleep: core.sleep.present && core.sleep.staleDays<=1,
    steps: core.steps.present && core.steps.staleDays<=1,
    rhr:   core.rhr.present   && core.rhr.staleDays<=1,
    hrv:   core.hrv.present   && core.hrv.staleDays<=1,
  };

  let basePts=0;
  if(fresh.sleep) basePts += CONF_CORE.sleep.dur*100;
  if(fresh.steps) basePts += CONF_CORE.activity.steps*100;
  if(fresh.rhr)   basePts += CONF_CORE.recovery.rhr*100;
  if(fresh.hrv)   basePts += CONF_CORE.recovery.hrv*100;

  if(!isProvisional){
    const penaltyFor=(staleDays, subWeight)=>{ if(!Number.isFinite(staleDays)) return 0; if(staleDays>=4) return 25*subWeight; if(staleDays>=2) return 10*subWeight; return 0; };
    let stalePenalty=0;
    if(core.sleep.present) stalePenalty += penaltyFor(core.sleep.staleDays, CONF_CORE.sleep.dur);
    if(core.steps.present) stalePenalty += penaltyFor(core.steps.staleDays, CONF_CORE.activity.steps);
    if(core.rhr.present)   stalePenalty += penaltyFor(core.rhr.staleDays,   CONF_CORE.recovery.rhr);
    if(core.hrv.present)   stalePenalty += penaltyFor(core.hrv.staleDays,   CONF_CORE.recovery.hrv);
    basePts=Math.max(0, basePts - stalePenalty);
  }

  const extrasPresence = clamp01(Number(anchorsExtrasPresence)||0);
  const extrasBonusPts = Math.min(CONF_EXTRAS_BONUS_MAX, extrasPresence*CONF_EXTRAS_BONUS_MAX) * 100;

  let conf=basePts + extrasBonusPts;
  conf = applyContextDampeners(conf, context);
  return Math.round(clamp(conf, 0, CONF_MAX));
}

/* ───────── Baseline calibration ───────── */

async function readFixedBaseline(uid){
  const u=await db.doc(`users/${uid}`).get(); const d=u.exists?(u.data()||{}):{};
  return isNum(d?.baseline_vitality_age_years)? Number(d.baseline_vitality_age_years): null;
}

async function maybeCalibrateBaseline(uid, dateKey){
  const col=db.collection(`users/${uid}/days`);
  const snap=await col.orderBy(FieldPath.documentId()).endAt(dateKey).limitToLast(60).get();
  const finals=[];
  for(const doc of snap.docs){
    const row=doc.data()||{};
    if(String(row?.display?.status||"").toLowerCase()==="final" && isNum(row?.vitality_age)){
      finals.push({ id:doc.id, va:Number(row.vitality_age) });
    }
  }
  finals.sort((a,b)=>(a.id>b.id?1:-1));
  const tail=finals.slice(-30);
  let needed=0;
  if(tail.length>=14) needed=14;
  else if(tail.length>=10) needed=10;
  else if(tail.length>=7)  needed=7;
  if(!needed) return { baseline:null, daysUsed:tail.length, calibrated:false };

  const sample=tail.slice(-needed).map(x=>x.va).filter(Number.isFinite);
  if(sample.length<7) return { baseline:null, daysUsed:sample.length, calibrated:false };

  const med=median(sample);
  if(!Number.isFinite(med)) return { baseline:null, daysUsed:sample.length, calibrated:false };

  await db.doc(`users/${uid}`).set({ baseline_vitality_age_years: round(med,1) }, { merge:true });
  logger.info("[vitality] baseline calibrated",{uid, baseline:round(med,1), days:sample.length});
  return { baseline: round(med,1), daysUsed: sample.length, calibrated:true };
}

/* ───────── Dynamic sensitivity (last 30 FINAL days) ───────── */

async function computeDynamicFromLast30Finals(uid, dateKey){
  const cfg = await loadModelConfig("v1").catch(()=> ({}));
  const neutral = Number(cfg?.neutral_risk ?? DY_NEUTRAL_RISK_DEFAULT);
  const targetSpanYears = Number(cfg?.dynamic_target_span_years ?? DY_TARGET_SPAN_YEARS_DEFAULT);
  const minScale = Number(cfg?.dynamic_min_scale ?? DY_MIN_SCALE);
  const maxScale = Number(cfg?.dynamic_max_scale ?? DY_MAX_SCALE);
  const pivotMin = Number(cfg?.dynamic_pivot_min ?? DY_PIVOT_MIN);
  const pivotMax = Number(cfg?.dynamic_pivot_max ?? DY_PIVOT_MAX);
  const shrink = Number(cfg?.dynamic_pivot_shrink ?? DY_PIVOT_SHRINK);

  const col=db.collection(`users/${uid}/days`);
  const snap=await col.orderBy(FieldPath.documentId()).endAt(dateKey).limitToLast(40).get();
  const risks=[];
  for(const doc of snap.docs){
    const d=doc.data()||{};
    if(String(d?.display?.status||"").toLowerCase()==="final" && Number.isFinite(d?.risk_index)){
      risks.push({ id:doc.id, r: Number(d.risk_index) });
    }
  }
  risks.sort((a,b)=>(a.id>b.id?1:-1));
  const last30=risks.slice(-30);
  if(last30.length<14) return null; // need at least 14 finals to turn on dynamic

  const arr=last30.map(x=>x.r).filter(Number.isFinite);
  if(arr.length<10) return null;

  const p5 = pTile(arr, 0.05);
  const p95= pTile(arr, 0.95);
  const span = Math.max(0.02, Number(p95) - Number(p5)); // avoid divide-by-zero; enforce small min span
  const scale_years = clamp(targetSpanYears / span, minScale, maxScale);

  const med = median(arr);
  const pivot_risk = clamp(neutral + shrink*(med - neutral), pivotMin, pivotMax);

  return {
    window: { p5: round(p5,3), p95: round(p95,3), days: arr.length },
    scale_years: round(scale_years,2),
    pivot_risk: round(pivot_risk,3),
  };
}

/* ───────── Coverage & ensure last 14 ───────── */

function _last14Keys(tz){ const todayKey=dateKeyInTZ(new Date(), tz||DEFAULT_TZ); const keys=[]; let d=parseDateKey(todayKey); for(let i=0;i<14;i++){ keys.push(toKey(d)); d.setUTCDate(d.getUTCDate()-1);} keys.sort(); return keys; }

async function countSyncCoverageLast14(uid,{tz=DEFAULT_TZ}={}){
  const keys14=_last14Keys(tz);
  try{
    const col=db.collection(`users/${uid}/sync_days`);
    const snap=await col.where("date_local",">=",keys14[0]).where("date_local","<=",keys14[keys14.length-1]).get();
    const coveredSet=new Set();
    for(const doc of snap.docs){
      const d=doc.data()||{}; const k=String(d?.date_local||""); if(!isDateKey(k)) continue;
      const any=[ d?.last_steps_count_utc, d?.last_sleep_total_hours_utc, d?.last_rhr_bpm_utc, d?.last_hrv_rmssd_ms_utc, d?.last_distance_km_utc, d?.last_calories_out_utc, d?.last_mvpa_minutes_utc, d?.last_zone_minutes_total_utc ].some(Boolean);
      if(any) coveredSet.add(k);
    }
    let covered=0; for(const k of keys14){ if(coveredSet.has(k)) covered++; }
    return { covered, keys14 };
  }catch(e){ logger.warn("[coverage] sync_days coverage read failed",{uid,message:e?.message}); return { covered:0, keys14 }; }
}
async function countExistingDayDocsLast14(uid,{tz=DEFAULT_TZ}={}){
  const keys14=_last14Keys(tz);
  const col=db.collection(`users/${uid}/days`);
  const snap=await col.orderBy(FieldPath.documentId()).startAt(keys14[0]).endAt(keys14[keys14.length-1]).get();
  const have=new Set(snap.docs.map(d=>d.id)); let existing=0; for(const k of keys14){ if(have.has(k)) existing++; } return { existing, keys14 };
}
async function ensureFourteenDays(uid,{tz,policy="lag_yesterday"}){
  const todayKey=dateKeyInTZ(new Date(), tz||DEFAULT_TZ);
  const keys14=[]; let d=parseDateKey(todayKey); for(let i=0;i<14;i++){ keys14.push(toKey(d)); d.setUTCDate(d.getUTCDate()-1); } keys14.sort();
  const newest4=keys14.slice(-4); const rest=keys14.slice(0,-4);
  for(const k of newest4){ try{ await runVitalityForDay(uid,k,{tz,policy,force:true,allowZerosToday:false,updated_reason:"ensure14_priority"}); }catch(e){ logger.warn("ensure14 priority compute failed",{uid,k,message:e?.message}); } }
  for(const k of rest){ try{ await runVitalityForDay(uid,k,{tz,policy,force:true,allowZerosToday:false,updated_reason:"ensure14_tail"});}catch(e){ logger.warn("ensure14 tail compute failed",{uid,k,message:e?.message}); } }
  for(const k of keys14.slice(0,-1)){ try{ const snap=await db.doc(`users/${uid}/days/${k}`).get(); await finalizeOne(uid,k, snap.exists?(snap.data()||{}):{});}catch(e){ logger.warn("ensure14 finalize failed",{uid,k,message:e?.message}); } }
}

async function rebaselineSweep(uid, { tz=DEFAULT_TZ, n=14 }={}){
  const todayKey=dateKeyInTZ(new Date(), tz);
  const keys=[]; let d=parseDateKey(todayKey); for(let i=0;i<n;i++){ keys.push(toKey(d)); d.setUTCDate(d.getUTCDate()-1); }
  keys.sort();
  for(const k of keys){ try{ await runVitalityForDay(uid,k,{ tz, policy:"lag_yesterday", force:true, allowZerosToday:false, updated_reason:"rebaseline_sweep" }); }catch(e){ logger.warn("rebaseline_sweep failed",{uid,k,message:e?.message}); } }
}

async function ensureIfCoverageLast14(uid,{tz=DEFAULT_TZ}={}){
  const {covered}=await countSyncCoverageLast14(uid,{tz}); if(covered<14) return {ok:true,ensured:false,reason:"coverage_lt_14"};
  const {existing}=await countExistingDayDocsLast14(uid,{tz}); if(existing>=14) return {ok:true,ensured:false,reason:"already_have_14"};
  await ensureFourteenDays(uid,{tz,policy:"lag_yesterday"}); return {ok:true,ensured:true};
}

/* ───────── Freshness helpers ───────── */

function hasMissingCore(d){
  if(!d) return true;
  const used=d?.inputs?.used||{};
  for(const k of ["sleep_total_hours","rhr_bpm","steps_count"]){ if(!Number.isFinite(Number(used?.[k]))) return true; }
  return false;
}
function isVendorNewerThanCompute(dayDoc){
  if(!dayDoc) return false;
  const computed=dayDoc?.computed_at_utc;
  const prevMs=(computed&&computed.toDate)? computed.toDate().getTime() : (computed? Date.parse(computed): 0);
  if(!prevMs) return false;
  const prov=dayDoc?.last_provider_sample_utc||{};
  const metric=dayDoc?.last_metric_sample_utc||{};
  let latestStr="";
  for(const v of Object.values(prov)){ const s=String(v||""); if(s>latestStr) latestStr=s; }
  for(const v of Object.values(metric)){ const s=String(v||""); if(s>latestStr) latestStr=s; }
  if(!latestStr) return false;
  const latestMs=Date.parse(latestStr);
  return Number.isFinite(latestMs)&&latestMs>prevMs+5000;
}
function requestPasses(req){ return !!(ENV.SYNC_SHARED_SECRET && req.get("x-sync-secret")===ENV.SYNC_SHARED_SECRET); }

/* ───────── HTTP endpoints ───────── */

export const vitalityComputeHttp = onRequest({ region: REGION, cors:true }, async (req,res)=>{
  try{
    const fromApp=await verifyAppCheckOrScheduler(req);
    const fromSecret=requestPasses(req);
    if(!(fromApp||fromSecret)) return res.status(401).json({ok:false, error:"unauthorized_app_check_or_secret"});
    if(req.method!=="POST") return res.status(405).json({ok:false, error:"Use POST"});

    const b=(req.body&&typeof req.body==="object")? req.body: {};
    const uid=String(b.uid||b.userId||"").trim();
    if(!uid) return res.status(400).json({ok:false, error:"missing uid"});

    const tz=String(b.tz||DEFAULT_TZ);
    const policy=String(b.policy||"lag_yesterday");
    const force=!!b.force;
    const allowZerosToday=!!b.allowZerosToday;

    try{ await ensureThirtyDayCoverageForUid(uid,{ includeCrf:true, backfill:true, lookbackDays:14 }); }catch(e){ logger.warn("ensureCoverage warning",{uid,message:e?.message}); }
    try{ await ensureIfCoverageLast14(uid,{tz}); }catch(e){ logger.warn("ensureIfCoverageLast14 warning",{uid,message:e?.message}); }

    let date_local=String(b.date_local||"").trim();
    if(!isDateKey(date_local)) date_local=dateKeyInTZ(new Date(), tz);

    const out=await runVitalityForDay(uid, date_local, { tz, policy, force, allowZerosToday, updated_reason:"compute_http" });
    return res.status(out.ok?200:500).json(out);
  }catch(e){
    logger.error("vitalityComputeHttp error",{message:e?.message, stack:e?.stack});
    return res.status(500).json({ok:false, error:String(e?.message||e)});
  }
});

export const vitalityComputeRangeHttp = onRequest({ region: REGION, cors:true }, async (req,res)=>{
  try{
    const fromApp=await verifyAppCheckOrScheduler(req);
    const fromSecret=requestPasses(req);
    if(!(fromApp||fromSecret)) return res.status(401).json({ok:false, error:"unauthorized_app_check_or_secret"});
    if(req.method!=="POST") return res.status(405).json({ok:false, error:"Use POST"});

    const b=(req.body&&typeof req.body==="object")? req.body: {};
    const uid=String(b.uid||b.userId||"").trim();
    if(!uid) return res.status(400).json({ok:false, error:"missing uid"});

    const tz=String(b.tz||DEFAULT_TZ);
    const policy=String(b.policy||"lag_yesterday");
    const force=!!b.force;

    try{ await ensureThirtyDayCoverageForUid(uid,{ includeCrf:true, backfill:true, lookbackDays:14 }); }catch(e){ logger.warn("ensureCoverage warning",{uid,message:e?.message}); }
    try{ await ensureIfCoverageLast14(uid,{tz}); }catch(e){ logger.warn("ensureIfCoverageLast14 warning",{uid,message:e?.message}); }

    const date_keys=Array.isArray(b.date_keys)? uniqSortKeys(b.date_keys): null;
    const start_key=isDateKey(b.start_key)? b.start_key: null;
    const end_key=  isDateKey(b.end_key)?   b.end_key:   null;
    const daysN=Number.isFinite(Number(b.days))? Math.max(1, Math.min(120, Number(b.days))) : null;
    const keys=await resolveRangeKeys({ tz, date_keys, start_key, end_key, daysN });

    const newestFirst=keys.slice().sort().reverse();
    const priority=newestFirst.slice(0, Math.max(ENV.BACKFILL_RECENT_N,4)).slice().sort();
    const rest=keys.filter(k=>!priority.includes(k));
    const ordered=[...priority, ...rest];

    const results=[]; let skipped_final=0;
    for(const k of ordered){
      const snap=await db.doc(`users/${uid}/days/${k}`).get();
      const isFinal=String(snap.data()?.display?.status||"").toLowerCase()==="final";
      const missing=hasMissingCore(snap.data());
      if(isFinal && !force && !missing){ skipped_final++; results.push({date_key:k, ok:true, no_op:true, reason:"already_final"}); continue; }
      try{ const r=await runVitalityForDay(uid,k,{ tz, policy, force:true, allowZerosToday:false, updated_reason:"range_http" }); results.push({ date_key:k, ...r }); }
      catch(e){ results.push({ date_key:k, ok:false, error:String(e?.message||e) }); }
    }

    const computed=results.filter(r=>r.ok && !r.no_op).length;
    const errors=  results.filter(r=>!r.ok).length;
    return res.status(errors?207:200).json({ ok: errors===0, total: keys.length, computed, skipped_final, errors, results });
  }catch(e){
    logger.error("vitalityComputeRangeHttp error",{message:e?.message, stack:e?.stack});
    return res.status(500).json({ok:false, error:String(e?.message||e)});
  }
});

export const ensureCoverageHttp = onRequest({ region: REGION, cors:true }, async (req,res)=>{
  try{
    const fromApp=await verifyAppCheckOrScheduler(req);
    const fromSecret=requestPasses(req);
    if(!(fromApp||fromSecret)) return res.status(401).json({ok:false, error:"unauthorized_app_check_or_secret"});
    if(req.method!=="POST") return res.status(405).json({ok:false, error:"Use POST"});

    const b=(req.body&&typeof req.body==="object")? req.body: {};
    const uid=String(b.uid||b.userId||"").trim();
    if(!uid) return res.status(400).json({ok:false, error:"missing uid"});

    const tz=String(b.tz||DEFAULT_TZ);

    const ensure = await ensureThirtyDayCoverageForUid(uid,{ includeCrf:true, backfill:true, lookbackDays:14 });
    await ensureFourteenDays(uid,{ tz, policy:"lag_yesterday" });

    const todayKey=dateKeyInTZ(new Date(), tz);
    const { calibrated } = await maybeCalibrateBaseline(uid, todayKey);
    if(calibrated){ await rebaselineSweep(uid,{ tz, n:14 }); }

    return res.status(200).json({ ok:true, ...ensure, ensured_days:14, rebaseline_ran: !!calibrated });
  }catch(e){
    logger.error("ensureCoverageHttp error",{message:e?.message, stack:e?.stack});
    return res.status(500).json({ok:false, error:String(e?.message||e)});
  }
});

export const vitalityMethodsHttp = onRequest({ region: REGION, cors:true }, async (_req,res)=>{
  try{
    const cfg=await loadModelConfig("v1").catch(()=> ({}));
    const methods={
      model_version:"v1",
      compute_engine_version: COMPUTE_ENGINE_VERSION,
      groups_weights: {
        recovery: Number(cfg?.groups?.recovery ?? 0.35),
        sleep:    Number(cfg?.groups?.sleep    ?? 0.30),
        activity: Number(cfg?.groups?.activity ?? 0.20),
        affect: 0.0,
      },
      risk_blend_today_vs_ema7: { today: TODAY_WEIGHT, ema7: EMA_WEIGHT },
      daily_delta_cap_years: DAILY_DELTA_CAP_YEARS,
      total_delta_cap_from_baseline: TOTAL_DELTA_CAP_FROM_BASELINE,
      ramp: {
        days: RAMP_DAYS, min_factor: RAMP_MIN_FACTOR, daily_cap_ramp: DAILY_DELTA_CAP_RAMP,
        total_caps: { d0_14: TOTAL_CAP_RAMP_0_14, d15_29: TOTAL_CAP_RAMP_15_29 }
      },
      confidence: { max: CONF_MAX, core_weights: CONF_CORE, extras_bonus_max: CONF_EXTRAS_BONUS_MAX },
      dynamic_defaults: {
        target_span_years: DY_TARGET_SPAN_YEARS_DEFAULT,
        min_scale: DY_MIN_SCALE, max_scale: DY_MAX_SCALE,
        pivot_min: DY_PIVOT_MIN, pivot_max: DY_PIVOT_MAX, neutral_risk: DY_NEUTRAL_RISK_DEFAULT,
        pivot_shrink: DY_PIVOT_SHRINK,
      },
      updated_at_utc: new Date().toISOString(),
    };
    return res.status(200).json({ ok:true, methods });
  }catch(e){
    logger.error("vitalityMethodsHttp error",{message:e?.message});
    return res.status(500).json({ok:false, error:String(e?.message||e)});
  }
});

/* ───────── Run one day ───────── */

async function writeSkeletonDay(uid, dateKey, { tz, updated_reason }){
  const ref=db.doc(`users/${uid}/days/${dateKey}`);
  const now=new Date();
  await ref.set({
    date_local: dateKey, tz, model_version:"v1", compute_engine_version:COMPUTE_ENGINE_VERSION,
    display:{ status:"provisional" },
    computed_at_utc: FieldValue.serverTimestamp(),
    computed_reason: updated_reason,
    updated_at_utc: now.toISOString(),
    updated_at_local: formatLocal(now, tz),
    updated_reason
  }, { merge:true });
  return { ok:true, date_key:dateKey, no_op:true, reason:"no_core_data_skeleton" };
}

function computeDrivers(groups, weights, risk_index){
  // risk_index ≈ 1 - Σ(g_i*w_i)/Σw; attribute contribution_i ≈ (1 - g_i)*w_i / Σw (scaled to sum to risk_index)
  const den = Object.values(weights).reduce((s,w)=>s+Number(w||0),0) || 1;
  const raw = {};
  let sumRaw = 0;
  for(const k of ["recovery","sleep","activity"]){
    const g = Number.isFinite(groups[k]) ? Number(groups[k]) : null;
    const w = Number(weights[k]||0);
    if(g==null || w<=0) continue;
    const c = (1 - g) * (w/den);
    raw[k]=c; sumRaw+=c;
  }
  const drivers={};
  if(sumRaw>0 && Number.isFinite(risk_index)){
    for(const k of Object.keys(raw)){ drivers[k]=round(risk_index * (raw[k]/sumRaw), 3); }
  }
  return drivers;
}
function computeEffectiveWeights(weights, fresh){
  const wused = { ...weights };
  const eff = { recovery:0, sleep:0, activity:0 };
  // consider domain present if its primary signal is fresh
  if(fresh?.rhr_bpm || fresh?.hrv_rmssd_ms) eff.recovery = Number(weights.recovery||0);
  if(fresh?.sleep_total_hours) eff.sleep = Number(weights.sleep||0);
  if(fresh?.steps_count) eff.activity = Number(weights.activity||0);
  const sumDecl = Object.values(weights).reduce((s,w)=>s+Number(w||0),0) || 1;
  const sumEff = Object.values(eff).reduce((s,w)=>s+Number(w||0),0);
  const wused_effective = {
    recovery: round(eff.recovery,3),
    sleep:    round(eff.sleep,3),
    activity: round(eff.activity,3),
  };
  const weightsObservedFrac = round(sumEff / sumDecl, 3);
  return { wused, wused_effective, weightsObservedFrac };
}

async function runVitalityForDay(uid, dateKey, { tz=DEFAULT_TZ, policy="lag_yesterday", force=false, allowZerosToday=false, updated_reason="compute" } = {}){
  if(!uid) throw new Error("missing uid");
  if(!isDateKey(dateKey)) throw new Error("invalid dateKey");
  const lease=await acquireDayLease(uid,dateKey,{ttlMs:90_000});
  if(!lease.ok) return { ok:true, date_key:dateKey, no_op:true, reason:"lease_held" };

  try{
    try{ await mergeDailyFromVendors(uid, dateKey, { allowZerosToday, tz }); }catch(e){ logger.warn("mergeDailyFromVendors failed",{uid,dateKey,message:e?.message}); }
    const ref=db.doc(`users/${uid}/days/${dateKey}`);
    const beforeSnap=await ref.get(); const before=beforeSnap.exists?(beforeSnap.data()||{}):{};

    const profile=await readUserProfile(uid);
    const userTz=profile?.tz || tz;
    const anthro=computeAnthro(profile);
    const { age_years }=computeChronoAgeOn(profile?.dobDate, dateKey);

    // Resolve activity (locked: lag_yesterday or fallback)
    const act=await resolveActivityInputs(uid, dateKey, { policy, tz:userTz, userProfile: profile });

    // Reload after merge
    const curSnap=await ref.get(); const cur=curSnap.exists?(curSnap.data()||{}):before;
    const isProvisional=isTodayLocal(dateKey, userTz);

    const used={ ...(cur?.inputs?.used||{}) };
    const inputsToday={
      sleep_total_hours: numOrNull(used.sleep_total_hours),
      hrv_rmssd_ms:     numOrNull(used.hrv_rmssd_ms),
      rhr_bpm:          numOrNull(used.rhr_bpm),
      steps_count:      numOrNull(act?.steps_count ?? used.steps_count),
      calories_out:     numOrNull(act?.calories_out ?? used.calories_out),
      distance_km:      numOrNull(act?.distance_km ?? used.distance_km),
      mvpa_minutes:     numOrNull(act?.mvpa_minutes ?? used.mvpa_minutes),
    };

    const missing={ sleep_total_hours: !isNum(inputsToday.sleep_total_hours), steps_count: !isNum(inputsToday.steps_count), rhr_bpm: !isNum(inputsToday.rhr_bpm) };
    if(missing.sleep_total_hours && missing.steps_count && missing.rhr_bpm){ return await writeSkeletonDay(uid, dateKey, { tz:userTz, updated_reason }); }

    // EMA7 + blended
    const ema7Prev=cur?.ema7||null;
    const ema7=updateEMA7(ema7Prev, inputsToday);
    const blended={
      hrv_rmssd_ms:     blendTodayWithEMA(ema7Prev?.hrv_rmssd_ms,    inputsToday.hrv_rmssd_ms),
      rhr_bpm:          blendTodayWithEMA(ema7Prev?.rhr_bpm,         inputsToday.rhr_bpm),
      sleep_total_hours:blendTodayWithEMA(ema7Prev?.sleep_total_hours, inputsToday.sleep_total_hours),
      steps_count:      blendTodayWithEMA(ema7Prev?.steps_count,      inputsToday.steps_count),
      mvpa_minutes:     blendTodayWithEMA(ema7Prev?.mvpa_minutes,     inputsToday.mvpa_minutes),
      calories_out:     inputsToday.calories_out,
      distance_km:      inputsToday.distance_km,
      ema7_hrv:         ema7Prev?.hrv_rmssd_ms,
      ema7_rhr:         ema7Prev?.rhr_bpm,
    };

    // Groups + risk
    const cfg=await loadModelConfig("v1").catch(()=> ({}));
    const weights={ recovery:Number(cfg?.groups?.recovery ?? 0.35), sleep:Number(cfg?.groups?.sleep ?? 0.30), activity:Number(cfg?.groups?.activity ?? 0.20), affect:0.0 };
    let groups=computeGroups(blended);
    let risk=aggregateRisk(groups, weights);

    // Anchors merged: stored + profile-derived anthro + demographics
    const anchorsStored=await loadAnchors(uid).catch(()=> null);
    const anchorsMerged={
      ...(anchorsStored||{}),
      anthro: {
        ...(anchorsStored?.anthro||{}),
        bmi:  Number.isFinite(anthro?.bmi)? anthro.bmi : anchorsStored?.anthro?.bmi,
        whtr: Number.isFinite(anthro?.waist_to_height)? anthro.waist_to_height : anchorsStored?.anthro?.whtr,
      },
      demographics: {
        ...(anchorsStored?.demographics||{}),
        sex: profile?.gender ?? anchorsStored?.demographics?.sex ?? null,
        dob_iso: profile?.dobDate ? profile.dobDate.toISOString().slice(0,10) : (anchorsStored?.demographics?.dob_iso ?? null),
      },
      bp: anchorsStored?.bp || null,
      glucose: anchorsStored?.glucose || null,
      crf: anchorsStored?.crf || null,
    };

    // Anchors → RISK via computeSlowAnchorsContrib
    const anchorsContrib=computeSlowAnchorsContrib(anchorsMerged||{}, cfg||{});
    const wA=clamp01(Number(anchorsContrib?.blended?.weight_sum || 0));
    if(wA>0 && Number.isFinite(Number(anchorsContrib?.blended?.risk)) && Number.isFinite(risk)){
      risk=round((1-wA)*risk + wA*Number(anchorsContrib.blended.risk), 3);
    }

    // Pivot/scale & ramp (dynamic sensitivity layer if available; baseline remains fixed)
    const fixedScale=Number(cfg?.scale_years ?? 12);
    const fixedPivot=Number(cfg?.pivot_risk ?? DY_NEUTRAL_RISK_DEFAULT);
    const daysValid=await countRecentValidDays(uid, dateKey);
    const inRamp=daysValid < RAMP_DAYS;

    let dynamic_used = null;
    try{ dynamic_used = await computeDynamicFromLast30Finals(uid, dateKey); }catch(e){ logger.warn("dynamic compute failed",{uid,dateKey,message:e?.message}); }

    const pivot_risk = dynamic_used?.pivot_risk ?? clamp(Number.isFinite(fixedPivot)? fixedPivot : DY_NEUTRAL_RISK_DEFAULT, inRamp?0.22:0.20, inRamp?0.35:0.60);
    const scale_years = dynamic_used?.scale_years ?? fixedScale;

    let va_delta_years_raw=toVitalityDeltaYears(risk, { pivot_risk, scale_years });

    // Confidence (with context dampeners)
    const anchorsExtrasPresence = computeExtrasPresenceFromAnchors(anchorsMerged);
    const dayContext = cur?.context || null; // optional { illness, travel, menstrual_phase }
    const score_confidence=confidence0to100_v1({
      inputs: blended,
      lastMetricUtc: cur?.last_metric_sample_utc||{},
      dateKey, tz:userTz, isProvisional: isProvisional,
      activity_policy: act?.provenance?.activity_policy || policy,
      activity_from_date: act?.provenance?.from_date || null,
      anchorsExtrasPresence,
      context: dayContext
    });

    // Apply ramp & confidence gate
    const rampFactor=inRamp? clamp((daysValid/RAMP_DAYS), RAMP_MIN_FACTOR, 1.0) : 1.0;
    const confFactor=clamp(score_confidence/100, 0, 1);
    let va_delta_years = Number.isFinite(va_delta_years_raw) ? round(va_delta_years_raw*rampFactor*confFactor, 2) : null;

    // Baseline
    let baseline_va=await readFixedBaseline(uid);
    if(!Number.isFinite(baseline_va)){
      const { baseline, calibrated } = await maybeCalibrateBaseline(uid, dateKey);
      baseline_va=Number.isFinite(baseline)? Number(baseline): null;
      if(calibrated){ rebaselineSweep(uid,{ tz:userTz, n:14 }).catch(()=>{}); }
    }

    // Visible vitality age
    const chronoAge=Number(age_years);
    const chronoAnchored=(Number.isFinite(chronoAge)&&Number.isFinite(va_delta_years))? round(chronoAge+va_delta_years,1): null;
    let vitality_age=null;
    if(inRamp){
      const blendW=clamp(daysValid/RAMP_DAYS,0,1);
      if(Number.isFinite(baseline_va)&&Number.isFinite(va_delta_years)){
        const baselineAnchored=round(baseline_va+va_delta_years,1);
        vitality_age = Number.isFinite(chronoAnchored)? round((1-blendW)*chronoAnchored + (1-blendW>=0?blendW:0)*baselineAnchored,1) : baselineAnchored;
      } else vitality_age=chronoAnchored;
    }else{
      if(Number.isFinite(va_delta_years)&&Number.isFinite(baseline_va)) vitality_age=round(baseline_va+va_delta_years,1);
      else if(Number.isFinite(chronoAnchored)) vitality_age=chronoAnchored;
    }

    // Caps
    if(Number.isFinite(vitality_age)){
      if(inRamp && Number.isFinite(chronoAge)){
        const totalCap = daysValid<=14 ? TOTAL_CAP_RAMP_0_14 : TOTAL_CAP_RAMP_15_29;
        vitality_age = clamp(vitality_age, chronoAge-totalCap, chronoAge+totalCap);
      } else if(Number.isFinite(baseline_va)){
        vitality_age = clamp(vitality_age, baseline_va-TOTAL_DELTA_CAP_FROM_BASELINE, baseline_va+TOTAL_DELTA_CAP_FROM_BASELINE);
      }
    }

    // Cross-day daily cap
    const prevKey=prevDateKey(dateKey);
    if(prevKey){
      const ps=await db.doc(`users/${uid}/days/${prevKey}`).get();
      const pd=ps.exists?(ps.data()||{}):{};
      if(Number.isFinite(pd?.vitality_age) && Number.isFinite(vitality_age)){
        const d=vitality_age-Number(pd.vitality_age);
        const cap=inRamp? DAILY_DELTA_CAP_RAMP: DAILY_DELTA_CAP_YEARS;
        if(Math.abs(d)>cap) vitality_age=round(Number(pd.vitality_age)+Math.sign(d)*cap,1);
      }
    }

    // Cooldown gate
    const vendorNewer=isVendorNewerThanCompute(cur);
    const activity_policy=act?.provenance?.activity_policy || policy;
    const activity_from_date=act?.provenance?.from_date || null;
    const activity_window_from_utc = act?.provenance?.activity_window_from_utc || null;
    const activity_window_to_utc   = act?.provenance?.activity_window_to_utc   || null;

    const compute_signature=JSON.stringify({
      date_key:dateKey,
      inputs_sig:{ slp:blended.sleep_total_hours, hrv:blended.hrv_rmssd_ms, rhr:blended.rhr_bpm, stp:blended.steps_count, cal:blended.calories_out, dist:blended.distance_km, mvpa:blended.mvpa_minutes },
      pivot_risk, scale_years, rampFactor,
      dailyCap: inRamp?DAILY_DELTA_CAP_RAMP:DAILY_DELTA_CAP_YEARS,
      totalCap: inRamp? (daysValid<=14?TOTAL_CAP_RAMP_0_14:TOTAL_CAP_RAMP_15_29) : TOTAL_DELTA_CAP_FROM_BASELINE
    });

    const updatedIsBypass=/ensure14|startup|rebaseline/i.test(String(updated_reason||""));
    if(!force && ENV.COOLDOWN_MINUTES>0 && curSnap.exists && !vendorNewer && !updatedIsBypass){
      const prevSig=String(cur?.compute_signature||"");
      const prevTs=cur?.computed_at_utc;
      const nowMs=Date.now();
      const prevMs=(prevTs&&prevTs.toDate)? prevTs.toDate().getTime(): (prevTs? Date.parse(prevTs): 0);
      const ageMin=prevMs? (nowMs - prevMs)/60000 : Infinity;
      const hadMissingBefore=hasMissingCore(cur);
      const missingNow=missing.sleep_total_hours || missing.steps_count || missing.rhr_bpm;
      if(prevSig===compute_signature && ageMin<ENV.COOLDOWN_MINUTES && !hadMissingBefore && !missingNow){
        return { ok:true, date_key:dateKey, no_op:true, reason:`cooldown_${Math.floor(ageMin)}m` };
      }
    }

    // Fresh/stale for UI (UI “todayness” stays false for lag)
    const lastUtc=cur?.last_metric_sample_utc||{};
    const fresh={
      sleep_total_hours: staleDaysForMetric(lastUtc?.sleep_total_hours, dateKey, userTz)<=1,
      rhr_bpm:           staleDaysForMetric(lastUtc?.rhr_bpm,           dateKey, userTz)<=1,
      hrv_rmssd_ms:      staleDaysForMetric(lastUtc?.hrv_rmssd_ms,      dateKey, userTz)<=1,
      steps_count:       false,
    };
    if(activity_policy!=="lag_yesterday" || (activity_policy==="lag_yesterday" && activity_from_date===dateKey)){
      fresh.steps_count = staleDaysForMetric(lastUtc?.steps_count, dateKey, userTz)<=1;
    }
    const stale_days={
      sleep_total_hours: staleDaysForMetric(lastUtc?.sleep_total_hours, dateKey, userTz),
      rhr_bpm:           staleDaysForMetric(lastUtc?.rhr_bpm,           dateKey, userTz),
      hrv_rmssd_ms:      staleDaysForMetric(lastUtc?.hrv_rmssd_ms,      dateKey, userTz),
      steps_count:       staleDaysForMetric(lastUtc?.steps_count,       dateKey, userTz),
    };

    // Slow anchors brief
    const crf={};
    const storedVo2=anchorsMerged?.crf?.vo2max_ml_kg_min;
    if(Number.isFinite(Number(storedVo2))){ crf.vo2max_ml_kg_min=Number(storedVo2); if(anchorsMerged?.crf?.last_updated_utc) crf.last_updated_utc=String(anchorsMerged.crf.last_updated_utc); }
    const anchors_brief={};
    if(Number.isFinite(Number(anthro?.bmi))) anchors_brief.bmi=Number(anthro.bmi);
    if(Number.isFinite(Number(anthro?.waist_to_height)) && Number(anthro.waist_to_height)>0) anchors_brief.whtr=Number(anthro.waist_to_height);
    if(Number.isFinite(Number(anchorsMerged?.bp?.sys))) anchors_brief.bp_sys=Number(anchorsMerged.bp.sys);
    if(Number.isFinite(Number(anchorsMerged?.bp?.dia))) anchors_brief.bp_dia=Number(anchorsMerged.bp.dia);
    if(Number.isFinite(Number(anchorsMerged?.glucose?.mg_dl))) anchors_brief.glucose_mg_dl=Number(anchorsMerged.glucose.mg_dl);
    if(anchorsMerged?.last_updated_utc) anchors_brief.last_updated_utc=String(anchorsMerged.last_updated_utc);

    const healthy_days_30=await computeHealthyDays30(uid, dateKey);

    // Transparency bundle
    const drivers = (Number.isFinite(risk) ? computeDrivers(groups, weights, risk) : {});
    const { wused, wused_effective, weightsObservedFrac } = computeEffectiveWeights(weights, fresh);

    const now=new Date();

    // ── NEW: prepare display map with last-known fields when we have a real vitality_age
    const displayMap = {
      status: isProvisional ? "provisional" : (cur?.display?.status || "provisional"),
      ...(Number.isFinite(vitality_age) ? {
        last_known_vitality_age: vitality_age,
        last_known_at_key: dateKey,
      } : {})
    };

    const write={
      date_local: dateKey,
      tz: userTz,
      model_version:"v1",
      compute_engine_version: COMPUTE_ENGINE_VERSION,

      vitality_age: Number.isFinite(vitality_age)? vitality_age: null,
      baseline_vitality_age: Number.isFinite(profile?.baseline_vitality_age_years)? round(profile.baseline_vitality_age_years,1): null,

      risk_index: Number.isFinite(risk)? risk: null,
      score_confidence: Number.isFinite(score_confidence)? score_confidence: null,
      healthy_days_30: Number.isFinite(healthy_days_30)? healthy_days_30: null,

      inputs: { ...(cur?.inputs||{}), used: inputsToday, manual: { ...(cur?.inputs?.manual||{}) } },
      sources: cur?.sources || {},
      ema7,

      fresh, stale_days,

      ...(Object.keys(crf).length? { crf }: {}),
      ...(Object.keys(anchors_brief).length? { anchors_brief }: {}),

      activity_policy,
      activity_from_date,
      ...(activity_window_from_utc && activity_window_to_utc ? {
        activity_window_from_utc, activity_window_to_utc
      } : {}),

      // Transparency
      drivers: Object.keys(drivers).length? drivers : FieldValue.delete(),
      wused,
      wused_effective,
      weightsObservedFrac,

      // Dynamic sensitivity used today (soft layer, baseline unchanged)
      ...(dynamic_used ? { dynamic_used } : {}),

      compute_signature,
      display: displayMap,

      computed_at_utc: FieldValue.serverTimestamp(),
      computed_reason: updated_reason,
      updated_at_utc: now.toISOString(),
      updated_at_local: formatLocal(now, userTz),
      updated_reason,
      last_provider_sample_utc: cur?.last_provider_sample_utc || {},
      last_metric_sample_utc:   cur?.last_metric_sample_utc   || {},
    };

    try{ await heartbeatDayLease(uid, dateKey, (await acquireDayLease(uid,dateKey,{ttlMs:1})).token, { extendMs:1 }); }catch{}
    await ref.set(write,{merge:true});

    return {
      ok:true, date_key:dateKey,
      vitality_age: write.vitality_age,
      baseline_vitality_age: write.baseline_vitality_age,
      risk_index: write.risk_index,
      score_confidence: write.score_confidence,
      healthy_days_30: write.healthy_days_30,
      no_op:false
    };
  } finally {
    try{ await releaseDayLease(uid, dateKey, lease.token); }catch{}
  }
}

/* ───────── Healthy Days 30 helper ───────── */

async function computeHealthyDays30(uid, dateKey){
  const keys=[]; let d=parseDateKey(dateKey); for(let i=0;i<30;i++){ keys.push(toKey(d)); d.setUTCDate(d.getUTCDate()-1); }
  const col=db.collection(`users/${uid}/days`);
  const snap=await col.orderBy(FieldPath.documentId()).startAt(keys[keys.length-1]).endAt(keys[0]).get();
  let count=0;
  for(const doc of snap.docs){
    const row=doc.data()||{};
    if(String(row?.display?.status||"").toLowerCase()==="final" && Number.isFinite(row?.risk_index)){
      if(row.risk_index<=0.40) count++;
    }
  }
  return count;
}

/* ───────── Finalize ───────── */

export const vitalityFinalizeDaily = onSchedule(
  { region: REGION, schedule:"every day 03:00", timeZone: DEFAULT_TZ },
  async ()=>{
    const now=new Date();
    const keys=[1,2].map(i=> dateKeyInTZ(new Date(now.getTime()-i*86400000), DEFAULT_TZ));
    let touched=0;
    for(const key of keys){
      const cg=await db.collectionGroup("days").where("date_local","==",key).get();
      for(const doc of cg.docs){
        const uid=doc.ref.parent.parent.id;
        const data=doc.data()||{};
        if(String(data?.display?.status||"").toLowerCase()==="final") continue;
        try{ await finalizeOne(uid,key,data); touched++; }catch(e){ logger.error("finalizeOne failed",{uid,key,message:e?.message}); }
      }
    }
    logger.info("[vitality] finalize sweep finished",{daysTouched:touched});
    return {ok:true, daysTouched:touched};
  }
);

function isFinalizeDue(dateKey, tz){
  const now=new Date(); const nowKey=dateKeyInTZ(now, tz);
  const d=parseDateKey(dateKey); d.setUTCDate(d.getUTCDate()+1);
  const dPlus1Key=dateKeyInTZ(d, tz);
  if(nowKey>dPlus1Key) return true;
  if(nowKey<dPlus1Key) return false;
  const hour=Number(new Intl.DateTimeFormat("en-GB",{timeZone:tz, hour:"2-digit", hour12:false}).format(now));
  return hour>=FINALIZE_HOUR_LOCAL;
}
async function finalizeOne(uid, dateKey, _dToday){
  const tz=_dToday?.tz || DEFAULT_TZ;
  if(!isFinalizeDue(dateKey, tz)) return;
  const ref=db.doc(`users/${uid}/days/${dateKey}`);
  await ref.set({ display:{ status:"final" }, finalized_at_utc: FieldValue.serverTimestamp() }, { merge:true });

  // Best-effort: update healthy_days_30 on today as well
  const todayKey=dateKeyInTZ(new Date(), tz);
  const target=(todayKey===dateKey)? dateKey: todayKey;
  try{ const hd=await computeHealthyDays30(uid, target); await db.doc(`users/${uid}/days/${target}`).set({ healthy_days_30: hd }, { merge:true }); }catch{}
}

/* ───────── Range resolver & helpers ───────── */

async function resolveRangeKeys({ tz, date_keys, start_key, end_key, daysN }){
  if(Array.isArray(date_keys)&&date_keys.length) return uniqSortKeys(date_keys);
  if(isDateKey(start_key)&&isDateKey(end_key)&&start_key<=end_key){
    const out=[]; let d=parseDateKey(start_key); const end=parseDateKey(end_key);
    while(d<=end){ out.push(toKey(d)); d.setUTCDate(d.getUTCDate()+1); }
    return out;
  }
  const n=daysN||14;
  const todayKey=dateKeyInTZ(new Date(), tz||DEFAULT_TZ);
  const out=[]; let d=parseDateKey(todayKey);
  for(let i=0;i<n;i++){ out.push(toKey(d)); d.setUTCDate(d.getUTCDate()-1); }
  out.sort(); return out;
}

async function countRecentValidDays(uid, dateKey){
  const col=db.collection(`users/${uid}/days`);
  const snap=await col.orderBy(FieldPath.documentId()).endAt(dateKey).limitToLast(40).get();
  let n=0;
  for(const doc of snap.docs){
    const d=doc.data()||{};
    const used=d?.inputs?.used||{};
    if(isNum(used?.sleep_total_hours) || isNum(used?.steps_count) || isNum(used?.rhr_bpm) || isNum(used?.hrv_rmssd_ms)) n++;
  }
  return n;
}
