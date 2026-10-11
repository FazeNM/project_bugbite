import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setLogLevel,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';
import {
  deleteObject,
  getBytes,
  getMetadata,
  listAll,
  ref,
  updateMetadata,
  uploadBytes,
} from 'firebase/storage';

// Never point these destructive fixture-reset tests at a live Firebase project.
const projectId = 'demo-bitewise-rules';
// Denied writes are expected assertions, not application failures. Node's test
// reporter still prints every failing assertion and its error details.
setLogLevel('silent');
function emulatorAddress(variable) {
  const value = process.env[variable];
  assert.ok(value, `Start the Firebase emulators first (${variable} is missing).`);
  const [host, port] = value.split(':');
  assert.ok(['127.0.0.1', 'localhost'].includes(host), 'Only local emulators are permitted.');
  return { host, port: Number(port) };
}

let environment;
let alice;
let bob;
let moderator;
let unverified;
let anonymous;
const aliceName = 'Alice';
const bobName = 'Bob';
const jpeg = Uint8Array.from([0xff, 0xd8, 0xff, 0xe0, 0, 16, 0x4a, 0x46, 0x49, 0x46, 0xff, 0xd9]);
const jpegMetadata = { contentType: 'image/jpeg' };

function newPost(overrides = {}) {
  return {
    authorId: 'alice',
    author: aliceName,
    location: 'Garden',
    createdAt: serverTimestamp(),
    possibleMatch: 'Mosquito',
    body: 'My observation, not a diagnosis.',
    guideId: 'mosquito',
    tags: ['itchy', 'red'],
    status: 'published',
    imagePath: null,
    likeCount: 0,
    commentCount: 0,
    lastCommentId: null,
    ...overrides,
  };
}

function post(db, id = 'post-1') {
  return doc(db, 'communityPosts', id);
}

function comment(db, id = 'comment-1', postId = 'post-1') {
  return doc(db, 'communityPosts', postId, 'comments', id);
}

function like(db, uid = 'bob', postId = 'post-1') {
  return doc(db, 'communityPosts', postId, 'likes', uid);
}

function notification(db, recipientId = 'alice', id = 'post-1_comment-1') {
  return doc(db, 'communityNotifications', recipientId, 'items', id);
}

function newNotification(overrides = {}) {
  return {
    recipientId: 'alice', actorId: 'bob', actorName: bobName,
    postId: 'post-1', commentId: 'comment-1', replyToCommentId: null,
    createdAt: serverTimestamp(), isRead: false, ...overrides,
  };
}

function commentWithNotification(db = bob.firestore(), {
  postId = 'post-1', commentId = 'comment-1', count = 1,
  authorId = 'bob', author = bobName, recipientId = 'alice',
  notificationId = `${postId}_${commentId}`,
  commentOverrides = {}, notificationOverrides = {},
} = {}) {
  const batch = writeBatch(db);
  batch.set(comment(db, commentId, postId), {
    authorId, author, body: 'Thanks for sharing.',
    createdAt: serverTimestamp(), ...commentOverrides,
  });
  batch.update(post(db, postId), { commentCount: count, lastCommentId: commentId });
  batch.set(notification(db, recipientId, notificationId), newNotification({
    recipientId, actorId: authorId, actorName: author, postId, commentId,
    replyToCommentId: commentOverrides.replyToCommentId ?? null,
    ...notificationOverrides,
  }));
  return batch.commit();
}

async function seedPost(overrides = {}, id = 'post-1') {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(post(context.firestore(), id), newPost({
      createdAt: Timestamp.fromDate(new Date('2026-09-01T12:00:00Z')),
      ...overrides,
    }));
  });
}

async function addComment(db = bob.firestore(), id = 'comment-1', overrides = {}) {
  const batch = writeBatch(db);
  batch.set(comment(db, id), {
    authorId: 'bob', author: bobName, body: 'Thanks for sharing.',
    createdAt: serverTimestamp(), ...overrides,
  });
  batch.update(post(db), { commentCount: 1, lastCommentId: id });
  return batch.commit();
}

async function addLike(db = bob.firestore(), uid = 'bob') {
  const batch = writeBatch(db);
  batch.set(like(db, uid), { userId: uid, createdAt: serverTimestamp() });
  batch.update(post(db), { likeCount: 1 });
  return batch.commit();
}

