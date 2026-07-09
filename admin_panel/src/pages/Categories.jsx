import React, { useState } from 'react';

export default function Categories() {
  // දැනට තියෙන සේවා වර්ග (Dummy Categories)
  const [categories, setCategories] = useState([
    { id: 1, name: 'Plumber', description: 'Leaking pipes and tap repairs' },
    { id: 2, name: 'Electrician', description: 'Wiring and electrical fixes' },
    { id: 3, name: 'Carpenter', description: 'Furniture and woodwork' },
  ]);

  // අලුත් Category එකක් ඇතුළත් කරන්න input fields සඳහා states
  const [newCategory, setNewCategory] = useState('');
  const [newDesc, setNewDesc] = useState('');

  // Form එක Submit කරන කොට ක්‍රියාත්මක වන function එක
  const handleAddCategory = (e) => {
    e.preventDefault();
    if (!newCategory.trim()) return;

    const newId = categories.length + 1;
    const addedItem = { id: newId, name: newCategory, description: newDesc };

    setCategories([...categories, addedItem]);
    setNewCategory(''); // Input එක clear කිරීමට
    setNewDesc('');     // Input එක clear කිරීමට
  };

  return (
    <div>
      <h2 style={{ marginBottom: '10px' }}>Category Management</h2>
      <p style={{ color: '#666', marginBottom: '30px' }}>Add and manage service categories available for users.</p>

      <div style={{ display: 'flex', gap: '30px', flexWrap: 'wrap' }}>
        {/* වම් පැත්තේ තියෙන Form එක - අලුත් Category එකක් එකතු කරන්න */}
        <div style={{ flex: '1', minWidth: '300px', background: '#fff', padding: '25px', borderRadius: '8px', boxShadow: '0 4px 6px rgba(0,0,0,0.05)', height: 'fit-content' }}>
          <h4 style={{ marginTop: 0, marginBottom: '20px', color: '#4e73df' }}>Add New Category</h4>
          <form onSubmit={handleAddCategory}>
            <div style={{ marginBottom: '15px' }}>
              <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '14px' }}>Category Name</label>
              <input
                type="text"
                value={newCategory}
                onChange={(e) => setNewCategory(e.target.value)}
                placeholder="e.g., Painter, Mason"
                style={{ width: '100%', padding: '10px', borderRadius: '4px', border: '1px solid #d1d3e2', boxSizing: 'border-box' }}
                required
              />
            </div>
            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '14px' }}>Description</label>
              <textarea
                value={newDesc}
                onChange={(e) => setNewDesc(e.target.value)}
                placeholder="Brief details about the service"
                style={{ width: '100%', padding: '10px', borderRadius: '4px', border: '1px solid #d1d3e2', boxSizing: 'border-box', height: '80px', resize: 'none' }}
              />
            </div>
            <button type="submit" style={{ width: '100%', background: '#4e73df', color: '#fff', border: 'none', padding: '12px', borderRadius: '4px', fontWeight: 'bold', cursor: 'pointer' }}>
              Add Category
            </button>
          </form>
        </div>

        {/* දකුණු පැත්තේ තියෙන List එක - දැනට තියෙන Categories පෙන්වන්න */}
        <div style={{ flex: '1.5', minWidth: '350px', background: '#fff', padding: '25px', borderRadius: '8px', boxShadow: '0 4px 6px rgba(0,0,0,0.05)' }}>
          <h4 style={{ marginTop: 0, marginBottom: '20px', color: '#333' }}>Existing Categories</h4>
          <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
            {categories.map((cat) => (
              <li key={cat.id} style={{ padding: '15px', borderBottom: '1px solid #e3e6f0', display: 'flex', flexDirection: 'column', gap: '5px' }}>
                <strong style={{ color: '#4e73df', fontSize: '16px' }}>{cat.name}</strong>
                <span style={{ color: '#666', fontSize: '14px' }}>{cat.description || 'No description provided.'}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}