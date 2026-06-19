'use strict';

/**
 * verifyPurchase — server-side Google Play purchase validation.
 *
 * Callable Cloud Function (Firebase Functions v2). The client
 * (`GooglePlayBillingService` → `CloudFunctionsReceiptValidator`) sends the
 * Android purchaseToken; this function:
 *   1. requires an authenticated caller (Firebase Anonymous Auth UID),
 *   2. rejects tokens already bound to a different account (replay/fraud),
 *   3. verifies the token with the Google Play Developer API,
 *   4. grants the entitlement under `entitlements/{uid}` (idempotent),
 *   5. returns `{ valid, entitlements, errorCode?, message? }`.
 *
 * Acknowledgement is intentionally left to the client (`completePurchase`),
 * so this function only verifies + grants and never double-acknowledges.
 *
 * See docs/adr/003-billing-receipt-validation.md.
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { google } = require('googleapis');

initializeApp();
const db = getFirestore();

// The Android applicationId. Override via environment for stage/prod projects.
const ANDROID_PACKAGE_NAME =
  process.env.ANDROID_PACKAGE_NAME || 'com.luminablocks.app';

const androidPublisher = google.androidpublisher('v3');
const playAuth = new google.auth.GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/androidpublisher'],
});

exports.verifyPurchase = onCall({ region: 'us-central1' }, async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const data = request.data || {};
  const { platform, productId, purchaseToken } = data;
  const source = data.source || 'purchase';

  if (platform !== 'android') {
    throw new HttpsError('invalid-argument', 'Only the android platform is supported.');
  }
  if (typeof productId !== 'string' || !productId) {
    throw new HttpsError('invalid-argument', 'Missing productId.');
  }
  if (typeof purchaseToken !== 'string' || !purchaseToken) {
    throw new HttpsError('invalid-argument', 'Missing purchaseToken.');
  }

  // Replay / cross-account protection: a purchase token may only ever belong
  // to one account.
  const tokenRef = db.collection('purchaseTokens').doc(purchaseToken);
  const tokenSnap = await tokenRef.get();
  if (tokenSnap.exists && tokenSnap.get('uid') !== uid) {
    throw new HttpsError('permission-denied', 'Token is bound to another account.');
  }

  // Verify the token against the Google Play Developer API.
  let purchase;
  try {
    const client = await playAuth.getClient();
    const res = await androidPublisher.purchases.products.get({
      auth: client,
      packageName: ANDROID_PACKAGE_NAME,
      productId,
      token: purchaseToken,
    });
    purchase = res.data;
  } catch (error) {
    console.error('Play Developer API verification failed', error);
    return {
      valid: false,
      errorCode: 'play_verify_failed',
      message: (error && error.message) || 'verification_failed',
    };
  }

  // purchaseState: 0 = Purchased, 1 = Canceled, 2 = Pending.
  if (purchase.purchaseState !== 0) {
    return {
      valid: false,
      errorCode: 'not_purchased',
      message: `purchaseState=${purchase.purchaseState}`,
    };
  }

  const entRef = db.collection('entitlements').doc(uid);
  await db.runTransaction(async (tx) => {
    tx.set(
      entRef,
      {
        productIds: FieldValue.arrayUnion(productId),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    tx.set(
      tokenRef,
      {
        uid,
        productId,
        source,
        orderId: purchase.orderId || null,
        verifiedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  const entSnap = await entRef.get();
  const entitlements =
    (entSnap.exists && entSnap.get('productIds')) || [productId];

  return { valid: true, entitlements };
});
