import React, { useState, useEffect } from 'react';
import { db } from '../components/firebase'; 
import { collection, onSnapshot } from 'firebase/firestore';

export default function Bookings() {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const requestsRef = collection(db, 'service_requests'); 
    
    const unsubscribe = onSnapshot(requestsRef, (snapshot) => {
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setRequests(data);
      setLoading(false);
    }, (error) => {
      console.error("Firebase fetch error: ", error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const getStatusStyle = (status) => {
    switch (status) {
      case 'Pending': 
        return { backgroundColor: '#fef9c3', color: '#854d0e' };
      case 'In Progress': 
        return { backgroundColor: '#dbeafe', color: '#1e40af' };
      case 'Completed': 
        return { backgroundColor: '#dcfce7', color: '#166534' };
      default: 
        return { backgroundColor: '#f1f5f9', color: '#334155' };
    }
  };

  return (
    <div style={{ 
      marginLeft: '260px',      
      padding: '32px', 
      backgroundColor: '#f8fafc', 
      minHeight: '100vh',
      boxSizing: 'border-box'
    }}>
      
      {/* Heading Section */}
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '28px', fontWeight: 'bold', color: '#1e293b', margin: 0 }}>
          Manage Service Requests
        </h1>
        <p style={{ color: '#64748b', marginTop: '4px', fontSize: '14px' }}>
          Monitor customer service requests, status tracking, and marketplace activities.
        </p>
      </div>

      {loading ? (
        <p style={{ color: '#64748b', fontSize: '16px' }}>Loading requests...</p>
      ) : (
        /* මෙතනට overflowX දාලා table එක කැපෙන එක හැදුවා */
        <div style={{ 
          backgroundColor: '#ffffff', 
          borderRadius: '8px', 
          boxShadow: '0 1px 3px rgba(0,0,0,0.1)', 
          overflowX: 'auto' 
        }}>
          {/* Table එකට minWidth එකක් දුන්නා ඔක්කොම columns ලස්සනට පේන්න */}
          <table style={{ width: '100%', minWidth: '900px', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ backgroundColor: '#f1f5f9', borderBottom: '1px solid #e2e8f0' }}>
                <th style={{ padding: '14px', color: '#475569', fontWeight: '600' }}>Request ID</th>
                <th style={{ padding: '14px', color: '#475569', fontWeight: '600' }}>Customer</th>
                <th style={{ padding: '14px', color: '#475569', fontWeight: '600' }}>Category</th>
                <th style={{ padding: '14px', color: '#475569', fontWeight: '600' }}>Location</th>
                <th style={{ padding: '14px', color: '#475569', fontWeight: '600' }}>Date</th>
                <th style={{ padding: '14px', color: '#475569', fontWeight: '600' }}>Status</th>
                <th style={{ padding: '14px', color: '#475569', fontWeight: '600' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {requests.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ padding: '20px', textAlign: 'center', color: '#64748b' }}>
                    No service requests found in database.
                  </td>
                </tr>
              ) : (
                requests.map((req) => (
                  <tr key={req.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                    {/* ID එක දිග වැඩි නිසා බිඳෙන්න wordBreak හැදුවා */}
                    <td style={{ padding: '14px', fontWeight: '500', color: '#334155', wordBreak: 'break-all', maxWidth: '180px' }}>
                      {req.id}
                    </td>
                    <td style={{ padding: '14px', color: '#334155' }}>{req.customer || 'Unknown'}</td>
                    <td style={{ padding: '14px', color: '#334155' }}>{req.category || 'N/A'}</td>
                    <td style={{ padding: '14px', color: '#334155' }}>{req.location || 'N/A'}</td>
                    <td style={{ padding: '14px', color: '#64748b' }}>{req.date || 'N/A'}</td>
                    <td style={{ padding: '14px' }}>
                      <span style={{
                        padding: '4px 10px',
                        borderRadius: '9999px',
                        fontSize: '12px',
                        fontWeight: '600',
                        whiteSpace: 'nowrap',
                        ...getStatusStyle(req.status)
                      }}>
                        {req.status || 'Pending'}
                      </span>
                    </td>
                    <td style={{ padding: '14px' }}>
                      <button style={{ 
                        backgroundColor: '#3b82f6', 
                        color: '#ffffff', 
                        padding: '6px 12px', 
                        borderRadius: '4px', 
                        border: 'none',
                        cursor: 'pointer',
                        fontSize: '13px',
                        whiteSpace: 'nowrap'
                      }}>
                        View Details
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}