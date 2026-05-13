class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.mindzep.com/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String googleAuth = '/auth/google';

  // Users
  static const String me = '/users/me';
  static const String users = '/users';
  static String userById(String id) => '/users/$id';
  static String suspendUser(String id) => '/users/$id/suspend';

  // Psychologists
  static const String psychologists = '/psychologists';
  static const String myPsychProfile = '/psychologists/me';
  static const String myAvailability = '/psychologists/me/availability';
  static String psychologistById(String id) => '/psychologists/$id';
  static String psychologistReviews(String id) => '/psychologists/$id/reviews';
  static String psychologistBlogs(String id) => '/psychologists/$id/blogs';

  // Slots
  static String psychologistSlots(String id) => '/psychologists/$id/slots';
  static const String mySlots = '/psychologists/me/slots';
  static String mySlotById(String slotId) => '/psychologists/me/slots/$slotId';
  static const String bulkSlots = '/psychologists/me/slots/bulk';

  // Appointments
  static const String appointments = '/appointments';
  static String appointmentById(String id) => '/appointments/$id';
  static String appointmentNotes(String id) => '/appointments/$id/notes';
  static String appointmentRating(String id) => '/appointments/$id/rating';

  // Calls
  static const String initiateCall = '/calls/initiate';
  static String endCall(String id) => '/calls/$id/end';
  static String callBilling(String id) => '/calls/$id/billing';

  // Payments
  static const String createOrder = '/payments/create-order';
  static const String verifyPayment = '/payments/verify';
  static String refundPayment(String id) => '/payments/$id/refund';
  static const String payments = '/payments';

  // Blogs
  static const String blogs = '/blogs';
  static String blogById(String id) => '/blogs/$id';
  static const String myBlogs = '/psychologists/me/blogs';
  static String myBlogById(String id) => '/psychologists/me/blogs/$id';
  static String submitBlog(String id) => '/psychologists/me/blogs/$id/submit';
  static String publishBlog(String id) => '/admin/blogs/$id/publish';
  static String rejectBlog(String id) => '/admin/blogs/$id/reject';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminPsychologists = '/admin/psychologists';
  static String adminApprovePsych(String id) =>
      '/admin/psychologists/$id/approve';
  static String adminRejectPsych(String id) =>
      '/admin/psychologists/$id/reject';
  static String adminEnablePsych(String id) =>
      '/admin/psychologists/$id/enable';
  static String adminDisablePsych(String id) =>
      '/admin/psychologists/$id/disable';
  static const String adminAppointments = '/admin/appointments';
  static const String adminRevenue = '/admin/revenue';
}
