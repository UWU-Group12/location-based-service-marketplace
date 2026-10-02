import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import EmptyState from "../components/EmptyState";
import LoadingSpinner from "../components/LoadingSpinner";
import MessageBanner from "../components/MessageBanner";
import StatusBadge from "../components/StatusBadge";
import { getDashboardData } from "../services/dashboardService";
import { formatDate, getDataErrorMessage } from "../utils/formatters";

const summaryCards = [
  { key: "customers", label: "Total customers", icon: "👥" },
  { key: "providers", label: "Total providers", icon: "🛠" },
  {
    key: "pendingVerifications",
    label: "Pending verifications",
    icon: "✓",
  },
  { key: "activeCategories", label: "Active categories", icon: "▤" },
];

function DashboardPage() {
  const [dashboardData, setDashboardData] = useState(null);
  const [errorMessage, setErrorMessage] = useState("");

  useEffect(() => {
    let isActive = true;

    async function loadDashboard() {
      try {
        const data = await getDashboardData();
        if (isActive) {
          setDashboardData(data);
        }
      } catch (error) {
        console.error("Dashboard data could not be loaded:", error);
        if (isActive) {
          setErrorMessage(
            getDataErrorMessage(
              error,
              "Dashboard data could not be loaded. Please refresh the page.",
            ),
          );
        }
      }
    }

    loadDashboard();
    return () => {
      isActive = false;
    };
  }, []);

  if (!dashboardData && !errorMessage) {
    return <LoadingSpinner label="Loading dashboard data..." />;
  }

  return (
    <div className="page-stack">
      <section className="page-intro">
        <div>
          <h2>Marketplace overview</h2>
          <p>Current account, verification, and category totals from Firestore.</p>
        </div>
      </section>

      <MessageBanner message={errorMessage} type="error" />

      {dashboardData && (
        <>
          <section className="summary-grid" aria-label="Marketplace totals">
            {summaryCards.map((card) => (
              <article className="summary-card" key={card.key}>
                <div className="summary-icon" aria-hidden="true">
                  {card.icon}
                </div>
                <div>
                  <span>{card.label}</span>
                  <strong>{dashboardData.totals[card.key]}</strong>
                </div>
              </article>
            ))}
          </section>

          <section className="content-card">
            <div className="card-heading">
              <div>
                <h3>Recent pending verifications</h3>
                <p>The latest provider identity submissions awaiting review.</p>
              </div>
              <Link className="text-link" to="/provider-verifications">
                Review all
              </Link>
            </div>

            {dashboardData.recentPendingVerifications.length === 0 ? (
              <EmptyState
                title="No pending verifications"
                message="New provider submissions will appear here."
              />
            ) : (
              <div className="table-scroll">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Provider</th>
                      <th>Document type</th>
                      <th>Submitted</th>
                      <th>Status</th>
                      <th>Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {dashboardData.recentPendingVerifications.map(
                      (verification) => (
                        <tr key={verification.id}>
                          <td>{verification.providerName}</td>
                          <td>{verification.documentType || "Not provided"}</td>
                          <td>{formatDate(verification.submittedAt)}</td>
                          <td>
                            <StatusBadge status={verification.status} />
                          </td>
                          <td>
                            <Link
                              className="button button-small button-secondary"
                              to={`/provider-verifications?providerId=${verification.providerId}`}
                            >
                              Review
                            </Link>
                          </td>
                        </tr>
                      ),
                    )}
                  </tbody>
                </table>
              </div>
            )}
          </section>
        </>
      )}
    </div>
  );
}

export default DashboardPage;
