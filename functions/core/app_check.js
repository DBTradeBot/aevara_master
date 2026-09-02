// functions/core/app_check.js
// ESM helper for verifying Firebase App Check (token header) OR Cloud Scheduler OIDC (strict).
// Node 20 / Firebase Admin v12+
//
// Requires: google-auth-library
//   npm i google-auth-library
//
// Usage (inside HTTPS handlers):
//   import { verifyAppCheckOrScheduler } from "../core/app_check.js";
//   const ok = await verifyAppCheckOrScheduler(req);
//   if (!ok) return res.status(401).json({ ok:false, error:"invalid_app_check" });

import { getAppCheck } from "firebase-admin/app-check";
import { OAuth2Client } from "google-auth-library";

/**
 * Verify App Check header or Cloud Scheduler OIDC (strict).
 * Returns true if verified, false if not.
 */
export async function verifyAppCheckOrScheduler(
  req,
  {
    allowedServiceAccounts = process.env.SCHEDULER_SA_EMAIL
      ? [String(process.env.SCHEDULER_SA_EMAIL)]
      : [],
  } = {}
) {
  // 1) Try Firebase App Check token
  const appCheckToken = req.get("X-Firebase-AppCheck");
  if (appCheckToken) {
    try {
      const appCheck = getAppCheck();
      await appCheck.verifyToken(appCheckToken);
      return true; // Verified via App Check
    } catch (e) {
      // fallthrough to OIDC path
    }
  }

  // 2) Strict Cloud Scheduler OIDC (Authorization: Bearer <JWT>)
  const auth = req.get("authorization") || req.get("Authorization") || "";
  const m = /^Bearer\s+(.+)$/.exec(auth);
  if (m && m[1]) {
    const idToken = m[1];

    // Expected audience = exact URL (no querystring)
    const proto = (req.get("x-forwarded-proto") || req.protocol || "https").split(",")[0].trim();
    const host = req.get("host");
    // originalUrl can include query "" strip it
    const pathOnly = String(req.originalUrl || req.url || "/").split("?")[0];
    const audience = `${proto}://${host}${pathOnly}`;

    const client = new OAuth2Client();
    try {
      const ticket = await client.verifyIdToken({
        idToken,
        audience, // must equal the function URL
      });
      const payload = ticket.getPayload() || {};
      const issuer = String(payload.iss || "");
      const email = String(payload.email || payload.sub || ""); // SA emails appear in 'email'
      // Must be Google issuer and a whitelisted service account if provided
      const issuerOk = issuer === "https://accounts.google.com";
      const saOk =
        allowedServiceAccounts.length === 0 ? true : allowedServiceAccounts.includes(email);
      if (issuerOk && saOk) return true;
    } catch (e) {
      // invalid OIDC or wrong audience/issuer/SA
    }
  }

  // Neither App Check nor OIDC verified
  return false;
}



