# Navodayan Mobile (Expo)

Android/iOS client for the Navodayan community portal.

Repo: https://github.com/raghvsc/navodayan-mobile

Uses the backend API from https://github.com/raghvsc/navodayan (`backend/`).

## Package / bundle IDs
- Android: `org.navodayan.app`
- iOS: `org.navodayan.app`

## Setup

### 1. Backend (required for local API)
```bash
git clone git@github.com:raghvsc/navodayan.git
cd navodayan/backend
npm install
# configure .env (see backend docs / .env.example)
npm run dev
```

### 2. Mobile app
```bash
git clone git@github.com:raghvsc/navodayan-mobile.git
cd navodayan-mobile
npm install
cp .env.example .env
```

Update `.env` for your device:
- Android emulator: `http://10.0.2.2:5000/api`
- iOS simulator: `http://127.0.0.1:5000/api`
- Physical phone: `http://<your-computer-lan-ip>:5000/api`
- Deployed API: `https://2v7xgmkczk.us-east-1.awsapprunner.com/api`

```bash
npm start
```

Scan the QR code with Expo Go, or press `a` for Android emulator.

## Current screens
- Home
- Login
- Register (lightweight join)
- Directory (list + search when logged in)

## Notes
- Play Store listing package name must stay `org.navodayan.app`.
- API changes belong in `navodayan` (backend) first; then update this app.
