class ApiEndpoints {
  ApiEndpoints._();

  static const String health = '/health';

  // Auth
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String resendOtp = '/auth/resend-otp';

  // Users
  static const String users = '/users';
  static const String me = '/users/me';
  static const String meAccount = '/users/me/account';
  static const String meProfile = '/users/me/profile';
  static const String meWallet = '/users/me/wallet';
  static const String meMoods = '/users/me/moods';
  static const String meNotifications = '/users/me/notifications';
  static const String meNotificationsReadAll = '/users/me/notifications/read-all';
  static String meNotificationRead(String id) => '/users/me/notifications/$id/read';
  static String userById(String id) => '/users/$id';
  static String userSuspend(String id) => '/users/$id/suspend';
  static String userUnsuspend(String id) => '/users/$id/unsuspend';

  // Psychologists
  static const String psychologists = '/psychologists';
  static const String psychologistMe = '/psychologists/me';
  static const String psychologistAvailability = '/psychologists/me/availability';
  static const String psychologistDocuments = '/psychologists/me/documents';
  static String psychologistById(String id) => '/psychologists/$id';
  static String psychologistReviews(String id) => '/psychologists/$id/reviews';
  static String psychologistBlogs(String id) => '/psychologists/$id/blogs';

  // Slots
  static String slotsByPsychologist(String psychologistId) =>
      '/slots/psychologist/$psychologistId';
  static const String slotsMe = '/slots/me';
  static const String slotsBulk = '/slots/me/bulk';
  static String slotById(String slotId) => '/slots/me/$slotId';

  // Appointments
  static const String appointments = '/appointments';
  static String appointmentById(String id) => '/appointments/$id';
  static String appointmentRate(String id) => '/appointments/$id/rate';
  static String appointmentPsychologistNotes(String id) => '/appointments/me/$id/notes';

  // Calls
  static String callInitiate(String appointmentId) => '/calls/$appointmentId/initiate';
  static String callBroadcastInitiate(String appointmentId) =>
      '/calls/$appointmentId/broadcast-initiate';
  static String callBroadcastAccept(String appointmentId) =>
      '/calls/$appointmentId/broadcast-accept';
  static String callConnect(String appointmentId) => '/calls/$appointmentId/connect';
  static String callHeartbeat(String appointmentId) => '/calls/$appointmentId/heartbeat';
  static String callEnd(String appointmentId) => '/calls/$appointmentId/end';
  static String callDetails(String appointmentId) => '/calls/$appointmentId';
  /// Psychologist-only: returns any currently pending incoming call.
  static const String callPending = '/calls/pending';
  /// Instant broadcast — no prior appointment needed.
  static const String callBroadcastInstant = '/calls/broadcast-instant';
  static const String callBroadcastInstantCancel = '/calls/broadcast-instant/cancel';

  // Chat
  static String chatMessages(String appointmentId) => '/chat/$appointmentId/messages';
  static String chatRead(String appointmentId) => '/chat/$appointmentId/read';

  // Payments
  static const String payments = '/payments';
  static const String paymentsCreateOrder = '/payments/create-order';
  static const String paymentsVerify = '/payments/verify';
  static const String paymentsRefund = '/payments/refund';
  // Pays for an appointment (or top-up) directly from the user's wallet
  // balance. Backend deducts the amount, marks the appointment paid, and
  // returns a paid/failed status.
  static const String paymentsWalletPay = '/payments/wallet-pay';

  // Blogs
  static const String blogs = '/blogs';
  static String blogById(String id) => '/blogs/$id';
  static String blogSubmit(String id) => '/blogs/$id/submit';
  static String blogReview(String id) => '/blogs/$id/review';
  static const String blogsMy = '/blogs/me/my-blogs';
  static const String blogsAdminAll = '/blogs/admin/all';
  static const String blogsAdminSubmitted = '/blogs/admin/submitted';
  static String blogsAdminApprove(String id) => '/blogs/admin/$id/approve';
  static String blogsAdminReject(String id) => '/blogs/admin/$id/reject';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminPsychologists = '/admin/psychologists';
  static String adminPsychologistById(String id) => '/admin/psychologists/$id';
  static String adminPsychologistSuspend(String id) => '/admin/psychologists/$id/suspend';
  static String adminPsychologistActivate(String id) => '/admin/psychologists/$id/activate';
  static const String adminUsers = '/admin/users';
  static String adminUserById(String id) => '/admin/users/$id';
  static String adminUserSuspend(String id) => '/admin/users/$id/suspend';
  static String adminUserActivate(String id) => '/admin/users/$id/activate';
  static String adminCreditWallet(String id) => '/admin/users/$id/wallet/credit';
  static const String adminAppointments = '/admin/appointments';
  static const String adminAuditLogs = '/admin/audit-logs';
  static String adminStaticContent(String type) => '/admin/static-content/$type';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notificationDelete(String id) => '/notifications/$id';
  static const String notificationsClearAll = '/notifications/clear-all';

  // Public
  static String publicStaticContent(String type) => '/public/static-content/$type';

  // Uploads
  static const String uploadAvatar = '/uploads/avatar';
  static const String uploadDocument = '/uploads/document';
  static const String uploadBlogCover = '/uploads/blog-cover';
}
