import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../auth/useAuth";
import LoadingSpinner from "../components/LoadingSpinner";

function ProtectedRoute() {
  const { currentAdmin, isAuthLoading } = useAuth();
  const location = useLocation();

  if (isAuthLoading) {
    return <LoadingSpinner fullPage label="Checking administrator access..." />;
  }

  if (!currentAdmin) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  }

  return <Outlet />;
}

export default ProtectedRoute;
