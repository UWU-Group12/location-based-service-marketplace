# Cloud Firestore Database Structure


## 1. Design Principles

The database follows these principles:

- Use Firebase Authentication UID values as user and provider document IDs.
- Keep public provider information separate from private verification data.
- Use top-level collections for records queried across multiple users.
- Use subcollections for data owned by one document, such as notifications and request history.
- Store uploaded files in Firebase Storage and save only their paths in Firestore.
- Use Firestore `Timestamp`, `GeoPoint`, and numeric fields instead of formatted strings.
- Prevent customers and providers from changing protected fields such as roles, verification status, rating totals, and admin decisions.

---

## 2. Main Database Structure

```text
firestore
├── users
│   └── {userId}
│       ├── notifications
│       │   └── {notificationId}
│       ├── devices
│       │   └── {deviceId}
│       └── favourites
│           └── {providerId}
│
├── providerProfiles
│   └── {providerId}
│
├── providerVerifications
│   └── {providerId}
│
├── categories
│   └── {categoryId}
│
├── locations
│   └── {locationId}
│
├── serviceRequests
│   └── {requestId}
│       └── statusHistory
│           └── {statusEventId}
│
├── quotations
│   └── {quotationId}
│
├── reviews
│   └── {requestId}
│
└── complaints
    └── {complaintId}
```

---

## 3. Users Collection

### Path

```text
users/{userId}
```

Use the Firebase Authentication UID as `userId`.

### Purpose

Stores common account information for customers and service providers.

### Example

