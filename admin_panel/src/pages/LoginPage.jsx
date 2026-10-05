import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../auth/useAuth";
import LoadingSpinner from "../components/LoadingSpinner";
import MessageBanner from "../components/MessageBanner";
import { getLoginErrorMessage } from "../services/authService";
import myLogo from "../assets/my-logo.png";
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
      
      <div
        className="logo-section"
        style={{
         
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          transform: "translateY(-52px)",
          gap: "2px",
        }}
      >
        <img
          src={myLogo}
          alt="Logo"
          style={{ height: "200px", width: "auto", display: "block"}}
        />
        <span
          style={{
            fontSize: "50px",
            fontWeight: "bold",
            color: "#050505",
            letterSpacing: "4px",
            textAlign: "center",
            marginTop: "-35px",
          }}
        >
          RAW
        </span>
      </div>

      
      <div className="login-panel" style={{ width: "350px", flexShrink: 0, transform: "translateY(-40px)" }}>
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
  style={{
    backgroundColor: "#000000",
    color: "#ffffff",
    height: "50px",
     minHeight: "0",
    fontSize: "16px",
    padding: "0 50px",
    border: "none",
  }}
>
  {isSubmitting ? "Signing in..." : "Sign in "}
</button>
        </form>
      </div>
    </div>
  );
}

export default LoginPage;