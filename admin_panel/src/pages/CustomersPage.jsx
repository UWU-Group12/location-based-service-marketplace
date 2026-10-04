import { useEffect, useMemo, useState } from "react";
import ConfirmDialog from "../components/ConfirmDialog";
import EmptyState from "../components/EmptyState";
import LoadingSpinner from "../components/LoadingSpinner";
import MessageBanner from "../components/MessageBanner";
import StatusBadge from "../components/StatusBadge";
import {
  createCustomerAccount,
  getCustomers,
  updateCustomerAccountStatus,
} from "../services/customerService";
import {
  formatDate,
  getCreateCustomerErrorMessage,
  getDataErrorMessage,
  getInitials,
} from "../utils/formatters";

const emptyForm = {
  displayName: "",
  email: "",
  phoneNumber: "",
  password: "",
  confirmPassword: "",
  accountStatus: "active",
  profileCompleted: false,
};

function CustomersPage() {
  const [customers, setCustomers] = useState([]);
  const [searchText, setSearchText] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [selectedCustomer, setSelectedCustomer] = useState(null);
  const [pendingAction, setPendingAction] = useState(null);
  const [customerForm, setCustomerForm] = useState(emptyForm);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [formError, setFormError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isProcessing, setIsProcessing] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [successMessage, setSuccessMessage] = useState("");

  useEffect(() => {
    let isActive = true;

    async function loadCustomers() {
      try {
        const customerList = await getCustomers();
        if (isActive) {
          setCustomers(customerList);
        }
      } catch (error) {
        console.error("Customers could not be loaded:", error);
        if (isActive) {
          setErrorMessage(
            getDataErrorMessage(
              error,
              "Customers could not be loaded. Please refresh the page.",
            ),
          );
        }
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    }

    loadCustomers();
    return () => {
      isActive = false;
    };
  }, []);

  const visibleCustomers = useMemo(() => {
    const queryText = searchText.trim().toLowerCase();

    return customers.filter((customer) => {
      const matchesSearch =
        !queryText ||
        customer.displayName?.toLowerCase().includes(queryText) ||
        customer.email?.toLowerCase().includes(queryText);
      const matchesStatus =
        statusFilter === "all" || customer.accountStatus === statusFilter;

      return matchesSearch && matchesStatus;
    });
  }, [customers, searchText, statusFilter]);

  function openAddForm() {
    setCustomerForm(emptyForm);
    setFormError("");
    setShowPassword(false);
    setIsFormOpen(true);
  }

  function closeForm() {
    setIsFormOpen(false);
    setFormError("");
  }

  function updateFormField(field, value) {
    setCustomerForm((currentForm) => ({ ...currentForm, [field]: value }));
  }

  async function handleCreateSubmit(event) {
    event.preventDefault();
    setFormError("");
    setErrorMessage("");
    setSuccessMessage("");

    if (!customerForm.displayName.trim()) {
      setFormError("Customer name is required.");
      return;
    }

    if (!customerForm.email.trim()) {
      setFormError("Email address is required.");
      return;
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(customerForm.email.trim())) {
      setFormError("Enter a valid email address.");
      return;
    }

    if (customerForm.password.length < 6) {
      setFormError("Use a password with at least 6 characters.");
      return;
    }

    if (customerForm.password !== customerForm.confirmPassword) {
      setFormError("The two passwords do not match.");
      return;
    }

    setIsProcessing(true);

    try {
      const customerId = await createCustomerAccount(customerForm);
      const newCustomer = {
        id: customerId,
        displayName: customerForm.displayName.trim(),
        email: customerForm.email.trim(),
        ...(customerForm.phoneNumber.trim()
          ? { phoneNumber: customerForm.phoneNumber.trim() }
          : {}),
        role: "customer",
        accountStatus: customerForm.accountStatus,
        profileCompleted: customerForm.profileCompleted,
      };
      setCustomers((currentCustomers) =>
        [...currentCustomers, newCustomer].sort((first, second) =>
          (first.displayName || "").localeCompare(second.displayName || ""),
        ),
      );
      setSuccessMessage(
        `${newCustomer.displayName} can now sign in with the temporary password.`,
      );
      closeForm();
    } catch (error) {
      console.error("Customer account could not be created:", error);
      setFormError(
        getCreateCustomerErrorMessage(
          error,
          "The customer account could not be created. Please try again.",
        ),
      );
    } finally {
      setIsProcessing(false);
    }
  }

  function requestStatusChange(customer) {
    const targetStatus =
      customer.accountStatus === "active" ? "suspended" : "active";
    setPendingAction({ customer, targetStatus });
  }

  async function confirmStatusChange() {
    if (!pendingAction) {
      return;
    }

    setIsProcessing(true);
    setErrorMessage("");
    setSuccessMessage("");

    try {
      await updateCustomerAccountStatus(
        pendingAction.customer.id,
        pendingAction.targetStatus,
      );
      setCustomers((currentCustomers) =>
        currentCustomers.map((customer) =>
          customer.id === pendingAction.customer.id
            ? { ...customer, accountStatus: pendingAction.targetStatus }
            : customer,
        ),
      );
      setSelectedCustomer((current) =>
        current?.id === pendingAction.customer.id
          ? { ...current, accountStatus: pendingAction.targetStatus }
          : current,
      );
      setSuccessMessage(
        `${pendingAction.customer.displayName || "Customer"} is now ${pendingAction.targetStatus}.`,
      );
      setPendingAction(null);
    } catch (error) {
      console.error("Customer status could not be updated:", error);
      setErrorMessage(
        getDataErrorMessage(
          error,
          "The customer account status could not be updated.",
        ),
      );
    } finally {
      setIsProcessing(false);
    }
  }

  if (isLoading) {
    return <LoadingSpinner label="Loading customers..." />;
  }

  return (
    <div className="page-stack">
      <section className="page-intro page-intro-actions">
        <div>
          <h2>Customer accounts</h2>
          <p>
            Add customer accounts manually, search customers, and manage access.
          </p>
        </div>
        <button
          type="button"
          className="button button-primary"
          onClick={openAddForm}
        >
          Add customer
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
            <span className="sr-only">Search customers</span>
            <input
              type="search"
              placeholder="Search by name or email"
              value={searchText}
              onChange={(event) => setSearchText(event.target.value)}
            />
          </label>
          <label className="select-control">
            <span>Account status</span>
            <select
              value={statusFilter}
              onChange={(event) => setStatusFilter(event.target.value)}
            >
              <option value="all">All statuses</option>
              <option value="active">Active</option>
              <option value="suspended">Suspended</option>
              <option value="disabled">Disabled</option>
            </select>
          </label>
        </div>

        {visibleCustomers.length === 0 ? (
          <EmptyState
            title="No customers found"
            message={
              customers.length === 0
                ? "Customer accounts will appear here after registration."
                : "Try changing the search text or account-status filter."
            }
          />
        ) : (
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Customer</th>
                  <th>Phone</th>
                  <th>Status</th>
                  <th>Profile</th>
                  <th>Created</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {visibleCustomers.map((customer) => (
                  <tr key={customer.id}>
                    <td>
                      <div className="person-cell">
                        <span className="person-avatar">
                          {getInitials(customer.displayName)}
                        </span>
                        <span>
                          <strong>{customer.displayName || "Unnamed customer"}</strong>
                          <small>{customer.email || "No email"}</small>
                        </span>
                      </div>
                    </td>
                    <td>{customer.phoneNumber || "Not provided"}</td>
                    <td>
                      <StatusBadge status={customer.accountStatus} />
                    </td>
                    <td>{customer.profileCompleted ? "Complete" : "Incomplete"}</td>
                    <td>{formatDate(customer.createdAt)}</td>
                    <td>
                      <div className="action-group">
                        <button
                          type="button"
                          className="button button-small button-secondary"
                          onClick={() => setSelectedCustomer(customer)}
                        >
                          Details
                        </button>
                        <button
                          type="button"
                          className={`button button-small ${
                            customer.accountStatus === "active"
                              ? "button-danger-soft"
                              : "button-success-soft"
                          }`}
                          onClick={() => requestStatusChange(customer)}
                        >
                          {customer.accountStatus === "active"
                            ? "Suspend"
                            : "Activate"}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {selectedCustomer && (
        <div className="modal-backdrop" role="presentation">
          <div
            className="modal-card"
            role="dialog"
            aria-modal="true"
            aria-labelledby="customer-details-title"
          >
            <div className="card-heading">
              <div>
                <h2 id="customer-details-title">Customer details</h2>
                <p>Basic account information stored in the users collection.</p>
              </div>
              <button
                type="button"
                className="icon-button"
                aria-label="Close customer details"
                onClick={() => setSelectedCustomer(null)}
              >
                ×
              </button>
            </div>
            <dl className="details-grid">
              <div><dt>Name</dt><dd>{selectedCustomer.displayName || "Not provided"}</dd></div>
              <div><dt>Email</dt><dd>{selectedCustomer.email || "Not provided"}</dd></div>
              <div><dt>Phone</dt><dd>{selectedCustomer.phoneNumber || "Not provided"}</dd></div>
              <div><dt>Status</dt><dd><StatusBadge status={selectedCustomer.accountStatus} /></dd></div>
              <div><dt>Profile completed</dt><dd>{selectedCustomer.profileCompleted ? "Yes" : "No"}</dd></div>
              <div><dt>Created</dt><dd>{formatDate(selectedCustomer.createdAt)}</dd></div>
            </dl>
          </div>
        </div>
      )}

      {isFormOpen && (
        <div className="modal-backdrop" role="presentation">
          <div
            className="modal-card"
            role="dialog"
            aria-modal="true"
            aria-labelledby="customer-form-title"
          >
            <div className="card-heading">
              <div>
                <h2 id="customer-form-title">Add customer</h2>
                <p>
                  Creates a Firebase sign-in account and a matching users
                  record.
                </p>
              </div>
              <button
                type="button"
                className="icon-button"
                aria-label="Close customer form"
                onClick={closeForm}
                disabled={isProcessing}
              >
                ×
              </button>
            </div>

            <MessageBanner message={formError} type="error" />

            <form className="form-stack" onSubmit={handleCreateSubmit} noValidate>
              <label className="form-field">
                <span>Customer name *</span>
                <input
                  type="text"
                  value={customerForm.displayName}
                  placeholder="Kasun Perera"
                  onChange={(event) =>
                    updateFormField("displayName", event.target.value)
                  }
                  disabled={isProcessing}
                />
              </label>

              <label className="form-field">
                <span>Email address *</span>
                <input
                  type="email"
                  value={customerForm.email}
                  autoComplete="off"
                  placeholder="kasun@example.com"
                  onChange={(event) =>
                    updateFormField("email", event.target.value)
                  }
                  disabled={isProcessing}
                />
              </label>

              <label className="form-field">
                <span>Phone number</span>
                <input
                  type="tel"
                  value={customerForm.phoneNumber}
                  autoComplete="off"
                  placeholder="+94771234567"
                  onChange={(event) =>
                    updateFormField("phoneNumber", event.target.value)
                  }
                  disabled={isProcessing}
                />
              </label>

              <label className="form-field">
                <span>Temporary password *</span>
                <div className="password-field">
                  <input
                    type={showPassword ? "text" : "password"}
                    value={customerForm.password}
                    autoComplete="new-password"
                    placeholder="At least 6 characters"
                    onChange={(event) =>
                      updateFormField("password", event.target.value)
                    }
                    disabled={isProcessing}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((current) => !current)}
                    disabled={isProcessing}
                  >
                    {showPassword ? "Hide" : "Show"}
                  </button>
                </div>
              </label>

              <label className="form-field">
                <span>Confirm password *</span>
                <input
                  type={showPassword ? "text" : "password"}
                  value={customerForm.confirmPassword}
                  autoComplete="new-password"
                  onChange={(event) =>
                    updateFormField("confirmPassword", event.target.value)
                  }
                  disabled={isProcessing}
                />
              </label>

              <label className="form-field">
                <span>Account status</span>
                <select
                  value={customerForm.accountStatus}
                  onChange={(event) =>
                    updateFormField("accountStatus", event.target.value)
                  }
                  disabled={isProcessing}
                >
                  <option value="active">Active</option>
                  <option value="suspended">Suspended</option>
                  <option value="disabled">Disabled</option>
                </select>
              </label>

              <label className="checkbox-field">
                <input
                  type="checkbox"
                  checked={customerForm.profileCompleted}
                  onChange={(event) =>
                    updateFormField("profileCompleted", event.target.checked)
                  }
                  disabled={isProcessing}
                />
                <span>Profile setup is already complete</span>
              </label>

              <p>
                Share the temporary password with the customer over a trusted
                channel. They can change it from the mobile app or use the
                password-reset email.
              </p>

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
                  {isProcessing ? "Creating..." : "Add customer"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <ConfirmDialog
        isOpen={Boolean(pendingAction)}
        title="Change customer status?"
        message={
          pendingAction
            ? `Set ${pendingAction.customer.displayName || "this customer"} to ${pendingAction.targetStatus}?`
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

export default CustomersPage;
