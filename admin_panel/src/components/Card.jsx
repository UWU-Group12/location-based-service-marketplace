// src/components/Card.js
import React from "react";

function Card({ title, value, status, statusColor, urgent, icon }) {
  return (
    <div className="card">
      <div className="card-top">
        <div className="card-icon">{icon || null}</div>
        {status ? (
          <div className={`status ${urgent ? "badge-urgent" : ""}`} style={{ color: statusColor || "#10B981" }}>
            {status}
          </div>
        ) : (
          <div style={{ width: 56 }} />
        )}
      </div>

      <div className="card-body">
        <h4>{title}</h4>
        <h2>{value}</h2>
      </div>
    </div>
  );
}

export default Card;