function photo(context, postId = 'post-1', uid = 'alice') {
  return ref(context.storage(), `communityPhotos/${uid}/${postId}/photo.jpg`);
}

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      ...emulatorAddress('FIRESTORE_EMULATOR_HOST'),
      rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8'),
    },
    storage: {
      ...emulatorAddress('FIREBASE_STORAGE_EMULATOR_HOST'),
      rules: await readFile(new URL('../../storage.rules', import.meta.url), 'utf8'),
    },
  });
  alice = environment.authenticatedContext('alice', { name: aliceName, email_verified: true });
  bob = environment.authenticatedContext('bob', { name: bobName, email_verified: true });
  moderator = environment.authenticatedContext('moderator', {
    name: 'Moderator', email_verified: true, moderator: true,
  });
  unverified = environment.authenticatedContext('unverified', { email_verified: false });
  anonymous = environment.unauthenticatedContext();
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.clearStorage();
});

after(async () => {
  await environment?.cleanup();
});

test('verified Account A publishes and Account B reads the same post and filtered feed', async () => {
  await assertSucceeds(setDoc(post(alice.firestore()), newPost()));
  const snapshot = await assertSucceeds(getDoc(post(bob.firestore())));
  assert.equal(snapshot.data().authorId, 'alice');
  const feed = await assertSucceeds(getDocs(query(
    collection(bob.firestore(), 'communityPosts'), where('status', '==', 'published'),
    where('tags', 'array-contains', 'itchy'), orderBy('createdAt', 'desc'),
  )));
  assert.equal(feed.size, 1);
});

test('verified publication can preflight a missing document without disclosing other private data', async () => {
  assert.equal((await assertSucceeds(getDoc(post(alice.firestore())))).exists(), false);
  await assertFails(getDocs(collection(alice.firestore(), 'communityPosts')));
});

test('author without a token name uses the safe Member fallback', async () => {
  const unnamed = environment.authenticatedContext('alice', { email_verified: true });
  await assertSucceeds(setDoc(post(unnamed.firestore()), newPost({ author: 'Member' })));
});

for (const [label, getContext] of [
  ['anonymous', () => anonymous], ['unverified', () => unverified],
]) {
  test(`${label} cannot read or write community content`, async () => {
    await seedPost();
    const db = getContext().firestore();
    await assertFails(getDoc(post(db)));
    await assertFails(getDocs(query(collection(db, 'communityPosts'), where('status', '==', 'published'))));
    await assertFails(setDoc(post(db, 'new-post'), newPost()));
    await assertFails(getDoc(comment(db)));
    await assertFails(getDoc(like(db)));
    await assertFails(addComment(db));
    await assertFails(addLike(db));
  });
}

for (const [label, overrides] of [
  ['another author ID', { authorId: 'bob' }],
  ['another display name', { author: 'Bob' }],
  ['backdated creation', { createdAt: Timestamp.fromMillis(1) }],
  ['fabricated likes', { likeCount: 100 }],
  ['fabricated comments', { commentCount: 100 }],
  ['non-integer counters', { likeCount: 0.1 }],
  ['prepopulated comment pointer', { lastCommentId: 'fake' }],
  ['another user photo path', { imagePath: 'communityPhotos/bob/post-1/photo.jpg' }],
  ['external photo URL', { imagePath: 'https://example.com/tracking.jpg' }],
  ['unknown tags', { tags: ['itchy', 'not-a-filter'] }],
  ['duplicate tags', { tags: ['itchy', 'itchy'] }],
  ['non-list tags', { tags: 'itchy' }],
  ['empty body', { body: '' }],
  ['oversized body', { body: 'a'.repeat(4001) }],
  ['oversized match', { possibleMatch: 'a'.repeat(101) }],
  ['oversized location', { location: 'a'.repeat(121) }],
  ['extra fields', { moderator: true }],
  ['deleted initial status', { status: 'deleted' }],
]) {
  test(`post creation rejects ${label}`, async () => {
    await assertFails(setDoc(post(alice.firestore()), newPost(overrides)));
  });
}

test('custom possible match with no guide and own canonical photo path is accepted', async () => {
  await assertSucceeds(setDoc(post(alice.firestore()), newPost({
    guideId: null, possibleMatch: 'A bug not yet in the catalog',
    imagePath: 'communityPhotos/alice/post-1/photo.jpg',
  })));
});

