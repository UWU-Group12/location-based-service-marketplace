import React from 'react';
import { Link, useLocation } from 'react-router-dom';

export default function Sidebar({ onLogout }) {
  const location = useLocation();

  const menuItems = [
    { name: 'Dashboard', path: '/' },
    { name: 'Bookings', path: '/bookings' },
    { name: 'Providers', path: '/providers' },
    { name: 'Categories', path: '/categories' },
    { name: 'Locations', path: '/locations' },
  ];

  return (
    <div style={{
      width: '250px',
      background: '#1f192f',
      color: '#fff',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between', // මේකෙන් තමයි Logout බටන් එක පල්ලෙහාටම යවන්නේ
      padding: '20px 0',
      boxSizing: 'border-box'
    }}>
      <div>
        <h3 style={{ textAlign: 'center', marginBottom: '30px', color: '#fff', letterSpacing: '1px' }}>
          Admin Panel
        </h3>
        <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
          {menuItems.map((item) => {
            const isActive = location.pathname === item.path;
            return (
              <li key={item.name} style={{ marginBottom: '5px' }}>
                <Link
                  to={item.path}
                  style={{
                    display: 'block',
                    padding: '15px 25px',
                    color: isActive ? '#fff' : '#a3a0fb',
                    textDecoration: 'none',
                    background: isActive ? '#322947' : 'transparent',
                    borderLeft: isActive ? '4px solid #4e73df' : '4px solid transparent',
                    fontWeight: isActive ? 'bold' : 'normal',
                    transition: 'all 0.3s'
                  }}
                >
                  {item.name}
                </Link>
              </li>
            );
          })}
        </ul>
      </div>

      {/* පල්ලෙහායින්ම වැටෙන Logout බටන් එක */}
      <div style={{ padding: '0 20px' }}>
        <button
          onClick={onLogout}
          style={{
            width: '100%',
            background: '#e74c3c',
            color: '#fff',
            border: 'none',
            padding: '12px',
            borderRadius: '4px',
            fontWeight: 'bold',
            cursor: 'pointer',
            transition: 'background 0.3s'
          }}
          onMouseOver={(e) => e.target.style.background = '#c0392b'}
          onMouseOut={(e) => e.target.style.background = '#e74c3c'}
        >
          Logout
        </button>
      </div>
    </div>
  );
}