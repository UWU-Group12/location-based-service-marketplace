import { BrowserRouter } from "react-router-dom";
import { AuthProvider } from "./auth/AuthContext";
import AppRoutes from "./routes/AppRoutes";
import "./App.css";

function App() {
  const isAppPath =
    window.location.pathname === "/app" ||
    window.location.pathname.startsWith("/app/");

  return (
    <BrowserRouter basename={isAppPath ? "/app" : "/"}>
      <AuthProvider>
        <AppRoutes />
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