test('published content is immutable even for its author', async () => {
  await seedPost();
  for (const context of [alice, bob, moderator]) {
    await assertFails(updateDoc(post(context.firestore()), { body: 'Changed after publication.' }));
    await assertFails(updateDoc(post(context.firestore()), { authorId: 'bob' }));
    await assertFails(updateDoc(post(context.firestore()), { imagePath: null, possibleMatch: 'Another bug' }));
  }
});

test('likes are shared and one member can atomically like then unlike once', async () => {
  await seedPost();
  await assertSucceeds(addLike());
  assert.equal((await getDoc(post(alice.firestore()))).data().likeCount, 1);
  await assertSucceeds(getDoc(like(alice.firestore())));
  const db = bob.firestore();
  const batch = writeBatch(db);
  batch.delete(like(db));
  batch.update(post(db), { likeCount: 0 });
  await assertSucceeds(batch.commit());
});

test('forged counter updates without a corresponding child change are denied', async () => {
  await seedPost();
  await assertFails(updateDoc(post(bob.firestore()), { likeCount: 1 }));
  await assertFails(updateDoc(post(bob.firestore()), { commentCount: 1, lastCommentId: 'invented' }));
  await assertFails(updateDoc(post(alice.firestore()), { likeCount: 99, commentCount: 99 }));
});

test('like cannot be created, deleted, or edited independently of its parent counter', async () => {
  await seedPost();
  const db = bob.firestore();
  await assertFails(setDoc(like(db), { userId: 'bob', createdAt: serverTimestamp() }));
  await assertSucceeds(addLike());
  await assertFails(deleteDoc(like(db)));
  await assertFails(updateDoc(like(db), { createdAt: serverTimestamp() }));
  await assertFails(addLike());
});

test('one member cannot create or remove another member like', async () => {
  await seedPost();
  await assertFails(addLike(bob.firestore(), 'alice'));
  await assertSucceeds(addLike());
  const db = alice.firestore();
  const batch = writeBatch(db);
  batch.delete(like(db));
  batch.update(post(db), { likeCount: 0 });
  await assertFails(batch.commit());
});

test('Account B comments on Account A post and both accounts read the comment', async () => {
  await seedPost();
  await assertSucceeds(addComment());
  assert.equal((await assertSucceeds(getDoc(comment(alice.firestore())))).data().body, 'Thanks for sharing.');
  const comments = await assertSucceeds(getDocs(query(
    collection(alice.firestore(), 'communityPosts', 'post-1', 'comments'),
    orderBy('createdAt'),
  )));
  assert.equal(comments.size, 1);
  assert.equal((await getDoc(post(alice.firestore()))).data().commentCount, 1);
});

test('comment author can atomically delete their comment and decrement the count', async () => {
  await seedPost();
  await addComment();
  const db = bob.firestore();
  const batch = writeBatch(db);
  batch.delete(comment(db));
  batch.update(post(db), { commentCount: 0, lastCommentId: 'comment-1' });
  await assertSucceeds(batch.commit());
});

test('only the comment author or moderator can remove a comment', async () => {
  await seedPost();
  await addComment();
  for (const context of [alice, moderator]) {
    const db = context.firestore();
    const batch = writeBatch(db);
    batch.delete(comment(db));
    batch.update(post(db), { commentCount: 0, lastCommentId: 'comment-1' });
    if (context === alice) await assertFails(batch.commit());
    else await assertSucceeds(batch.commit());
  }
});

test('comment text and author cannot be rewritten after creation', async () => {
  await seedPost();
  await addComment();
  await assertFails(updateDoc(comment(bob.firestore()), { body: 'Edited' }));
  await assertFails(updateDoc(comment(bob.firestore()), { authorId: 'alice' }));
  await assertFails(deleteDoc(comment(bob.firestore())));
});

test('comment create rejects impersonation, old timestamps, empty/oversized text, and extra fields', async () => {
  await seedPost();
  for (const overrides of [
    { authorId: 'alice' }, { author: 'Alice' }, { createdAt: Timestamp.fromMillis(1) },
    { body: '' }, { body: 'x'.repeat(4001) }, { admin: true },
  ]) {
    await assertFails(addComment(bob.firestore(), 'comment-1', overrides));
  }
});

