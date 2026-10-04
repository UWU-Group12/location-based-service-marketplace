export function formatDate(value) {
  if (!value) {
    return "Not available";
  }

  const date = typeof value.toDate === "function" ? value.toDate() : new Date(value);

  if (Number.isNaN(date.getTime())) {
    return "Not available";
  }

  return new Intl.DateTimeFormat("en-LK", {
    year: "numeric",
    month: "short",
    day: "numeric",
  }).format(date);
}

export function getInitials(name = "") {
  const initials = name
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join("");

  return initials.toUpperCase() || "?";
}

export function getDataErrorMessage(error, fallbackMessage) {
  if (error?.code === "permission-denied") {
    return "Your administrator account is not allowed to perform this action.";
  }

  if (error?.code === "unavailable") {
    return "Firebase is temporarily unavailable. Please try again.";
  }

  return fallbackMessage;
}

export function getCreateCustomerErrorMessage(error, fallbackMessage) {
  switch (error?.code) {
    case "auth/email-already-in-use":
      return "A sign-in account already exists for this email address.";
    case "auth/invalid-email":
      return "Enter a valid email address.";
    case "auth/weak-password":
      return "Use a password with at least 6 characters.";
    case "auth/operation-not-allowed":
      return "Email and password sign-in is disabled in Firebase Authentication.";
    case "auth/too-many-requests":
      return "Too many attempts. Please wait and try again.";
    case "auth/network-request-failed":
      return "Unable to reach Firebase. Check your internet connection.";
    default:
      return getDataErrorMessage(error, fallbackMessage);
  }
}
