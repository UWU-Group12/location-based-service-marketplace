# System Design – Location-Based Service Marketplace

> ICT 212-2 · Group 12. Paste into AI chats for context. Coding conventions: `service_finder_app/AI_GUIDE.md`.
> Status legend: ✅ done · 🟡 partial · 🔴 not started (as of 2026-10-02)
> Decision: no admin-managed `locations` / `locationId`. Location = GPS (`baseLocation`) + `serviceRadiusKm`; maps & place names via OpenStreetMap (planned).

## 1. Purpose
Mobile marketplace connecting customers with nearby skilled workers (plumber, electrician, carpenter, painter, mason, mobile repair). Replaces word-of-mouth with search → request → quotation → job tracking → review. Contact details stay hidden until a request is made; all requests/reviews are recorded.

## 2. Architecture
```
┌────────────────────────┐     ┌──────────────────────┐
│ Flutter Android app    │     │ React admin panel    │
│ roles: customer/provider│     │ role: admin          │
└──────────┬─────────────┘     └──────────┬───────────┘
           │ Firebase SDKs                │ Firebase JS SDK
┌──────────▼──────────────────────────────▼───────────┐
│ Firebase: Auth · Firestore · Storage · FCM (planned) │
│ Security rules = role-based access control           │
└──────────┬──────────────────────────────────────────┘
           │ HTTPS
┌──────────▼───────────────┐   ┌──────────────────────┐
│ Cloudflare Worker → Gemini│   │ OpenStreetMap (plan) │
│ (AI suggestions only)     │   │ geolocator for GPS   │
└───────────────────────────┘   └──────────────────────┘
```
- **No custom backend.** Clients talk to Firebase directly; Firestore rules enforce who can read/write what. Cloud Functions may be added for trusted status changes & notifications.
- **App layers:** Screens (`features/`) → Services (`services/`) → Firebase. Models (`models/`) map Firestore docs.
- **Roles:** stored in `users/{uid}.role` (`customer` | `provider` | `admin`). `AuthWrapper` in `main.dart` routes to the matching shell.

| Layer | Tech |
|---|---|
| Mobile | Flutter / Dart, `provider` state |
| Admin | React + Vite + Tailwind |
| Auth | Firebase Auth (email, Google) |
| Data | Cloud Firestore |
| Files | Firebase Storage |
| Notifications | Firebase Cloud Messaging |
| AI | Gemini via Cloudflare Worker |
| Location | geolocator for GPS (+ OpenStreetMap map/place names planned) |

## 3. Data Model (Firestore)
| Collection | Key fields | Written by |
|---|---|---|
| `users/{uid}` | role, displayName, email, phoneNumber, photoPath, accountStatus (active/suspended/disabled), profileCompleted | owner, admin |
| `providerProfiles/{uid}` | displayName, bio, categoryIds[], experienceYears, workingDays, workingHours, baseLocation, geohash (reserved), serviceRadiusKm (5/10/15/20/30), verificationStatus, availabilityStatus, profileImagePath, ratingAverage, reviewCount, completedJobCount | provider, admin |
| `providerVerifications/{uid}` | documentType, frontDocumentPath, backDocumentPath, certificatePaths, status, submittedAt, reviewedAt, reviewedBy, rejectionReason | provider (create), admin (review) |
| `categories/{id}` | name, iconPath, active, sortOrder | admin |
| `serviceRequests/{id}` | customerId, providerId, categoryId, title, description, imagePaths[], serviceLocation{point}, addressText, preferredDate/Time (🔴 not saved yet), requestStatus, quotationStatus, acceptedQuotationId, finalAmount | customer (create), status updates by both |
| `quotations/{id}` | requestId, customerId, providerId, serviceCharge, inspectionFee, materialCostNote, estimatedTotal, availableAt, message, status | provider (create), customer (accept/reject) |
| `reviews/{id}` 🔴 | requestId, customerId, providerId, rating 1–5, comment, hidden | customer, admin (moderate) |
| `notifications/{id}` 🔴 | userId, type, title, body, refId, read | system |
| `complaints/{id}` 🔴 | requestId, raisedBy, against, reason, status | customer/provider, admin |

Storage: `providers/{uid}/profile.*` · `verification/{uid}/*` · `requests/{requestId}/*` (planned).

## 4. Status Lifecycle
```
requestStatus:   submitted ─► quotation_received ─► confirmed ─► in_progress ─► completed
                     │                │                 │
                     └─► rejected     └─► cancelled ◄───┘   (customer may cancel before in_progress)
quotationStatus: pending ─► sent ─► accepted | rejected | expired
```
| Transition | Actor |
|---|---|
| submitted → rejected | provider declines request |
| submitted → quotation_received | provider sends quotation |
| quotation_received → confirmed | customer accepts quotation |
| quotation_received → submitted/rejected | customer rejects quotation (provider may re-quote) |
| confirmed → in_progress → completed | provider |
| any (before in_progress) → cancelled | customer |
| completed → review allowed | customer |

Every change updates `updatedAt` and (planned) creates a notification for the other party.

