const {
  IDS,
  setup,
  teardown,
  seedFixtures,
  authAs,
  assertFails,
  assertSucceeds,
} = require("./helpers");

function profileDoc(uid, profileId = IDS.provider) {
  return authAs(uid)
    .firestore()
    .collection("providerProfiles")
    .doc(profileId);
}

describe("providerProfiles rules", () => {
  before(async () => {
    await setup();
  });

  beforeEach(async () => {
    await seedFixtures();
  });

  after(async () => {
    await teardown();
  });

  describe("aggregates stay trusted", () => {
    it("blocks a provider writing ratingAverage", async () => {
      await assertFails(profileDoc(IDS.provider).update({ ratingAverage: 5 }));
    });

    it("blocks a provider writing reviewCount", async () => {
      await assertFails(profileDoc(IDS.provider).update({ reviewCount: 999 }));
    });

    it("blocks a provider writing completedJobCount", async () => {
      await assertFails(
        profileDoc(IDS.provider).update({ completedJobCount: 999 }),
      );
    });

    it("blocks inflating ratingAverage alongside a legal field", async () => {
      // Guards against a legal field being used as cover for an illegal one.
      await assertFails(
        profileDoc(IDS.provider).update({ bio: "New bio", ratingAverage: 5 }),
      );
    });
  });

  describe("legitimate profile editing still works", () => {
    it("allows updating bio", async () => {
      await assertSucceeds(profileDoc(IDS.provider).update({ bio: "Updated" }));
    });

    it("allows updating displayName", async () => {
      await assertSucceeds(
        profileDoc(IDS.provider).update({ displayName: "New Name" }),
      );
    });

    it("allows updating categoryIds", async () => {
      await assertSucceeds(
        profileDoc(IDS.provider).update({ categoryIds: ["electrical"] }),
      );
    });

    it("allows updating serviceRadiusKm and location fields", async () => {
      await assertSucceeds(
        profileDoc(IDS.provider).update({
          serviceRadiusKm: 25,
          baseLocation: { latitude: 6.99, longitude: 81.06 },
        }),
      );
    });

    it("allows toggling availabilityStatus", async () => {
      await assertSucceeds(
        profileDoc(IDS.provider).update({ availabilityStatus: "unavailable" }),
      );
    });
  });

  describe("verification is not self-assignable", () => {
    it("blocks a provider promoting themselves to verified", async () => {
      // The fixture is seeded as 'pending', so this write really does try to
      // change the verification status.
      await assertFails(
        profileDoc(IDS.otherProvider, IDS.otherProvider).update({
          verificationStatus: "verified",
        }),
      );
    });

    it("blocks a provider editing someone else's profile", async () => {
      await assertFails(
        profileDoc(IDS.otherProvider, IDS.provider).update({
          bio: "Tampered",
        }),
      );
    });
  });

  describe("create", () => {
    it("blocks creating a profile that starts as verified", async () => {
      // The document id must be the caller's own uid, otherwise this would be
      // denied by isMe() and never reach the verification check.
      await assertFails(
        profileDoc(IDS.newProvider, IDS.newProvider).set({
          displayName: "Sneaky",
          verificationStatus: "verified",
        }),
      );
    });

    it("allows creating a profile that starts as pending", async () => {
      await assertSucceeds(
        profileDoc(IDS.newProvider, IDS.newProvider).set({
          displayName: "Honest",
          verificationStatus: "pending",
        }),
      );
    });
  });
});