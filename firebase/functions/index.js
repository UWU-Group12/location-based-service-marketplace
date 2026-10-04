const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

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