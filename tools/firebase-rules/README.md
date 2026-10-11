# Community security tests

These tests use only local Firestore and Storage emulators and the synthetic
`demo-bitewise-rules` project. They reject non-local emulator endpoints and never
read or alter production user data.

Requires Node.js 22+, a supported Java runtime for the Firebase emulators, and
dependencies installed in this directory (`pnpm install --frozen-lockfile`).
From the Flutter project root:

```powershell
& .\tools\firebase-rules\node_modules\.bin\firebase.cmd emulators:exec --only firestore,storage --project demo-bitewise-rules "node --test --test-concurrency=1 tools/firebase-rules/community.rules.test.mjs"
```

The tests exercise cross-account reads, replies and likes, schema validation,
forged counters/identity, atomic parent/child changes, moderator boundaries,
private reports, recipient-only notifications, default-deny private paths, and
photo ownership/size/visibility.
The emulator does not prove production IAM, billing, indexes, or cross-service
permissions have been configured; verify deployment separately.

## Verified local result

On September 27, 2026, all **75 security tests passed** with **0 failures and
0 skipped tests**. The complete run took 13.82 seconds for the test process.
Both emulators shut down successfully.
These are emulator results, not a claim that production Storage is enabled.

The index file covers the published newest-first feed, tag-filtered feed,
author-filtered feed, and combined author/tag-filtered feed. Firestore's emulator
does not enforce composite-index availability; production indexes must finish
building before their corresponding queries can succeed.

## Replies and private notification inboxes

Comments may include `replyToCommentId`, `replyToAuthorId`, and `replyToAuthor`.
All three must be present together and identify an existing comment in the same
post. The author ID/name must match that stored comment, preventing a client from
misdirecting a reply. Older top-level comments omit all three fields and continue
to work. Deleting a target comment does not hide existing replies, but no new
reply may reference a deleted target.

An inbox entry lives at
`communityNotifications/{recipientId}/items/{postId}_{commentId}` and contains
only event metadata: `recipientId`, `actorId`, `actorName`, `postId`, `commentId`,
`replyToCommentId` (null for a top-level comment), `createdAt`, and `isRead`.
Comment bodies, photos, and personal bite information are not copied into it.

The notification must be created atomically with its new comment. Its recipient
must be the reply target's author, or the post author for a top-level comment.
Actor ID/name and creation time are checked against authentication and the new
comment. Self-notifications, fabricated identities, unrelated recipients,
replays of existing comments, arbitrary notification content, and non-atomic
creation are denied. Notifications are optional for comment creation so an
older installed app can continue posting without a coordinated client update.

Only the verified recipient can read/list their inbox, including after its
source comment or post is deleted. Senders and moderators cannot read someone
else's inbox. The recipient may change only `isRead` from false to true; clients
must treat an already-read entry as a no-op. No client may delete an entry or
rewrite its identity/content. Keeping its event ID prevents later recreation.

The newest-first inbox query orders by `createdAt`. The unread query filters on
`isRead == false` without ordering. Each uses an automatic single-field index,
so these additions need no composite index. These rules do not deliver phone
push notifications or grant access to device tokens.

## Storage/Firestore permission

Storage Rules read the default Firestore database to check photo publication.
The first deployment prompts the project owner to grant the Storage service
agent the necessary Firestore-read role. Do not replace these checks with an
allow-all rule if permissions are missing. See the official
[cross-service conditions documentation](https://firebase.google.com/docs/storage/security/rules-conditions#enhance_with_cloud_firestore).

Staged and deleted photos are accessible only to their verified uploader so
interrupted publication/deletion can be retried. Other verified members can
read a photo only while its matching post is published. No bucket listing or
mutable image metadata is allowed. The app downloads authenticated bytes,
not public download-token URLs. MIME and size checks are not malware scanning;
server-side image validation and abuse throttling are further release hardening.

Posts use soft-deletion tombstones to prevent reuse of published IDs. Comments
and likes must atomically change their matching parent counter. Client edits to
published content are deliberately disabled; author/moderator removal is allowed.
Moderator claims must be issued by a trusted Admin SDK process, never by a client.

Private profile/history/saved data are not enabled in Firestore by these rules;
all paths outside the explicit community schema are denied.
