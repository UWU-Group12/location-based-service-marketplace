# Location-Based Service Marketplace

ICT 212-2 Independent Study Project 1 - Group 12
Uva Wellassa University

## About the Project

This is a mobile app that helps customers find skilled workers near them, like plumbers, electricians, carpenters, painters and mobile repair technicians.

Many good workers don't have any online presence, so customers usually find them through friends or roadside boards. Our app tries to solve this by letting customers search for workers by location and category, send job requests, and give ratings after the job is done.

There are 3 types of users:

- **Customer** - searches for workers, sends requests, accepts quotations and gives reviews
- **Service Provider** - creates a profile, receives requests, sends quotations and updates job status
- **Admin** - verifies providers and manages the system using a web panel

## Main Features

- Login and register for customers and providers
- Search nearby workers using the map
- View provider profiles, ratings and reviews
- Send service requests with location and photos
- Providers can send quotations
- Track job status (pending, accepted, in progress, completed)
- Ratings and reviews
- Notifications
- AI help to suggest a category and write a better request description
- Admin panel to verify providers and manage users and categories

## Technologies Used

- **Flutter (Dart)** - mobile app
- **React** - admin panel
- **Firebase** - authentication, Firestore database, storage and notifications
- **Google Maps** - location and map features
- **Gemini API** - AI features
- **Git and GitHub** - version control

## Folder Structure

```
service_finder_app/   Flutter mobile app
admin_panel/          React admin panel
firebase/             Firestore and storage rules
docs/                 Project documents, diagrams and reports
```

## How to Run

### Mobile App

You need Flutter, Android Studio (or VS Code) and an emulator or Android phone.

```
cd service_finder_app
flutter pub get
flutter run
```

### Admin Panel

You need Node.js installed.

```
cd admin_panel
npm install
npm run dev
```

Note: Firebase config files and API keys are needed to connect to the backend. Ask a team member for them. Please don't push any keys to GitHub.

## Git Workflow

- `main` - final working version
- `develop` - main development branch
- `feature/...` - for new features

Create a new branch from `develop`, do your work, then make a pull request back to `develop`.

## Team Members

| Name | Registration Number |
|---|---|
| D.S.R. Dissanayake | UWU/ICT/23/006 |
| M.T. Kaushalya | UWU/ICT/23/002 |
| K.D.P. Kandegama | UWU/ICT/23/064 |
| L.R.N.P. Rajakaruna | UWU/ICT/23/073 |
| W.M.D.H. Chathumina | UWU/ICT/23/021 |


## Project Status

Still under development.
