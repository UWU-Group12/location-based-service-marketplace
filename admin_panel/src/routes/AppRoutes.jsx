import { Navigate, Route, Routes } from "react-router-dom";
import AdminLayout from "../components/AdminLayout";
import CategoriesPage from "../pages/CategoriesPage";
import CustomersPage from "../pages/CustomersPage";
import DashboardPage from "../pages/DashboardPage";
import LoginPage from "../pages/LoginPage";
import ProviderVerificationsPage from "../pages/ProviderVerificationsPage";
import ProvidersPage from "../pages/ProvidersPage";
import ProtectedRoute from "./ProtectedRoute";

function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />

      <Route element={<ProtectedRoute />}>
        <Route element={<AdminLayout />}>
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/customers" element={<CustomersPage />} />
          <Route path="/providers" element={<ProvidersPage />} />
          <Route
            path="/provider-verifications"
            element={<ProviderVerificationsPage />}
          />
          <Route path="/categories" element={<CategoriesPage />} />
        </Route>
      </Route>

      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}

export default AppRoutes;
