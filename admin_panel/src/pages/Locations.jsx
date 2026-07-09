import React, { useState } from 'react';

export default function Locations() {
  // දැනට තියෙන නගර/ප්‍රදේශ (Dummy Locations)
  const [locations, setLocations] = useState([
    { id: 1, city: 'Colombo', zone: 'Western Province' },
    { id: 2, city: 'Kandy', zone: 'Central Province' },
    { id: 3, city: 'Galle', zone: 'Southern Province' },
  ]);

  const [newCity, setNewCity] = useState('');
  const [newZone, setNewZone] = useState('');

  const handleAddLocation = (e) => {
    e.preventDefault();
    if (!newCity.trim()) return;

    const newId = locations.length + 1;
    const addedLocation = { id: newId, city: newCity, zone: newZone };

    setLocations([...locations, addedLocation]);
    setNewCity('');
    setNewZone('');
  };

  return (
    <div>
      <h2 style={{ marginBottom: '10px' }}>Location Management</h2>
      <p style={{ color: '#666', marginBottom: '30px' }}>Manage the cities and zones where services are provided.</p>

      <div style={{ display: 'flex', gap: '30px', flexWrap: 'wrap' }}>
        {/* වම් පැත්තේ Form එක - අලුත් Location එකක් එකතු කරන්න */}
        <div style={{ flex: '1', minWidth: '300px', background: '#fff', padding: '25px', borderRadius: '8px', boxShadow: '0 4px 6px rgba(0,0,0,0.05)', height: 'fit-content' }}>
          <h4 style={{ marginTop: 0, marginBottom: '20px', color: '#4e73df' }}>Add New Location</h4>
          <form onSubmit={handleAddLocation}>
            <div style={{ marginBottom: '15px' }}>
              <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '14px' }}>City Name</label>
              <input
                type="text"
                value={newCity}
                onChange={(e) => setNewCity(e.target.value)}
                placeholder="e.g., Malabe, Gampaha"
                style={{ width: '100%', padding: '10px', borderRadius: '4px', border: '1px solid #d1d3e2', boxSizing: 'border-box' }}
                required
              />
            </div>
            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '14px' }}>Province / District</label>
              <input
                type="text"
                value={newZone}
                onChange={(e) => setNewZone(e.target.value)}
                placeholder="e.g., Western Province"
                style={{ width: '100%', padding: '10px', borderRadius: '4px', border: '1px solid #d1d3e2', boxSizing: 'border-box' }}
                required
              />
            </div>
            <button type="submit" style={{ width: '100%', background: '#4e73df', color: '#fff', border: 'none', padding: '12px', borderRadius: '4px', fontWeight: 'bold', cursor: 'pointer' }}>
              Add Location
            </button>
          </form>
        </div>

        {/* දකුණු පැත්තේ තියෙන List එක - දැනට තියෙන Locations පෙන්වන්න */}
        <div style={{ flex: '1.5', minWidth: '350px', background: '#fff', padding: '25px', borderRadius: '8px', boxShadow: '0 4px 6px rgba(0,0,0,0.05)' }}>
          <h4 style={{ marginTop: 0, marginBottom: '20px', color: '#333' }}>Active Locations</h4>
          <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
            {locations.map((loc) => (
              <li key={loc.id} style={{ padding: '15px', borderBottom: '1px solid #e3e6f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <strong style={{ color: '#333', fontSize: '16px' }}>{loc.city}</strong>
                <span style={{ color: '#4e73df', background: '#eaecf4', padding: '3px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: 'bold' }}>{loc.zone}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}