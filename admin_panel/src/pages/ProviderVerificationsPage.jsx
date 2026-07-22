import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { useAuth } from "../auth/useAuth";
import ConfirmDialog from "../components/ConfirmDialog";
import EmptyState from "../components/EmptyState";
import LoadingSpinner from "../components/LoadingSpinner";
import MessageBanner from "../components/MessageBanner";
import StatusBadge from "../components/StatusBadge";
import { getAuthorizedFileUrl } from "../services/storageService";
import {
  getVerificationSubmissions,
  reviewProviderVerification,
} from "../services/verificationService";
import { formatDate, getDataErrorMessage } from "../utils/formatters";

function ProviderVerificationsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const selectedProviderId = searchParams.get("providerId") || "";
  const [statusFilter, setStatusFilter] = useState("pending");
  const [submissions, setSubmissions] = useState([]);
  const [rejectionReasons, setRejectionReasons] = useState({});
  const [pendingDecision, setPendingDecision] = useState(null);
  const [openingFile, setOpeningFile] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isProcessing, setIsProcessing] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [successMessage, setSuccessMessage] = useState("");
  const { currentAdmin } = useAuth();

  useEffect(() => {
    let isActive = true;

    async function loadSubmissions() {
      setIsLoading(true);
      setErrorMessage("");

      try {
        const verificationList = await getVerificationSubmissions({
          status: statusFilter,
          providerId: selectedProviderId,
        });
        if (isActive) {
          setSubmissions(verificationList);
        }
      } catch (error) {
        console.error("Verification submissions could not be loaded:", error);
        if (isActive) {
          setErrorMessage(
            getDataErrorMessage(
              error,
              "Verification submissions could not be loaded.",
            ),
          );
        }
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    }

    loadSubmissions();
    return () => {
      isActive = false;
    };
  }, [selectedProviderId, statusFilter]);

  function requestDecision(submission, decision) {
    const rejectionReason =
      rejectionReasons[submission.providerId]?.trim() || "";

    if (decision === "rejected" && !rejectionReason) {
      setErrorMessage("Enter a rejection reason before rejecting this provider.");
      return;
    }

    setErrorMessage("");
    setPendingDecision({ submission, decision, rejectionReason });
  }

  async function confirmDecision() {
    if (!pendingDecision || !currentAdmin) {
      return;
    }

    setIsProcessing(true);
    setErrorMessage("");
    setSuccessMessage("");

    try {
      await reviewProviderVerification({
        providerId: pendingDecision.submission.providerId,
        decision: pendingDecision.decision,
        administratorId: currentAdmin.uid,
        rejectionReason: pendingDecision.rejectionReason,
      });

      setSubmissions((currentSubmissions) => {
        if (selectedProviderId) {
          return currentSubmissions.map((submission) =>
            submission.providerId === pendingDecision.submission.providerId
              ? {
                  ...submission,
                  status: pendingDecision.decision,
                  rejectionReason:
                    pendingDecision.decision === "rejected"
                      ? pendingDecision.rejectionReason
                      : null,
                  profile: {
                    ...submission.profile,
                    verificationStatus: pendingDecision.decision,
                  },
                }
              : submission,
          );
        }

        return currentSubmissions.filter(
          (submission) =>
            submission.providerId !== pendingDecision.submission.providerId,
        );
      });
      setSuccessMessage(
        `${pendingDecision.submission.user.displayName || "Provider"} was ${pendingDecision.decision}.`,
      );
      setPendingDecision(null);
    } catch (error) {
      console.error("Verification decision could not be saved:", error);
      setErrorMessage(
        getDataErrorMessage(
          error,
          "The verification decision could not be saved.",
        ),
      );
    } finally {
      setIsProcessing(false);
    }
  }

  async function openFile(filePath, fileKey) {
    setOpeningFile(fileKey);
    setErrorMessage("");

    try {
      const fileUrl = await getAuthorizedFileUrl(filePath);
      window.open(fileUrl, "_blank", "noopener,noreferrer");
    } catch (error) {
      console.error("Verification document could not be opened:", error);
      setErrorMessage(
        getDataErrorMessage(
          error,
          "The selected verification document could not be opened.",
        ),
      );
    } finally {
      setOpeningFile("");
    }
  }

  return (
    <div className="page-stack">
      <section className="page-intro">
        <div>
          <h2>Provider verification reviews</h2>
          <p>
            Identity documents are private and opened through authorized
            Firebase Storage access.
          </p>
        </div>
      </section>

      <MessageBanner
        message={errorMessage}
        type="error"
        onDismiss={() => setErrorMessage("")}
      />
      <MessageBanner
        message={successMessage}
        type="success"
        onDismiss={() => setSuccessMessage("")}
      />

      <section className="content-card">
        <div className="filter-bar">
          <label className="select-control">
            <span>Verification status</span>
            <select
              value={statusFilter}
              disabled={Boolean(selectedProviderId)}
              onChange={(event) => setStatusFilter(event.target.value)}
            >
              <option value="pending">Pending</option>
              <option value="verified">Verified</option>
              <option value="rejected">Rejected</option>
            </select>
          </label>
          {selectedProviderId && (
            <div className="selected-record-note">
              <span>Showing one selected provider record.</span>
              <button
                type="button"
                className="button button-small button-secondary"
                onClick={() => setSearchParams({})}
              >
                Show filtered list
              </button>
            </div>
          )}
        </div>

        {isLoading ? (
          <LoadingSpinner label="Loading verification submissions..." />
        ) : submissions.length === 0 ? (
          <EmptyState
            title="No verification submissions"
            message={
              selectedProviderId
                ? "This provider does not have a verification record."
                : `There are no ${statusFilter} verification submissions.`
            }
          />
        ) : (
          <div className="verification-list">
            {submissions.map((submission) => {
              const profile = submission.profile;
              const displayName =
                submission.user.displayName ||
                profile.displayName ||
                "Unnamed provider";
              const certificates = Array.isArray(submission.certificatePaths)
                ? submission.certificatePaths
                : [];

              return (
                <article className="verification-card" key={submission.id}>
                  <div className="verification-heading">
                    <div>
                      <span className="header-eyebrow">Provider submission</span>
                      <h3>{displayName}</h3>
                      <p>
                        {submission.user.email ||
                          submission.user.phoneNumber ||
                          "No contact details"}
                      </p>
                    </div>
                    <StatusBadge status={submission.status} />
                  </div>

                  <dl className="details-grid verification-details">
                    <div><dt>Document type</dt><dd>{submission.documentType || "Not provided"}</dd></div>
                    <div><dt>Submitted</dt><dd>{formatDate(submission.submittedAt)}</dd></div>
                    <div><dt>Categories</dt><dd>{Array.isArray(profile.categoryIds) && profile.categoryIds.length > 0 ? profile.categoryIds.join(", ") : "Not selected"}</dd></div>
                    <div><dt>Experience</dt><dd>{profile.experienceYears || 0} years</dd></div>
                    <div><dt>Service area</dt><dd>{profile.locationId || "Not provided"}</dd></div>
                    <div><dt>Account status</dt><dd><StatusBadge status={submission.user.accountStatus || "unknown"} /></dd></div>
                  </dl>

                  <div className="document-actions">
                    <button
                      type="button"
                      className="button button-secondary"
                      disabled={
                        !submission.frontDocumentPath ||
                        openingFile === `${submission.id}-front`
                      }
                      onClick={() =>
                        openFile(
                          submission.frontDocumentPath,
                          `${submission.id}-front`,
                        )
                      }
                    >
                      {openingFile === `${submission.id}-front`
                        ? "Opening..."
                        : "Open NIC front"}
                    </button>
                    <button
                      type="button"
                      className="button button-secondary"
                      disabled={
                        !submission.backDocumentPath ||
                        openingFile === `${submission.id}-back`
                      }
                      onClick={() =>
                        openFile(
                          submission.backDocumentPath,
                          `${submission.id}-back`,
                        )
                      }
                    >
                      {openingFile === `${submission.id}-back`
                        ? "Opening..."
                        : "Open NIC back"}
                    </button>
                    {certificates.map((certificatePath, index) => {
                      const fileKey = `${submission.id}-certificate-${index}`;
                      return (
                        <button
                          type="button"
                          className="button button-secondary"
                          key={certificatePath}
                          disabled={openingFile === fileKey}
                          onClick={() => openFile(certificatePath, fileKey)}
                        >
                          {openingFile === fileKey
                            ? "Opening..."
                            : `Open certificate ${index + 1}`}
                        </button>
                      );
                    })}
                  </div>

                  {submission.status === "rejected" &&
                    submission.rejectionReason && (
                      <div className="rejection-note">
                        <strong>Rejection reason</strong>
                        <p>{submission.rejectionReason}</p>
                      </div>
                    )}

                  {submission.status === "pending" && (
                    <div className="review-panel">
                      <label className="form-field">
                        <span>Rejection reason</span>
                        <textarea
                          rows="3"
                          value={rejectionReasons[submission.providerId] || ""}
                          placeholder="Required only when rejecting"
                          onChange={(event) =>
                            setRejectionReasons((current) => ({
                              ...current,
                              [submission.providerId]: event.target.value,
                            }))
                          }
                          disabled={isProcessing}
                        />
                      </label>
                      <div className="action-group">
                        <button
                          type="button"
                          className="button button-success"
                          onClick={() =>
                            requestDecision(submission, "verified")
                          }
                          disabled={isProcessing}
                        >
                          Approve
                        </button>
                        <button
                          type="button"
                          className="button button-danger"
                          onClick={() =>
                            requestDecision(submission, "rejected")
                          }
                          disabled={isProcessing}
                        >
                          Reject
                        </button>
                      </div>
                    </div>
                  )}
                </article>
              );
            })}
          </div>
        )}
      </section>

      <ConfirmDialog
        isOpen={Boolean(pendingDecision)}
        title={
          pendingDecision?.decision === "verified"
            ? "Approve this provider?"
            : "Reject this provider?"
        }
        message={
          pendingDecision
            ? `This will update both verification documents for ${pendingDecision.submission.user.displayName || "this provider"}.`
            : ""
        }
        confirmLabel={
          pendingDecision?.decision === "verified" ? "Approve" : "Reject"
        }
        confirmTone={
          pendingDecision?.decision === "verified" ? "success" : "danger"
        }
        isProcessing={isProcessing}
        onCancel={() => setPendingDecision(null)}
        onConfirm={confirmDecision}
      >
        {pendingDecision?.decision === "rejected" && (
          <div className="rejection-note">
            <strong>Reason</strong>
            <p>{pendingDecision.rejectionReason}</p>
          </div>
        )}
      </ConfirmDialog>
    </div>
  );
}

export default ProviderVerificationsPage;
