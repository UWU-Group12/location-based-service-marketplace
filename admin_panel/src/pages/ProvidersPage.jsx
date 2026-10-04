import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import ConfirmDialog from "../components/ConfirmDialog";
import EmptyState from "../components/EmptyState";
import LoadingSpinner from "../components/LoadingSpinner";
import MessageBanner from "../components/MessageBanner";
import StatusBadge from "../components/StatusBadge";
import {
  createProvider,
  getProviders,
  updateProviderAccountStatus,
  updateProviderDetails,
  uploadProviderProfilePhoto,
} from "../services/providerService";
import { getAuthorizedFileUrl } from "../services/storageService";
import { getDataErrorMessage, getInitials } from "../utils/formatters";

function ProvidersPage() {
  const [providers, setProviders] = useState([]);
  const [searchText, setSearchText] = useState("");
  const [verificationFilter, setVerificationFilter] = useState("all");
  const [availabilityFilter, setAvailabilityFilter] = useState("all");
  const [selectedProvider, setSelectedProvider] = useState(null);
  const [isCreatingProvider, setIsCreatingProvider] = useState(false);
  const [isEditingProvider, setIsEditingProvider] = useState(false);
  const [editProviderForm, setEditProviderForm] = useState(null);
  const [createProviderForm, setCreateProviderForm] = useState(null);
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

  function openCreateProviderForm() {
    setCreateProviderForm({
      displayName: "",
      email: "",
      phoneNumber: "",
      categories: "",
      availabilityStatus: "unavailable",
      verificationStatus: "not_submitted",
      experienceYears: 0,
      workingHours: "",
      bio: "",
      accountStatus: "active",
      serviceRadiusKm: 10,
      photoPath: "",
      photoPreview: "",
      photoFile: null,
    });
    setIsCreatingProvider(true);
  }

  async function openProviderEditForm() {
    if (!selectedProvider) {
      return;
    }

    const existingPhotoPath =
      selectedProvider.photoPath ||
      selectedProvider.profile?.profileImagePath ||
      selectedProvider.profile?.photoPath ||
      "";

    let photoPreview = "";

    if (existingPhotoPath) {
      try {
        photoPreview = await getAuthorizedFileUrl(existingPhotoPath);
      } catch (error) {
        console.warn("Could not load provider photo preview:", error);
      }
    }

    setEditProviderForm({
      displayName:
        selectedProvider.displayName ||
        selectedProvider.profile.displayName ||
        "",
      email: selectedProvider.email || "",
      phoneNumber: selectedProvider.phoneNumber || "",
      availabilityStatus:
        selectedProvider.profile.availabilityStatus || "unavailable",
      verificationStatus:
        selectedProvider.profile.verificationStatus || "not_submitted",
      experienceYears: selectedProvider.profile.experienceYears || 0,
      workingHours: selectedProvider.profile.workingHours || "",
      bio: selectedProvider.profile.bio || "",
      accountStatus: selectedProvider.accountStatus || "active",
      serviceRadiusKm: selectedProvider.profile.serviceRadiusKm || "",
      photoPath: existingPhotoPath,
      photoPreview,
      photoFile: null,
    });
    setIsEditingProvider(true);
  }

  function handleEditProviderChange(field, value) {
    setEditProviderForm((current) => ({
      ...current,
      [field]: value,
    }));
  }

  function handlePhotoSelection(event, formSetter) {
    const selectedFile = event.target.files?.[0];

    if (!selectedFile) {
      return;
    }

    if (!selectedFile.type.startsWith("image/")) {
      setErrorMessage("Please choose a valid image file for the provider photo.");
      event.target.value = "";
      return;
    }

    formSetter((current) => ({
      ...current,
      photoFile: selectedFile,
      photoPreview: URL.createObjectURL(selectedFile),
    }));
    setErrorMessage("");
  }

  async function saveEditedProvider() {
    if (!selectedProvider || !editProviderForm) {
      return;
    }

    setIsProcessing(true);
    setErrorMessage("");
    setSuccessMessage("");

    try {
      const normalizedProfile = {
        availabilityStatus: editProviderForm.availabilityStatus,
        verificationStatus: editProviderForm.verificationStatus,
        experienceYears: Number(editProviderForm.experienceYears || 0),
        workingHours: editProviderForm.workingHours.trim(),
        bio: editProviderForm.bio.trim(),
        serviceRadiusKm: Number(editProviderForm.serviceRadiusKm || 0),
      };

      const updatePayload = {
        displayName: editProviderForm.displayName.trim(),
        email: editProviderForm.email.trim(),
        phoneNumber: editProviderForm.phoneNumber.trim(),
        accountStatus: editProviderForm.accountStatus,
        profile: normalizedProfile,
      };

      if (editProviderForm.photoFile) {
        const uploadedPhotoPath = await uploadProviderProfilePhoto(
          selectedProvider.id,
          editProviderForm.photoFile,
        );

        if (uploadedPhotoPath) {
          updatePayload.photoPath = uploadedPhotoPath;
          updatePayload.profile.profileImagePath = uploadedPhotoPath;
        }
      }

      await updateProviderDetails(selectedProvider.id, updatePayload);

      const updatedSelectedProvider = {
        ...selectedProvider,
        displayName: editProviderForm.displayName.trim(),
        email: editProviderForm.email.trim(),
        phoneNumber: editProviderForm.phoneNumber.trim(),
        accountStatus: editProviderForm.accountStatus,
        photoPath:
          updatePayload.photoPath || selectedProvider.photoPath || "",
        profile: {
          ...selectedProvider.profile,
          ...normalizedProfile,
          profileImagePath:
            updatePayload.profile.profileImagePath ||
            selectedProvider.profile?.profileImagePath ||
            "",
        },
      };

      setProviders((currentProviders) =>
        currentProviders.map((provider) =>
          provider.id === selectedProvider.id
            ? {
                ...provider,
                displayName: editProviderForm.displayName.trim(),
                email: editProviderForm.email.trim(),
                phoneNumber: editProviderForm.phoneNumber.trim(),
                accountStatus: editProviderForm.accountStatus,
                photoPath:
                  updatePayload.photoPath || provider.photoPath || "",
                profile: {
                  ...provider.profile,
                  ...normalizedProfile,
                  profileImagePath:
                    updatePayload.profile.profileImagePath ||
                    provider.profile?.profileImagePath ||
                    "",
                },
              }
            : provider,
        ),
      );
      setSelectedProvider(updatedSelectedProvider);
      setIsEditingProvider(false);
      setEditProviderForm(null);
      setSuccessMessage("Provider details were updated successfully.");
    } catch (error) {
      console.error("Provider details could not be updated:", error);
      setErrorMessage(
        getDataErrorMessage(
          error,
          "The provider details could not be updated.",
        ),
      );
    } finally {
      setIsProcessing(false);
    }
  }

  async function saveNewProvider() {
    if (!createProviderForm) {
      return;
    }

    setIsProcessing(true);
    setErrorMessage("");
    setSuccessMessage("");

    try {
      const categoryIds = createProviderForm.categories
        .split(",")
        .map((value) => value.trim())
        .filter(Boolean);

      const createdProvider = await createProvider({
        displayName: createProviderForm.displayName.trim(),
        email: createProviderForm.email.trim(),
        phoneNumber: createProviderForm.phoneNumber.trim(),
        categories: categoryIds.join(", "),
        categoryIds,
        availabilityStatus: createProviderForm.availabilityStatus,
        verificationStatus: createProviderForm.verificationStatus,
        experienceYears: Number(createProviderForm.experienceYears || 0),
        workingHours: createProviderForm.workingHours.trim(),
        bio: createProviderForm.bio.trim(),
        accountStatus: createProviderForm.accountStatus,
        serviceRadiusKm: Number(createProviderForm.serviceRadiusKm || 10),
      });

      if (createProviderForm.photoFile) {
        const uploadedPhotoPath = await uploadProviderProfilePhoto(
          createdProvider.id,
          createProviderForm.photoFile,
        );

        if (uploadedPhotoPath) {
          await updateProviderDetails(createdProvider.id, {
            photoPath: uploadedPhotoPath,
            profile: {
              profileImagePath: uploadedPhotoPath,
            },
          });

          createdProvider.photoPath = uploadedPhotoPath;
          createdProvider.profile.profileImagePath = uploadedPhotoPath;
        }
      }

      setProviders((currentProviders) => [createdProvider, ...currentProviders]);
      setSelectedProvider(createdProvider);
      setIsCreatingProvider(false);
      setCreateProviderForm(null);
      setSuccessMessage(`${createdProvider.displayName} was added successfully.`);
    } catch (error) {
      console.error("Provider could not be created:", error);
      setErrorMessage(
        getDataErrorMessage(
          error,
          "The provider could not be created.",
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
        <div className="page-intro-actions">
          <button
            type="button"
            className="button button-primary"
            onClick={openCreateProviderForm}
          >
            Add Provider
          </button>
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
                            className={`button button-small ${provider.accountStatus === "active"
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

      {isCreatingProvider && createProviderForm && (
        <div className="modal-backdrop" role="presentation">
          <div
            className="modal-card modal-wide"
            role="dialog"
            aria-modal="true"
            aria-labelledby="provider-create-title"
          >
            <div className="card-heading">
              <div>
                <h2 id="provider-create-title">Add provider</h2>
                <p>Create a new provider account and profile.</p>
              </div>
              <button
                type="button"
                className="icon-button"
                aria-label="Close add provider form"
                onClick={() => {
                  setIsCreatingProvider(false);
                  setCreateProviderForm(null);
                }}
              >
                ×
              </button>
            </div>

            <div className="form-stack">
              <div className="details-grid">
                <div className="form-field">
                  <label htmlFor="provider-create-name">Name</label>
                  <input
                    id="provider-create-name"
                    value={createProviderForm.displayName}
                    onChange={(event) =>
                      setCreateProviderForm((current) => ({
                        ...current,
                        displayName: event.target.value,
                      }))
                    }
                  />
                </div>
                <div className="form-field">
                  <label htmlFor="provider-create-email">Email</label>
                  <input
                    id="provider-create-email"
                    type="email"
                    value={createProviderForm.email}
                    onChange={(event) =>
                      setCreateProviderForm((current) => ({
                        ...current,
                        email: event.target.value,
                      }))
                    }
                  />
                </div>
                <div className="form-field">
                  <label htmlFor="provider-create-phone">Phone</label>
                  <input
                    id="provider-create-phone"
                    value={createProviderForm.phoneNumber}
                    onChange={(event) =>
                      setCreateProviderForm((current) => ({
                        ...current,
                        phoneNumber: event.target.value,
                      }))
                    }
                  />
                </div>
                <div className="form-field">
                  <label htmlFor="provider-create-categories">Categories</label>
                  <input
                    id="provider-create-categories"
                    value={createProviderForm.categories}
                    onChange={(event) =>
                      setCreateProviderForm((current) => ({
                        ...current,
                        categories: event.target.value,
                      }))
                    }
                    placeholder="electrician, plumbing"
                  />
                </div>
                <div className="form-field">
                  <label htmlFor="provider-create-account-status">Account status</label>
                  <select
                    id="provider-create-account-status"
                    value={createProviderForm.accountStatus}
                    onChange={(event) =>
                      setCreateProviderForm((current) => ({
                        ...current,
                        accountStatus: event.target.value,
                      }))
                    }
                  >
                    <option value="active">Active</option>
                    <option value="suspended">Suspended</option>
                    <option value="disabled">Disabled</option>
                  </select>
                </div>
                <div className="form-field">
                  <label htmlFor="provider-create-availability">Availability</label>
                  <select
                    id="provider-create-availability"
                    value={createProviderForm.availabilityStatus}
                    onChange={(event) =>
                      setCreateProviderForm((current) => ({
                        ...current,
                        availabilityStatus: event.target.value,
                      }))
                    }
                  >
                    <option value="available">Available</option>
                    <option value="busy">Busy</option>
                    <option value="unavailable">Unavailable</option>
                  </select>
                </div>
                <div className="form-field">
                  <label htmlFor="provider-create-verification">Verification</label>
                  <select
                    id="provider-create-verification"
                    value={createProviderForm.verificationStatus}
                    onChange={(event) =>
                      setCreateProviderForm((current) => ({
                        ...current,
                        verificationStatus: event.target.value,
                      }))
                    }
                  >
                    <option value="not_submitted">Not submitted</option>
                    <option value="pending">Pending</option>
                    <option value="verified">Verified</option>
                    <option value="rejected">Rejected</option>
                  </select>
                </div>
                <div className="form-field">
                  <label htmlFor="provider-create-experience">Experience (years)</label>
                  <input
                    id="provider-create-experience"
                    type="number"
                    min="0"
                    value={createProviderForm.experienceYears}
                    onChange={(event) =>
                      setCreateProviderForm((current) => ({
                        ...current,
                        experienceYears: event.target.value,
                      }))
                    }
                  />
                </div>
                <div className="form-field">
                  <label htmlFor="provider-create-hours">Working hours</label>
                  <input
                    id="provider-create-hours"
                    value={createProviderForm.workingHours}
                    onChange={(event) =>
                      setCreateProviderForm((current) => ({
                        ...current,
                        workingHours: event.target.value,
                      }))
                    }
                  />
                </div>
                <div className="form-field">
                  <label htmlFor="provider-create-radius">Service radius (km)</label>
                  <input
                    id="provider-create-radius"
                    type="number"
                    min="0"
                    value={createProviderForm.serviceRadiusKm}
                    onChange={(event) =>
                      setCreateProviderForm((current) => ({
                        ...current,
                        serviceRadiusKm: event.target.value,
                      }))
                    }
                  />
                </div>
                <div className="form-field details-grid-full">
                  <label htmlFor="provider-create-bio">Bio</label>
                  <textarea
                    id="provider-create-bio"
                    rows="4"
                    value={createProviderForm.bio}
                    onChange={(event) =>
                      setCreateProviderForm((current) => ({
                        ...current,
                        bio: event.target.value,
                      }))
                    }
                  />
                </div>
                <div className="form-field details-grid-full">
                  <label>Profile photo</label>
                  <div className="photo-upload-box">
                    {createProviderForm.photoPreview ? (
                      <img
                        src={createProviderForm.photoPreview}
                        alt="Provider preview"
                        className="photo-preview"
                      />
                    ) : (
                      <div className="photo-upload-placeholder">No image</div>
                    )}
                    <label className="photo-upload-label">
                      <input
                        type="file"
                        accept="image/*"
                        onChange={(event) =>
                          handlePhotoSelection(event, setCreateProviderForm)
                        }
                      />
                      <span>
                        {createProviderForm.photoFile
                          ? "Replace photo"
                          : "Upload photo"}
                      </span>
                    </label>
                  </div>
                </div>
              </div>

              <div className="modal-actions">
                <button
                  type="button"
                  className="button button-secondary"
                  onClick={() => {
                    setIsCreatingProvider(false);
                    setCreateProviderForm(null);
                  }}
                  disabled={isProcessing}
                >
                  Cancel
                </button>
                <button
                  type="button"
                  className="button button-primary"
                  onClick={saveNewProvider}
                  disabled={isProcessing}
                >
                  {isProcessing ? "Creating..." : "Create provider"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

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
              <div className="card-header-actions">
                {!isEditingProvider && (
                  <button
                    type="button"
                    className="button button-secondary"
                    onClick={openProviderEditForm}
                  >
                    Edit
                  </button>
                )}
                <button
                  type="button"
                  className="icon-button"
                  aria-label="Close provider details"
                  onClick={() => {
                    setSelectedProvider(null);
                    setIsEditingProvider(false);
                    setEditProviderForm(null);
                  }}
                >
                  ×
                </button>
              </div>
            </div>

            {isEditingProvider && editProviderForm ? (
              <div className="form-stack">
                <div className="details-grid">
                  <div className="form-field">
                    <label htmlFor="provider-edit-name">Name</label>
                    <input
                      id="provider-edit-name"
                      value={editProviderForm.displayName}
                      onChange={(event) =>
                        handleEditProviderChange("displayName", event.target.value)
                      }
                    />
                  </div>
                  <div className="form-field">
                    <label htmlFor="provider-edit-email">Email</label>
                    <input
                      id="provider-edit-email"
                      type="email"
                      value={editProviderForm.email}
                      onChange={(event) =>
                        handleEditProviderChange("email", event.target.value)
                      }
                    />
                  </div>
                  <div className="form-field">
                    <label htmlFor="provider-edit-phone">Phone</label>
                    <input
                      id="provider-edit-phone"
                      value={editProviderForm.phoneNumber}
                      onChange={(event) =>
                        handleEditProviderChange("phoneNumber", event.target.value)
                      }
                    />
                  </div>
                  <div className="form-field">
                    <label htmlFor="provider-edit-account-status">Account status</label>
                    <select
                      id="provider-edit-account-status"
                      value={editProviderForm.accountStatus}
                      onChange={(event) =>
                        handleEditProviderChange("accountStatus", event.target.value)
                      }
                    >
                      <option value="active">Active</option>
                      <option value="suspended">Suspended</option>
                      <option value="disabled">Disabled</option>
                    </select>
                  </div>
                  <div className="form-field">
                    <label htmlFor="provider-edit-availability">Availability</label>
                    <select
                      id="provider-edit-availability"
                      value={editProviderForm.availabilityStatus}
                      onChange={(event) =>
                        handleEditProviderChange(
                          "availabilityStatus",
                          event.target.value,
                        )
                      }
                    >
                      <option value="available">Available</option>
                      <option value="busy">Busy</option>
                      <option value="unavailable">Unavailable</option>
                    </select>
                  </div>
                  <div className="form-field">
                    <label htmlFor="provider-edit-verification">Verification</label>
                    <select
                      id="provider-edit-verification"
                      value={editProviderForm.verificationStatus}
                      onChange={(event) =>
                        handleEditProviderChange(
                          "verificationStatus",
                          event.target.value,
                        )
                      }
                    >
                      <option value="not_submitted">Not submitted</option>
                      <option value="pending">Pending</option>
                      <option value="verified">Verified</option>
                      <option value="rejected">Rejected</option>
                    </select>
                  </div>
                  <div className="form-field">
                    <label htmlFor="provider-edit-experience">Experience (years)</label>
                    <input
                      id="provider-edit-experience"
                      type="number"
                      min="0"
                      value={editProviderForm.experienceYears}
                      onChange={(event) =>
                        handleEditProviderChange(
                          "experienceYears",
                          event.target.value,
                        )
                      }
                    />
                  </div>
                  <div className="form-field">
                    <label htmlFor="provider-edit-working-hours">Working hours</label>
                    <input
                      id="provider-edit-working-hours"
                      value={editProviderForm.workingHours}
                      onChange={(event) =>
                        handleEditProviderChange("workingHours", event.target.value)
                      }
                    />
                  </div>
                  <div className="form-field">
                    <label htmlFor="provider-edit-radius">Service radius (km)</label>
                    <input
                      id="provider-edit-radius"
                      type="number"
                      min="0"
                      value={editProviderForm.serviceRadiusKm}
                      onChange={(event) =>
                        handleEditProviderChange(
                          "serviceRadiusKm",
                          event.target.value,
                        )
                      }
                    />
                  </div>
                  <div className="form-field details-grid-full">
                    <label htmlFor="provider-edit-bio">Bio</label>
                    <textarea
                      id="provider-edit-bio"
                      rows="4"
                      value={editProviderForm.bio}
                      onChange={(event) =>
                        handleEditProviderChange("bio", event.target.value)
                      }
                    />
                  </div>
                  <div className="form-field details-grid-full">
                    <label>Profile photo</label>
                    <div className="photo-upload-box">
                      {editProviderForm.photoPreview ? (
                        <img
                          src={editProviderForm.photoPreview}
                          alt="Provider preview"
                          className="photo-preview"
                        />
                      ) : (
                        <div className="photo-upload-placeholder">No image</div>
                      )}
                      <label className="photo-upload-label">
                        <input
                          type="file"
                          accept="image/*"
                          onChange={(event) =>
                            handlePhotoSelection(event, setEditProviderForm)
                          }
                        />
                        <span>
                          {editProviderForm.photoFile
                            ? "Replace photo"
                            : "Upload photo"}
                        </span>
                      </label>
                    </div>
                  </div>
                </div>

                <div className="modal-actions">
                  <button
                    type="button"
                    className="button button-secondary"
                    onClick={() => {
                      setIsEditingProvider(false);
                      setEditProviderForm(null);
                    }}
                    disabled={isProcessing}
                  >
                    Cancel
                  </button>
                  <button
                    type="button"
                    className="button button-primary"
                    onClick={saveEditedProvider}
                    disabled={isProcessing}
                  >
                    {isProcessing ? "Saving..." : "Save changes"}
                  </button>
                </div>
              </div>
            ) : (
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
                <div><dt>Service area</dt><dd>{selectedProvider.profile.serviceRadiusKm ? `${selectedProvider.profile.serviceRadiusKm} km radius` : "Not provided"}</dd></div>
                <div className="details-grid-full"><dt>Bio</dt><dd>{selectedProvider.profile.bio || "Not provided"}</dd></div>
              </dl>
            )}
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
