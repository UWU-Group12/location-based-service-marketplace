// src/App.jsx
import React from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import Sidebar from "./components/Sidebar";
import Dashboard from "./pages/Dashboard";
import Providers from "./pages/Providers.jsx";
import Verification from "./pages/Verification.jsx";
import "./App.css";

function App() {
  return (
    <Router>
      <div className="app">
        <Sidebar />
        <div className="main" style={{ marginLeft: "220px", padding: "20px" }}>
          <Routes>
            <Route path="/" element={<Navigate to="/verification" replace />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/providers" element={<Providers />} />
            <Route path="/verification" element={<Verification />} />
            <Route path="*" element={<Navigate to="/verification" replace />} />
            {/* oyāṭa Users, Reports, Settings pages daanna puluwan */}
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default App;
