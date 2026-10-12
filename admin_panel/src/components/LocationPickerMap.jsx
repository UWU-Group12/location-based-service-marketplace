import L from "leaflet";
import "leaflet/dist/leaflet.css";
import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";
import { MapContainer, Marker, TileLayer, useMapEvents } from "react-leaflet";

// Vite renames Leaflet's bundled marker images, so point the icon at them.
L.Icon.Default.mergeOptions({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIcon2x,
  shadowUrl: markerShadow,
});

// Same fallback centre as the mobile app (Colombo).
const defaultCenter = [6.9271, 79.8612];

function MapClickHandler({ onPick, disabled }) {
  useMapEvents({
    click(event) {
      if (!disabled) {
        onPick({
          latitude: event.latlng.lat,
          longitude: event.latlng.lng,
        });
      }
    },
  });
  return null;
}

function LocationPickerMap({ value, onChange, disabled }) {
  const position = value ? [value.latitude, value.longitude] : null;

  return (
    <>
      <MapContainer
        center={position || defaultCenter}
        zoom={position ? 13 : 8}
        style={{ height: 300, borderRadius: 12 }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <MapClickHandler onPick={onChange} disabled={disabled} />
        {position && <Marker position={position} />}
      </MapContainer>
      <small>
        {position
          ? `${value.latitude.toFixed(5)}, ${value.longitude.toFixed(5)}`
          : "Click the map to set the provider's location."}
        {position && !disabled && (
          <>
            {" "}
            <button
              type="button"
              className="button button-small button-secondary"
              onClick={() => onChange(null)}
            >
              Clear
            </button>
          </>
        )}
      </small>
    </>
  );
}

export default LocationPickerMap;
