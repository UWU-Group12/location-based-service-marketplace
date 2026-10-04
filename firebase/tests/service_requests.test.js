const {
  IDS,
  REQUEST_ID,
  OTHER_REQUEST_ID,
  setup,
  teardown,
  seedFixtures,
  seedRequest,
  authAs,
  authAsAdmin,
  requestDoc,
  assertFails,
  assertSucceeds,
} = require("./helpers");

describe("serviceRequests rules", () => {
  before(async () => {
    await setup();
  });

  // Each test drives the request through part of the state machine, so the
  // fixture is rebuilt before every test to keep them independent.
  beforeEach(async () => {
    await seedFixtures();
  });

  after(async () => {
    await teardown();
  });

  describe("create", () => {
    it("lets a customer create their own request", async () => {
      await assertSucceeds(
        authAs(IDS.customer)
          .firestore()
          .collection("serviceRequests")
          .doc("request-new")
          .set({
            customerId: IDS.customer,
            providerId: IDS.provider,
            requestStatus: "submitted",
          }),
      );
    });

    it("blocks a request created on behalf of someone else", async () => {
      await assertFails(
        authAs(IDS.customer)
          .firestore()
          .collection("serviceRequests")
          .doc("request-forged")
          .set({
            customerId: IDS.otherCustomer,
            providerId: IDS.provider,
            requestStatus: "submitted",
          }),
      );
    });

    it("blocks a request that starts out already completed", async () => {
      // Otherwise a customer could mint a review without doing any work.
      await assertFails(
        authAs(IDS.customer)
          .firestore()
          .collection("serviceRequests")
          .doc("request-instant")
          .set({
            customerId: IDS.customer,
            providerId: IDS.provider,
            requestStatus: "completed",
          }),
      );
    });
  });

  describe("provider transitions", () => {
    it("allows submitted -> quotation_received", async () => {
      await assertSucceeds(
        requestDoc(IDS.provider).update({
          requestStatus: "quotation_received",
          quotationStatus: "sent",
        }),
      );
    });

    it("allows submitted -> provider_rejected", async () => {
      await assertSucceeds(
        requestDoc(IDS.provider).update({ requestStatus: "provider_rejected" }),
      );
    });

    it("allows confirmed -> in_progress (provider starts the job)", async () => {
      await seedRequest(REQUEST_ID, "confirmed");

      await assertSucceeds(
        requestDoc(IDS.provider).update({ requestStatus: "in_progress" }),
      );
    });

    it("blocks submitted -> completed (forged job completion)", async () => {
      await assertFails(
        requestDoc(IDS.provider).update({ requestStatus: "completed" }),
      );
    });

    it("blocks submitted -> confirmed (skipping the quote step)", async () => {
      await assertFails(
        requestDoc(IDS.provider).update({ requestStatus: "confirmed" }),
      );
    });

    it("blocks a second quotation while one is already out", async () => {
      // A request carries a single quotation, so the state must not move again
      // while a price is already on the table.
      await seedRequest(REQUEST_ID, "quotation_received");

      await assertFails(
        requestDoc(IDS.provider).update({
          requestStatus: "quotation_received",
          quotationStatus: "sent",
          finalAmount: 2000,
        }),
      );
    });

    it("blocks a provider moving a request backwards", async () => {
      await seedRequest(REQUEST_ID, "in_progress");

      await assertFails(
        requestDoc(IDS.provider).update({ requestStatus: "confirmed" }),
      );
    });

    it("blocks a provider marking the job complete themselves", async () => {
      // The customer confirms the work, not the provider, so this is the rule
      // that stops a provider forcing a five star review.
      await assertFails(
        requestDoc(IDS.provider, OTHER_REQUEST_ID).update({
          requestStatus: "completed",
        }),
      );
    });

    it("blocks a provider updating a request assigned to someone else", async () => {
      await seedRequest("request-unassigned", "submitted", {
        providerId: IDS.otherProvider,
      });

      await assertFails(
        requestDoc(IDS.provider, "request-unassigned").update({
          requestStatus: "quotation_received",
          quotationStatus: "sent",
        }),
      );
    });
  });

  describe("customer transitions", () => {
    it("allows submitted -> cancelled", async () => {
      await assertSucceeds(
        requestDoc(IDS.customer).update({ requestStatus: "cancelled" }),
      );
    });

    it("allows in_progress -> completed (job is done)", async () => {
      await assertSucceeds(
        requestDoc(IDS.customer, OTHER_REQUEST_ID).update({
          requestStatus: "completed",
        }),
      );
    });

    it("blocks submitted -> completed, so nobody can forge a rating", async () => {
      await assertFails(
        requestDoc(IDS.customer).update({ requestStatus: "completed" }),
      );
    });

    it("blocks a customer cancelling someone else's request", async () => {
      await seedRequest("request-not-mine", "submitted", {
        customerId: IDS.otherCustomer,
      });

      await assertFails(
        requestDoc(IDS.customer, "request-not-mine").update({
          requestStatus: "cancelled",
        }),
      );
    });
  });

  describe("quotation acceptance", () => {
    it("allows accepting a quotation", async () => {
      // The provider already recorded the price, so the customer only
      // records the decision.
      await seedRequest(REQUEST_ID, "quotation_received", { finalAmount: 1000 });

      await assertSucceeds(
        requestDoc(IDS.customer).update({
          requestStatus: "confirmed",
          quotationStatus: "accepted",
          acceptedQuotationId: REQUEST_ID,
        }),
      );
    });

    it("blocks the customer writing the price themselves", async () => {
      await seedRequest(REQUEST_ID, "quotation_received", { finalAmount: 1000 });

      await assertFails(
        requestDoc(IDS.customer).update({
          requestStatus: "confirmed",
          quotationStatus: "accepted",
          acceptedQuotationId: REQUEST_ID,
          finalAmount: 1,
        }),
      );
    });

    it("blocks the customer dropping the price to zero", async () => {
      await seedRequest(REQUEST_ID, "quotation_received", { finalAmount: 1000 });

      await assertFails(
        requestDoc(IDS.customer).update({
          finalAmount: 0,
        }),
      );
    });

    it("lets the provider record the price when quoting", async () => {
      await assertSucceeds(
        requestDoc(IDS.provider).update({
          requestStatus: "quotation_received",
          quotationStatus: "sent",
          finalAmount: 1000,
        }),
      );
    });
  });

  describe("quotation rejection", () => {
    it("allows the customer rejecting and cancelling the job", async () => {
      await seedRequest(REQUEST_ID, "quotation_received", { finalAmount: 1000 });

      await assertSucceeds(
        requestDoc(IDS.customer).update({
          requestStatus: "cancelled",
          quotationStatus: "rejected",
        }),
      );
    });

    it("blocks the customer marking a quote as sent", async () => {
      // Sending is the provider's move, so the customer must not be able to
      // fake a quote arriving.
      await assertFails(
        requestDoc(IDS.customer).update({
          requestStatus: "quotation_received",
          quotationStatus: "sent",
        }),
      );
    });

    it("blocks the customer marking a quote as expired", async () => {
      await assertFails(
        requestDoc(IDS.customer).update({
          quotationStatus: "expired",
        }),
      );
    });

    it("blocks the provider accepting their own quote", async () => {
      await seedRequest(REQUEST_ID, "quotation_received", { finalAmount: 1000 });

      await assertFails(
        requestDoc(IDS.provider).update({
          requestStatus: "confirmed",
          quotationStatus: "accepted",
        }),
      );
    });

    it("lets the customer cancel before any quote arrives", async () => {
      // Cancelling your own job is legitimate and is the same transition the
      // rules already allow from 'submitted'.
      await assertSucceeds(
        requestDoc(IDS.customer).update({ requestStatus: "cancelled" }),
      );
    });
  });

  describe("immutable fields", () => {
    it("blocks a customer reassigning providerId", async () => {
      await assertFails(
        requestDoc(IDS.customer).update({ providerId: IDS.otherProvider }),
      );
    });

    it("blocks a provider changing customerId", async () => {
      await assertFails(
        requestDoc(IDS.provider).update({ customerId: IDS.otherCustomer }),
      );
    });

    it("blocks editing request content", async () => {
      await assertFails(
        requestDoc(IDS.customer).update({ title: "Rewritten by customer" }),
      );
    });

    it("blocks editing createdAt", async () => {
      await assertFails(
        requestDoc(IDS.customer).update({ createdAt: "2020-01-01" }),
      );
    });

    it("blocks a customer deleting their own request", async () => {
      await assertFails(requestDoc(IDS.customer).delete());
    });
  });

  describe("reads", () => {
    it("lets the customer read their own request", async () => {
      await assertSucceeds(requestDoc(IDS.customer).get());
    });

    it("lets the assigned provider read the request", async () => {
      await assertSucceeds(requestDoc(IDS.provider).get());
    });

    it("blocks an unrelated user from reading the request", async () => {
      await assertFails(requestDoc(IDS.otherCustomer).get());
    });

    it("lets an admin read the request", async () => {
      await assertSucceeds(
        authAsAdmin()
          .firestore()
          .collection("serviceRequests")
          .doc(REQUEST_ID)
          .get(),
      );
    });
  });
});