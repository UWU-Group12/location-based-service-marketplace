function EmptyState({ title, message }) {
  return (
    <div className="empty-state">
      <div className="empty-state-icon" aria-hidden="true">
        ◇
      </div>
      <h3>{title}</h3>
      <p>{message}</p>
    </div>
  );
}

export default EmptyState;
