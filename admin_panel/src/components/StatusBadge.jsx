function StatusBadge({ status }) {
  const normalizedStatus = status || "unknown";
  const label = normalizedStatus.replaceAll("_", " ");

  return (
    <span className={`status-badge status-${normalizedStatus}`}>
      {label}
    </span>
  );
}

export default StatusBadge;