test('comment cannot be written alone or with the wrong parent pointer/count', async () => {
  await seedPost();
  const db = bob.firestore();
  const data = { authorId: 'bob', author: bobName, body: 'Hello', createdAt: serverTimestamp() };
  await assertFails(setDoc(comment(db), data));
  for (const changes of [
    { commentCount: 5, lastCommentId: 'comment-1' },
    { commentCount: 1, lastCommentId: 'a-different-comment' },
  ]) {
    const batch = writeBatch(db);
    batch.set(comment(db), data);
    batch.update(post(db), changes);
    await assertFails(batch.commit());
  }
});

test('two comments cannot be smuggled into one counter increment', async () => {
  await seedPost();
  const db = bob.firestore();
  const data = { authorId: 'bob', author: bobName, body: 'Hello', createdAt: serverTimestamp() };
  const batch = writeBatch(db);
  batch.set(comment(db, 'first'), data);
  batch.set(comment(db, 'second'), data);
  batch.update(post(db), { commentCount: 1, lastCommentId: 'first' });
  await assertFails(batch.commit());
});

test('top-level comment atomically notifies only the post owner', async () => {
  await seedPost();
  await assertSucceeds(commentWithNotification());
  const item = await assertSucceeds(getDoc(notification(alice.firestore())));
  assert.equal(item.data().actorName, bobName);
  assert.equal(item.data().replyToCommentId, null);
  assert.equal(item.data().isRead, false);
  assert.equal(Object.hasOwn(item.data(), 'body'), false);
  await assertFails(getDoc(notification(bob.firestore())));
  await assertFails(getDoc(notification(moderator.firestore())));
  const inbox = await assertSucceeds(getDocs(query(
    collection(alice.firestore(), 'communityNotifications', 'alice', 'items'),
    orderBy('createdAt', 'desc'),
  )));
  assert.equal(inbox.size, 1);
  const unread = await assertSucceeds(getDocs(query(
    collection(alice.firestore(), 'communityNotifications', 'alice', 'items'),
    where('isRead', '==', false),
  )));
  assert.equal(unread.size, 1);
  await assertFails(getDocs(collection(bob.firestore(), 'communityNotifications', 'alice', 'items')));
});

test('reply to another member notifies the comment author rather than the post owner', async () => {
  await seedPost();
  // Old clients may still write valid comments without a notification.
  await assertSucceeds(addComment());
  await assertSucceeds(commentWithNotification(alice.firestore(), {
    commentId: 'reply-1', count: 2, authorId: 'alice', author: aliceName,
    recipientId: 'bob',
    commentOverrides: {
      replyToCommentId: 'comment-1', replyToAuthorId: 'bob', replyToAuthor: bobName,
    },
  }));
  const reply = await assertSucceeds(getDoc(comment(bob.firestore(), 'reply-1')));
  assert.equal(reply.data().replyToAuthorId, 'bob');
  const item = notification(bob.firestore(), 'bob', 'post-1_reply-1');
  assert.equal((await assertSucceeds(getDoc(item))).data().replyToCommentId, 'comment-1');
  await assertFails(getDoc(notification(alice.firestore(), 'bob', 'post-1_reply-1')));
  assert.equal((await getDocs(collection(alice.firestore(), 'communityNotifications', 'alice', 'items'))).size, 0);
});

test('reply without a notification remains compatible with older clients', async () => {
  await seedPost();
  await addComment();
  const db = alice.firestore();
  const batch = writeBatch(db);
  batch.set(comment(db, 'reply-1'), {
    authorId: 'alice', author: aliceName, body: 'Thank you.', createdAt: serverTimestamp(),
    replyToCommentId: 'comment-1', replyToAuthorId: 'bob', replyToAuthor: bobName,
  });
  batch.update(post(db), { commentCount: 2, lastCommentId: 'reply-1' });
  await assertSucceeds(batch.commit());
});

