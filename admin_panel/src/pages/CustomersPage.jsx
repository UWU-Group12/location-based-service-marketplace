import { useEffect, useMemo, useState } from "react";
import ConfirmDialog from "../components/ConfirmDialog";
import EmptyState from "../components/EmptyState";
import LoadingSpinner from "../components/LoadingSpinner";
import MessageBanner from "../components/MessageBanner";
import StatusBadge from "../components/StatusBadge";
import {
  getCustomers,
  updateCustomerAccountStatus,
} from "../services/customerService";
import {
  formatDate,
  getDataErrorMessage,
  getInitials,
} from "../utils/formatters";

function CustomersPage() {
  const [customers, setCustomers] = useState([]);
  const [searchText, setSearchText] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [selectedCustomer, setSelectedCustomer] = useState(null);
  const [pendingAction, setPendingAction] = useState(null);
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
      <section className="page-intro">
        <div>
          <h2>Customer accounts</h2>
          <p>Search customers and manage access without changing profile data.</p>
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