## 5. Functional Requirements
### Customer
| ID | Requirement | Status |
|---|---|---|
| C1 | Register / login (email, Google) | ✅ |
| C2 | View & edit profile | 🟡 view + logout only |
| C3 | Browse categories, list verified & available providers | ✅ |
| C4 | Filter / sort providers by distance (customer GPS vs provider `baseLocation` + `serviceRadiusKm`), rating | 🔴 |
| C5 | AI category suggestion from problem description | ✅ |
| C6 | View provider profile (no contact details) | ✅ |
| C7 | Send request: title, description, GPS + address, preferred date/time, images | 🟡 images & preferred date/time not saved |
| C8 | AI improve request description | ✅ |
| C9 | View my requests & history (live) | 🟡 dummy data |
| C10 | Request details with status timeline; cancel | 🔴 |
| C11 | View quotation; accept / reject | 🔴 |
| C12 | Rate & review completed job | 🔴 |
| C13 | Notifications | 🔴 |

### Service Provider
| ID | Requirement | Status |
|---|---|---|
| P1 | Register / login | ✅ |
| P2 | Onboarding: profile, image, category, experience, working days/hours, GPS location & radius, NIC documents | ✅ |
| P3 | Edit profile, toggle availability | 🔴 |
| P4 | View incoming requests (live) & request details | 🔴 |
| P5 | Accept / reject request | 🔴 |
| P6 | Send quotation (charge, inspection fee, material note, available time, message) | 🔴 |
| P7 | Update job status (in_progress, completed) | 🔴 |
| P8 | Job history | 🔴 |
| P9 | Dashboard: counts, earnings, rating | 🔴 |
| P10 | Notifications | 🔴 |

### Administrator (React panel)
| ID | Requirement | Status |
|---|---|---|
| A1 | Admin login (Firebase Auth, `admin` custom claim) | ✅ |
| A2 | Verify providers & documents (approve/reject with reason) | ✅ |
| A3 | Manage customers & providers (suspend/activate) | ✅ |
| A4 | Manage categories | ✅ (locations removed from scope) |
| A5 | Monitor requests & quotations | 🔴 |
| A6 | Manage complaints; moderate reviews | 🔴 |
| A7 | Reports & statistics | 🟡 dashboard counts |

### System / Non-functional
- Role-based access enforced in Firestore & Storage rules (not just UI).
- Only `verified` + `available` providers are searchable; suspended accounts are blocked.
- Status changes visible to all roles in real time (Firestore streams).
- Images ≤ 10 MB, image MIME types only.
- AI is advisory only – the user always confirms the final category/description.
- Android first; works on low-end devices; clear loading/error/empty states.

## 6. Main Flows
**F1 – Onboarding & auth**
```
Splash ─► Welcome ─► Login ──(existing)──► AuthWrapper ─► Customer / Provider shell
                    └► Role selection ─► Customer register ─► Customer shell
                                       └► Provider steps (name ► contact ► password ► personal ► service ►
                                          experience ► working area ► documents ► summary) ─► Provider shell
                                          (verificationStatus = pending until admin approves)
```
**F2 – Find a provider**
```
Customer home ─► category  ──┐
             └► AI: describe problem ─► suggested category ─► confirm ─┘
             ─► provider list (verified + available) ─► provider details ─► "Request service"
```
**F3 – Request → quotation → job (core workflow)**
```
Customer: create request (+AI improve, location, time, images) ─► submitted
Provider: sees request ─► reject  ─► rejected (customer notified)
                       └► send quotation ─► quotation_received
Customer: view quotation ─► reject ─► provider may re-quote
                         └► accept ─► confirmed (contact details now visible)
Provider: start job ─► in_progress ─► complete ─► completed
Customer: rate & review ─► provider rating updated
```
**F4 – Provider verification (admin)**
```
Provider submits docs ─► providerVerifications (pending) ─► Admin reviews
  ─► approve ─► providerProfiles.verificationStatus = verified ─► searchable
  └► reject (reason) ─► provider notified, can resubmit
```
**F5 – Complaints & moderation (admin)**
```
User raises complaint on a request ─► admin reviews ─► resolve / suspend account
Admin hides abusive review ─► excluded from provider rating
```

## 7. Project Direction (Roadmap)
| Phase | Goal | Key work |
|---|---|---|
| 1 ✅ | Foundation | Auth, roles, models, categories, provider onboarding, search, AI features, rules |
| 2 ⏳ next | Core workflow | Provider requests tab + details, quotation create/view/accept, customer requests on live data, status timeline, cancel, request images, rules for status updates |
| 3 | Completion & trust | Job status updates, reviews + rating aggregation, provider dashboard & history, profile edit, availability toggle |
| 4 | Engagement | FCM notifications + notifications screen, distance sort/filters, OpenStreetMap view + place names |
| 5 | Admin | Remaining admin: request/quotation monitoring, complaints, review moderation, reports (login, verification, users, categories done) |
| 6 | Release | Remove dummy/dev code, testing (unit + manual test cases in `docs/testing`), performance, final report |

**Principles:** finish the core workflow end-to-end before polish · real Firestore data only · every new write path ships with a rules update · keep AI advisory.
