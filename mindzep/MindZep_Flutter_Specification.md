# MindZep – Flutter App Technical Specification
**Version:** 1.0  
**Platform:** iOS (primary), Android (secondary)  
**Architecture:** Clean Architecture + BLoC State Management  
**Design Language:** iOS-native feel, modern mobile UI

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Tech Stack & Dependencies](#2-tech-stack--dependencies)
3. [Project Structure](#3-project-structure)
4. [Clean Architecture Layers](#4-clean-architecture-layers)
5. [Role-Based Navigation](#5-role-based-navigation)
6. [Authentication Module](#6-authentication-module)
7. [User Module](#7-user-module)
8. [Psychologist Module](#8-psychologist-module)
9. [Admin Module](#9-admin-module)
10. [Shared / Common Components](#10-shared--common-components)
11. [BLoC Architecture Details](#11-bloc-architecture-details)
12. [Data Models](#12-data-models)
13. [API Contract](#13-api-contract)
14. [Design System & Theme](#14-design-system--theme)
15. [Navigation & Routing](#15-navigation--routing)
16. [Mock Data Reference](#16-mock-data-reference)

---

## 1. Project Overview

**App Name:** MindZep  
**Tagline:** Mental health support, on your schedule  
**Website:** https://mindzep.com/

MindZep is a mental health counselling platform connecting users with licensed psychologists. It has three distinct role-based interfaces:

| Role | Primary Goal |
|------|-------------|
| **User** | Browse psychologists, book/call sessions, manage appointments |
| **Psychologist** | Manage availability slots, view session history, publish blogs |
| **Admin** | Approve/manage psychologists, oversee users and payments |

### Key Business Rules
- **Free minutes:** Each call includes 2 free minutes; billing starts from minute 3 at a per-minute rate.
- **Booking window:** Users can only book appointments within 1 month from today's date.
- **Psychologist compensation:** Psychologists are salaried employees. No earnings, wallet, commission, or payout data must appear anywhere on the Psychologist interface.
- **Availability indicator:** Psychologist cards show a colored dot (green = available, orange = busy, red = offline) overlaid on the bottom-right corner of the profile photo. No status text on cards.

---

## 2. Tech Stack & Dependencies

### Core
```yaml
flutter: ">=3.19.0"
dart: ">=3.3.0"
```

### State Management
```yaml
flutter_bloc: ^8.1.6
bloc: ^8.1.4
equatable: ^2.0.5
```

### Navigation
```yaml
go_router: ^13.2.0
```

### Networking
```yaml
dio: ^5.4.3
retrofit: ^4.1.0          # type-safe REST client
pretty_dio_logger: ^1.3.1
```

### Local Storage
```yaml
flutter_secure_storage: ^9.0.0   # tokens, sensitive data
shared_preferences: ^2.2.3       # non-sensitive preferences
hive_flutter: ^1.1.0             # offline cache
```

### UI & Styling
```yaml
cached_network_image: ^3.3.1
shimmer: ^3.0.0
lottie: ^3.1.0               # micro-animations
flutter_svg: ^2.0.10
intl: ^0.19.0
timeago: ^3.6.1
dotted_border: ^2.1.0
smooth_page_indicator: ^1.1.0
```

### Calling & Media
```yaml
agora_rtc_engine: ^6.3.2     # or zegocloud_uikit_prebuilt_call
permission_handler: ^11.3.1
wakelock_plus: ^1.2.1
```

### Payments
```yaml
razorpay_flutter: ^1.3.6     # primary (Indian market)
# fallback: stripe_flutter
```

### Forms & Validation
```yaml
reactive_forms: ^17.0.0
```

### File & Media Upload
```yaml
image_picker: ^1.1.1
file_picker: ^8.0.0
firebase_storage: ^11.7.0    # or S3 presigned URLs
```

### Notifications
```yaml
firebase_messaging: ^14.9.0
flutter_local_notifications: ^17.2.1
```

### Utilities
```yaml
dartz: ^0.10.1               # functional error handling (Either)
injectable: ^2.4.2           # dependency injection
get_it: ^7.7.0               # service locator
freezed: ^2.5.2              # immutable data classes
json_annotation: ^4.9.0
connectivity_plus: ^6.0.3
url_launcher: ^6.3.0
```

---

## 3. Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_dimensions.dart
│   │   ├── app_strings.dart
│   │   └── app_assets.dart
│   ├── errors/
│   │   ├── failures.dart          # ServerFailure, CacheFailure, etc.
│   │   └── exceptions.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── api_endpoints.dart
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       └── error_interceptor.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_theme_extension.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── currency_utils.dart
│   │   ├── validators.dart
│   │   └── extensions.dart
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_card.dart
│       ├── app_avatar.dart         # avatar + status dot
│       ├── app_badge.dart
│       ├── app_shimmer.dart
│       ├── app_empty_state.dart
│       ├── app_error_state.dart
│       ├── app_bottom_sheet.dart
│       └── app_snackbar.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── user/
│   │   ├── calling/
│   │   ├── appointments/
│   │   ├── profile/
│   │   └── home/
│   ├── psychologist/
│   │   ├── slots/
│   │   ├── sessions/
│   │   ├── blog/
│   │   └── profile/
│   └── admin/
│       ├── dashboard/
│       ├── psychologist_management/
│       ├── user_management/
│       └── appointments/
│
├── injection/
│   └── injection_container.dart   # get_it + injectable setup
│
└── main.dart
```

Each feature folder follows the three-layer structure:
```
feature/
├── data/
│   ├── datasources/
│   │   ├── feature_remote_datasource.dart
│   │   └── feature_local_datasource.dart
│   ├── models/
│   │   └── feature_model.dart          # JSON serializable
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart         # pure Dart, no JSON
│   ├── repositories/
│   │   └── feature_repository.dart     # abstract
│   └── usecases/
│       ├── get_feature_usecase.dart
│       └── ...
└── presentation/
    ├── bloc/
    │   ├── feature_bloc.dart
    │   ├── feature_event.dart
    │   └── feature_state.dart
    ├── pages/
    │   └── feature_page.dart
    └── widgets/
        └── feature_widget.dart
```

---

## 4. Clean Architecture Layers

### Domain Layer (innermost – no Flutter dependencies)
- **Entities:** Plain Dart classes, `@freezed` for immutability.
- **Repository interfaces:** Abstract classes only.
- **Use Cases:** Single-responsibility classes, each implementing `UseCase<Type, Params>`.

```dart
// core/usecases/usecase.dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
```

### Data Layer
- **Models:** Extend domain entities, add `fromJson`/`toJson` via `json_serializable`.
- **Remote DataSources:** Dio + Retrofit annotated interfaces.
- **Local DataSources:** Hive boxes for offline caching.
- **Repository Implementations:** Merge remote + local, handle `Either<Failure, T>`.

### Presentation Layer
- **BLoC:** Handles UI logic; emits States; responds to Events.
- **Pages:** Stateless widgets that listen to BLoC via `BlocBuilder`/`BlocListener`.
- **Widgets:** Reusable UI components extracted from pages.

---

## 5. Role-Based Navigation

After login the app routes to a role-specific shell based on the authenticated user's role.

### User Bottom Navigation (Flutter `NavigationBar`)
```
Tab 1: Home / Browse         (icon: explore_outlined / explore)
Tab 2: Appointments          (icon: calendar_today_outlined / calendar_today)
Tab 3: Sessions / Calls      (icon: call_outlined / call)
Tab 4: Profile               (icon: person_outline / person)
```

### Psychologist Bottom Navigation
```
Tab 1: Dashboard             (icon: dashboard_outlined / dashboard)
Tab 2: My Slots              (icon: schedule_outlined / schedule)
Tab 3: Session History       (icon: history_outlined / history)
Tab 4: Blog                  (icon: article_outlined / article)
Tab 5: Profile               (icon: person_outline / person)
```

### Admin Bottom Navigation
```
Tab 1: Dashboard             (icon: bar_chart_outlined / bar_chart)
Tab 2: Psychologists         (icon: psychology_outlined / psychology)
Tab 3: Users                 (icon: group_outlined / group)
Tab 4: Appointments          (icon: event_note_outlined / event_note)
Tab 5: Settings              (icon: settings_outlined / settings)
```

**Implementation note:** Use Flutter's `NavigationBar` widget (Material 3) styled to match iOS conventions via `Theme`. Use `IndexedStack` to preserve tab state.

```dart
// Shell widget pseudo-code
class UserShell extends StatefulWidget { ... }
class _UserShellState extends State<UserShell> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    UserHomePage(), AppointmentsPage(), CallsPage(), UserProfilePage()
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _currentIndex, children: _pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: [...],
    ),
  );
}
```

---

## 6. Authentication Module

### Screens

#### 6.1 Splash Screen
- Full-screen gradient background (primary brand gradient).
- Centered MindZep logo (SVG) with Lottie entrance animation.
- Auto-navigates after 2.5 seconds: checks stored token → routes to correct dashboard or login.

#### 6.2 Onboarding (first launch only)
- 3-page `PageView` with `SmoothPageIndicator`.
- Page 1: "Find Your Therapist" – illustration + heading + body.
- Page 2: "Book in Seconds" – illustration + heading + body.
- Page 3: "Start Healing" – illustration + CTA button "Get Started".
- Skip button top-right on pages 1–2.
- Stored in `SharedPreferences` as `onboarding_complete`.

#### 6.3 Login Screen
- Logo + tagline at top.
- `TextFormField` for email (keyboard: emailAddress).
- `TextFormField` for password (obscureText, eye toggle).
- "Forgot Password?" text button.
- Primary "Login" button (full width, rounded, brand gradient).
- Divider "OR".
- Google Sign-In button (outlined, Google logo SVG).
- "Don't have an account? Register" text button.
- Role is determined from API response, not from UI.

#### 6.4 Register Screen
- Full name, email, phone (Indian +91 prefix), password, confirm password.
- Role selector: User / Psychologist (Admin accounts created by existing admins).
- OTP verification flow for phone number.
- Terms & conditions checkbox.

#### 6.5 Forgot Password
- Email input → send OTP → OTP entry (6 boxes) → new password.

### BLoC: `AuthBloc`
```
Events: LoginRequested, RegisterRequested, LogoutRequested,
        GoogleSignInRequested, ForgotPasswordRequested, OtpSubmitted

States: AuthInitial, AuthLoading, AuthAuthenticated(user, role),
        AuthUnauthenticated, AuthError(message)
```

### Entities
```dart
class UserEntity extends Equatable {
  final String id, name, email, phone, avatarUrl;
  final UserRole role;  // enum: user, psychologist, admin
  final bool isVerified;
}
```

---

## 7. User Module

### 7.1 Home / Browse Screen

**Layout:**
- Custom `SliverAppBar` with greeting "Good morning, [name]" + notification bell icon.
- Search bar (tappable → navigates to search/filter page).
- Horizontal `ListView` of specialization filter chips (All, Anxiety, Depression, Relationships, Stress, Trauma, Sleep, Anger).
- "Featured Psychologists" horizontal card scroll.
- "All Psychologists" vertical list with `ListView.builder`.

**Psychologist Card (vertical list):**
```
┌─────────────────────────────────────────┐
│  [Photo+dot]  Dr. Ananya Krishnan        │
│               Clinical Psychologist     │
│               ★ 4.8  (124 reviews)      │
│               10 yrs exp  |  ₹12/min    │
│  [Book]                      [Call Now] │
└─────────────────────────────────────────┘
```
- Profile photo: `CircleAvatar` (radius 28).
- Status dot: `Positioned` widget at `bottom: 0, right: 0`, `Container` of size 14×14, white border 2px, fill: green/amber/red based on `AvailabilityStatus` enum.
- No status text anywhere on the card.
- "Call Now" button: disabled + grey if status ≠ `available`.
- "Book" button: always enabled.
- Tapping the card → Psychologist Detail Page.

**Filter Bottom Sheet:**
- Specialization multi-select chips.
- Experience range slider (0–20+ years).
- Price range slider (₹5–₹50/min).
- Rating filter (≥3★, ≥4★, ≥4.5★).
- Availability toggle (Show only available now).
- "Apply Filters" primary button + "Reset" text button.

**BLoC: `PsychologistListBloc`**
```
Events: LoadPsychologists, FilterChanged(FilterParams), SearchQueryChanged(query),
        LoadMorePsychologists (pagination)
States: PsychologistListInitial, PsychologistListLoading,
        PsychologistListLoaded(list, hasMore, appliedFilters),
        PsychologistListError(message)
```

---

### 7.2 Psychologist Detail Page

**Header:**
- Full-width hero `CachedNetworkImage` (height 280, with gradient overlay at bottom).
- Back button (iOS `CupertinoNavigationBar` style).
- Floating action-style "Share" icon top-right.

**Content (scrollable):**
- Name, credentials (e.g. "PhD, RCI Licensed"), rating + review count.
- Specializations: wrapped `Chip` list.
- About section (expandable with "Read more").
- Languages spoken: icon + text list.
- Session stats: Total sessions, years experience, response rate.
- Pricing: "₹12 / minute after 2 free minutes".
- Reviews section: 3 most recent + "View all" button.
- Blog posts by this psychologist (horizontal scroll, max 3).

**Bottom sticky bar:**
```
[Book Appointment]          [Call Now  ▶]
```

---

### 7.3 Calling Flow

#### 7.3.1 Pre-Call Screen (Psychologist Detail → Call Now)
- Shows psychologist photo, name, specialization.
- Device permission check (microphone, camera).
- Video/Audio toggle before connecting.
- "Connect" primary button.
- Rate shown: "₹0 for first 2 min, then ₹12/min".

#### 7.3.2 Active Call Screen
- **Full-screen layout** (no bottom nav).
- Remote video feed (full screen background) or audio-only avatar.
- Local video feed: draggable `PiP` overlay (bottom-right, 120×160, rounded corners).
- **Call timer** displayed prominently at top: `MM:SS`.
- Free-time banner: "2 free minutes remaining" → changes to "Billing started – ₹X accrued" after 2 min.
- Billing counter (animated tick every second after free minutes).
- Bottom control row (frosted glass `BackdropFilter` style):
  ```
  [Mute mic]  [End Call]  [Toggle cam]  [Speaker]  [Chat]
  ```
- "End Call" button: red circle, size 64, centered and elevated.

**Timer & Billing logic (handled in BLoC):**
```dart
// CallBloc tracks seconds elapsed
// 0–119s: free
// 120s+: billable
// Billing amount = ((seconds - 120) / 60).ceil() * ratePerMinute
```

#### 7.3.3 Post-Call Summary Screen
- Duration: "You spoke for 8 min 34 sec".
- Charges breakdown: "2 min free + 6 min 34 sec billed = ₹84".
- Payment status badge (Paid / Pending).
- Star rating prompt (1–5 stars) + optional text feedback.
- "Done" button → back to Home.

**BLoC: `CallBloc`**
```
Events: InitiateCall(psychologistId), CallConnected, CallDisconnected,
        ToggleMute, ToggleCamera, ToggleSpeaker, EndCall,
        TimerTick, SubmitRating(stars, feedback)

States: CallIdle, CallConnecting, CallInProgress(durationSeconds,
        billedSeconds, estimatedCost, isMuted, isCameraOn),
        CallEnded(CallSummary), CallError(message)
```

---

### 7.4 Slot Booking Flow

#### 7.4.1 Slot Booking Page
**Date Picker:**
- Horizontal date strip (Flutter `ListView.builder`, 30 items = today + 29 days).
- Each date item: day abbreviation (Mon), date number (13), month if first of month.
- Selected date: brand color background, white text, slight elevation.
- Dates beyond 1 month from today: greyed out, non-tappable.

```dart
// Booking window enforcement
final maxBookingDate = DateTime.now().add(const Duration(days: 30));
bool isDateSelectable(DateTime date) =>
    date.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
    date.isBefore(maxBookingDate.add(const Duration(days: 1)));
```

**Time Slot Grid:**
- After selecting date, load available slots for that psychologist.
- Grid: `GridView` with 3 columns, each slot is a `ChoiceChip`.
- Slot states: Available (brand outline), Selected (brand fill), Booked (grey, disabled).
- Slot format: "10:00 AM", "02:30 PM".

**Session Type:**
- `SegmentedButton` (Flutter built-in): "Video Call" | "Audio Call" | "Chat".

**Session Duration:**
- `SegmentedButton`: "30 min" | "45 min" | "60 min".

**Booking Summary:**
- Card showing: Psychologist, Date, Time, Type, Duration, Rate/min.
- Estimated cost note.

**Proceed to Payment** button (sticky at bottom).

#### 7.4.2 Payment Gateway Screen
- Order summary at top.
- Payment methods:
  - UPI (default, highlighted): UPI ID input or QR scan.
  - Net Banking: bank selector `ListView`.
  - Cards: card number, expiry, CVV fields.
  - Wallets: PhonePe, Google Pay, Paytm tiles.
- Integration: Razorpay SDK (`razorpay_flutter`).
- On success → Booking Confirmed screen.
- On failure → error dialog with retry option.

#### 7.4.3 Booking Confirmed Screen
- Lottie success animation (checkmark).
- "Appointment Confirmed!" heading.
- Details card: psychologist, date/time, session type.
- "Add to Calendar" button (`url_launcher` → calendar intent).
- "View Appointment" button → navigates to appointment detail.
- "Back to Home" text button.

**BLoC: `SlotBookingBloc`**
```
Events: LoadAvailableSlots(psychologistId, date), SelectDate(date),
        SelectSlot(slot), SelectSessionType(type), SelectDuration(duration),
        ProceedToPayment, PaymentCompleted(paymentId), PaymentFailed(reason)

States: SlotBookingInitial, SlotsLoading, SlotsLoaded(slots, selectedDate),
        SlotSelected(slot), PaymentProcessing, BookingConfirmed(appointment),
        BookingError(message)
```

---

### 7.5 Appointments Page

**Tabs (Flutter `TabBar`):**
```
[Upcoming]  [Ongoing]  [Past]
```

#### Upcoming Tab
- List of booked future appointments.
- **Appointment Card:**
  ```
  ┌──────────────────────────────────────────┐
  │ [Photo]  Dr. Ananya Krishnan             │
  │          Thu, 15 May 2026 · 10:00 AM    │
  │          Video Call · 45 min            │
  │  [Join]                    [Cancel]     │
  └──────────────────────────────────────────┘
  ```
- "Join" button enabled 5 minutes before appointment time.
- "Cancel" allowed up to 24 hours before (else shows refund policy note).
- Countdown timer for next appointment shown at top if within 24 hours.

#### Ongoing Tab
- Active/in-progress session cards.
- "Rejoin" button if call dropped.
- Live duration indicator.

#### Past Tab
- Completed appointments.
- Rating badge if rated, "Rate Now" if not.
- "Rebook" button on each card.
- Expandable session notes (if psychologist added notes).
- Filter by: This week / This month / Last 3 months / Custom range.

**BLoC: `AppointmentsBloc`**
```
Events: LoadAppointments(AppointmentFilter), CancelAppointment(id),
        RebookAppointment(appointmentId), TabChanged(AppointmentTab)

States: AppointmentsInitial, AppointmentsLoading,
        AppointmentsLoaded(upcoming, ongoing, past),
        AppointmentCancelling, AppointmentCancelled,
        AppointmentsError(message)
```

---

### 7.6 User Profile Page

- Avatar (tappable to change), name, email, phone.
- Edit Profile option.
- **Sections:**
  - My Appointments (quick count chips: upcoming, completed, cancelled)
  - Payment History (link to transaction list)
  - Notifications Settings (toggle list)
  - Privacy & Security (change password, 2FA)
  - Help & Support (FAQ, chat with support)
  - About MindZep (version, terms, privacy policy)
  - Logout (with confirmation dialog)

---

## 8. Psychologist Module

> **CRITICAL CONSTRAINT:** No earnings, wallet, commission, payout, or financial data must appear anywhere on the Psychologist interface. Psychologists are salaried employees.

### 8.1 Psychologist Dashboard (Home)

**Header:**
- "Welcome back, Dr. [Name]" greeting with current date.
- Availability toggle: `Switch` widget labeled "Available for calls" (updates status dot for users).

**Stats Row (3 cards):**
```
[Today's Sessions: 4]  [This Week: 18]  [Rating: 4.8★]
```
- These are `Card` widgets in a `Row` with `Expanded`.

**Today's Schedule:**
- Horizontal timeline or vertical list of today's booked slots.
- Each slot card: Time, patient name (initials only for privacy), session type icon, status badge (Upcoming/In Progress/Completed).
- "Start Session" button on upcoming slots near their time.

**Recent Activity Feed:**
- New booking notifications.
- Patient ratings received.
- Blog post engagement (views/comments count).

**BLoC: `PsychologistDashboardBloc`**
```
Events: LoadDashboard, ToggleAvailability(bool), RefreshDashboard

States: DashboardInitial, DashboardLoading,
        DashboardLoaded(stats, todaySchedule, recentActivity, isAvailable),
        DashboardError(message)
```

---

### 8.2 Slot Management Page

**Calendar View:**
- Flutter built-in approach: custom `TableCalendar`-like grid using `Table` widget, or use `table_calendar` package.
- Month view with dots indicating days that have slots configured.
- Tap a date → shows slot list for that day.

**Slot List for Selected Date:**
- Each slot: time range, status (Available / Booked / Blocked).
- Booked slots show patient first name + session type.
- FAB `+` → Add Slot bottom sheet.

**Add Slot Bottom Sheet:**
- Time picker: Flutter `showTimePicker`.
- Duration selector: `SegmentedButton` (30/45/60 min).
- Session types: multi-select `FilterChip` (Video / Audio / Chat).
- Repeat options: `RadioListTile` (No repeat / Daily / Weekdays / Custom days).
- "Save Slot" button.

**Bulk Slot Management:**
- Long-press slot → multi-select mode.
- Delete selected / Block selected / Make available.

**BLoC: `SlotManagementBloc`**
```
Events: LoadSlotsForDate(date), LoadSlotsForMonth(month, year),
        AddSlot(SlotData), EditSlot(slotId, SlotData),
        DeleteSlot(slotId), BlockSlot(slotId), BulkAction(ids, action)

States: SlotManagementInitial, SlotsLoading, SlotsLoaded(slotsMap),
        SlotSaving, SlotSaved, SlotError(message)
```

---

### 8.3 Session History Page

**Filter Bar:**
- `SegmentedButton`: All | Upcoming | Completed | Cancelled.
- Date range filter (icon button → `showDateRangePicker`).
- Search by patient name.

**Session List:**
- `ListView.builder` with `Divider`.
- **Session Card:**
  ```
  [Patient avatar initials]  Patient: Aryan K.
                             15 May 2026 · 10:00 AM
                             Video · 45 min · Completed
                             [View Notes] [Add Notes]
  ```
- "Add Notes" → opens `TextField` in bottom sheet (plain text, 1000 char limit).
- "View Notes" → shows previously saved notes.

**Session Detail Page (on tap):**
- Full session info.
- Session timeline (joined at, ended at, actual duration).
- Notes editor.
- Patient rating received (1–5 stars displayed, no actions).

**BLoC: `SessionHistoryBloc`**
```
Events: LoadSessions(SessionFilter), LoadMoreSessions,
        AddNote(sessionId, note), UpdateNote(sessionId, note),
        SearchSessions(query)

States: SessionHistoryInitial, SessionsLoading,
        SessionsLoaded(sessions, hasMore, appliedFilter),
        NotesSaving, NotesSaved, SessionHistoryError(message)
```

---

### 8.4 Blog Management Page

**Blog List Tab:**
- Cards showing: thumbnail, title, status badge (Draft / Published / Under Review), date, view count.
- Swipe-to-delete with confirmation.
- FAB → Create New Blog.

**Blog Editor Page:**
- Title `TextField` (large, 100 char limit).
- Category selector (`DropdownButtonFormField`): Mental Health, Anxiety, Depression, Relationships, Sleep, Mindfulness, etc.
- Tags input (chip input pattern).
- Cover image picker (`ImagePicker`).
- Rich text body (use `flutter_quill` package or a simple `TextField` with markdown support).
- Word count indicator.
- "Save Draft" button + "Submit for Review" primary button.

**Blog Preview:**
- Renders the blog as it will appear to users.
- "Back to Edit" AppBar action.

**Published Blogs Tab:**
- Same as Blog List but filtered to published only.
- Shows view count, comment count.
- Tap → read view (same as user-facing blog).

**BLoC: `BlogBloc`**
```
Events: LoadBlogs(BlogFilter), CreateBlog, UpdateBlog(Blog),
        DeleteBlog(id), SubmitBlogForReview(id), LoadBlogById(id)

States: BlogInitial, BlogsLoading, BlogsLoaded(blogs),
        BlogSaving, BlogSaved(Blog), BlogSubmitted,
        BlogDeleted, BlogError(message)
```

---

### 8.5 Psychologist Profile Page

- Profile photo (editable).
- Name, credentials, specializations (editable chips).
- About/Bio (editable rich text).
- Languages (add/remove).
- Years of experience.
- Education & certifications (add/remove list tiles).
- "Save Changes" button (sticky bottom).
- Password change option.
- Help & Support link.
- Logout.

---

## 9. Admin Module

### 9.1 Admin Dashboard

**Header:**
- "Admin Panel" title + logout icon.
- Last refreshed timestamp.
- Pull-to-refresh.

**Key Metrics Grid (2×2):**
```
┌──────────────────┬──────────────────┐
│ Total Users      │ Active Psych.    │
│     1,248  📈    │     32  📈       │
├──────────────────┼──────────────────┤
│ Sessions Today   │ Pending Approval │
│     87           │     5  🔴        │
└──────────────────┴──────────────────┘
```
- Each `Card` shows metric name, value, trend icon.
- Pending Approval has red badge if > 0.

**Revenue Chart:**
- `LineChart` or `BarChart` using `fl_chart` package.
- Toggle: Daily / Weekly / Monthly.
- Shows platform revenue (user payments collected).

**Recent Activity Timeline:**
- List of latest events: new user registered, session completed, new psychologist application, blog published.
- Each with icon, description, timestamp.

**Quick Actions:**
- "Review Pending Psychologists" button → navigates to approval queue.
- "View Today's Sessions" button.

**BLoC: `AdminDashboardBloc`**
```
Events: LoadDashboard, RefreshDashboard, ChangeChartPeriod(period)

States: DashboardInitial, DashboardLoading,
        DashboardLoaded(metrics, chartData, recentActivity),
        DashboardError(message)
```

---

### 9.2 Psychologist Management Page

**Tabs:**
```
[All]  [Pending Approval]  [Active]  [Disabled]
```

**Psychologist Admin Card:**
```
┌────────────────────────────────────────────┐
│ [Photo]  Dr. Ananya Krishnan               │
│          Clinical Psychologist             │
│          Applied: 10 May 2026  ★ 4.8      │
│          Sessions: 142 total              │
│ [View Profile]  [Enable/Disable]  [▼ More]│
└────────────────────────────────────────────┘
```
- "More" dropdown: View Slots, View Blogs, Reset Password, Delete Account.

**Pending Approval Flow:**
- Tap psychologist in Pending tab → Approval Detail Page.
- Shows full profile: photo, credentials, uploaded documents (license, certificates).
- Document viewer (`PDFView` or image viewer).
- Notes field for admin.
- Two action buttons: "Approve" (green) | "Reject" (red, requires rejection reason).
- On approve: sends welcome email (API call), changes status to Active.

**Psychologist Detail (Admin view):**
- All profile info.
- Slot management (admin can add/edit/delete slots on behalf of psychologist).
- Blog management (admin can approve/reject/publish/unpublish blogs).
- Session history (full list, all patients).
- Enable/Disable account toggle with reason field.

**BLoC: `PsychologistManagementBloc`**
```
Events: LoadPsychologists(PsychManagementFilter), LoadMorePsychologists,
        ApprovePsychologist(id), RejectPsychologist(id, reason),
        EnablePsychologist(id), DisablePsychologist(id, reason),
        LoadPsychologistDetail(id), SearchPsychologists(query),
        AdminAddSlot(psychId, slot), AdminDeleteSlot(psychId, slotId),
        AdminToggleBlog(psychId, blogId, isPublished)

States: PsychManagementInitial, PsychManagementLoading,
        PsychManagementLoaded(psychologists, tab, hasMore),
        PsychApproving, PsychApproved, PsychRejected,
        PsychDetailLoading, PsychDetailLoaded(PsychologistAdmin),
        PsychManagementError(message)
```

---

### 9.3 User Management Page

**Search & Filter:**
- Search by name, email, phone.
- Filter: All / Active / Suspended / Unverified.
- Sort: Newest / Most Sessions / Alphabetical.

**User Admin Card:**
```
[Avatar]  Aryan Kapoor
          aryan.kapoor@email.com  |  +91 98XXXXXXXX
          Joined: 12 Jan 2026  |  Sessions: 8
          Status: Active ●
          [View]  [Suspend]
```

**User Detail Page (Admin):**
- Full profile.
- Appointment history (all sessions with all psychologists).
- Payment history: table with Date, Psychologist, Duration, Amount, Status.
- Account actions: Suspend / Unsuspend / Delete (with confirmation dialogs).
- Notes field for admin to log reasons for actions.

**BLoC: `UserManagementBloc`**
```
Events: LoadUsers(UserManagementFilter), LoadMoreUsers,
        LoadUserDetail(id), SearchUsers(query),
        SuspendUser(id, reason), UnsuspendUser(id),
        DeleteUser(id, reason)

States: UserManagementInitial, UsersLoading,
        UsersLoaded(users, hasMore, appliedFilter),
        UserDetailLoading, UserDetailLoaded(UserAdmin),
        UserActionProcessing, UserActionDone,
        UserManagementError(message)
```

---

### 9.4 Appointments Management (Admin)

**Filters:** All / Upcoming / Ongoing / Completed / Cancelled  
**Date range picker** for custom range.  
**Search** by user name or psychologist name.

**Appointment Admin Card:**
```
User: Aryan Kapoor ↔ Dr. Ananya Krishnan
15 May 2026 · 10:00 AM · 45 min · Video
Status: Completed | Amount: ₹396
[View Details]  [Refund]  [Cancel]
```

**Appointment Detail (Admin):**
- Full info + audit trail (created at, updated at, cancelled at, who cancelled).
- Payment breakdown.
- Session notes (read-only).
- Refund action (with amount input, reason, confirmation).

---

## 10. Shared / Common Components

### `AppAvatar`
```dart
// Usage example
AppAvatar(
  imageUrl: psychologist.avatarUrl,
  radius: 28,
  availabilityStatus: psychologist.status, // AvailabilityStatus enum
  showStatusDot: true,
)
```
- Renders `CircleAvatar` with `CachedNetworkImage`.
- If `showStatusDot` is true: `Stack` with `Positioned` status dot.
- Status dot: 14×14, border 2px white, fill from `_statusColor(status)`.
- No status text rendered.

### `AppButton`
```dart
enum AppButtonStyle { primary, secondary, outlined, ghost, danger }
```
- `primary`: brand gradient fill, white text.
- `secondary`: brand color fill.
- `outlined`: brand color border, transparent fill.
- `danger`: red fill.
- `loading` state replaces label with `CircularProgressIndicator`.
- All use `FilledButton`/`OutlinedButton` under the hood.

### `AppCard`
- `Container` with `BoxDecoration`: white/surface background, border-radius 16, subtle shadow.
- Optional `onTap` (wraps in `InkWell` with clipped border radius).

### `AppTextField`
- Wraps `TextFormField` with consistent styling matching the design system.
- Optional prefix icon, suffix icon (e.g. eye toggle).
- Error styling via `InputDecoration`.

### `AppShimmer`
- Wrapper around `shimmer` package for loading placeholders.
- Pre-built shimmer shapes: `ShimmerCard`, `ShimmerAvatar`, `ShimmerListTile`.

### `AppEmptyState`
- Illustration (Lottie or SVG) + title + body + optional action button.
- Variants: `EmptyStateVariant.appointments`, `.psychologists`, `.blogs`, etc.

### `AppErrorState`
- Error icon + message + "Retry" button.

### `AppBottomSheet`
- `showModalBottomSheet` wrapper with consistent handle bar, padding, and border radius.

### `AppSnackbar`
```dart
AppSnackbar.show(context, message: "Appointment booked!", type: SnackbarType.success);
```

### `StatusBadge`
```dart
StatusBadge(status: "Confirmed")  // color-coded pill
```
- Maps status strings to colors: Confirmed→green, Pending→amber, Cancelled→red, Completed→blue.

---

## 11. BLoC Architecture Details

### Global / App-level BLoC

```dart
// Provided at MaterialApp level
class AppBloc extends Bloc<AppEvent, AppState> {
  // Tracks: auth status, theme mode, network connectivity
}
```

### BLoC Structure Convention

```dart
// event.dart
abstract class FeatureEvent extends Equatable {}

class LoadFeature extends FeatureEvent {
  final String id;
  const LoadFeature(this.id);
  @override List<Object?> get props => [id];
}

// state.dart
abstract class FeatureState extends Equatable {}

class FeatureInitial extends FeatureState { ... }
class FeatureLoading extends FeatureState { ... }
class FeatureLoaded extends FeatureState {
  final FeatureEntity data;
  const FeatureLoaded(this.data);
  @override List<Object?> get props => [data];
}
class FeatureError extends FeatureState {
  final String message;
  const FeatureError(this.message);
  @override List<Object?> get props => [message];
}

// bloc.dart
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final GetFeatureUseCase getFeature;

  FeatureBloc({required this.getFeature}) : super(FeatureInitial()) {
    on<LoadFeature>(_onLoadFeature);
  }

  Future<void> _onLoadFeature(LoadFeature event, Emitter<FeatureState> emit) async {
    emit(FeatureLoading());
    final result = await getFeature(GetFeatureParams(id: event.id));
    result.fold(
      (failure) => emit(FeatureError(failure.message)),
      (data) => emit(FeatureLoaded(data)),
    );
  }
}
```

### BLoC Provision Pattern

```dart
// In router / page
BlocProvider(
  create: (context) => sl<FeatureBloc>()..add(LoadFeature(id)),
  child: FeaturePage(),
)
```

### UI Pattern

```dart
BlocConsumer<FeatureBloc, FeatureState>(
  listener: (context, state) {
    if (state is FeatureError) AppSnackbar.show(context, state.message);
  },
  builder: (context, state) => switch (state) {
    FeatureLoading() => const AppShimmer(),
    FeatureLoaded(:final data) => FeatureContent(data: data),
    FeatureError(:final message) => AppErrorState(message: message,
        onRetry: () => context.read<FeatureBloc>().add(LoadFeature(id))),
    _ => const SizedBox.shrink(),
  },
)
```

---

## 12. Data Models

### UserEntity
```dart
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    required String phone,
    String? avatarUrl,
    required UserRole role,
    required bool isVerified,
    required bool isActive,
    required DateTime createdAt,
  }) = _UserEntity;
}

enum UserRole { user, psychologist, admin }
```

### PsychologistEntity
```dart
@freezed
class PsychologistEntity with _$PsychologistEntity {
  const factory PsychologistEntity({
    required String id,
    required String name,
    required String credentials,          // "PhD, RCI Licensed"
    required String specialization,
    required List<String> specializations,
    required List<String> languages,
    required int yearsExperience,
    required double ratingAverage,
    required int totalReviews,
    required int totalSessions,
    required double ratePerMinute,
    required int freeMinutes,             // always 2
    required AvailabilityStatus status,
    String? avatarUrl,
    String? bio,
    required bool isApproved,
    required bool isActive,
    required DateTime createdAt,
  }) = _PsychologistEntity;
}

enum AvailabilityStatus { available, busy, offline }
```

### AppointmentEntity
```dart
@freezed
class AppointmentEntity with _$AppointmentEntity {
  const factory AppointmentEntity({
    required String id,
    required String userId,
    required String userName,
    required String psychologistId,
    required String psychologistName,
    String? psychologistAvatar,
    required DateTime scheduledAt,
    required int durationMinutes,
    required SessionType sessionType,
    required AppointmentStatus status,
    int? actualDurationSeconds,
    double? totalCharge,
    String? paymentId,
    PaymentStatus? paymentStatus,
    double? rating,
    String? userNotes,
    String? psychologistNotes,
    required DateTime createdAt,
  }) = _AppointmentEntity;
}

enum SessionType { video, audio, chat }
enum AppointmentStatus { upcoming, ongoing, completed, cancelled, noShow }
enum PaymentStatus { pending, paid, refunded, failed }
```

### SlotEntity
```dart
@freezed
class SlotEntity with _$SlotEntity {
  const factory SlotEntity({
    required String id,
    required String psychologistId,
    required DateTime startTime,
    required int durationMinutes,
    required List<SessionType> sessionTypes,
    required SlotStatus status,
  }) = _SlotEntity;
}

enum SlotStatus { available, booked, blocked }
```

### BlogEntity
```dart
@freezed
class BlogEntity with _$BlogEntity {
  const factory BlogEntity({
    required String id,
    required String psychologistId,
    required String psychologistName,
    String? psychologistAvatar,
    required String title,
    required String body,
    required String category,
    required List<String> tags,
    String? coverImageUrl,
    required BlogStatus status,
    int? viewCount,
    int? commentCount,
    required DateTime createdAt,
    DateTime? publishedAt,
  }) = _BlogEntity;
}

enum BlogStatus { draft, underReview, published, rejected }
```

### CallSessionEntity
```dart
@freezed
class CallSessionEntity with _$CallSessionEntity {
  const factory CallSessionEntity({
    required String id,
    required String appointmentId,
    required String channelName,       // Agora channel
    required String token,             // Agora RTC token
    required double ratePerMinute,
    required int freeMinutes,
    DateTime? connectedAt,
    DateTime? disconnectedAt,
    int? totalSeconds,
    int? billedSeconds,
    double? totalCharge,
  }) = _CallSessionEntity;
}
```

---

## 13. API Contract

### Base URL
```
https://api.mindzep.com/v1
```

### Authentication
- JWT Bearer tokens.
- `Authorization: Bearer <access_token>` header on all authenticated requests.
- Refresh token stored in `flutter_secure_storage`.

### Endpoints

#### Auth
```
POST   /auth/login              → {accessToken, refreshToken, user}
POST   /auth/register           → {accessToken, refreshToken, user}
POST   /auth/refresh            → {accessToken}
POST   /auth/logout             → 200
POST   /auth/forgot-password    → 200
POST   /auth/verify-otp         → {accessToken}
POST   /auth/google             → {accessToken, refreshToken, user}
```

#### Users
```
GET    /users/me                → UserModel
PUT    /users/me                → UserModel
GET    /users/:id               → UserModel (admin only)
GET    /users                   → PaginatedList<UserModel> (admin only)
PUT    /users/:id/suspend       → UserModel (admin only)
DELETE /users/:id               → 200 (admin only)
```

#### Psychologists
```
GET    /psychologists           → PaginatedList<PsychologistModel>
  ?page=1&limit=20&specialization=anxiety&minRating=4&available=true
GET    /psychologists/:id       → PsychologistModel
PUT    /psychologists/me        → PsychologistModel
PUT    /psychologists/me/availability → {isAvailable: bool}
GET    /psychologists/:id/reviews → PaginatedList<ReviewModel>
GET    /psychologists/:id/blogs   → PaginatedList<BlogModel>
```

#### Slots
```
GET    /psychologists/:id/slots → List<SlotModel>
  ?date=2026-05-15&month=2026-05
POST   /psychologists/me/slots  → SlotModel
PUT    /psychologists/me/slots/:slotId → SlotModel
DELETE /psychologists/me/slots/:slotId → 200
PATCH  /psychologists/me/slots/bulk → 200 (admin & psychologist)
```

#### Appointments
```
POST   /appointments            → AppointmentModel
GET    /appointments            → PaginatedList<AppointmentModel>
  ?status=upcoming&page=1
GET    /appointments/:id        → AppointmentModel
DELETE /appointments/:id        → 200 (cancel)
POST   /appointments/:id/notes  → AppointmentModel
POST   /appointments/:id/rating → AppointmentModel
```

#### Calls
```
POST   /calls/initiate          → {channelName, token, appointmentId}
  body: {psychologistId}
POST   /calls/:id/end           → CallSummaryModel
  body: {durationSeconds}
POST   /calls/:id/billing       → {billedSeconds, estimatedCharge}
  (called every 30 sec while call is active)
```

#### Payments
```
POST   /payments/create-order   → {orderId, amount, currency, keyId}
  body: {appointmentId}
POST   /payments/verify         → AppointmentModel
  body: {razorpayPaymentId, razorpayOrderId, razorpaySignature}
POST   /payments/:id/refund     → PaymentModel (admin only)
GET    /payments                → PaginatedList<PaymentModel>
```

#### Blogs
```
GET    /blogs                   → PaginatedList<BlogModel>
GET    /blogs/:id               → BlogModel
POST   /psychologists/me/blogs  → BlogModel
PUT    /psychologists/me/blogs/:id → BlogModel
DELETE /psychologists/me/blogs/:id → 200
PATCH  /psychologists/me/blogs/:id/submit → BlogModel
PATCH  /admin/blogs/:id/publish  → BlogModel (admin only)
PATCH  /admin/blogs/:id/reject   → BlogModel (admin only)
```

#### Admin
```
GET    /admin/dashboard         → DashboardMetricsModel
GET    /admin/psychologists     → PaginatedList<PsychologistAdminModel>
  ?status=pending
PATCH  /admin/psychologists/:id/approve → PsychologistModel
PATCH  /admin/psychologists/:id/reject  → PsychologistModel
PATCH  /admin/psychologists/:id/enable  → PsychologistModel
PATCH  /admin/psychologists/:id/disable → PsychologistModel
GET    /admin/appointments      → PaginatedList<AppointmentModel>
GET    /admin/revenue           → RevenueChartModel
  ?period=weekly
```

---

## 14. Design System & Theme

### Color Palette
```dart
class AppColors {
  // Primary Brand
  static const Color primary = Color(0xFF6C63FF);       // Purple
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42D6);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Semantic
  static const Color success = Color(0xFF34C759);       // iOS green
  static const Color warning = Color(0xFFFF9500);       // iOS orange
  static const Color error = Color(0xFFFF3B30);         // iOS red
  static const Color info = Color(0xFF007AFF);          // iOS blue

  // Availability dots
  static const Color available = Color(0xFF34C759);
  static const Color busy = Color(0xFFFF9500);
  static const Color offline = Color(0xFFFF3B30);

  // Surface
  static const Color background = Color(0xFFF2F2F7);    // iOS systemGroupedBackground
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFEFEFF4);

  // Text
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6C6C70);
  static const Color textTertiary = Color(0xFFAEAEB2);

  // Border
  static const Color border = Color(0xFFC6C6C8);
}
```

### Typography
```dart
class AppTextStyles {
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 0.37);
  static const TextStyle title1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.36);
  static const TextStyle title2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.35);
  static const TextStyle title3 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.38);
  static const TextStyle headline = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.41);
  static const TextStyle body = TextStyle(
    fontSize: 17, fontWeight: FontWeight.normal, letterSpacing: -0.41);
  static const TextStyle callout = TextStyle(
    fontSize: 16, fontWeight: FontWeight.normal, letterSpacing: -0.32);
  static const TextStyle subheadline = TextStyle(
    fontSize: 15, fontWeight: FontWeight.normal, letterSpacing: -0.24);
  static const TextStyle footnote = TextStyle(
    fontSize: 13, fontWeight: FontWeight.normal, letterSpacing: -0.08);
  static const TextStyle caption1 = TextStyle(
    fontSize: 12, fontWeight: FontWeight.normal, letterSpacing: 0.0);
  static const TextStyle caption2 = TextStyle(
    fontSize: 11, fontWeight: FontWeight.normal, letterSpacing: 0.07);
}
```

### Dimensions
```dart
class AppDimensions {
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  static const double avatarS = 32.0;
  static const double avatarM = 56.0;
  static const double avatarL = 80.0;
  static const double avatarXL = 120.0;

  static const double statusDotSize = 14.0;
  static const double statusDotBorderWidth = 2.0;

  static const double cardElevation = 2.0;
  static const double bottomNavHeight = 83.0;  // includes safe area
}
```

### ThemeData
```dart
ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: AppTextStyles.headline,
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.primary.withOpacity(0.12),
    labelTextStyle: WidgetStateProperty.all(AppTextStyles.caption1),
  ),
  cardTheme: CardTheme(
    color: AppColors.surface,
    elevation: AppDimensions.cardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
    ),
  ),
  // ... additional component themes
);
```

---

## 15. Navigation & Routing

Using `go_router` with `ShellRoute` for nested navigation.

```dart
// route_names.dart
class RouteNames {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // User routes
  static const userShell = '/user';
  static const userHome = '/user/home';
  static const userAppointments = '/user/appointments';
  static const userCalls = '/user/calls';
  static const userProfile = '/user/profile';
  static const psychologistDetail = '/user/psychologist/:id';
  static const slotBooking = '/user/book/:psychologistId';
  static const payment = '/user/payment';
  static const bookingConfirmed = '/user/booking-confirmed';
  static const activeCall = '/user/call/:appointmentId';
  static const postCallSummary = '/user/call-summary';

