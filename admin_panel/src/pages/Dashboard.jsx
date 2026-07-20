import React from "react";
import Card from "../components/Card.jsx";
import Navbar from "../components/Navbar.jsx";

function Dashboard() {
  return (
    <div className="dashboard">
      <Navbar />

      <div className="page-header">
        <div>
          <h2>Dashboard Overview</h2>
          <p className="muted">Welcome back, administrator. Here is what is happening today.</p>
        </div>
      </div>

      <div className="cards">
        <Card
          title="Total Customers"
          value="1,284"
          status="+12%"
          statusColor="#10B981"
          icon={(
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4z" fill="#0B1C30" opacity="0.9"/>
              <path d="M4 20c0-2.21 3.582-4 8-4s8 1.79 8 4v1H4v-1z" fill="#06B6D4" opacity="0.12"/>
            </svg>
          )}
        />

        <Card
          title="Total Providers"
          value="452"
          status="+5%"
          statusColor="#06B6D4"
          icon={(
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M4 7h16v2H4z" fill="#0B1C30" opacity="0.9"/>
              <path d="M6 11h12v8H6z" fill="#F59E0B" opacity="0.12"/>
            </svg>
          )}
        />

        <Card
          title="Pending Verifications"
          value="18"
          status="URGENT"
          statusColor="#EF4444"
          urgent
          icon={(
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M12 2l2.5 4.5L19 8l-3.5 3L16 16l-4-2.5L8 16l.5-5L5 8l4.5-1.5L12 2z" fill="#EF4444"/>
            </svg>
          )}
        />

        <Card
          title="Total Categories"
          value="24"
          status=""
          icon={(
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="3" y="3" width="8" height="8" fill="#0B1C30" opacity="0.9"/>
              <rect x="13" y="3" width="8" height="8" fill="#9CA3AF" opacity="0.12"/>
            </svg>
          )}
        />
      </div>
    </div>
  );
}

export default Dashboard;
