# Firestore rules tests

Deny/allow matrix for `firestore.rules`, run against the Firestore emulator so
it exercises the real rules engine rather than a reading of the file.

```bash
npm install
npm test
```

## JDK 21 or newer is required

`firebase-tools` refuses to start the emulators on anything older:

```
Error: firebase-tools no longer supports Java version before 21.
```

This is **not** the JDK the Android build uses. Android Gradle runs on 17 here,
and moving the global `JAVA_HOME` to satisfy the emulator would invalidate the
Gradle daemon and force a full rebuild. Point `JAVA_HOME` at 21 for this command
only:

```powershell
$env:JAVA_HOME = 'D:\Java\jdk-21.0.x'
npm test
```

## What the matrix covers

| Collection | Owner | Other signed-in user | Signed out |
|---|---|---|---|
| `entitlements/{uid}` | read only | nothing | nothing |
| `purchaseTokens/{token}` | nothing | nothing | nothing |
| `users/{uid}` | read + write own fields | nothing | nothing |
| anything else | nothing | nothing | nothing |

Plus the cases that matter more than the table: that a client cannot grant
itself an entitlement, cannot rebind a purchase token, and cannot smuggle
`entitlements` or `ownedSkus` into its own progress document alongside a
legitimate score update.
