import { useState } from "react";
import { Outlet, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/useAuth";
import AdminSidebar from "./AdminSidebar";

const pageTitles = {
  "/dashboard": "Dashboard",
  "/customers": "Customers",
  "/providers": "Providers",
  "/provider-verifications": "Provider Verifications",
  "/categories": "Categories",
};

function AdminLayout() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isSigningOut, setIsSigningOut] = useState(false);
  const { currentAdmin, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const pageTitle = pageTitles[location.pathname] ?? "Admin Console";

  async function handleLogout() {
    setIsSigningOut(true);
    try {
      await logout();
      navigate("/login", { replace: true });
    } catch (error) {
      console.error("Administrator sign-out failed:", error);
      setIsSigningOut(false);
    }
  }

  return (
    <div className="admin-shell">
      <AdminSidebar
        isOpen={isSidebarOpen}
        onClose={() => setIsSidebarOpen(false)}
      />

      <div className="admin-main">
        <header className="admin-header">
          <div className="header-title">
            <button
              type="button"
              className="menu-button"
              aria-label="Open navigation"
              onClick={() => setIsSidebarOpen(true)}
            >
              ☰
            </button>
            <div>
              <span className="header-eyebrow">Administrator panel</span>
              <h1>{pageTitle}</h1>
            </div>
          </div>

          <div className="admin-profile">
            <div className="admin-avatar" aria-hidden="true">
              {(currentAdmin?.email?.[0] ?? "A").toUpperCase()}
            </div>
            <div className="admin-details">
              <strong>Administrator</strong>
              <span>{currentAdmin?.email}</span>
            </div>
            <button
              type="button"
              className="button button-secondary"
              onClick={handleLogout}
              disabled={isSigningOut}
            >
              {isSigningOut ? "Signing out..." : "Logout"}
            </button>
          </div>
        </header>

        <main className="page-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

export default AdminLayout;
