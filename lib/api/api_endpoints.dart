class ApiEndpoints {
  ApiEndpoints._();
  static const authLogin='/auth/login', authProfile='/auth/profile', authPassword='/auth/password';
  static const members='/members', finance='/finance', settings='/settings', settingsGoal='/settings/goal', settingsPlans='/settings/plans', checkins='/checkins';
  static String member(int id)=>'/members/$id';
  static String memberPhoto(int id)=>'/members/$id/photo';
  static String memberRenew(int id)=>'/members/$id/renew';
  static String memberAdjustment(int id)=>'/members/$id/adjustment';
  static String memberStatus(int id)=>'/members/$id/status';
  static String memberPr(int id)=>'/members/$id/pr';
  static String memberNotes(int id)=>'/members/$id/notes';
  static String checkin(int id)=>'/checkins/$id';
  static String checkinStats(int id)=>'/checkins/$id/stats';
  static const todayCheckins='/checkins/today/list';
}
