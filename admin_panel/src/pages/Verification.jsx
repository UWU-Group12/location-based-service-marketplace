import React, { useEffect, useState } from 'react';
import Navbar from "../components/Navbar.jsx";
import { db } from '../firebase';
import { doc, getDoc, updateDoc } from 'firebase/firestore';

export default function Verification() {
  const [provider, setProvider] = useState(null);
  const [loading, setLoading] = useState(true);

  const providerId = "YOUR_PROVIDER_DOC_ID"; 

  useEffect(() => {
    const fetchProvider = async () => {
      try {
        const docRef = doc(db, "providers", providerId);
        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {
          setProvider({ id: docSnap.id, ...docSnap.data() });
        } else {
          console.log("No such provider document found!");
        }
      } catch (error) {
        console.error("Error fetching provider: ", error);
      } finally {
        setLoading(false);
      }
    };

    fetchProvider();
  }, [providerId]);

  const handleApprove = async () => {
    try {
      const docRef = doc(db, "providers", providerId);
      await updateDoc(docRef, { label: "APPROVED", status: "verified" });
      alert("Provider approved successfully!");
    } catch (error) {
      console.error("Error updating document: ", error);
    }
  };

  const handleReject = async () => {
    try {
      const docRef = doc(db, "providers", providerId);
      await updateDoc(docRef, { label: "REJECTED", status: "rejected" });
      alert("Provider rejected.");
    } catch (error) {
      console.error("Error updating document: ", error);
    }
  };

  if (loading) {
    return <div className="dashboard verification-page"><Navbar /><div style={{padding: '40px', color: '#fff'}}>Loading...</div></div>;
  }

  if (!provider) {
    return <div className="dashboard verification-page"><Navbar /><div style={{padding: '40px', color: '#fff'}}>No provider data found.</div></div>;
  }

  return (
    <div className="dashboard verification-page">
      <Navbar />
      <div className="verification-card-shell">
        <div className="verification-card">
          <div className="verification-header">
            <div className="verification-title-group">
              <div className="verification-badge-icon">
                <div className="verification-badge-dot" />
              </div>
              <div className="verification-header-text">
                <div className="verification-title">Worker Verification</div>
                <div className="verification-subtitle-row">
                  <div className="verification-name">{provider.name || provider.displayName}</div>
                  <div className="status-pill pending status-pill-large">{provider.label || "PENDING"}</div>
                </div>
              </div>
            </div>
            <button type="button" className="verification-close-button" aria-label="Close">
              ×
            </button>
          </div>

          <div className="verification-body">
            <div className="verification-section">
              <div className="section-heading-row">
                <div className="section-icon-dot" />
                <div className="section-heading">Personal Information</div>
              </div>
              <div className="personal-info-panel">
                <div className="info-row">
                  <div className="info-block">
                    <div className="info-label">Display Name</div>
                    <div className="info-value">{provider.displayName}</div>
                  </div>
                  <div className="info-block">
                    <div className="info-label">Email Address</div>
                    <div className="info-value">{provider.email}</div>
                  </div>
                </div>
                <div className="info-row">
                  <div className="info-block">
                    <div className="info-label">Category IDs</div>
                    <div className="category-pill-row">
                      {provider.categories && provider.categories.map((category, index) => (
                        <span key={index} className="category-pill">{category}</span>
                      ))}
                    </div>
                  </div>
                  <div className="info-block">
                    <div className="info-label">District / Location</div>
                    <div className="info-value">{provider.location}</div>
                  </div>
                </div>
                <div className="info-row single-column-row">
                  <div className="info-block">
                    <div className="info-label">NIC Number</div>
                    <div className="info-value">{provider.nic}</div>
                  </div>
                </div>
              </div>
            </div>

            <div className="verification-section">
              <div className="section-heading-row">
                <div className="section-icon-dot" />
                <div className="section-heading">Verification Documents</div>
              </div>
              <div className="documents-row">
                <div className="document-card">
                  <div className="document-label">Front Document</div>
                  <div className="document-preview">
                    <img src={provider.frontDoc || "https://placehold.co/267x166"} alt="Front document" />
                    <div className="document-overlay">
                      <div className="overlay-icon" />
                    </div>
                  </div>
                </div>
                <div className="document-card">
                  <div className="document-label">Back Document</div>
                  <div className="document-preview">
                    <img src={provider.backDoc || "https://placehold.co/267x166"} alt="Back document" />
                    <div className="document-overlay">
                      <div className="overlay-icon" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="verification-footer">
            <button type="button" className="reject-btn" onClick={handleReject}>Reject Verification</button>
            <button type="button" className="approve-btn" onClick={handleApprove}>Approve & Verify</button>
          </div>
        </div>
      </div>
    </div>
  );
}