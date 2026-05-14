class RouteNames {
  RouteNames._();

  // Auth
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // User shell
  static const userHome = '/user/home';
  static const userConsult = '/user/consult';
  static const userAppointments = '/user/appointments';
  static const userWallet = '/user/wallet';
  static const userProfile = '/user/profile';

  // User — outside shell
  static const userBroadcast = '/user/broadcast';
  static const userNotifications = '/user/notifications';
  static const userBlogList = '/user/blogs';
  static const userBlogDetail = '/user/blog-detail';
  static const psychologistDetail = '/psychologist/:id';
  static const slotBooking = '/book/:psychologistId';
  static const payment = '/payment';
  static const bookingConfirmed = '/booking-confirmed';
  static const preCall = '/pre-call';
  static const activeCall = '/active-call';
  static const callSummary = '/call-summary';

  // Psychologist shell
  static const psychDashboard = '/psych/dashboard';
  static const psychSlots = '/psych/slots';
  static const psychSessions = '/psych/sessions';
  static const psychBlogs = '/psych/blogs';
  static const psychProfile = '/psych/profile';

  // Psychologist — outside shell
  static const psychBlogDetail = '/psych/blog-detail';

  // Admin shell
  static const adminDashboard = '/admin/dashboard';
  static const adminPsychologists = '/admin/psychologists';
  static const adminUsers = '/admin/users';
  static const adminAppointments = '/admin/appointments';
  static const adminBlogs = '/admin/blogs';
  static const adminSettings = '/admin/settings';
}