```json
{
  "displayName": "Kasun Perera",
  "email": "kasun@example.com",
  "phoneNumber": "+94771234567",
  "photoPath": "users/user-id/profile.jpg",
  "role": "customer",
  "accountStatus": "active",
  "profileCompleted": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `displayName` | String | Yes | User's display name |
| `email` | String | Yes | Email from Firebase Authentication |
| `phoneNumber` | String | No | User's contact number |
| `photoPath` | String | No | Firebase Storage path of profile image |
| `role` | String | Yes | `customer` or `provider` |
| `accountStatus` | String | Yes | `active`, `suspended`, or `disabled` |
| `profileCompleted` | Boolean | Yes | Indicates whether profile setup is complete |
| `createdAt` | Timestamp | Yes | Account creation time |
| `updatedAt` | Timestamp | Yes | Last profile update time |

### Protected Fields

Normal users must not directly update:

```text
role
accountStatus
createdAt
```

Administrator privileges should be handled using Firebase Authentication custom claims.

---

## 4. Provider Profiles Collection

### Path

```text
providerProfiles/{providerId}
```

Use the provider's Firebase Authentication UID as `providerId`.

### Purpose

Stores provider information that customers are allowed to view and search.

### Example

```json
{
  "providerId": "provider-user-id",
  "displayName": "Nimal Electric Works",
  "profileImagePath": "providers/provider-user-id/profile.jpg",
  "bio": "Residential electrician with five years of experience.",
  "categoryIds": [
    "electrician",
    "home-appliance-repair"
  ],
  "baseLocation": "GeoPoint",
  "geohash": "tc1abc123",
  "locationId": "badulla-town",
  "serviceRadiusKm": 20,
  "availabilityStatus": "available",
  "verificationStatus": "pending",
  "ratingAverage": 0,
  "reviewCount": 0,
  "completedJobCount": 0,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `providerId` | String | Yes | Provider UID |
| `displayName` | String | Yes | Public provider or business name |
| `profileImagePath` | String | No | Provider profile image path |
| `bio` | String | No | Provider description |
| `categoryIds` | Array<String> | Yes | Selected service categories |
| `baseLocation` | GeoPoint | Yes | Provider's working location |
| `geohash` | String | Yes | Used for nearby search |
| `locationId` | String | Yes | Supported location reference |
| `serviceRadiusKm` | Number | Yes | Maximum working distance |
| `availabilityStatus` | String | Yes | Current availability |
| `verificationStatus` | String | Yes | Provider verification state |
| `ratingAverage` | Number | Yes | Average provider rating |
| `reviewCount` | Number | Yes | Total number of reviews |
| `completedJobCount` | Number | Yes | Number of completed jobs |
| `createdAt` | Timestamp | Yes | Profile creation time |
| `updatedAt` | Timestamp | Yes | Last profile update |

### Availability Values

```text
available
busy
unavailable
```

### Verification Values

```text
not_submitted
pending
verified
rejected
```

### Protected Fields

Only administrators or trusted backend functions should update:

```text
verificationStatus
ratingAverage
reviewCount
completedJobCount
```

---

## 5. Provider Verifications Collection

### Path

```text
providerVerifications/{providerId}
```

### Purpose

Stores private provider identity and verification information. Customers must not have access to this collection.

### Example

```json
{
  "providerId": "provider-user-id",
  "documentType": "national_id",
  "frontDocumentPath": "verification/provider-user-id/nic-front.jpg",
  "backDocumentPath": "verification/provider-user-id/nic-back.jpg",
  "certificatePaths": [
    "verification/provider-user-id/certificate-1.pdf"
  ],
  "status": "pending",
  "submittedAt": "Timestamp",
  "reviewedBy": null,
  "reviewedAt": null,
  "rejectionReason": null
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `providerId` | String | Yes | Provider UID |
| `documentType` | String | Yes | Main submitted document type |
| `frontDocumentPath` | String | No | Front document image path |
| `backDocumentPath` | String | No | Back document image path |
| `certificatePaths` | Array<String> | No | Supporting certificate paths |
| `status` | String | Yes | Verification status |
| `submittedAt` | Timestamp | Yes | Submission time |
| `reviewedBy` | String | No | Admin UID |
| `reviewedAt` | Timestamp | No | Review completion time |
| `rejectionReason` | String | No | Reason for rejection |

Only the provider who owns the document and authorized administrators should be able to read it.

---

## 6. Categories Collection

### Path

```text
categories/{categoryId}
```

### Purpose

Stores service categories managed by administrators.

### Example

```json
{
  "name": "Electrician",
  "description": "Electrical installation and repair services",
  "iconPath": "categories/electrician.png",
  "active": true,
  "sortOrder": 1,
}
```

### Recommended IDs

```text
electrician
plumber
carpenter
mason
painter
shoe-repair
mobile-repair
```

### Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `name` | String | Yes | Category name |
| `description` | String | No | Category description |
| `iconPath` | String | No | Icon path in Firebase Storage |
| `active` | Boolean | Yes | Whether category is visible |
| `sortOrder` | Number | Yes | Display order |


Only administrators should create, update, or deactivate categories.

---

## 7. Locations Collection

### Path

```text
locations/{locationId}
```

### Purpose

Stores supported service locations managed by administrators.

### Example

```json
{
  "name": "Badulla",
  "district": "Badulla",
  "province": "Uva Province",
  "active": true,
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `name` | String | Yes | Location name |
| `district` | String | Yes | District name |
| `province` | String | Yes | Province name |
| `active` | Boolean | Yes | Whether location is supported |

---

## 8. Service Requests Collection

### Path

```text
serviceRequests/{requestId}
```

### Purpose

Stores customer service requests sent to selected providers.

### Example

```json
{
  "customerId": "customer-user-id",
  "providerId": "provider-user-id",
  "categoryId": "electrician",
  "title": "Kitchen power socket not working",
  "description": "Two kitchen sockets stopped working this morning.",
  "imagePaths": [
    "serviceRequests/request-id/image-1.jpg"
  ],
  "serviceLocation": {
    "point": "GeoPoint",
    "geohash": "tc1abc123",
    "addressText": "Badulla town"
  },
  "requestStatus": "submitted",
  "quotationStatus": "pending",
  "acceptedQuotationId": null,
  "finalAmount": null,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp",
  
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `customerId` | String | Yes | Customer UID |
| `providerId` | String | Yes | Selected provider UID |
| `categoryId` | String | Yes | Requested service category |
| `title` | String | Yes | Short request title |
| `description` | String | Yes | Detailed request description |
| `imagePaths` | Array<String> | No | Uploaded problem images |
| `serviceLocation` | Map | Yes | Location details |
| `requestStatus` | String | Yes | Current request state |
| `quotationStatus` | String | Yes | Current quotation state |
| `acceptedQuotationId` | String | No | Accepted quotation ID |
| `finalAmount` | Number | No | Final confirmed job amount |
| `createdAt` | Timestamp | Yes | Request creation time |
| `updatedAt` | Timestamp | Yes | Last update time |


### Request Status Values

```text
submitted
provider_rejected
quotation_received
confirmed
in_progress
completed
cancelled
```

### Quotation Status Values

```text
pending
sent
accepted
rejected
expired
```

The request status and quotation status should remain separate.

---

## 9. Request Status History Subcollection

### Path

```text
serviceRequests/{requestId}/statusHistory/{statusEventId}
```

### Purpose

Stores each request status change for the tracking screen and audit history.

### Example

```json
{
  "status": "in_progress",
  "changedBy": "provider-user-id",
  "changedByRole": "provider",
  "note": "Work started",
  "createdAt": "Timestamp"
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `status` | String | Yes | New request status |
| `changedBy` | String | Yes | UID of the user who changed it |
| `changedByRole` | String | Yes | `customer`, `provider`, or `admin` |
| `note` | String | No | Optional update note |
| `createdAt` | Timestamp | Yes | Status change time |

---

## 10. Quotations Collection

### Path

```text
quotations/{quotationId}
```

For the MVP, the quotation document ID may be the same as the request ID when only one provider can quote for each request.

### Example

```json
{
  "requestId": "request-id",
  "customerId": "customer-user-id",
  "providerId": "provider-user-id",
  "serviceCharge": 5000,
  "inspectionFee": 500,
  "materialCostNote": "Material cost will be confirmed after inspection.",
  "estimatedTotal": 5500,
  "availableAt": "Timestamp",
  "message": "I can visit tomorrow morning.",
  "status": "sent",
  "expiresAt": "Timestamp",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `requestId` | String | Yes | Related service request |
| `customerId` | String | Yes | Customer UID |
| `providerId` | String | Yes | Provider UID |
| `serviceCharge` | Number | Yes | Estimated service charge |
| `inspectionFee` | Number | No | Inspection fee |
| `materialCostNote` | String | No | Material cost explanation |
| `estimatedTotal` | Number | Yes | Estimated total |
| `availableAt` | Timestamp | No | Provider's available time |
| `message` | String | No | Provider message |
| `status` | String | Yes | Quotation state |
| `expiresAt` | Timestamp | No | Expiration time |
| `createdAt` | Timestamp | Yes | Creation time |
| `updatedAt` | Timestamp | Yes | Last update time |

### Status Values

```text
sent
accepted
rejected
expired
```

All monetary values must be stored as numbers, not formatted strings.

---

## 11. Reviews Collection

### Path

```text
reviews/{requestId}
```

Using the request ID as the review ID prevents multiple reviews for the same completed job.

### Example

```json
{
  "requestId": "request-id",
  "customerId": "customer-user-id",
  "providerId": "provider-user-id",
  "rating": 5,
  "comment": "Arrived on time and completed the work properly.",
  "moderationStatus": "visible",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `requestId` | String | Yes | Completed request ID |
| `customerId` | String | Yes | Customer UID |
| `providerId` | String | Yes | Provider UID |
| `rating` | Number | Yes | Rating from 1 to 5 |
| `comment` | String | No | Review text |
| `moderationStatus` | String | Yes | Review visibility state |
| `createdAt` | Timestamp | Yes | Creation time |
| `updatedAt` | Timestamp | Yes | Last update time |

### Moderation Values

```text
visible
hidden
under_review
```

The provider's average rating and review count should be updated by trusted backend logic.

---

## 12. Complaints Collection

### Path

```text
complaints/{complaintId}
```

### Example

```json
{
  "requestId": "request-id",
  "createdBy": "customer-user-id",
  "againstUserId": "provider-user-id",
  "complaintType": "service_quality",
  "description": "The reported job was not completed.",
  "status": "open",
  "assignedAdminId": null,
  "adminResponse": null,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp",
  "resolvedAt": null
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `requestId` | String | Yes | Related request |
| `createdBy` | String | Yes | Complaint creator UID |
| `againstUserId` | String | Yes | Reported user UID |
| `complaintType` | String | Yes | Complaint category |
| `description` | String | Yes | Complaint details |
| `status` | String | Yes | Complaint state |
| `assignedAdminId` | String | No | Assigned administrator |
| `adminResponse` | String | No | Administrator response |
| `createdAt` | Timestamp | Yes | Complaint creation time |
| `updatedAt` | Timestamp | Yes | Last update time |
| `resolvedAt` | Timestamp | No | Resolution time |

### Status Values

```text
open
under_review
resolved
dismissed
```

---

## 13. Notifications Subcollection

### Path

```text
users/{userId}/notifications/{notificationId}
```

### Example

```json
{
  "type": "quotation_received",
  "title": "New quotation received",
  "body": "A provider sent a quotation for your request.",
  "relatedRequestId": "request-id",
  "read": false,
  "createdAt": "Timestamp"
}
```

### Notification Types

```text
request_received
request_rejected
quotation_received
quotation_accepted
quotation_rejected
job_started
job_completed
verification_approved
verification_rejected
complaint_updated
```

---

## 14. Device Tokens Subcollection

### Path

```text
users/{userId}/devices/{deviceId}
```

### Example

```json
{
  "fcmToken": "firebase-cloud-messaging-token",
  "platform": "android",
  "updatedAt": "Timestamp"
}
```

This supports Firebase Cloud Messaging notifications on multiple devices.

---

## 15. Favourites Subcollection

### Path

```text
users/{userId}/favourites/{providerId}
```

### Example

```json
{
  "providerId": "provider-user-id",
  "createdAt": "Timestamp"
}
```

This feature is optional for the MVP.

---

## 16. Firebase Storage Structure

Uploaded files should be stored in Firebase Storage.

```text
users/{userId}/profile.jpg

providers/{providerId}/profile.jpg

verification/{providerId}/nic-front.jpg
verification/{providerId}/nic-back.jpg
verification/{providerId}/certificates/{fileName}

serviceRequests/{requestId}/{fileName}

categories/{categoryId}/{fileName}
```

Firestore should store the Storage path or download URL, not the file itself.

---

## 17. Main Queries

### Customer Request History

```dart
FirebaseFirestore.instance
    .collection('serviceRequests')
    .where('customerId', isEqualTo: currentUserId)
    .orderBy('createdAt', descending: true);
```

### Provider Incoming Requests

```dart
FirebaseFirestore.instance
    .collection('serviceRequests')
    .where('providerId', isEqualTo: currentUserId)
    .where('requestStatus', isEqualTo: 'submitted')
    .orderBy('createdAt', descending: true);
```

### Verified and Available Providers by Category

```dart
FirebaseFirestore.instance
    .collection('providerProfiles')
    .where('verificationStatus', isEqualTo: 'verified')
    .where('availabilityStatus', isEqualTo: 'available')
    .where('categoryIds', arrayContains: selectedCategoryId);
```

Nearby provider search should also use geohash bounds and exact distance filtering.

---

## 18. Recommended Composite Indexes

```text
serviceRequests
customerId ASC, createdAt DESC

serviceRequests
providerId ASC, requestStatus ASC, createdAt DESC

quotations
customerId ASC, status ASC, createdAt DESC

quotations
providerId ASC, status ASC, createdAt DESC

reviews
providerId ASC, moderationStatus ASC, createdAt DESC

providerProfiles
verificationStatus ASC,
availabilityStatus ASC,
categoryIds ARRAY,
geohash ASC
```

Firestore may request additional indexes when new compound queries are added.

---

## 19. Security Access Summary

| Collection | Customer | Provider | Admin |
|---|---|---|---|
| `users` | Own document | Own document | Read and manage |
| `providerProfiles` | Read verified profiles | Manage own profile | Read and manage |
| `providerVerifications` | No access | Own document | Read and manage |
| `categories` | Read | Read | Manage |
| `locations` | Read | Read | Manage |
| `serviceRequests` | Own requests | Assigned requests | Read and manage |
| `quotations` | Own quotations | Own quotations | Read and manage |
| `reviews` | Create for completed jobs | Read related reviews | Moderate |
| `complaints` | Create and read own | Create and read own | Manage |
| `notifications` | Own notifications | Own notifications | No normal access |

