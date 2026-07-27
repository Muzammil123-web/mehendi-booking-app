# Mehendi Studio — Flutter App

A complete Flutter app for a mehendi/henna business:
- 📅 Book henna appointments by choosing a service, date, and time slot
- 💳 Pay online (Razorpay: UPI/cards/wallets) or Cash on Delivery / pay-on-visit
- 🛍️ Shop and buy henna cones (product catalog, cart, checkout)
- 📦 Track bookings and orders
- 🛠️ Admin dashboard to manage bookings, orders, products, and services

Built with **Flutter + Firebase** (Auth + Firestore) and **Razorpay** for payments.

---

## 1. Prerequisites

- Flutter SDK installed (3.3+): https://docs.flutter.dev/get-started/install
- A free Firebase account: https://console.firebase.google.com
- A Razorpay account (free to sign up, test mode works immediately): https://razorpay.com
- Android Studio / Xcode for running on device/emulator

---

## 2. Install dependencies

```bash
cd mehendi_booking_app
flutter pub get
```

---

## 3. Set up Firebase (Auth + Firestore)

1. Go to https://console.firebase.google.com → **Add project** → name it (e.g. "mehendi-studio").
2. In the project, enable:
   - **Authentication** → Sign-in method → enable **Email/Password**
   - **Firestore Database** → Create database → start in **production mode**
3. Install the FlutterFire CLI (one-time):
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. From the project root, run:
   ```bash
   flutterfire configure
   ```
   Select your Firebase project, and select the platforms you want (Android/iOS/Web).
   This automatically **overwrites** `lib/firebase_options.dart` with your real project keys.
5. That's it — the app now talks to your Firebase project.

### Firestore Security Rules
Go to Firestore → Rules and paste this starter ruleset (tighten further before production):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, update: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
    }
    match /services/{doc} {
      allow read: if true;
      allow write: if request.auth != null; // tighten: restrict to admins only
    }
    match /products/{doc} {
      allow read: if true;
      allow write: if request.auth != null; // tighten: restrict to admins only
    }
    match /time_slots/{doc} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /bookings/{doc} {
      allow read, write: if request.auth != null;
    }
    match /orders/{doc} {
      allow read, write: if request.auth != null;
    }
  }
}
```

> ⚠️ For real production use, restrict `write` on `services`/`products` to admin
> accounts only (e.g. via a custom claim or checking `isAdmin` on the user's doc),
> and restrict `bookings`/`orders` reads/writes to the owning `userId` or an admin.

### Making yourself an Admin
After you sign up once in the app, go to Firestore → `users` collection → find your
user document → set the field `isAdmin` to `true`. You'll now see the Admin
Dashboard option in the Profile tab (and land there on login).

### Seeding sample data (optional, recommended)
Add a couple of documents manually in Firestore console to get started:

**`services` collection** — example document:
```
name: "Bridal Henna"
description: "Intricate bridal design for hands and feet"
price: 2999
durationMinutes: 180
imageUrl: ""
isActive: true
```

**`products` collection** — example document:
```
name: "Natural Henna Cone (Pack of 12)"
description: "100% natural, chemical-free henna cones with deep, long-lasting stain."
price: 249
stock: 50
category: "Henna Cone"
rating: 4.7
isActive: true
```

---

## 4. Set up Razorpay (online payments)

1. Sign up at https://dashboard.razorpay.com/signup
2. Go to **Settings → API Keys** → Generate **Test Keys**
3. Copy the **Key ID** (starts with `rzp_test_...`)
4. Paste it into `lib/utils/constants.dart`:
   ```dart
   static const String razorpayKeyId = 'rzp_test_XXXXXXXXXXXX';
   ```
5. Test payments using Razorpay's test cards: https://razorpay.com/docs/payments/payments/test-card-upi-details/
6. When ready to go live, switch to your **Live Key ID** from the same page
   (requires KYC/business verification on Razorpay's side first).

> 🔒 **Security note:** This app uses Razorpay's standard client-side checkout,
> which is enough to accept real payments. For production-grade order
> verification (recommended before scaling up), create a small backend or
> **Firebase Cloud Function** that creates a Razorpay Order server-side using
> your **Key Secret** (never put the secret in the app), and verify the payment
> signature after checkout. Razorpay's docs: https://razorpay.com/docs/payments/server-integration/

### Android setup for Razorpay
In `android/app/build.gradle`, ensure `minSdkVersion` is at least 21 (Razorpay requirement).

### iOS setup for Razorpay
Run `cd ios && pod install` after `flutter pub get`.

---

## 5. Run the app

```bash
flutter run
```

---

## 6. App structure

```
lib/
  models/         Data models (User, Service, TimeSlot, Booking, Product, Order, CartItem)
  services/        Firebase Auth, Firestore, and Razorpay wrappers
  providers/       App-wide state (auth session, shopping cart) via Provider
  screens/
    auth/          Login, Signup
    home/          Bottom-nav shell
    booking/       Calendar → service → time slot → confirm & pay
    shop/          Product grid → detail → cart → checkout & pay
    orders/        "My Activity" — booking & order history
    admin/         Dashboard, manage bookings, orders, products, services
    profile/       User profile, logout, admin entry point
  widgets/         Reusable UI (buttons, product cards, status badges)
  utils/           Theme (henna maroon/gold palette) & constants
```

## 7. Customizing

- **Branding/colors**: edit `lib/utils/theme.dart` (`AppColors`)
- **Default time slots**: edit `AppConstants.defaultTimeSlots` in `lib/utils/constants.dart`
- **Delivery fee / free delivery threshold**: same constants file
- **App name/icon**: update `pubspec.yaml` name and use a tool like
  `flutter_launcher_icons` to set your logo as the app icon

## 8. Known limitations / next steps

- Payment verification is client-side only (see Razorpay note above) — add a
  Cloud Function for signature verification before going fully live.
- No push notifications yet — consider Firebase Cloud Messaging for booking
  reminders / order status updates.
- No image upload UI for products/services yet — currently you paste an image
  URL when adding a product/service in the admin panel. `image_picker` and
  `firebase_storage` are already included as dependencies if you want to add
  in-app photo uploads.
- Time slots are generated per-day automatically from `defaultTimeSlots`;
  build an admin screen if you want per-day custom slot editing later.