for (const [label, overrides] of [
  ['missing reply author ID', { replyToCommentId: 'comment-1', replyToAuthor: bobName }],
  ['missing reply author name', { replyToCommentId: 'comment-1', replyToAuthorId: 'bob' }],
  ['missing reply target', { replyToAuthorId: 'bob', replyToAuthor: bobName }],
  ['forged reply author ID', { replyToCommentId: 'comment-1', replyToAuthorId: 'alice', replyToAuthor: bobName }],
  ['forged reply author name', { replyToCommentId: 'comment-1', replyToAuthorId: 'bob', replyToAuthor: aliceName }],
  ['nonexistent reply target', { replyToCommentId: 'missing', replyToAuthorId: 'bob', replyToAuthor: bobName }],
  ['null reply identity', { replyToCommentId: null, replyToAuthorId: null, replyToAuthor: null }],
]) {
  test(`comment rejects ${label}`, async () => {
    await seedPost();
    await addComment();
    const db = alice.firestore();
    const batch = writeBatch(db);
    batch.set(comment(db, 'reply-1'), {
      authorId: 'alice', author: aliceName, body: 'Reply.', createdAt: serverTimestamp(), ...overrides,
    });
    batch.update(post(db), { commentCount: 2, lastCommentId: 'reply-1' });
    await assertFails(batch.commit());
  });
}

test('reply target must exist in the same post, not only in another post', async () => {
  await seedPost();
  await addComment();
  await seedPost({}, 'post-2');
  await assertFails(commentWithNotification(alice.firestore(), {
    postId: 'post-2', authorId: 'alice', author: aliceName, recipientId: 'bob',
    commentId: 'reply-1',
    commentOverrides: {
      replyToCommentId: 'comment-1', replyToAuthorId: 'bob', replyToAuthor: bobName,
    },
  }));
});

test('a deleted reply target cannot receive new replies but existing replies remain readable', async () => {
  await seedPost();
  await addComment();
  await commentWithNotification(alice.firestore(), {
    commentId: 'reply-1', count: 2, authorId: 'alice', author: aliceName, recipientId: 'bob',
    commentOverrides: {
      replyToCommentId: 'comment-1', replyToAuthorId: 'bob', replyToAuthor: bobName,
    },
  });
  const db = bob.firestore();
  const deletion = writeBatch(db);
  deletion.delete(comment(db));
  deletion.update(post(db), { commentCount: 1, lastCommentId: 'comment-1' });
  await assertSucceeds(deletion.commit());
  await assertSucceeds(getDoc(comment(alice.firestore(), 'reply-1')));
  await assertFails(commentWithNotification(alice.firestore(), {
    commentId: 'reply-2', count: 2, authorId: 'alice', author: aliceName, recipientId: 'bob',
    commentOverrides: {
      replyToCommentId: 'comment-1', replyToAuthorId: 'bob', replyToAuthor: bobName,
    },
  }));
});

for (const [label, overrides] of [
  ['forged actor ID', { actorId: 'alice' }],
  ['forged actor name', { actorName: 'Alice' }],
  ['forged recipient field', { recipientId: 'bob' }],
  ['wrong source comment', { commentId: 'missing' }],
  ['wrong source post', { postId: 'other-post' }],
  ['backdated creation', { createdAt: Timestamp.fromMillis(1) }],
  ['already-read creation', { isRead: true }],
  ['non-boolean read state', { isRead: 0 }],
  ['arbitrary notification text', { body: 'Click this malicious link.' }],
  ['fabricated reply pointer', { replyToCommentId: 'made-up' }],
]) {
  test(`notification rejects ${label}`, async () => {
    await seedPost();
    await assertFails(commentWithNotification(bob.firestore(), { notificationOverrides: overrides }));
    assert.equal((await getDoc(comment(bob.firestore()))).exists(), false);
  });
}

test('notification ID must be the deterministic post and comment ID', async () => {
  await seedPost();
  await assertFails(commentWithNotification(bob.firestore(), { notificationId: 'random-notification' }));
});

test('notification cannot be sent to an arbitrary third-party recipient', async () => {
  await seedPost();
  await assertFails(commentWithNotification(bob.firestore(), { recipientId: 'moderator' }));
});

test('notification cannot be sent for self-comments or self-replies', async () => {
  await seedPost();
  await assertFails(commentWithNotification(alice.firestore(), {
    authorId: 'alice', author: aliceName,
  }));
  await addComment();
  await assertFails(commentWithNotification(bob.firestore(), {
    commentId: 'reply-1', count: 2, recipientId: 'bob',
    commentOverrides: {
      replyToCommentId: 'comment-1', replyToAuthorId: 'bob', replyToAuthor: bobName,
    },
  }));
});

test('notification cannot be created before, separately from, or replayed after a comment', async () => {
  await seedPost();
  await assertFails(setDoc(notification(bob.firestore()), newNotification()));
  await addComment();
  await assertFails(setDoc(notification(bob.firestore()), newNotification()));
  await assertFails(setDoc(notification(bob.firestore(), 'alice', 'post-1_comment-2'), newNotification({ commentId: 'comment-2' })));
});

