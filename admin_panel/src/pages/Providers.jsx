import React from "react";
import Navbar from "../components/Navbar.jsx";

const providerList = [
  { id: 1, name: "Marcus Chen", email: "marcus.c@skilllink.pro", category: "Electrician", location: "Downtown Core", rating: "4.9", jobs: 342, status: "Active" },
  { id: 2, name: "Sarah Jennings", email: "s.jennings@hvacpro.com", category: "HVAC Specialist", location: "North District", rating: "4.7", jobs: 218, status: "Active" },
  { id: 3, name: "David Miller", email: "miller_plumbing@fastmail.com", category: "Plumber", location: "West End Area", rating: "4.8", jobs: 567, status: "Inactive" },
  { id: 4, name: "Elena Rodriguez", email: "elena.woodworks@gmail.com", category: "Carpenter", location: "South Side", rating: "4.5", jobs: 89, status: "Suspended" },
];

function Providers() {
  return (
    <div className="dashboard">
      <Navbar />

      <div className="page-header">
        <div>
          <h2>Providers</h2>
          <p className="muted">Browse and manage marketplace providers in the system.</p>
        </div>
      </div>

      <div className="filters-row">
        <input className="search-input" placeholder="Search name or email..." />
        <select className="filter-select">
          <option>All Categories</option>
          <option>Electrician</option>
          <option>HVAC Specialist</option>
          <option>Plumber</option>
          <option>Carpenter</option>
        </select>
        <select className="filter-select">
          <option>All Status</option>
          <option>Active</option>
          <option>Inactive</option>
          <option>Suspended</option>
        </select>
        <select className="filter-select">
          <option>All Locations</option>
          <option>Downtown Core</option>
          <option>North District</option>
          <option>West End Area</option>
          <option>South Side</option>
        </select>
        <button className="secondary-btn">Filter</button>
      </div>

      <div className="table-card">
        <table className="provider-table">
          <thead>
            <tr>
              <th>Provider</th>
              <th>Category</th>
              <th>Location</th>
              <th>Rating</th>
              <th>Jobs</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {providerList.map((provider) => (
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
                <td>{provider.location}</td>
                <td>{provider.rating}</td>
                <td>{provider.jobs}</td>
                <td>{provider.status}</td>
                <td className="actions-cell">
                  <button className="action-btn view">Edit</button>
                  <button className="action-btn approve">Details</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default Providers;
