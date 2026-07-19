// src/components/Sidebar.jsx
import React from "react";
import { Link, useLocation } from "react-router-dom";

function Sidebar() {
  const location = useLocation();

  const items = [
    { to: "/dashboard", label: "Dashboard", icon: (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M3 13h8V3H3v10zm0 8h8v-6H3v6zM13 21h8V11h-8v10zM13 3v6h8V3h-8z" fill="#A5B4FC"/></svg>
      ) },
    { to: "/customers", label: "Customers", icon: (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4z" fill="#93C5FD"/><path d="M4 20c0-2.21 3.582-4 8-4s8 1.79 8 4v1H4v-1z" fill="#BFDBFE" opacity="0.35"/></svg>
      ) },
    { to: "/providers", label: "Providers", icon: (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M4 7h16v2H4z" fill="#A7F3D0"/><path d="M6 11h12v8H6z" fill="#86EFAC" opacity="0.25"/></svg>
      ) },
    { to: "/verification", label: "Provider Verification", icon: (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2l2.5 4.5L19 8l-3.5 3L16 16l-4-2.5L8 16l.5-5L5 8l4.5-1.5L12 2z" fill="#FCA5A5"/></svg>
      ) },
    { to: "/categories", label: "Categories", icon: (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="8" height="8" fill="#E9D5FF"/><rect x="13" y="3" width="8" height="8" fill="#DDD6FE" opacity="0.5"/></svg>
      ) },
  ];

  return (
    <div className="sidebar">
      <h2 className="logo">SkillLink</h2>
      <div className="subtitle">Admin Console</div>
      <ul>
        {items.map((it) => (
          <li key={it.to} className={location.pathname === it.to ? "active" : ""}>
            <Link to={it.to} style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <span className="side-icon">{it.icon}</span>
              <span>{it.label}</span>
            </Link>
          </li>
        ))}
      </ul>

      <div style={{ position: "absolute", bottom: 24, left: 20, right: 20 }}>
        <hr style={{ borderColor: "rgba(255,255,255,0.06)" }} />
        <div style={{ marginTop: 12 }}>
          <a href="#logout" style={{ color: "rgba(255,255,255,0.8)", textDecoration: "none" }}>Logout</a>
        </div>
      </div>
    </div>
  );
}

export default Sidebar;