test('notification cannot accompany creation of another member comment', async () => {
  await seedPost();
  await assertFails(commentWithNotification(bob.firestore(), {
    commentOverrides: { authorId: 'moderator', author: 'Moderator' },
  }));
});

test('notification retains historical identity after its comment or post is deleted', async () => {
  await seedPost();
  await commentWithNotification();
  const db = bob.firestore();
  const deletion = writeBatch(db);
  deletion.delete(comment(db));
  deletion.update(post(db), { commentCount: 0, lastCommentId: 'comment-1' });
  await assertSucceeds(deletion.commit());
  await assertSucceeds(updateDoc(post(alice.firestore()), { status: 'deleted' }));
  await assertSucceeds(getDoc(notification(alice.firestore())));
  await assertFails(commentWithNotification());
  await assertFails(setDoc(notification(db), newNotification()));
});

test('only recipient can mark unread notification read and no other fields can change', async () => {
  await seedPost();
  await commentWithNotification();
  for (const context of [bob, moderator, unverified, anonymous]) {
    await assertFails(getDoc(notification(context.firestore())));
    await assertFails(updateDoc(notification(context.firestore()), { isRead: true }));
  }
  for (const changes of [
    { actorName: 'Fake', isRead: true },
    { actorId: 'alice', isRead: true },
    { recipientId: 'bob', isRead: true },
    { postId: 'other', isRead: true },
    { createdAt: serverTimestamp(), isRead: true },
    { replyToCommentId: 'other', isRead: true },
    { body: 'Extra content', isRead: true },
  ]) {
    await assertFails(updateDoc(notification(alice.firestore()), changes));
  }
  await assertSucceeds(updateDoc(notification(alice.firestore()), { isRead: true }));
  await assertFails(updateDoc(notification(alice.firestore()), { isRead: false }));
  await assertFails(deleteDoc(notification(alice.firestore())));
  await assertFails(deleteDoc(notification(bob.firestore())));
});

test('unverified recipient cannot read their own notifications', async () => {
  await seedPost();
  await commentWithNotification();
  const unverifiedAlice = environment.authenticatedContext('alice', { name: aliceName, email_verified: false });
  await assertFails(getDoc(notification(unverifiedAlice.firestore())));
  await assertFails(getDocs(collection(unverifiedAlice.firestore(), 'communityNotifications', 'alice', 'items')));
});

test('soft deletion is restricted to author/moderator and hides posts and comments from other accounts', async () => {
  await seedPost();
  await addComment();
  await addLike();
  await assertFails(updateDoc(post(bob.firestore()), { status: 'deleted' }));
  await assertSucceeds(updateDoc(post(alice.firestore()), { status: 'deleted' }));
  await assertFails(getDoc(post(bob.firestore())));
  await assertFails(getDoc(comment(bob.firestore())));
  await assertFails(getDoc(like(bob.firestore())));
  // Author may inspect their tombstone for idempotent photo cleanup only.
  await assertSucceeds(getDoc(post(alice.firestore())));
  const feed = await assertSucceeds(getDocs(query(
    collection(bob.firestore(), 'communityPosts'), where('status', '==', 'published'),
  )));
  assert.equal(feed.size, 0);
  await assertFails(updateDoc(post(alice.firestore()), { status: 'published' }));
  await assertFails(deleteDoc(post(alice.firestore())));
  await assertFails(addComment(bob.firestore(), 'after-delete'));
});

test('moderator can soft-delete harmful posts but cannot rewrite their content', async () => {
  await seedPost();
  await assertFails(updateDoc(post(moderator.firestore()), { body: 'Rewritten by moderator' }));
  await assertSucceeds(updateDoc(post(moderator.firestore()), { status: 'deleted' }));
});

