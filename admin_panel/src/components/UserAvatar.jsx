import { useEffect, useState } from "react";
import { getAuthorizedFileUrl } from "../services/storageService";

export default function UserAvatar({ photoPath, name, size = 40 }) {
  const [photoUrl, setPhotoUrl] = useState("");
  const [hasPhotoError, setHasPhotoError] = useState(false);

  useEffect(() => {
    let isActive = true;

    async function resolvePhotoUrl() {
      setPhotoUrl("");
      setHasPhotoError(false);

      if (!photoPath) {
        return;
      }

      try {
        const resolvedUrl = await getAuthorizedFileUrl(photoPath);
        if (isActive) {
          setPhotoUrl(resolvedUrl);
        }
      } catch (error) {
        console.error(`Could not load profile photo for ${name || "user"}:`, error);
        if (isActive) {
          setHasPhotoError(true);
        }
      }
    }

    resolvePhotoUrl();
    return () => {
      isActive = false;
    };
  }, [name, photoPath]);

  if (photoUrl && !hasPhotoError) {
    return (
      <img
        className="person-avatar person-avatar-photo"
        src={photoUrl}
        alt=""
        width={size}
        height={size}
        onError={() => {
          console.error(`Profile photo could not be displayed for ${name || "user"}.`);
          setHasPhotoError(true);
        }}
      />
    );
  }

  return (
    <span
      className="person-avatar person-avatar-placeholder"
      style={{ width: size, height: size }}
      aria-hidden="true"
    >
      <svg viewBox="0 0 100 100" focusable="false">
        <circle cx="50" cy="50" r="50" fill="#f1f1f1" />
        <circle cx="50" cy="37" r="18" fill="#bdbdbd" />
        <path
          d="M15 88c4-20 17-31 35-31s31 11 35 31a50 50 0 0 1-70 0Z"
          fill="#bdbdbd"
        />
      </svg>
    </span>
  );
}