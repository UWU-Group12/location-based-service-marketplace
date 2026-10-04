const {
  IDS,
  OTHER_REQUEST_ID,
  HIDDEN_REVIEW_ID,
  setup,
  teardown,
  seedFixtures,
  authAs,
  unauthenticated,
  reviewDoc,
  reviewPayload,
  assertFails,
  assertSucceeds,
} = require("./helpers");

// The reviews create rule requires createdAt and updatedAt to equal
// request.time, which only a real FieldValue.serverTimestamp() satisfies.
// @firebase/rules-unit-testing cannot send that (see helpers.js), so the
// individual create-path conditions -- customer role, request ownership,
// completed status, rating range, moderationStatus -- cannot be isolated from
// the timestamp clause and are therefore not asserted here. Covering them
// needs the Auth emulator plus the real Firebase SDK.
//
// What IS provable from this library is the opposite direction: a client that
// chooses its own timestamps is rejected, plus the read/update/delete rules.
describe("reviews rules", () => {
  before(async () => {
    await setup();
  });

  beforeEach(async () => {
    await seedFixtures();
  });

  after(async () => {
    await teardown();
  });

  describe("create", () => {
    it("blocks a review carrying client-chosen timestamps", async () => {
      // Proves the anti-backdating control: only the server may stamp a review.
      await assertFails(
        authAs(IDS.customer)
          .firestore()
          .collection("reviews")
          .doc("request-backdated")
          .set(reviewPayload("request-backdated")),
      );
    });

    it("blocks a provider submitting a review", async () => {
      await assertFails(
        authAs(IDS.provider)
          .firestore()
          .collection("reviews")
          .doc("request-by-provider")
          .set(
            reviewPayload("request-by-provider", { customerId: IDS.provider }),
          ),
      );
    });
  });

  describe("read", () => {
    it("lets a signed-in customer read a visible review", async () => {
      await assertSucceeds(reviewDoc(IDS.otherCustomer).get());
    });

    it("lets a signed-in provider read a review on their own job", async () => {
      await assertSucceeds(reviewDoc(IDS.provider).get());
    });

    it("blocks reading a review held back by moderation", async () => {
      // Visible reviews are public on purpose, so the moderation check is what
      // actually protects a flagged one.
      await assertFails(reviewDoc(IDS.otherCustomer, HIDDEN_REVIEW_ID).get());
    });

    it("blocks an unauthenticated read of a held back review", async () => {
      await assertFails(
        unauthenticated()
          .firestore()
          .collection("reviews")
          .doc(HIDDEN_REVIEW_ID)
          .get(),
      );
    });
  });

  describe("update and delete", () => {
    it("blocks a customer editing their own review", async () => {
      await assertFails(
        reviewDoc(IDS.customer).update({ rating: 1, comment: "Changed" }),
      );
    });

    it("blocks a customer deleting their own review", async () => {
      await assertFails(reviewDoc(IDS.customer).delete());
    });

    it("blocks a provider editing a review on their own job", async () => {
      await assertFails(reviewDoc(IDS.provider).update({ rating: 1 }));
    });

    it("blocks overwriting a review by writing the same document id", async () => {
      // Reviews are keyed by request id, so a second review for a job has to
      // overwrite the first one. Firestore treats that as an update.
      await assertFails(
        reviewDoc(IDS.customer).set(
          reviewPayload(OTHER_REQUEST_ID, { rating: 1, comment: "Rewritten" }),
        ),
      );
    });
  });
});