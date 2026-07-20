import React from "react";
import Navbar from "../components/Navbar.jsx";


const providers = [
  {
    id: 1,
    name: "Arjuna Perera",
    email: "arjuna.p@email.com",
    category: "Electrician",
    district: "Colombo 03",
    nic: "198512345678",
    submitted: "Oct 24, 2023",
    status: "Pending",
  },
  {
    id: 2,
    name: "Nimali Silva",
    email: "nimali.s@email.com",
    category: "Plumber",
    district: "Kandy",
    nic: "199298765432",
    submitted: "Oct 22, 2023",
    status: "Approved",
  },
  {
    id: 3,
    name: "Kasun Jayawardena",
    email: "kasun.j@email.com",
    category: "Carpenter",
    district: "Galle",
    nic: "198855667788",
    submitted: "Oct 20, 2023",
    status: "Rejected",
  },
  {
    id: 4,
    name: "Thilina Bandara",
    email: "thilina.b@email.com",
    category: "HVAC",
    district: "Colombo 07",
    nic: "199522334455",
    submitted: "Oct 19, 2023",
    status: "Pending",
  },
];

function statusClass(status) {
  if (status === "Approved") return "status-pill approved";
  if (status === "Rejected") return "status-pill rejected";
  return "status-pill pending";
}

function Verification() {
  return (
    <div className="dashboard">
      <Navbar />

      <div className="page-header">
        <div>
          <h2>Provider Verification</h2>
          <p className="muted">Review and manage professional certifications for new marketplace providers.</p>
        </div>
        <div className="top-actions">
          <button className="secondary-btn">Export CSV</button>
          <button className="secondary-btn">Refresh</button>
        </div>
      </div>

      <div className="filters-row">
        <input className="search-input" placeholder="Search Provider" />
        <select className="filter-select">
          <option value="">Category</option>
          <option>Electrician</option>
          <option>Plumber</option>
          <option>Carpenter</option>
          <option>HVAC</option>
        </select>
        <select className="filter-select">
          <option value="">District</option>
          <option>Colombo 03</option>
          <option>Colombo 07</option>
          <option>Kandy</option>
          <option>Galle</option>
        </select>
        <select className="filter-select">
          <option value="">Status</option>
          <option>Pending</option>
          <option>Approved</option>
          <option>Rejected</option>
        </select>
        <input className="search-input" type="date" />
      </div>

      <div className="stat-cards">
        <div className="stat-card">
          <div className="stat-card-title">Pending Verification</div>
          <div className="stat-card-value">24</div>
        </div>
        <div className="stat-card">
          <div className="stat-card-title">Approved Providers</div>
          <div className="stat-card-value">1,240</div>
        </div>
        <div className="stat-card">
          <div className="stat-card-title">Rejected Providers</div>
          <div className="stat-card-value">86</div>
        </div>
        <div className="stat-card">
          <div className="stat-card-title">Total Providers</div>
          <div className="stat-card-value">1,350</div>
        </div>
      </div>

      <div className="table-card">
        <table className="provider-table">
          <thead>
            <tr>
              <th>Provider</th>
              <th>Category</th>
              <th>District</th>
              <th>NIC Number</th>
              <th>Submitted Date</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {providers.map((provider) => (
              <tr key={provider.id}>
                <td>
                  <div className="provider-user">
                    <div className="provider-avatar">{provider.name.split(" ").map((part) => part[0]).join("")}</div>
                    <div>
                      <div className="provider-name">{provider.name}</div>
                      <div className="provider-email">{provider.email}</div>
                    </div>
                  </div>
                </td>
                <td>{provider.category}</td>
                <td>{provider.district}</td>
                <td>{provider.nic}</td>
                <td>{provider.submitted}</td>
                <td><span className={statusClass(provider.status)}>{provider.status}</span></td>
                <td className="actions-cell">
                  <button className="action-btn view">View</button>
                  <button className="action-btn approve">Approve</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="pagination-row">
          <span>Showing 1 to 8 of 24 results</span>
          <div className="pagination-buttons">
            <button className="pagination-btn">Previous</button>
            <button className="pagination-btn active">1</button>
            <button className="pagination-btn">2</button>
            <button className="pagination-btn">3</button>
            <button className="pagination-btn">Next</button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Verification;
