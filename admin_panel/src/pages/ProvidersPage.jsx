import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import ConfirmDialog from "../components/ConfirmDialog";
import EmptyState from "../components/EmptyState";
import LoadingSpinner from "../components/LoadingSpinner";
import MessageBanner from "../components/MessageBanner";
import StatusBadge from "../components/StatusBadge";
import {
  getProviders,
  updateProviderAccountStatus,
} from "../services/providerService";
import { getDataErrorMessage, getInitials } from "../utils/formatters";

function ProvidersPage() {
  const [providers, setProviders] = useState([]);
  const [searchText, setSearchText] = useState("");
  const [verificationFilter, setVerificationFilter] = useState("all");
  const [availabilityFilter, setAvailabilityFilter] = useState("all");
  const [selectedProvider, setSelectedProvider] = useState(null);
  const [pendingAction, setPendingAction] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isProcessing, setIsProcessing] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [successMessage, setSuccessMessage] = useState("");

  useEffect(() => {
    let isActive = true;

    async function loadProviders() {
      try {
        const providerList = await getProviders();
        if (isActive) {
          setProviders(providerList);
        }
      } catch (error) {
        console.error("Providers could not be loaded:", error);
        if (isActive) {
          setErrorMessage(
            getDataErrorMessage(
              error,
              "Providers could not be loaded. Please refresh the page.",
            ),
          );
        }
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    }

    loadProviders();
    return () => {
      isActive = false;
    };
  }, []);

  const visibleProviders = useMemo(() => {
    const queryText = searchText.trim().toLowerCase();

    return providers.filter((provider) => {
      const displayName =
        provider.displayName || provider.profile.displayName || "";
      const matchesSearch =
        !queryText ||
        displayName.toLowerCase().includes(queryText) ||
        provider.email?.toLowerCase().includes(queryText);
      const matchesVerification =
        verificationFilter === "all" ||
        provider.profile.verificationStatus === verificationFilter;
      const matchesAvailability =
        availabilityFilter === "all" ||
        provider.profile.availabilityStatus === availabilityFilter;

      return matchesSearch && matchesVerification && matchesAvailability;
    });
  }, [
    availabilityFilter,
    providers,
    searchText,
    verificationFilter,
  ]);

  function requestStatusChange(provider) {
    const targetStatus =
      provider.accountStatus === "active" ? "suspended" : "active";
    setPendingAction({ provider, targetStatus });
  }

  async function confirmStatusChange() {
    if (!pendingAction) {
      return;
    }

    setIsProcessing(true);
    setErrorMessage("");
    setSuccessMessage("");

    try {
      await updateProviderAccountStatus(
        pendingAction.provider.id,
        pendingAction.targetStatus,
      );
      setProviders((currentProviders) =>
        currentProviders.map((provider) =>
          provider.id === pendingAction.provider.id
            ? { ...provider, accountStatus: pendingAction.targetStatus }
            : provider,
        ),
      );
      setSelectedProvider((current) =>
        current?.id === pendingAction.provider.id
          ? { ...current, accountStatus: pendingAction.targetStatus }
          : current,
      );
      setSuccessMessage(
        `${pendingAction.provider.displayName || "Provider"} is now ${pendingAction.targetStatus}.`,
      );
      setPendingAction(null);
    } catch (error) {
      console.error("Provider status could not be updated:", error);
      setErrorMessage(
        getDataErrorMessage(
          error,
          "The provider account status could not be updated.",
        ),
      );
    } finally {
      setIsProcessing(false);
    }
  }

  if (isLoading) {
    return <LoadingSpinner label="Loading providers..." />;
  }

  return (
    <div className="page-stack">
      <section className="page-intro">
        <div>
          <h2>Service providers</h2>
          <p>
            Review provider profiles and manage account access. Verification
            decisions remain on the verification page.
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
        <div className="filter-bar filter-bar-wide">
          <label className="search-control">
            <span className="sr-only">Search providers</span>
            <input
              type="search"
              placeholder="Search by name or email"
              value={searchText}
              onChange={(event) => setSearchText(event.target.value)}
            />
          </label>
          <label className="select-control">
            <span>Verification</span>
            <select
              value={verificationFilter}
              onChange={(event) => setVerificationFilter(event.target.value)}
            >
              <option value="all">All verification states</option>
              <option value="not_submitted">Not submitted</option>
              <option value="pending">Pending</option>
              <option value="verified">Verified</option>
              <option value="rejected">Rejected</option>
            </select>
          </label>
          <label className="select-control">
            <span>Availability</span>
            <select
              value={availabilityFilter}
              onChange={(event) => setAvailabilityFilter(event.target.value)}
            >
              <option value="all">All availability states</option>
              <option value="available">Available</option>
              <option value="busy">Busy</option>
              <option value="unavailable">Unavailable</option>
            </select>
          </label>
        </div>

        {visibleProviders.length === 0 ? (
          <EmptyState
            title="No providers found"
            message={
              providers.length === 0
                ? "Provider accounts will appear here after registration."
                : "Try changing the search text or filters."
            }
          />
        ) : (
          <div className="table-scroll">
            <table className="data-table provider-data-table">
              <thead>
                <tr>
                  <th>Provider</th>
                  <th>Categories</th>
                  <th>Availability</th>
                  <th>Verification</th>
                  <th>Rating</th>
                  <th>Jobs</th>
                  <th>Account</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {visibleProviders.map((provider) => {
                  const profile = provider.profile;
                  const displayName =
                    provider.displayName ||
                    profile.displayName ||
                    "Unnamed provider";

                  return (
                    <tr key={provider.id}>
                      <td>
                        <div className="person-cell">
                          <span className="person-avatar">
                            {getInitials(displayName)}
                          </span>
                          <span>
                            <strong>{displayName}</strong>
                            <small>
                              {provider.email ||
                                provider.phoneNumber ||
                                "No contact details"}
                            </small>
                          </span>
                        </div>
                      </td>
                      <td>
                        {provider.categoryNames.length > 0
                          ? provider.categoryNames.join(", ")
                          : "Not selected"}
                      </td>
                      <td>
                        <StatusBadge
                          status={profile.availabilityStatus || "unavailable"}
                        />
                      </td>
                      <td>
                        <StatusBadge
                          status={
                            profile.verificationStatus || "not_submitted"
                          }
                        />
                      </td>
                      <td>{Number(profile.ratingAverage || 0).toFixed(1)}</td>
                      <td>{profile.completedJobCount || 0}</td>
                      <td><StatusBadge status={provider.accountStatus} /></td>
                      <td>
                        <div className="action-group">
                          <button
                            type="button"
                            className="button button-small button-secondary"
                            onClick={() => setSelectedProvider(provider)}
                          >
                            Details
                          </button>
                          <Link
                            className="button button-small button-secondary"
                            to={`/provider-verifications?providerId=${provider.id}`}
                          >
                            Verification
                          </Link>
                          <button
                            type="button"
                            className={`button button-small ${
                              provider.accountStatus === "active"
                                ? "button-danger-soft"
                                : "button-success-soft"
                            }`}
                            onClick={() => requestStatusChange(provider)}
                          >
                            {provider.accountStatus === "active"
                              ? "Suspend"
                              : "Activate"}
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {selectedProvider && (
        <div className="modal-backdrop" role="presentation">
          <div
            className="modal-card modal-wide"
            role="dialog"
            aria-modal="true"
            aria-labelledby="provider-details-title"
          >
            <div className="card-heading">
              <div>
                <h2 id="provider-details-title">Provider details</h2>
                <p>Account and public profile information.</p>
              </div>
              <button
                type="button"
                className="icon-button"
                aria-label="Close provider details"
                onClick={() => setSelectedProvider(null)}
              >
                ×
              </button>
            </div>
            <dl className="details-grid">
              <div><dt>Name</dt><dd>{selectedProvider.displayName || selectedProvider.profile.displayName || "Not provided"}</dd></div>
              <div><dt>Email</dt><dd>{selectedProvider.email || "Not provided"}</dd></div>
              <div><dt>Phone</dt><dd>{selectedProvider.phoneNumber || "Not provided"}</dd></div>
              <div><dt>Categories</dt><dd>{selectedProvider.categoryNames.join(", ") || "Not selected"}</dd></div>
              <div><dt>Availability</dt><dd><StatusBadge status={selectedProvider.profile.availabilityStatus || "unavailable"} /></dd></div>
              <div><dt>Verification</dt><dd><StatusBadge status={selectedProvider.profile.verificationStatus || "not_submitted"} /></dd></div>
              <div><dt>Experience</dt><dd>{selectedProvider.profile.experienceYears || 0} years</dd></div>
              <div><dt>Working hours</dt><dd>{selectedProvider.profile.workingHours || "Not provided"}</dd></div>
              <div><dt>Rating</dt><dd>{Number(selectedProvider.profile.ratingAverage || 0).toFixed(1)} ({selectedProvider.profile.reviewCount || 0} reviews)</dd></div>
              <div><dt>Completed jobs</dt><dd>{selectedProvider.profile.completedJobCount || 0}</dd></div>
              <div><dt>Account status</dt><dd><StatusBadge status={selectedProvider.accountStatus} /></dd></div>
              <div><dt>Service area</dt><dd>{selectedProvider.profile.locationId || "Not provided"}{selectedProvider.profile.serviceRadiusKm ? ` · ${selectedProvider.profile.serviceRadiusKm} km` : ""}</dd></div>
            </dl>
          </div>
        </div>
      )}

      <ConfirmDialog
        isOpen={Boolean(pendingAction)}
        title="Change provider status?"
        message={
          pendingAction
            ? `Set ${pendingAction.provider.displayName || "this provider"} to ${pendingAction.targetStatus}?`
            : ""
        }
        confirmLabel={
          pendingAction?.targetStatus === "active" ? "Activate" : "Suspend"
        }
        confirmTone={
          pendingAction?.targetStatus === "active" ? "success" : "danger"
        }
        isProcessing={isProcessing}
        onCancel={() => setPendingAction(null)}
        onConfirm={confirmStatusChange}
      />
    </div>
  );
}

export default ProvidersPage;
