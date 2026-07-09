import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.jsx'
import './index.css' // ඔයාගේ style file එකක් තියෙනවා නම් විතරක් මේක තියන්න

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)