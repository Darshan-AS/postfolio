// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Postfolio';

  @override
  String get users => 'Users';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get deposits => 'Deposits';

  @override
  String get recurringDeposits => 'Recurring Deposits';

  @override
  String get rd => 'RD';

  @override
  String get newUser => 'New User';

  @override
  String get editUser => 'Edit User';

  @override
  String get saveUser => 'Save User';

  @override
  String get saving => 'Saving...';

  @override
  String get loading => 'Loading...';

  @override
  String get noUsersFound => 'No users found. Add one!';

  @override
  String get dashboardCharts => 'Dashboard Charts Go Here';

  @override
  String get depositsList => 'Deposits List Goes Here';

  @override
  String get rdList => 'RD List Goes Here';

  @override
  String get fullName => 'Full Name *';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get homeAddress => 'Home Address';

  @override
  String get delete => 'Delete';

  @override
  String get deleteUser => 'Delete User';

  @override
  String get deleteUserConfirmation =>
      'Are you sure you want to delete this user?';

  @override
  String get cancel => 'Cancel';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get userNotFound => 'User not found';

  @override
  String get notProvided => 'Not provided';

  @override
  String failedToSaveUser(String error) {
    return 'Failed to save user: $error';
  }

  @override
  String failedToDeleteUser(String error) {
    return 'Failed to delete user: $error';
  }
}
