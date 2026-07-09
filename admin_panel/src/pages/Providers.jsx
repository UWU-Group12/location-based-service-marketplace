import React, { useState } from 'react';

export default function Providers() {
  // දැනට ටෙස්ට් කරලා බලන්න Dummy Providers ලා 3 දෙනෙක්
  const [providers, setProviders] = useState([
    { id: 1, name: 'Kamal Perera', skill: 'Plumber', experience: '5 Years', status: 'Pending' },
    { id: 2, name: 'Sunil Shantha', skill: 'Electrician', experience: '3 Years', status: 'Pending' },
    { id: 3, name: 'Nimal Silva', skill: 'Carpenter', experience: '8 Years', status: 'Pending' },
  ]);

  // Approve බටන් එක ක්ලික් කරාම වෙනස් වෙන්න
  const handleApprove = (id) => {
    setProviders(providers.map(p => p.id === id ? { ...p, status: 'Approved' } : p));
  };

  // Reject බටන් එක ක්ලික් කරාම වෙනස් වෙන්න
  const handleReject = (id) => {
    setProviders(providers.map(p => p.id === id ? { ...p, status: 'Rejected' } : p));
  };

  return (
    <div>
      <h2 style={{ marginBottom: '10px' }}>Provider Verification</h2>
      <p style={{ color: '#666', marginBottom: '20px' }}>Verify and manage skilled workers registered in the system.</p>

      <table style={{ width: '100%', borderCollapse: 'collapse', background: '#fff', borderRadius: '8px', overflow: 'hidden', boxShadow: '0 4px 6px rgba(0,0,0,0.05)' }}>
        <thead>
          <tr style={{ background: '#4e73df', color: '#fff', textAlign: 'left' }}>
            <th style={{ padding: '15px' }}>Name</th>
            <th style={{ padding: '15px' }}>Skill</th>
            <th style={{ padding: '15px' }}>Experience</th>
            <th style={{ padding: '15px' }}>Status</th>
            <th style={{ padding: '15px' }}>Actions</th>
          </tr>
        </thead>
        <tbody>
          {providers.map((provider) => (
            <tr key={provider.id} style={{ borderBottom: '1px solid #e3e6f0' }}>
              <td style={{ padding: '15px' }}>{provider.name}</td>
              <td style={{ padding: '15px' }}>{provider.skill}</td>
              <td style={{ padding: '15px' }}>{provider.experience}</td>
              <td style={{ padding: '15px' }}>
                <span style={{
                  padding: '5px 10px',
                  borderRadius: '4px',
                  fontSize: '12px',
                  fontWeight: 'bold',
                  background: provider.status === 'Approved' ? '#d4edda' : provider.status === 'Rejected' ? '#f8d7da' : '#fff3cd',
                  color: provider.status === 'Approved' ? '#155724' : provider.status === 'Rejected' ? '#721c24' : '#856404'
                }}>
                  {provider.status}
                </span>
              </td>
              <td style={{ padding: '15px', display: 'flex', gap: '10px' }}>
                {provider.status === 'Pending' && (
                  <>
                    <button onClick={() => handleApprove(provider.id)} style={{ background: '#1cc88a', color: '#fff', border: 'none', padding: '5px 10px', borderRadius: '4px', cursor: 'pointer' }}>Approve</button>
                    <button onClick={() => handleReject(provider.id)} style={{ background: '#e74a3b', color: '#fff', border: 'none', padding: '5px 10px', borderRadius: '4px', cursor: 'pointer' }}>Reject</button>
                  </>
                )}
                {provider.status !== 'Pending' && <span style={{ color: '#aaa', fontSize: '14px' }}>Action Taken</span>}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}