// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'StyleMemory';

  @override
  String get welcomeTitle => 'Welcome to StyleMemory';

  @override
  String get welcomeSubtitle =>
      'Capture and remember your clients\' unique styles';

  @override
  String get getStarted => 'Get Started';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signInToAccount => 'Sign in to your account';

  @override
  String get clients => 'Clients';

  @override
  String get addClient => 'Add Client';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get phone => 'Phone';

  @override
  String get notes => 'Notes';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get visits => 'visits';

  @override
  String get newVisit => 'New Visit';

  @override
  String get visitDetails => 'Visit Details';

  @override
  String get date => 'Date';

  @override
  String get service => 'Service';

  @override
  String get staff => 'Staff';

  @override
  String get rating => 'Rating';

  @override
  String get photos => 'Photos';

  @override
  String get noPhotos => 'No photos available';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get client => 'Client';

  @override
  String get storeName => 'Store Name';

  @override
  String get address => 'Address';

  @override
  String get tapToAdd => 'Tap to add';

  @override
  String get tapToAddStoreName => 'Tap to add store name';

  @override
  String get tapToAddPhone => 'Tap to add phone number';

  @override
  String get tapToAddAddress => 'Tap to add address';

  @override
  String get settings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get storeInformation => 'Store Information';

  @override
  String get management => 'Management';

  @override
  String get staffManagement => 'Staff Management';

  @override
  String get serviceManagement => 'Service Management';

  @override
  String get subscription => 'Subscription';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get about => 'About';

  @override
  String get manageTeamMembers => 'Manage your team members';

  @override
  String get manageServicesAndPricing => 'Manage your services and pricing';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get freePlan => 'Free Plan';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get howToUse => 'How to Use StyleMemory';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get appVersion => 'App Version';

  @override
  String get signOut => 'Sign Out';

  @override
  String get editStoreName => 'Edit Store Name';

  @override
  String get editPhoneNumber => 'Edit Phone Number';

  @override
  String get editAddress => 'Edit Address';

  @override
  String get enterStoreName => 'Enter your store name';

  @override
  String get enterPhoneNumber => 'Enter phone number';

  @override
  String get enterAddress => 'Enter your store address';

  @override
  String get storeNameUpdated => 'Store name updated successfully';

  @override
  String get phoneNumberUpdated => 'Phone number updated successfully';

  @override
  String get addressUpdated => 'Address updated successfully';

  @override
  String get failedToUpdateStoreName => 'Failed to update store name';

  @override
  String get failedToUpdatePhoneNumber => 'Failed to update phone number';

  @override
  String get failedToUpdateAddress => 'Failed to update address';

  @override
  String get lovedStyles => 'Loved Styles';

  @override
  String get gallery => 'Gallery';

  @override
  String get capture => 'Capture';

  @override
  String get newPhotos => 'New Photos';

  @override
  String get selectPhotos => 'Select Photos';

  @override
  String get sharePhotos => 'Share Photos';

  @override
  String get deletePhotos => 'Delete Photos';

  @override
  String get visitNotFound => 'Visit Not Found';

  @override
  String get clientNotFound => 'Client Not Found';

  @override
  String get staffNotFound => 'Staff not found';

  @override
  String get serviceSelected => 'Service selected';

  @override
  String get stylingSession => 'Styling session';

  @override
  String get totalClients => 'Total Clients';

  @override
  String get totalPhotos => 'Total Photos';

  @override
  String get storageUsage => 'Storage Usage';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get howToUseStyleMemory => 'How to Use StyleMemory';

  @override
  String get close => 'Close';

  @override
  String get gotIt => 'Got it';

  @override
  String get confirmSignOut => 'Are you sure you want to sign out?';

  @override
  String get confirmDelete => 'Are you sure you want to delete?';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get ok => 'OK';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageUpdated => 'Language updated successfully';

  @override
  String photosSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count photo$_temp0 selected';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count day$_temp0 ago';
  }

  @override
  String weeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count week$_temp0 ago';
  }

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count month$_temp0 ago';
  }

  @override
  String get enterYourEmail => 'Enter your email address';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get createOne => 'Create one';

  @override
  String get forgotPasswordFeature => 'Forgot password feature coming soon';

  @override
  String get creatingAccount => 'Creating account...';

  @override
  String get chooseSecurePassword => 'Choose a secure password';

  @override
  String get fullNameOptional => 'Full Name (optional)';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get passwordMustBe6Characters =>
      'Password must be at least 6 characters';

  @override
  String get yourClients => 'Your Clients';

  @override
  String get searchByNamePhoneEmail => 'Search by name, phone, or email...';

  @override
  String get searchResults => 'Search Results';

  @override
  String get allClients => 'All Clients';

  @override
  String get found => 'found';

  @override
  String get total => 'total';

  @override
  String get noClientsFound => 'No clients found';

  @override
  String get tryAdjustingSearch =>
      'Try adjusting your search terms or add a new client.';

  @override
  String get clearSearch => 'Clear Search';

  @override
  String get welcomeToStyleMemory => 'Welcome to Style Memory!';

  @override
  String get startByAddingFirstClient =>
      'Start by adding your first client to track their styles, preferences, and visit history.';

  @override
  String get addYourFirstClient => 'Add Your First Client';

  @override
  String get visit => 'visit';

  @override
  String get lastVisit => 'Last visit';

  @override
  String get noVisitsYet => 'No visits yet';

  @override
  String startByCaptureFirstVisit(String clientName) {
    return 'Start by capturing photos for $clientName\'s first visit';
  }

  @override
  String get newClient => 'New Client';

  @override
  String get creatingClient => 'Creating client...';

  @override
  String get clientName => 'Client Name';

  @override
  String get enterClientFullName => 'Enter client\'s full name';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get enterEmailAddress => 'Enter email address';

  @override
  String get clientNameRequired => 'Client name is required';

  @override
  String get pleaseEnterValidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get saveAndAddPhotos => 'Save & Add Photos';

  @override
  String get afterSavingCanCapturePhotos =>
      'After saving, you\'ll be able to capture photos for this client\'s first visit.';

  @override
  String get addPhotosAndNotes => 'Add Photos & Notes';

  @override
  String get staffMember => 'Staff Member';

  @override
  String get selectStaffMember => 'Select staff member';

  @override
  String get serviceType => 'Service Type';

  @override
  String get selectServiceType => 'Select service type';

  @override
  String get visitNotes => 'Visit Notes';

  @override
  String get addNotesAboutService =>
      'Add notes about the service, products used, client preferences, etc...';

  @override
  String get addPhotosToDocument => 'Add photos to document this visit';

  @override
  String get onePhotoSelected => '1 photo selected';

  @override
  String photosSelectedCount(Object count) {
    return '$count photos selected';
  }

  @override
  String get camera => 'Camera';

  @override
  String get saveVisit => 'Save Visit';

  @override
  String get savingVisit => 'Saving Visit...';

  @override
  String get cameraError => 'Camera error';

  @override
  String get galleryError => 'Gallery error';

  @override
  String get pleaseAddPhotoOrNotes =>
      'Please add at least one photo or some notes';

  @override
  String get visitSavedSuccessfully => 'Visit saved successfully!';

  @override
  String errorSavingVisit(Object error) {
    return 'Error saving visit: $error';
  }

  @override
  String get recent => 'Recent';

  @override
  String get loved => 'Loved';

  @override
  String get dateColon => 'Date:';

  @override
  String get serviceColon => 'Service:';

  @override
  String get staffColon => 'Staff:';

  @override
  String get ratingColon => 'Rating:';

  @override
  String get editClient => 'Edit Client';

  @override
  String get deleteClient => 'Delete Client';

  @override
  String get searchByNotesOrService => 'Search by notes or service';

  @override
  String get enterSearchTerms => 'Enter search terms...';

  @override
  String get allServices => 'All Services';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get searchByClientName => 'Search by client name';

  @override
  String get enterClientName => 'Enter client name...';

  @override
  String get clientColon => 'Client:';

  @override
  String get photosColon => 'Photos:';

  @override
  String get notesColon => 'Notes:';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get addStaffMember => 'Add Staff Member';

  @override
  String get specialty => 'Specialty';

  @override
  String get add => 'Add';

  @override
  String get generalStylist => 'General Stylist';

  @override
  String get joined => 'Joined';

  @override
  String get newHire => 'New hire';

  @override
  String get addService => 'Add Service';

  @override
  String get serviceName => 'Service Name';

  @override
  String get enterServiceName => 'Enter service name';

  @override
  String get noStaffMembersYet => 'No staff members yet';

  @override
  String get addFirstTeamMember => 'Add your first team member to get started';

  @override
  String staffDetailsComingSoon(Object staffName) {
    return 'Staff details for $staffName coming soon';
  }

  @override
  String get removeStaffMember => 'Remove Staff Member';

  @override
  String confirmRemoveStaff(Object staffName) {
    return 'Are you sure you want to remove $staffName from your team? They will be marked as inactive but their work history will be preserved.';
  }

  @override
  String get remove => 'Remove';

  @override
  String staffRemovedFromTeam(Object staffName) {
    return '$staffName removed from team';
  }

  @override
  String get staffAnalytics => 'Staff Analytics';

  @override
  String get totalStaff => 'Total Staff';

  @override
  String get activeStaff => 'Active Staff';

  @override
  String get inactiveStaff => 'Inactive Staff';

  @override
  String get editStaffMember => 'Edit Staff Member';

  @override
  String get enterStaffMemberName => 'Enter staff member name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get specialtyHint => 'e.g., Hair Color Specialist, Nail Art';

  @override
  String get staffEmailHint => 'staff@salon.com';

  @override
  String get phoneNumberHint => '(555) 123-4567';

  @override
  String get additionalInformation => 'Additional information...';

  @override
  String get update => 'Update';

  @override
  String staffUpdatedSuccessfully(Object staffName) {
    return '$staffName updated successfully';
  }

  @override
  String staffAddedToTeam(Object staffName) {
    return '$staffName added to your team';
  }

  @override
  String get showAllStaff => 'Show All Staff';

  @override
  String get noServicesYet => 'No services yet';

  @override
  String get addFirstService => 'Add your first service to get started';

  @override
  String get showAllServices => 'Show All Services';

  @override
  String get serviceAnalytics => 'Service Analytics';

  @override
  String get totalServices => 'Total Services';

  @override
  String get activeServices => 'Active Services';

  @override
  String get inactiveServices => 'Inactive Services';

  @override
  String get editService => 'Edit Service';

  @override
  String get serviceAddedSuccessfully => 'Service added successfully';

  @override
  String get serviceUpdatedSuccessfully => 'Service updated successfully';

  @override
  String get deleteService => 'Delete Service';

  @override
  String confirmDeleteService(Object serviceName) {
    return 'Are you sure you want to delete \"$serviceName\"? This action cannot be undone.';
  }

  @override
  String get serviceDeletedSuccessfully => 'Service deleted successfully';

  @override
  String get pleaseEnterServiceName => 'Please enter a service name';
}
