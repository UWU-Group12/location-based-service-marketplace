import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../auth/useAuth";
import LoadingSpinner from "../components/LoadingSpinner";
import MessageBanner from "../components/MessageBanner";
import { getLoginErrorMessage } from "../services/authService";

function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [formError, setFormError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const {
    accessError,
    clearAccessError,
    currentAdmin,
    isAuthLoading,
    login,
  } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (currentAdmin) {
      navigate("/dashboard", { replace: true });
    }
  }, [currentAdmin, navigate]);

  async function handleSubmit(event) {
    event.preventDefault();
    setFormError("");
    clearAccessError();

    if (!email.trim() || !password) {
      setFormError("Email and password are required.");
      return;
    }

    setIsSubmitting(true);
    try {
      await login(email, password);
      navigate("/dashboard", { replace: true });
    } catch (error) {
      console.error("Administrator sign-in failed:", error);
      setFormError(getLoginErrorMessage(error));
    } finally {
      setIsSubmitting(false);
    }
  }

  if (isAuthLoading) {
    return <LoadingSpinner fullPage label="Checking your session..." />;
  }

  return (
    <div className="login-page">
      <div className="login-panel">
        <div className="login-brand">
          <span className="brand-mark">S</span>
          <span>Raw</span>
        </div>

        <div className="login-heading">
          <span className="header-eyebrow">Administrator access</span>
          <h1>Welcome back</h1>
          <p>Sign in with an account that has the Firebase admin claim.</p>
        </div>

        <MessageBanner message={formError || accessError} type="error" />

        <form className="form-stack" onSubmit={handleSubmit} noValidate>
          <label className="form-field">
            <span>Email address</span>
            <input
              type="email"
              value={email}
              autoComplete="email"
              placeholder="admin@example.com"
              onChange={(event) => setEmail(event.target.value)}
              disabled={isSubmitting}
            />
          </label>

          <label className="form-field">
            <span>Password</span>
            <div className="password-field">
              <input
                type={showPassword ? "text" : "password"}
                value={password}
                autoComplete="current-password"
                placeholder="Enter your password"
                onChange={(event) => setPassword(event.target.value)}
                disabled={isSubmitting}
              />
              <button
                type="button"
                onClick={() => setShowPassword((current) => !current)}
                disabled={isSubmitting}
              >
                {showPassword ? "Hide" : "Show"}
              </button>
            </div>
          </label>

          <button
            type="submit"
            className="button button-primary login-button"
            disabled={isSubmitting}
          >
            {isSubmitting ? "Signing in..." : "Sign in to admin panel"}
          </button>
        </form>

        <p className="login-security-note">
          Normal customer and provider accounts cannot access this panel.
        </p>
      </div>

      <div className="login-decoration" aria-hidden="true">
        <div>
          <span>Secure administration</span>
          <h2>Manage the marketplace with verified, real-time data.</h2>
          <p>
            Review providers, support users, and maintain service categories
            from one focused workspace.
          </p>
        </div>
      </div>
    </div>
  );
}

export default LoginPage;
