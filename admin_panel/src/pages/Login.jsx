import React, { useState } from 'react';

export default function Login({ onLoginSuccess }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleLogin = (e) => {
    e.preventDefault();
    setError('');

    // දැනට ටෙස්ට් කරන්න Dummy Admin කෙනෙක් පාවිච්චි කරමු
    // (පස්සේ Firebase Auth එකෙන් මේක ඇත්තටම චෙක් කරන විදිහට හදමු)
    if (email === 'admin@marketplace.com' && password === 'admin123') {
      onLoginSuccess(); // ලොගින් සාර්ථක නම් ප්‍රධාන පිටුවට යන්න
    } else {
      setError('Invalid email or password. Please try again.');
    }
  };

  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      height: '100vh',
      background: '#f4f6f9',
      fontFamily: 'Arial, sans-serif'
    }}>
      <div style={{
        background: '#fff',
        padding: '40px',
        borderRadius: '8px',
        boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
        width: '100%',
        maxWidth: '400px',
        boxSizing: 'border-box'
      }}>
        <h2 style={{ textAlign: 'center', marginBottom: '10px', color: '#4e73df' }}>Admin Login</h2>
        <p style={{ textAlign: 'center', color: '#666', marginBottom: '30px', fontSize: '14px' }}>
          Sign in to manage your marketplace
        </p>

        {error && (
          <div style={{
            background: '#f8d7da',
            color: '#721c24',
            padding: '10px',
            borderRadius: '4px',
            marginBottom: '20px',
            fontSize: '14px',
            textAlign: 'center',
            border: '1px solid #f5c6cb'
          }}>
            {error}
          </div>
        )}

        <form onSubmit={handleLogin}>
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '14px' }}>Email Address</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@marketplace.com"
              style={{ width: '100%', padding: '12px', borderRadius: '4px', border: '1px solid #d1d3e2', boxSizing: 'border-box' }}
              required
            />
          </div>

          <div style={{ marginBottom: '30px' }}>
            <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '14px' }}>Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              style={{ width: '100%', padding: '12px', borderRadius: '4px', border: '1px solid #d1d3e2', boxSizing: 'border-box' }}
              required
            />
          </div>

          <button type="submit" style={{
            width: '100%',
            background: '#4e73df',
            color: '#fff',
            border: 'none',
            padding: '14px',
            borderRadius: '4px',
            fontWeight: 'bold',
            fontSize: '16px',
            cursor: 'pointer'
          }}>
            Login
          </button>
        </form>
      </div>
    </div>
  );
}