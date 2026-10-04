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
  "experienceYears": 5,
  "workingDays": ["Mon", "Tue", "Wed", "Thu", "Fri"],
  "workingHours": "Full Day",
  "baseLocation": "GeoPoint",
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
| `experienceYears` | Number | Yes | Whole years of professional experience |
| `workingDays` | Array<String> | Yes | Days the provider normally works |
| `workingHours` | String | Yes | Selected working-hours period |
| `baseLocation` | GeoPoint | Yes | Provider's captured working location |
| `geohash` | String | No | Reserved for a future geohash search improvement |
| `serviceRadiusKm` | Number | Yes | Maximum working distance: 5, 10, 15, 20, or 30 km |
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

## 7. Service Requests Collection

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

### Allowed Request Status Transitions

Enforced in `firestore.rules` by `validRequestTransition`. Skipping a step is
rejected, so a request cannot reach `completed` (and therefore cannot be
reviewed) without the work actually progressing through the states.

```text
submitted         -> quotation_received | provider_rejected | cancelled
quotation_received -> confirmed | cancelled
confirmed         -> in_progress
in_progress       -> completed | cancelled
```

A new request must be created with `requestStatus == 'submitted'`. Without
that, a customer could create a request already `completed` and review it
immediately, which is the forgery the transition graph exists to prevent.

Only the customer may perform the `in_progress -> completed` transition, so a
provider cannot unilaterally mark a job finished. Admin updates bypass the
state machine entirely.

Who may write which fields on a request:

| Actor | Writable fields |
| --- | --- |
| Provider (assigned) | `requestStatus`, `quotationStatus`, `finalAmount`, `updatedAt` |
| Customer (own) | `requestStatus`, `quotationStatus`, `acceptedQuotationId`, `updatedAt` |

The provider is the only party that may write `finalAmount`. They record it on
the request at the moment they send the quotation, so a price always originates
from the provider and the customer can only decide whether to take it.

Each side may also write `quotationStatus`, but only within its own part:

| Actor | May write `quotationStatus` as |
| --- | --- |
| Provider | `sent` |
| Customer | `accepted`, `rejected` |

So a provider cannot accept their own price and start work the customer never
agreed to, and a customer cannot fake a quote having arrived. Rejecting a
quotation cancels the request, because a request only ever carries one quote.

Neither party may change `customerId`, `providerId`, `categoryId`, `title`,
`description`, `imagePaths`, `serviceLocation`, `addressText`, `customerName`,
`createdAt`, or `preferredDate`.

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

## 8. Request Status History Subcollection

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

## 9. Quotations Collection

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

## 10. Reviews Collection

### Path

```text
reviews/{requestId}
```

Using the request ID as the review ID prevents multiple reviews for the same completed job.

### Who Can Write

Only the customer named on the request, and only once the request has reached
`completed`, may create a review. `rating` must be between 1 and 5, and
`createdAt` / `updatedAt` must equal `request.time`, so a client cannot
backdate a review to make it look older than it is. Reviews are immutable
afterwards: no customer, provider or admin may edit or delete one through the
client SDK. Corrections are made by a trusted backend, which is also what
recomputes the provider aggregates.

### Who Can Read

Reading reviews requires a signed-in user. A review with
`moderationStatus == 'visible'` is readable by any signed-in user. A review
with any other moderation status is readable only by its author and by admins.
Reading a review that does not exist yet is allowed, so the app can check
whether a job has already been reviewed.

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

## 11. Complaints Collection

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

## 12. Notifications Subcollection

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

## 13. Device Tokens Subcollection

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

## 14. Favourites Subcollection

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

## 15. Firebase Storage Structure

Uploaded files should be stored in Firebase Storage.

```text
users/{userId}/profile.jpg

providers/{providerId}/profile.jpg

verification/{providerId}/nic-front.jpg
verification/{providerId}/nic-back.jpg
verification/{providerId}/certificates/{fileName}

serviceRequests/{requestId}/{fileName}

categories/{fileName}
```

Firestore should store the Storage path or download URL, not the file itself.

Storage rules allow providers to manage their own profile images and admins
with the `admin` custom claim to upload provider profile images on their behalf.
Provider profile image uploads must be image files smaller than 5 MB. Category
icons are managed by admins and their `iconPath` must point to an image that
exists in Storage.

---

## 16. Main Queries

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

For the current MVP, this query shows all verified and available providers in the selected category. Provider location is stored only as GPS (`baseLocation`) plus `serviceRadiusKm`; there is no `locationId`. Distance-based filtering (on device) and OpenStreetMap area names can be added later.

---

## 17. Recommended Composite Indexes

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
categoryIds ARRAY
```

Firestore may request additional indexes when new compound queries are added.

---

## 18. Security Access Summary

| Collection | Customer | Provider | Admin |
|---|---|---|---|
| `users` | Own document | Own document | Read and manage |
| `providerProfiles` | Read verified profiles | Manage own profile | Read and manage |
| `providerVerifications` | No access | Own document | Read and manage |
| `categories` | Read | Read | Manage |
| `serviceRequests` | Own requests | Assigned requests | Read and manage |
| `quotations` | Own quotations | Own quotations | Read and manage |
| `reviews` | Create for completed jobs | Read related reviews | Moderate |
| `complaints` | Create and read own | Create and read own | Manage |
| `notifications` | Own notifications | Own notifications | No normal access |
