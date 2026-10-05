const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

// Same region as the Firestore database (firebase.json)
setGlobalOptions({ region: "asia-south1" });

initializeApp();

const db = getFirestore();

async function recomputeProviderRating(providerId) {
  if (!providerId) {
    return;
  }

  const reviewsSnapshot = await db
    .collection("reviews")
    .where("providerId", "==", providerId)
    .where("moderationStatus", "==", "visible")
    .get();

  const reviewCount = reviewsSnapshot.size;

  const ratingTotal = reviewsSnapshot.docs.reduce(
    (total, document) => total + (document.data().rating || 0),
    0,
  );

  await db.collection("providerProfiles").doc(providerId).update({
    ratingAverage: reviewCount === 0 ? 0 : ratingTotal / reviewCount,
    reviewCount,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

exports.recomputeRatingOnReviewCreated = onDocumentCreated(
  "reviews/{requestId}",
  async (event) => {
    const review = event.data && event.data.data();
    await recomputeProviderRating(review && review.providerId);
  },
);

exports.recomputeRatingOnReviewUpdated = onDocumentUpdated(
  "reviews/{requestId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const providerId = (after && after.providerId) || (before && before.providerId);

    const visibilityChanged =
      (before && before.moderationStatus) !== (after && after.moderationStatus);

    if (!visibilityChanged && before.rating === after.rating) {
      return;
    }

    await recomputeProviderRating(providerId);
  },
);

// completedJobCount is server-owned (rules block client writes), so keep it
// in sync whenever a request moves into or out of 'completed'.
exports.recomputeJobCountOnRequestUpdated = onDocumentUpdated(
  "serviceRequests/{requestId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (before.requestStatus === after.requestStatus) {
      return;
    }

    if (before.requestStatus !== "completed" && after.requestStatus !== "completed") {
      return;
    }

    const providerId = after.providerId || before.providerId;
    if (!providerId) {
      return;
    }

    const completedSnapshot = await db
      .collection("serviceRequests")
      .where("providerId", "==", providerId)
      .where("requestStatus", "==", "completed")
      .count()
      .get();

    await db.collection("providerProfiles").doc(providerId).update({
      completedJobCount: completedSnapshot.data().count,
      updatedAt: FieldValue.serverTimestamp(),
    });
  },
);
// Admin panel: set a new sign-in password for a customer or provider.
// Changing another user's password needs the Admin SDK, so it runs here.
exports.setUserPassword = onCall(async (request) => {
  if (!request.auth || request.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "Only administrators can change passwords.");
  }

  const { userId, password } = request.data || {};

  if (typeof userId !== "string" || !userId) {
    throw new HttpsError("invalid-argument", "A user ID is required.");
  }

  if (typeof password !== "string" || password.length < 6) {
    throw new HttpsError("invalid-argument", "Use a password with at least 6 characters.");
  }

  const userSnapshot = await db.collection("users").doc(userId).get();
  const role = userSnapshot.exists ? userSnapshot.data().role : null;

  // Only app users; administrator passwords are not managed from the panel.
  if (role !== "customer" && role !== "provider") {
    throw new HttpsError("not-found", "Customer or provider account not found.");
  }

  await getAuth().updateUser(userId, { password });
});
