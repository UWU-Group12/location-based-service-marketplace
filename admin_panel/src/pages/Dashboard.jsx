import React from 'react';
import { FaUserCheck, FaTags, FaClipboardList } from 'react-icons/fa';

export default function Dashboard() {
  // දැනට නිකන් දත්ත ටිකක් (Dummy Data) පාවිච්චි කරමු
  const stats = [
    { id: 1, title: 'Total Providers', count: '24', icon: <FaUserCheck size={30} />, color: '#4e73df' },
    { id: 2, title: 'Categories Available', count: '6', icon: <FaTags size={30} />, color: '#1cc88a' },
    { id: 3, title: 'Active Bookings', count: '12', icon: <FaClipboardList size={30} />, color: '#f6c23e' },
  ];

  return (
    <div>
      <h2 style={{ marginBottom: '10px', color: '#333' }}>Dashboard</h2>
      <p style={{ color: '#666', marginBottom: '30px' }}>Welcome to your service marketplace administration area.</p>

      {/* Cards Grid layout එක */}
      <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap' }}>
        {stats.map((item) => (
          <div
            key={item.id}
            style={{
              flex: '1',
              minWidth: '220px',
              background: '#fff',
              borderRadius: '8px',
              padding: '20px',
              boxShadow: '0 4px 6px rgba(0,0,0,0.05)',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              borderLeft: `5px solid ${item.color}`,
            }}
          >
            <div>
              <h4 style={{ margin: 0, color: '#858796', fontSize: '14px', textTransform: 'uppercase' }}>
                {item.title}
              </h4>
              <h2 style={{ margin: '5px 0 0 0', color: '#5a5c69', fontSize: '28px' }}>{item.count}</h2>
            </div>
            <div style={{ color: item.color }}>{item.icon}</div>
          </div>
        ))}
      </div>
    </div>
  );
}