  // Psychologist routes
  static const psychShell = '/psych';
  static const psychDashboard = '/psych/dashboard';
  static const psychSlots = '/psych/slots';
  static const psychSessions = '/psych/sessions';
  static const psychBlog = '/psych/blog';
  static const psychProfile = '/psych/profile';
  static const blogEditor = '/psych/blog/editor';
  static const blogEditor_id = '/psych/blog/editor/:id';

  // Admin routes
  static const adminShell = '/admin';
  static const adminDashboard = '/admin/dashboard';
  static const adminPsychologists = '/admin/psychologists';
  static const adminPsychologistDetail = '/admin/psychologist/:id';
  static const adminUsers = '/admin/users';
  static const adminUserDetail = '/admin/user/:id';
  static const adminAppointments = '/admin/appointments';
  static const adminSettings = '/admin/settings';
}
```

```dart
// app_router.dart
final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    // Redirect logic based on auth state and role
  },
  routes: [
    GoRoute(path: RouteNames.splash, builder: ...),
    GoRoute(path: RouteNames.onboarding, builder: ...),
    GoRoute(path: RouteNames.login, builder: ...),
    GoRoute(path: RouteNames.register, builder: ...),

    ShellRoute(
      builder: (ctx, state, child) => UserShell(child: child),
      routes: [
        GoRoute(path: RouteNames.userHome, builder: ...),
        GoRoute(path: RouteNames.userAppointments, builder: ...),
        // ...
      ],
    ),

    ShellRoute(
      builder: (ctx, state, child) => PsychShell(child: child),
      routes: [ /* psych routes */ ],
    ),

    ShellRoute(
      builder: (ctx, state, child) => AdminShell(child: child),
      routes: [ /* admin routes */ ],
    ),
  ],
);
```

---

## 16. Mock Data Reference

### Psychologists
```dart
final mockPsychologists = [
  PsychologistEntity(
    id: 'p001',
    name: 'Dr. Ananya Krishnan',
    credentials: 'PhD, RCI Licensed',
    specialization: 'Clinical Psychologist',
    specializations: ['Anxiety', 'Depression', 'Trauma'],
    languages: ['English', 'Hindi', 'Tamil'],
    yearsExperience: 10,
    ratingAverage: 4.8,
    totalReviews: 124,
    totalSessions: 842,
    ratePerMinute: 12.0,
    freeMinutes: 2,
    status: AvailabilityStatus.available,
    bio: 'Specializing in cognitive behavioral therapy with over 10 years of experience helping individuals overcome anxiety and trauma.',
    isApproved: true,
    isActive: true,
    createdAt: DateTime(2024, 3, 15),
  ),
  PsychologistEntity(
    id: 'p002',
    name: 'Dr. Vikram Mehta',
    credentials: 'MSc Psychology, NIMHANS',
    specialization: 'Child & Adolescent Psychologist',
    specializations: ['Child Therapy', 'ADHD', 'Learning Disabilities'],
    languages: ['English', 'Hindi', 'Gujarati'],
    yearsExperience: 8,
    ratingAverage: 4.7,
    totalReviews: 98,
    totalSessions: 620,
    ratePerMinute: 10.0,
    freeMinutes: 2,
    status: AvailabilityStatus.busy,
    isApproved: true,
    isActive: true,
    createdAt: DateTime(2024, 5, 20),
  ),
  PsychologistEntity(
    id: 'p003',
    name: 'Dr. Priya Nair',
    credentials: 'MPhil, CBT Certified',
    specialization: 'Relationship Counsellor',
    specializations: ['Relationships', 'Couples Therapy', 'Grief'],
    languages: ['English', 'Malayalam', 'Hindi'],
    yearsExperience: 6,
    ratingAverage: 4.9,
    totalReviews: 76,
    totalSessions: 415,
    ratePerMinute: 9.0,
    freeMinutes: 2,
    status: AvailabilityStatus.available,
    isApproved: true,
    isActive: true,
    createdAt: DateTime(2024, 8, 10),
  ),
  // Dr. Rajesh Sharma - Stress & Burnout, p004
  // Dr. Kavya Reddy - Sleep Disorders, p005
  // Dr. Arjun Bose - Anger Management, p006
  // Dr. Meera Iyer - Mindfulness, p007
  // Dr. Siddharth Rao - Addiction Counselling, p008
];
```

### Users (for Admin mock data)
```dart
// Aryan Kapoor, Riya Sharma, Ishaan Verma, Pooja Patel,
// Kabir Malhotra, Nidhi Joshi, Rohan Desai, Anika Singh
```

### Sample Appointments
```dart
final mockAppointments = [
  AppointmentEntity(
    id: 'a001',
    userId: 'u001',
    userName: 'Aryan Kapoor',
    psychologistId: 'p001',
    psychologistName: 'Dr. Ananya Krishnan',
    scheduledAt: DateTime.now().add(const Duration(days: 2, hours: 4)),
    durationMinutes: 45,
    sessionType: SessionType.video,
    status: AppointmentStatus.upcoming,
    totalCharge: 396.0,
    paymentStatus: PaymentStatus.paid,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  // ... more appointments
];
```

---

## Appendix A: Billing Logic Implementation

```dart
// Inside CallBloc, on each TimerTick event:
void _onTimerTick(TimerTick event, Emitter<CallState> emit) {
  if (state is CallInProgress) {
    final s = state as CallInProgress;
    final newSeconds = s.durationSeconds + 1;
    final billedSeconds = newSeconds > (freeMinutes * 60)
        ? newSeconds - (freeMinutes * 60)
        : 0;
    final estimatedCost =
        (billedSeconds / 60.0) * ratePerMinute;

    emit(s.copyWith(
      durationSeconds: newSeconds,
      billedSeconds: billedSeconds,
      estimatedCost: estimatedCost,
    ));

    // Send billing heartbeat to server every 30 seconds
    if (newSeconds % 30 == 0) {
      _repository.sendBillingHeartbeat(
        sessionId: s.sessionId,
        durationSeconds: newSeconds,
      );
    }
  }
}
```

## Appendix B: Date Booking Constraint

```dart
// In SlotBookingBloc
bool _isDateBookable(DateTime date) {
  final today = DateTime.now();
  final maxDate = DateTime(today.year, today.month + 1, today.day);
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final normalizedToday = DateTime(today.year, today.month, today.day);
  return !normalizedDate.isBefore(normalizedToday) &&
         !normalizedDate.isAfter(maxDate);
}
```

## Appendix C: Status Dot Widget

```dart
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final AvailabilityStatus? availabilityStatus;
  final bool showStatusDot;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.radius = 28,
    this.availabilityStatus,
    this.showStatusDot = false,
  });

  Color _dotColor(AvailabilityStatus status) => switch (status) {
    AvailabilityStatus.available => AppColors.available,
    AvailabilityStatus.busy => AppColors.busy,
    AvailabilityStatus.offline => AppColors.offline,
  };

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundImage: imageUrl != null
          ? CachedNetworkImageProvider(imageUrl!)
          : null,
      child: imageUrl == null
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    );

    if (!showStatusDot || availabilityStatus == null) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: AppDimensions.statusDotSize,
            height: AppDimensions.statusDotSize,
            decoration: BoxDecoration(
              color: _dotColor(availabilityStatus!),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: AppDimensions.statusDotBorderWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

---

*End of MindZep Flutter Specification v1.0*
