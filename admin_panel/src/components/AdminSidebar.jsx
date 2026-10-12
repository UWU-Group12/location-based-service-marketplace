  import { NavLink } from "react-router-dom";
 import myNewLogo from '../assets/my-logo.png';
const navigationItems = [
  { to: "/dashboard", label: "Dashboard", icon: "▦" },
  {
    to: "/customers",
    label: "Customers",
    icon: (
      <svg viewBox="0 0 24 24" width="16" height="16" fill="none">
        <circle cx="9" cy="8" r="3" stroke="currentColor" strokeWidth="2" />
        <path
          d="M3.5 19v-1.5A4.5 4.5 0 0 1 8 13h2a4.5 4.5 0 0 1 4.5 4.5V19"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
        />
        <path
          d="M16 5.3a3 3 0 0 1 0 5.8m2.5 7.4v-1a4.5 4.5 0 0 0-3-4.25"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
        />
      </svg>
    ),
  },
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
          <img src={myNewLogo} alt="Logo" className="sidebar-logo" style={{ width: "40px", height: "auto" }} />
          
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
