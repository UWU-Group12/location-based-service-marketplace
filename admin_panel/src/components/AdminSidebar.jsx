import { NavLink } from "react-router-dom";

const navigationItems = [
  { to: "/dashboard", label: "Dashboard", icon: "▦" },
  { to: "/customers", label: "Customers", icon: "👥" },
  { to: "/providers", label: "Providers", icon: "🛠" },
  {
    to: "/provider-verifications",
    label: "Provider Verifications",
    icon: "✓",
  },
  { to: "/categories", label: "Categories", icon: "▤" },
];

function AdminSidebar({ isOpen, onClose }) {
  return (
    <>
      <button
        type="button"
        className={`sidebar-backdrop ${isOpen ? "is-visible" : ""}`}
        aria-label="Close navigation"
        onClick={onClose}
      />

      <aside className={`sidebar ${isOpen ? "is-open" : ""}`}>
        <div className="sidebar-brand">
          <span className="brand-mark">S</span>
          <div>
            <strong>Raw</strong>
            <span>Admin Console</span>
          </div>
        </div>

        <nav aria-label="Administrator navigation">
          <ul className="sidebar-nav">
            {navigationItems.map((item) => (
              <li key={item.to}>
                <NavLink
                  to={item.to}
                  onClick={onClose}
                  className={({ isActive }) =>
                    `sidebar-link ${isActive ? "active" : ""}`
                  }
                >
                  <span className="sidebar-icon" aria-hidden="true">
                    {item.icon}
                  </span>
                  <span>{item.label}</span>
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>
      </aside>
    </>
  );
}

export default AdminSidebar;