test('reports are private to reporter/moderator, append-only, and bound to an existing published post', async () => {
  await seedPost();
  const reportData = { reporterId: 'bob', postId: 'post-1', reason: 'Please review.', createdAt: serverTimestamp() };
  const report = (context, id = 'bob_post-1') => doc(context.firestore(), 'communityReports', id);
  assert.equal((await assertSucceeds(getDoc(report(bob)))).exists(), false);
  await assertSucceeds(setDoc(report(bob), reportData));
  await assertSucceeds(getDoc(report(bob)));
  await assertSucceeds(getDoc(report(moderator)));
  await assertFails(getDoc(report(alice)));
  await assertFails(setDoc(report(bob), reportData));
  await assertFails(deleteDoc(report(bob)));
  await assertFails(setDoc(report(bob, 'alice_post-1'), { ...reportData, reporterId: 'alice' }));
  await assertFails(setDoc(report(bob, 'bob_missing'), { ...reportData, postId: 'missing' }));
  await assertSucceeds(deleteDoc(report(moderator)));
});

test('community authentication never grants access to profile, history, saved, or unknown paths', async () => {
  for (const path of ['profiles/alice', 'users/alice', 'history/private', 'saved/private', 'unknown/private']) {
    await environment.withSecurityRulesDisabled((context) => setDoc(doc(context.firestore(), path), { private: true }));
    for (const context of [alice, bob, moderator]) {
      await assertFails(getDoc(doc(context.firestore(), path)));
      await assertFails(setDoc(doc(context.firestore(), path), { private: false }));
    }
  }
});

test('photo is private while staged and readable across accounts only after publication', async () => {
  await assertSucceeds(uploadBytes(photo(alice), jpeg, jpegMetadata));
  await assertSucceeds(getMetadata(photo(alice)));
  await assertFails(getBytes(photo(bob)));
  await seedPost({ imagePath: 'communityPhotos/alice/post-1/photo.jpg' });
  await assertSucceeds(getBytes(photo(bob)));
  await assertFails(getBytes(photo(anonymous)));
  await assertFails(getBytes(photo(unverified)));
});

test('photo upload enforces owner path, verification, fixed filename, JPEG type and 5 MiB maximum', async () => {
  await assertFails(uploadBytes(photo(bob), jpeg, jpegMetadata));
  await assertFails(uploadBytes(photo(anonymous), jpeg, jpegMetadata));
  await assertFails(uploadBytes(photo(unverified, 'post-1', 'unverified'), jpeg, jpegMetadata));
  await assertFails(uploadBytes(photo(alice), jpeg, { contentType: 'text/html' }));
  await assertFails(uploadBytes(photo(alice), new Uint8Array(0), jpegMetadata));
  await assertFails(uploadBytes(photo(alice), new Uint8Array(5 * 1024 * 1024 + 1), jpegMetadata));
  await assertFails(uploadBytes(ref(alice.storage(), 'communityPhotos/alice/post-1/other.jpg'), jpeg, jpegMetadata));
  await assertFails(uploadBytes(ref(alice.storage(), 'profiles/alice/photo.jpg'), jpeg, jpegMetadata));
});

test('published photo cannot be overwritten, metadata-mutated, or uploaded after post creation', async () => {
  await assertSucceeds(uploadBytes(photo(alice), jpeg, jpegMetadata));
  await seedPost({ imagePath: 'communityPhotos/alice/post-1/photo.jpg' });
  await assertFails(uploadBytes(photo(alice), jpeg, jpegMetadata));
  await assertFails(updateMetadata(photo(alice), { customMetadata: { firebaseStorageDownloadTokens: 'public-token' } }));
  await seedPost({}, 'post-2');
  await assertFails(uploadBytes(photo(alice, 'post-2'), jpeg, jpegMetadata));
});

test('only the owner deletes photos; deleted-post photos are inaccessible to other accounts', async () => {
  await uploadBytes(photo(alice), jpeg, jpegMetadata);
  await seedPost({ imagePath: 'communityPhotos/alice/post-1/photo.jpg' });
  await assertFails(deleteObject(photo(bob)));
  await assertSucceeds(updateDoc(post(alice.firestore()), { status: 'deleted' }));
  await assertFails(getBytes(photo(bob)));
  await assertSucceeds(getMetadata(photo(alice)));
  await assertSucceeds(deleteObject(photo(alice)));
  await assertFails(uploadBytes(photo(alice), jpeg, jpegMetadata));
});

test('photo path must be referenced by the published post and bucket listing remains disabled', async () => {
  await uploadBytes(photo(alice), jpeg, jpegMetadata);
  await seedPost({ imagePath: null });
  await assertFails(getBytes(photo(bob)));
  await assertFails(listAll(ref(alice.storage(), 'communityPhotos/alice')));
});
