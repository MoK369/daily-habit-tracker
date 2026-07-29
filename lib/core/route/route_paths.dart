class RoutePaths {
  const RoutePaths._();

  static const String home = '/';
  static const String addHabit = '/habit/add';
  static const String editHabitPattern = '/habit/:id/edit';

  static String editHabit(String id) => '/habit/$id/edit';
}
