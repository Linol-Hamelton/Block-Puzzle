/**
 * Deny/allow matrix for firestore.rules.
 *
 * These run against the Firestore emulator, so they exercise the real rules
 * engine rather than a reading of the rules file. Start them with:
 *
 *   npm install
 *   npm test
 *
 * The emulator needs a JDK on PATH.
 */
const assert = require('node:assert/strict');
const { test, before, after, beforeEach, describe } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc } = require('firebase/firestore');

const PROJECT_ID = 'lumina-blocks-f5cf1';
const ME = 'uid-me';
const OTHER = 'uid-other';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, '../../firestore.rules'),
        'utf8',
      ),
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

/** Seeds a document while bypassing the rules, the way the server would. */
async function seedAsServer(collectionPath, id, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), collectionPath, id), data);
  });
}

describe('entitlements', () => {
  test('the owner can read their own entitlements', async () => {
    await seedAsServer('entitlements', ME, { ownedSkus: ['skin_aurora'] });
    const db = testEnv.authenticatedContext(ME).firestore();
    await assertSucceeds(getDoc(doc(db, 'entitlements', ME)));
  });

  test('another signed-in user cannot read them', async () => {
    await seedAsServer('entitlements', ME, { ownedSkus: ['skin_aurora'] });
    const db = testEnv.authenticatedContext(OTHER).firestore();
    await assertFails(getDoc(doc(db, 'entitlements', ME)));
  });

  test('nobody signed out can read them', async () => {
    await seedAsServer('entitlements', ME, { ownedSkus: ['skin_aurora'] });
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'entitlements', ME)));
  });

  test('the owner cannot grant themselves an entitlement', async () => {
    const db = testEnv.authenticatedContext(ME).firestore();
    await assertFails(
      setDoc(doc(db, 'entitlements', ME), { ownedSkus: ['skin_aurora'] }),
    );
  });
});

describe('purchase tokens', () => {
  test('a client cannot read a token binding', async () => {
    await seedAsServer('purchaseTokens', 'token-1', { uid: ME });
    const db = testEnv.authenticatedContext(ME).firestore();
    await assertFails(getDoc(doc(db, 'purchaseTokens', 'token-1')));
  });

  test('a client cannot rebind a token to itself', async () => {
    await seedAsServer('purchaseTokens', 'token-1', { uid: OTHER });
    const db = testEnv.authenticatedContext(ME).firestore();
    await assertFails(setDoc(doc(db, 'purchaseTokens', 'token-1'), { uid: ME }));
  });
});

describe('player progress', () => {
  const validProgress = {
    schemaVersion: 2,
    bestScore: 1200,
    lastScore: 900,
    totalRuns: 14,
    streakDays: 3,
    lastPlayedAtUtc: '2026-09-15T10:00:00Z',
    updatedAtUtc: '2026-09-15T10:00:00Z',
  };

  test('the owner can write their own progress', async () => {
    const db = testEnv.authenticatedContext(ME).firestore();
    await assertSucceeds(setDoc(doc(db, 'users', ME), validProgress));
  });

  test('the owner can read their own progress', async () => {
    await seedAsServer('users', ME, validProgress);
    const db = testEnv.authenticatedContext(ME).firestore();
    await assertSucceeds(getDoc(doc(db, 'users', ME)));
  });

  test('a user cannot write into somebody else document', async () => {
    const db = testEnv.authenticatedContext(OTHER).firestore();
    await assertFails(setDoc(doc(db, 'users', ME), validProgress));
  });

  test('a user cannot read somebody else progress', async () => {
    await seedAsServer('users', ME, validProgress);
    const db = testEnv.authenticatedContext(OTHER).firestore();
    await assertFails(getDoc(doc(db, 'users', ME)));
  });

  test('a signed-out client can do neither', async () => {
    await seedAsServer('users', ME, validProgress);
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'users', ME)));
    await assertFails(setDoc(doc(db, 'users', ME), validProgress));
  });

  test('entitlements cannot be smuggled in through the progress document', async () => {
    // This is the field restriction earning its keep: without it, the client
    // writes its own progress and grants itself the catalogue in the same call.
    const db = testEnv.authenticatedContext(ME).firestore();
    await assertFails(
      setDoc(doc(db, 'users', ME), {
        ...validProgress,
        entitlements: { premiumPass: true },
      }),
    );
    await assertFails(
      setDoc(doc(db, 'users', ME), {
        ...validProgress,
        ownedSkus: ['skin_aurora'],
      }),
    );
  });

  test('an unknown field is rejected rather than quietly stored', async () => {
    const db = testEnv.authenticatedContext(ME).firestore();
    await assertFails(
      setDoc(doc(db, 'users', ME), { ...validProgress, arbitraryField: 1 }),
    );
  });

  test('progress cannot be deleted by the client', async () => {
    await seedAsServer('users', ME, validProgress);
    const db = testEnv.authenticatedContext(ME).firestore();
    const { deleteDoc } = require('firebase/firestore');
    await assertFails(deleteDoc(doc(db, 'users', ME)));
  });
});

describe('everything else is closed', () => {
  test('an unlisted collection is not readable or writable', async () => {
    const db = testEnv.authenticatedContext(ME).firestore();
    await assertFails(getDoc(doc(db, 'leaderboards', 'weekly')));
    await assertFails(setDoc(doc(db, 'leaderboards', 'weekly'), { score: 1 }));
  });
});

test('the rules file the tests loaded is the one in the repository', () => {
  const rules = fs.readFileSync(
    path.resolve(__dirname, '../../firestore.rules'),
    'utf8',
  );
  assert.match(rules, /rules_version = '2'/);
  assert.match(rules, /match \/entitlements\/\{uid\}/);
  assert.match(rules, /match \/users\/\{uid\}/);
});
