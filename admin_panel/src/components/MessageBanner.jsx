function MessageBanner({ message, type = "error", onDismiss }) {
  if (!message) {
    return null;
  }

  return (
    <div className={`message-banner message-${type}`} role="status">
      <span>{message}</span>
      {onDismiss && (
        <button type="button" onClick={onDismiss} aria-label="Dismiss message">
          ×
        </button>
      )}
    </div>
  );
}

export default MessageBanner;
