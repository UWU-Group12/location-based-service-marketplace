function LoadingSpinner({ fullPage = false, label = "Loading..." }) {
  return (
    <div className={fullPage ? "loading-state loading-full-page" : "loading-state"}>
      <span className="spinner" aria-hidden="true" />
      <span>{label}</span>
    </div>
  );
}

export default LoadingSpinner;
