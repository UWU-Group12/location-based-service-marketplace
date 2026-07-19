// src/App.jsx
import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Sidebar from "./components/Sidebar";
import Dashboard from "./pages/Dashboard";
import "./App.css";

function App() {
  return (
    <Router>
      <div className="app">
        <Sidebar />
        <div className="main" style={{ marginLeft: "220px", padding: "20px" }}>
          <Routes>
            <Route path="/dashboard" element={<Dashboard />} />
            {/* oyāṭa Users, Reports, Settings pages daanna puluwan */}
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default App;
