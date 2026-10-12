import { useEffect, useMemo, useState } from "react";
import ConfirmDialog from "../components/ConfirmDialog";
import EmptyState from "../components/EmptyState";
import LoadingSpinner from "../components/LoadingSpinner";
import MessageBanner from "../components/MessageBanner";
import StatusBadge from "../components/StatusBadge";
import {
  createLocation,
  getLocations,
  setLocationActive,
  updateLocation,
} from "../services/locationService";
import { getDataErrorMessage } from "../utils/formatters";

const emptyForm = {
  id: "",
  name: "",
  district: "",
  province: "",
  active: true,
};

function LocationsPage() {
  const [locations, setLocations] = useState([]);
  const [searchText, setSearchText] = useState("");
  const [editingLocation, setEditingLocation] = useState(null);
  const [locationForm, setLocationForm] = useState(emptyForm);
  const [locationToDeactivate, setLocationToDeactivate] = useState(null);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [isProcessing, setIsProcessing] = useState(false);
  const [formError, setFormError] = useState("");
  const [errorMessage, setErrorMessage] = useState("");
  const [successMessage, setSuccessMessage] = useState("");

  useEffect(() => {
    let isActive = true;

    async function loadLocations() {
      try {
        const locationList = await getLocations();
        if (isActive) {
          setLocations(locationList);
        }
      } catch (error) {
        console.error("Locations could not be loaded:", error);
        if (isActive) {
          setErrorMessage(
            getDataErrorMessage(
              error,
              "Locations could not be loaded. Please refresh the page.",
            ),
          );
        }
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    }

    loadLocations();
    return () => {
      isActive = false;
    };
  }, []);

  const visibleLocations = useMemo(() => {
    const queryText = searchText.trim().toLowerCase();

    return locations.filter(
      (location) =>
        !queryText ||
        location.id?.toLowerCase().includes(queryText) ||
        location.name?.toLowerCase().includes(queryText) ||
        location.district?.toLowerCase().includes(queryText) ||
        location.province?.toLowerCase().includes(queryText),
    );
  }, [locations, searchText]);

  function openAddForm() {
    setEditingLocation(null);
    setLocationForm(emptyForm);
    setFormError("");
    setIsFormOpen(true);
  }

  function openEditForm(location) {
    setEditingLocation(location);
    setLocationForm({
      id: location.id,
      name: location.name || "",
      district: location.district || "",
      province: location.province || "",
      active: Boolean(location.active),
    });
    setFormError("");
    setIsFormOpen(true);
  }

  function closeForm() {
    setIsFormOpen(false);
    setEditingLocation(null);
    setLocationForm(emptyForm);
    setFormError("");
  }

  function updateFormField(field, value) {
    setLocationForm((current) => ({ ...current, [field]: value }));
  }

  async function handleSubmit(event) {
    event.preventDefault();
    setFormError("");
    setErrorMessage("");
    setSuccessMessage("");

    const locationId = locationForm.id.trim();
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(locationId)) {
      setFormError(
        "Location ID must use lowercase letters, numbers, and single hyphens (for example, badulla-town).",
      );
      return;
    }

    if (
      !locationForm.name.trim() ||
      !locationForm.district.trim() ||
      !locationForm.province.trim()
    ) {
      setFormError("Name, district, and province are required.");
      return;
    }

    setIsProcessing(true);

    try {
      if (editingLocation) {
        await updateLocation(editingLocation.id, locationForm);
        setLocations((currentLocations) =>
          currentLocations
            .map((location) =>
              location.id === editingLocation.id
                ? { ...location, ...locationForm }
                : location,
            )
            .sort((first, second) => first.name.localeCompare(second.name)),
        );
        setSuccessMessage(`${locationForm.name} was updated.`);
      } else {
        await createLocation(locationId, locationForm);
        setLocations((currentLocations) =>
          [...currentLocations, { ...locationForm, id: locationId }].sort(
            (first, second) => first.name.localeCompare(second.name),
          ),
        );
        setSuccessMessage(`${locationForm.name} was added.`);
      }

      closeForm();
    } catch (error) {
      console.error("Location could not be saved:", error);
      if (error?.code === "location/already-exists") {
        setFormError("A location with this ID already exists.");
      } else {
        setFormError(
          getDataErrorMessage(error, "The location could not be saved."),
        );
      }
    } finally {
      setIsProcessing(false);
    }
  }

  async function setLocationStatus(location, active) {
    setErrorMessage("");
    setSuccessMessage("");
    setIsProcessing(true);

    try {
      await setLocationActive(location.id, active);
      setLocations((currentLocations) =>
        currentLocations.map((currentLocation) =>
          currentLocation.id === location.id
            ? { ...currentLocation, active }
            : currentLocation,
        ),
      );
      setSuccessMessage(
        active ? `${location.name} is active.` : `${location.name} was deactivated.`,
      );
      if (!active) {
        setLocationToDeactivate(null);
      }
    } catch (error) {
      console.error("Location status could not be changed:", error);
      setErrorMessage(
        getDataErrorMessage(error, "The location status could not be changed."),
      );
    } finally {
      setIsProcessing(false);
    }
  }

  if (isLoading) {
    return <LoadingSpinner label="Loading locations..." />;
  }

  return (
    <div className="page-stack">
      <section className="page-intro page-intro-actions">
        <div>
          <h2>Service locations</h2>
          <p>Manage supported locations referenced by provider profiles.</p>
        </div>
        <button
          type="button"
          className="button button-primary"
          onClick={openAddForm}
        >
          Add location
        </button>
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
          <label className="search-control">
            <span className="sr-only">Search locations</span>
            <input
              type="search"
              placeholder="Search locations or IDs"
              value={searchText}
              onChange={(event) => setSearchText(event.target.value)}
            />
          </label>
        </div>

        {visibleLocations.length === 0 ? (
          <EmptyState
            title="No locations found"
            message={
              locations.length === 0
                ? "Add the first supported service location to get started."
                : "Try changing the search text."
            }
          />
        ) : (
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Location ID</th>
                  <th>Name</th>
                  <th>District</th>
                  <th>Province</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {visibleLocations.map((location) => (
                  <tr key={location.id}>
                    <td className="path-cell">{location.id}</td>
                    <td>{location.name}</td>
                    <td>{location.district}</td>
                    <td>{location.province}</td>
                    <td>
                      <StatusBadge
                        status={location.active ? "active" : "inactive"}
                      />
                    </td>
                    <td>
                      <div className="action-group">
                        <button
                          type="button"
                          className="button button-small button-secondary"
                          onClick={() => openEditForm(location)}
                          disabled={isProcessing}
                        >
                          Edit
                        </button>
                        {location.active ? (
                          <button
                            type="button"
                            className="button button-small button-danger-soft"
                            onClick={() => setLocationToDeactivate(location)}
                            disabled={isProcessing}
                          >
                            Deactivate
                          </button>
                        ) : (
                          <button
                            type="button"
                            className="button button-small button-success-soft"
                            onClick={() => setLocationStatus(location, true)}
                            disabled={isProcessing}
                          >
                            Activate
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {isFormOpen && (
        <div className="modal-backdrop" role="presentation">
          <div
            className="modal-card"
            role="dialog"
            aria-modal="true"
            aria-labelledby="location-form-title"
          >
            <div className="card-heading">
              <div>
                <h2 id="location-form-title">
                  {editingLocation ? "Edit location" : "Add location"}
                </h2>
                <p>The location ID is used by provider profiles.</p>
              </div>
              <button
                type="button"
                className="icon-button"
                aria-label="Close location form"
                onClick={closeForm}
                disabled={isProcessing}
              >
                ×
              </button>
            </div>

            <MessageBanner message={formError} type="error" />

            <form className="form-stack" onSubmit={handleSubmit} noValidate>
              <label className="form-field">
                <span>Location ID *</span>
                <input
                  type="text"
                  value={locationForm.id}
                  placeholder="badulla-town"
                  onChange={(event) => updateFormField("id", event.target.value)}
                  disabled={isProcessing || Boolean(editingLocation)}
                  required
                />
              </label>
              <label className="form-field">
                <span>Name *</span>
                <input
                  type="text"
                  value={locationForm.name}
                  onChange={(event) =>
                    updateFormField("name", event.target.value)
                  }
                  disabled={isProcessing}
                  required
                />
              </label>
              <label className="form-field">
                <span>District *</span>
                <input
                  type="text"
                  value={locationForm.district}
                  onChange={(event) =>
                    updateFormField("district", event.target.value)
                  }
                  disabled={isProcessing}
                  required
                />
              </label>
              <label className="form-field">
                <span>Province *</span>
                <input
                  type="text"
                  value={locationForm.province}
                  onChange={(event) =>
                    updateFormField("province", event.target.value)
                  }
                  disabled={isProcessing}
                  required
                />
              </label>
              <label className="checkbox-field">
                <input
                  type="checkbox"
                  checked={locationForm.active}
                  onChange={(event) =>
                    updateFormField("active", event.target.checked)
                  }
                  disabled={isProcessing}
                />
                <span>Location is active</span>
              </label>

              <div className="modal-actions">
                <button
                  type="button"
                  className="button button-secondary"
                  onClick={closeForm}
                  disabled={isProcessing}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="button button-primary"
                  disabled={isProcessing}
                >
                  {isProcessing
                    ? "Saving..."
                    : editingLocation
                      ? "Save changes"
                      : "Add location"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <ConfirmDialog
        isOpen={Boolean(locationToDeactivate)}
        title="Deactivate this location?"
        message={
          locationToDeactivate
            ? `${locationToDeactivate.name} will no longer be selectable for provider profiles. Existing records are kept.`
            : ""
        }
        confirmLabel="Deactivate"
        confirmTone="danger"
        isProcessing={isProcessing}
        onCancel={() => setLocationToDeactivate(null)}
        onConfirm={() => setLocationStatus(locationToDeactivate, false)}
      />
    </div>
  );
}

export default LocationsPage;