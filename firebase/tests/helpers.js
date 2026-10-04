const fs = require("fs");
const path = require("path");
const { setLogLevel } = require("firebase/firestore");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

// Hide the error logs from denied writes so the test output is readable
setLogLevel("silent");

const RULES = fs.readFileSync(
  path.join(__dirname, "..", "firestore.rules"),
  "utf8",
);

const IDS = {
  customer: "customer-1",
  otherCustomer: "customer-2",
  provider: "provider-1",
  otherProvider: "provider-2",
  newProvider: "provider-3",
  admin: "admin-1",
};

const REQUEST_ID = "request-1";
const OTHER_REQUEST_ID = "request-2";
const HIDDEN_REVIEW_ID = "request-3";

// Plain string timestamp for test data
const SEED_TIME = "2026-01-01T00:00:00.000Z";

let testEnv;

async function setup() {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-service-finder",
    firestore: { rules: RULES },
  });

  // Clear data left over from earlier runs
  await testEnv.clearFirestore();
  await seedFixtures();

  return testEnv;
}

async function teardown() {
  if (testEnv) {
    await testEnv.cleanup();
  }
}

// Seed with rules disabled so fixtures exist regardless of who "creates" them.
// Call this from beforeEach as well: several tests move a request through the
// state machine, so a shared fixture would leak state between tests.
async function seedFixtures() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await Promise.all([
      db.collection("users").doc(IDS.customer).set({
        role: "customer",
        displayName: "Test Customer",
      }),
      db.collection("users").doc(IDS.otherCustomer).set({
        role: "customer",
        displayName: "Other Customer",
      }),
      db.collection("users").doc(IDS.provider).set({
        role: "provider",
        displayName: "Test Provider",
      }),
      db.collection("users").doc(IDS.otherProvider).set({
        role: "provider",
        displayName: "Other Provider",
      }),
      db.collection("users").doc(IDS.newProvider).set({
        role: "provider",
        displayName: "Brand New Provider",
      }),
    ]);

    await db
      .collection("providerProfiles")
      .doc(IDS.provider)
      .set(providerProfile(IDS.provider));

    await db
      .collection("providerProfiles")
      .doc(IDS.otherProvider)
      .set(providerProfile(IDS.otherProvider));

    await db
      .collection("serviceRequests")
      .doc(REQUEST_ID)
      .set(serviceRequest(REQUEST_ID, "submitted"));

    await db
      .collection("serviceRequests")
      .doc(OTHER_REQUEST_ID)
      .set(serviceRequest(OTHER_REQUEST_ID, "in_progress"));

    // Quotation for REQUEST_ID, keyed by request id like the app writes it.
    await db
      .collection("quotations")
      .doc(REQUEST_ID)
      .set({
        requestId: REQUEST_ID,
        customerId: IDS.customer,
        providerId: IDS.provider,
        serviceCharge: 900,
        inspectionFee: 100,
        estimatedTotal: 1000,
        status: "sent",
      });

    // Reviews are keyed by request id. One visible, one held back by
    // moderation, so the read rules can be checked both ways.
    await db
      .collection("reviews")
      .doc(OTHER_REQUEST_ID)
      .set(reviewPayload(OTHER_REQUEST_ID));

    await db
      .collection("reviews")
      .doc(HIDDEN_REVIEW_ID)
      .set(
        reviewPayload(HIDDEN_REVIEW_ID, { moderationStatus: "hidden" }),
      );
  });
}

// Puts one request into an exact state without going through the state
// machine, so each test can start from the transition it is exercising.
async function seedRequest(requestId, requestStatus, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context
      .firestore()
      .collection("serviceRequests")
      .doc(requestId)
      .set({ ...serviceRequest(requestId, requestStatus), ...overrides });
  });
}

function providerProfile(providerId) {
  return {
    displayName: "Test Provider",
    bio: "A helpful professional.",
    categoryIds: ["plumbing"],
    // A real provider starts unverified and can only become verified by an
    // admin, so seeding it as verified would make the self-promotion test pass
    // for the wrong reason.
    verificationStatus: "pending",
    availabilityStatus: "available",
    ratingAverage: 0,
    reviewCount: 0,
    completedJobCount: 0,
    serviceRadiusKm: 10,
  };
}

function serviceRequest(requestId, requestStatus) {
  const quotationStatus = {
    submitted: "pending",
    quotation_received: "sent",
    confirmed: "accepted",
    in_progress: "accepted",
  }[requestStatus] ?? "accepted";

  return {
    customerId: IDS.customer,
    providerId: IDS.provider,
    categoryId: "plumbing",
    title: "Leaking tap",
    description: "Water leaking under the sink.",
    addressText: "Badulla",
    serviceLocation: {
      point: { latitude: 6.99, longitude: 81.06 },
      addressText: "Badulla",
    },
    requestStatus,
    quotationStatus,
    acceptedQuotationId: quotationStatus === "accepted" ? REQUEST_ID : null,
    finalAmount: quotationStatus === "accepted" ? 1000 : null,
    createdAt: SEED_TIME,
    updatedAt: SEED_TIME,
  };
}

function authAs(uid) {
  return testEnv.authenticatedContext(uid);
}

function unauthenticated() {
  return testEnv.unauthenticatedContext();
}

function authAsAdmin() {
  return testEnv.authenticatedContext(IDS.admin, { admin: true });
}

function requestDoc(uid, requestId = REQUEST_ID) {
  return authAs(uid)
    .firestore()
    .collection("serviceRequests")
    .doc(requestId);
}

function reviewDoc(uid, requestId = OTHER_REQUEST_ID) {
  return authAs(uid)
    .firestore()
    .collection("reviews")
    .doc(requestId);
}

function reviewPayload(requestId, overrides = {}) {
  return {
    requestId,
    customerId: IDS.customer,
    providerId: IDS.provider,
    rating: 5,
    comment: "Great work.",
    moderationStatus: "visible",
    createdAt: SEED_TIME,
    updatedAt: SEED_TIME,
    ...overrides,
  };
}

module.exports = {
  IDS,
  REQUEST_ID,
  OTHER_REQUEST_ID,
  HIDDEN_REVIEW_ID,
  setup,
  teardown,
  seedFixtures,
  seedRequest,
  authAs,
  authAsAdmin,
  unauthenticated,
  requestDoc,
  reviewDoc,
  reviewPayload,
  providerProfile,
  serviceRequest,
  assertFails,
  assertSucceeds,
};