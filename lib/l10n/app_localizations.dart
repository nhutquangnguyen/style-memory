import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'StyleMemory'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to StyleMemory'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture and remember your clients\' unique styles'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signInToAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToAccount;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @addClient.
  ///
  /// In en, this message translates to:
  /// **'Add Client'**
  String get addClient;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @visits.
  ///
  /// In en, this message translates to:
  /// **'visits'**
  String get visits;

  /// No description provided for @newVisit.
  ///
  /// In en, this message translates to:
  /// **'New Visit'**
  String get newVisit;

  /// No description provided for @visitDetails.
  ///
  /// In en, this message translates to:
  /// **'Visit Details'**
  String get visitDetails;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos available'**
  String get noPhotos;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @storeName.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get tapToAdd;

  /// No description provided for @tapToAddStoreName.
  ///
  /// In en, this message translates to:
  /// **'Tap to add store name'**
  String get tapToAddStoreName;

  /// No description provided for @tapToAddPhone.
  ///
  /// In en, this message translates to:
  /// **'Tap to add phone number'**
  String get tapToAddPhone;

  /// No description provided for @tapToAddAddress.
  ///
  /// In en, this message translates to:
  /// **'Tap to add address'**
  String get tapToAddAddress;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @storeInformation.
  ///
  /// In en, this message translates to:
  /// **'Store Information'**
  String get storeInformation;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @staffManagement.
  ///
  /// In en, this message translates to:
  /// **'Staff Management'**
  String get staffManagement;

  /// No description provided for @serviceManagement.
  ///
  /// In en, this message translates to:
  /// **'Service Management'**
  String get serviceManagement;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @manageTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'Manage your team members'**
  String get manageTeamMembers;

  /// No description provided for @manageServicesAndPricing.
  ///
  /// In en, this message translates to:
  /// **'Manage your services and pricing'**
  String get manageServicesAndPricing;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get freePlan;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to Use StyleMemory'**
  String get howToUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @editStoreName.
  ///
  /// In en, this message translates to:
  /// **'Edit Store Name'**
  String get editStoreName;

  /// No description provided for @editPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit Phone Number'**
  String get editPhoneNumber;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @enterStoreName.
  ///
  /// In en, this message translates to:
  /// **'Enter your store name'**
  String get enterStoreName;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your store address'**
  String get enterAddress;

  /// No description provided for @storeNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Store name updated successfully'**
  String get storeNameUpdated;

  /// No description provided for @phoneNumberUpdated.
  ///
  /// In en, this message translates to:
  /// **'Phone number updated successfully'**
  String get phoneNumberUpdated;

  /// No description provided for @addressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Address updated successfully'**
  String get addressUpdated;

  /// No description provided for @failedToUpdateStoreName.
  ///
  /// In en, this message translates to:
  /// **'Failed to update store name'**
  String get failedToUpdateStoreName;

  /// No description provided for @failedToUpdatePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Failed to update phone number'**
  String get failedToUpdatePhoneNumber;

  /// No description provided for @failedToUpdateAddress.
  ///
  /// In en, this message translates to:
  /// **'Failed to update address'**
  String get failedToUpdateAddress;

  /// No description provided for @lovedStyles.
  ///
  /// In en, this message translates to:
  /// **'Loved Styles'**
  String get lovedStyles;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @capture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get capture;

  /// No description provided for @newPhotos.
  ///
  /// In en, this message translates to:
  /// **'New Photos'**
  String get newPhotos;

  /// No description provided for @selectPhotos.
  ///
  /// In en, this message translates to:
  /// **'Select Photos'**
  String get selectPhotos;

  /// No description provided for @sharePhotos.
  ///
  /// In en, this message translates to:
  /// **'Share Photos'**
  String get sharePhotos;

  /// No description provided for @deletePhotos.
  ///
  /// In en, this message translates to:
  /// **'Delete Photos'**
  String get deletePhotos;

  /// No description provided for @visitNotFound.
  ///
  /// In en, this message translates to:
  /// **'Visit Not Found'**
  String get visitNotFound;

  /// No description provided for @clientNotFound.
  ///
  /// In en, this message translates to:
  /// **'Client Not Found'**
  String get clientNotFound;

  /// No description provided for @staffNotFound.
  ///
  /// In en, this message translates to:
  /// **'Staff not found'**
  String get staffNotFound;

  /// No description provided for @serviceSelected.
  ///
  /// In en, this message translates to:
  /// **'Service selected'**
  String get serviceSelected;

  /// No description provided for @stylingSession.
  ///
  /// In en, this message translates to:
  /// **'Styling session'**
  String get stylingSession;

  /// No description provided for @totalClients.
  ///
  /// In en, this message translates to:
  /// **'Total Clients'**
  String get totalClients;

  /// No description provided for @totalPhotos.
  ///
  /// In en, this message translates to:
  /// **'Total Photos'**
  String get totalPhotos;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get storageUsage;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @howToUseStyleMemory.
  ///
  /// In en, this message translates to:
  /// **'How to Use StyleMemory'**
  String get howToUseStyleMemory;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirmSignOut;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get confirmDelete;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get thisActionCannotBeUndone;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated successfully'**
  String get languageUpdated;

  /// Shows number of selected photos
  ///
  /// In en, this message translates to:
  /// **'{count} photo{count, plural, =1{} other{s}} selected'**
  String photosSelected(int count);

  /// Shows days ago
  ///
  /// In en, this message translates to:
  /// **'{count} day{count, plural, =1{} other{s}} ago'**
  String daysAgo(int count);

  /// Shows weeks ago
  ///
  /// In en, this message translates to:
  /// **'{count} week{count, plural, =1{} other{s}} ago'**
  String weeksAgo(int count);

  /// Shows months ago
  ///
  /// In en, this message translates to:
  /// **'{count} month{count, plural, =1{} other{s}} ago'**
  String monthsAgo(int count);

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterYourEmail;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @createOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createOne;

  /// No description provided for @forgotPasswordFeature.
  ///
  /// In en, this message translates to:
  /// **'Forgot password feature coming soon'**
  String get forgotPasswordFeature;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get creatingAccount;

  /// No description provided for @chooseSecurePassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a secure password'**
  String get chooseSecurePassword;

  /// No description provided for @fullNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Full Name (optional)'**
  String get fullNameOptional;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @passwordMustBe6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBe6Characters;

  /// No description provided for @yourClients.
  ///
  /// In en, this message translates to:
  /// **'Your Clients'**
  String get yourClients;

  /// No description provided for @searchByNamePhoneEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone, or email...'**
  String get searchByNamePhoneEmail;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @allClients.
  ///
  /// In en, this message translates to:
  /// **'All Clients'**
  String get allClients;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'found'**
  String get found;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get total;

  /// No description provided for @noClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No clients found'**
  String get noClientsFound;

  /// No description provided for @tryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms or add a new client.'**
  String get tryAdjustingSearch;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @welcomeToStyleMemory.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Style Memory!'**
  String get welcomeToStyleMemory;

  /// No description provided for @startByAddingFirstClient.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first client to track their styles, preferences, and visit history.'**
  String get startByAddingFirstClient;

  /// No description provided for @addYourFirstClient.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Client'**
  String get addYourFirstClient;

  /// No description provided for @visit.
  ///
  /// In en, this message translates to:
  /// **'visit'**
  String get visit;

  /// No description provided for @lastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last visit'**
  String get lastVisit;

  /// No description provided for @noVisitsYet.
  ///
  /// In en, this message translates to:
  /// **'No visits yet'**
  String get noVisitsYet;

  /// Empty state description for no visits
  ///
  /// In en, this message translates to:
  /// **'Start by capturing photos for {clientName}\'s first visit'**
  String startByCaptureFirstVisit(String clientName);

  /// No description provided for @newClient.
  ///
  /// In en, this message translates to:
  /// **'New Client'**
  String get newClient;

  /// No description provided for @creatingClient.
  ///
  /// In en, this message translates to:
  /// **'Creating client...'**
  String get creatingClient;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientName;

  /// No description provided for @enterClientFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter client\'s full name'**
  String get enterClientFullName;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @enterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get enterEmailAddress;

  /// No description provided for @clientNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Client name is required'**
  String get clientNameRequired;

  /// No description provided for @pleaseEnterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhoneNumber;

  /// No description provided for @saveAndAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Save & Add Photos'**
  String get saveAndAddPhotos;

  /// No description provided for @afterSavingCanCapturePhotos.
  ///
  /// In en, this message translates to:
  /// **'After saving, you\'ll be able to capture photos for this client\'s first visit.'**
  String get afterSavingCanCapturePhotos;

  /// No description provided for @addPhotosAndNotes.
  ///
  /// In en, this message translates to:
  /// **'Add Photos & Notes'**
  String get addPhotosAndNotes;

  /// No description provided for @staffMember.
  ///
  /// In en, this message translates to:
  /// **'Staff Member'**
  String get staffMember;

  /// No description provided for @selectStaffMember.
  ///
  /// In en, this message translates to:
  /// **'Select staff member'**
  String get selectStaffMember;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Service Type'**
  String get serviceType;

  /// No description provided for @selectServiceType.
  ///
  /// In en, this message translates to:
  /// **'Select service type'**
  String get selectServiceType;

  /// No description provided for @visitNotes.
  ///
  /// In en, this message translates to:
  /// **'Visit Notes'**
  String get visitNotes;

  /// No description provided for @addNotesAboutService.
  ///
  /// In en, this message translates to:
  /// **'Add notes about the service, products used, client preferences, etc...'**
  String get addNotesAboutService;

  /// No description provided for @addPhotosToDocument.
  ///
  /// In en, this message translates to:
  /// **'Add photos to document this visit'**
  String get addPhotosToDocument;

  /// No description provided for @onePhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'1 photo selected'**
  String get onePhotoSelected;

  /// No description provided for @photosSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos selected'**
  String photosSelectedCount(Object count);

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @saveVisit.
  ///
  /// In en, this message translates to:
  /// **'Save Visit'**
  String get saveVisit;

  /// No description provided for @savingVisit.
  ///
  /// In en, this message translates to:
  /// **'Saving Visit...'**
  String get savingVisit;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera error'**
  String get cameraError;

  /// No description provided for @galleryError.
  ///
  /// In en, this message translates to:
  /// **'Gallery error'**
  String get galleryError;

  /// No description provided for @pleaseAddPhotoOrNotes.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one photo or some notes'**
  String get pleaseAddPhotoOrNotes;

  /// No description provided for @visitSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Visit saved successfully!'**
  String get visitSavedSuccessfully;

  /// No description provided for @errorSavingVisit.
  ///
  /// In en, this message translates to:
  /// **'Error saving visit: {error}'**
  String errorSavingVisit(Object error);

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @loved.
  ///
  /// In en, this message translates to:
  /// **'Loved'**
  String get loved;

  /// No description provided for @dateColon.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get dateColon;

  /// No description provided for @serviceColon.
  ///
  /// In en, this message translates to:
  /// **'Service:'**
  String get serviceColon;

  /// No description provided for @staffColon.
  ///
  /// In en, this message translates to:
  /// **'Staff:'**
  String get staffColon;

  /// No description provided for @ratingColon.
  ///
  /// In en, this message translates to:
  /// **'Rating:'**
  String get ratingColon;

  /// No description provided for @editClient.
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get editClient;

  /// No description provided for @deleteClient.
  ///
  /// In en, this message translates to:
  /// **'Delete Client'**
  String get deleteClient;

  /// No description provided for @searchByNotesOrService.
  ///
  /// In en, this message translates to:
  /// **'Search by notes or service'**
  String get searchByNotesOrService;

  /// No description provided for @enterSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Enter search terms...'**
  String get enterSearchTerms;

  /// No description provided for @allServices.
  ///
  /// In en, this message translates to:
  /// **'All Services'**
  String get allServices;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @searchByClientName.
  ///
  /// In en, this message translates to:
  /// **'Search by client name'**
  String get searchByClientName;

  /// No description provided for @enterClientName.
  ///
  /// In en, this message translates to:
  /// **'Enter client name...'**
  String get enterClientName;

  /// No description provided for @clientColon.
  ///
  /// In en, this message translates to:
  /// **'Client:'**
  String get clientColon;

  /// No description provided for @photosColon.
  ///
  /// In en, this message translates to:
  /// **'Photos:'**
  String get photosColon;

  /// No description provided for @notesColon.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get notesColon;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @addStaffMember.
  ///
  /// In en, this message translates to:
  /// **'Add Staff Member'**
  String get addStaffMember;

  /// No description provided for @specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialty;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @generalStylist.
  ///
  /// In en, this message translates to:
  /// **'General Stylist'**
  String get generalStylist;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @newHire.
  ///
  /// In en, this message translates to:
  /// **'New hire'**
  String get newHire;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceName;

  /// No description provided for @enterServiceName.
  ///
  /// In en, this message translates to:
  /// **'Enter service name'**
  String get enterServiceName;

  /// No description provided for @noStaffMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No staff members yet'**
  String get noStaffMembersYet;

  /// No description provided for @addFirstTeamMember.
  ///
  /// In en, this message translates to:
  /// **'Add your first team member to get started'**
  String get addFirstTeamMember;

  /// No description provided for @staffDetailsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Staff details for {staffName} coming soon'**
  String staffDetailsComingSoon(Object staffName);

  /// No description provided for @removeStaffMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Staff Member'**
  String get removeStaffMember;

  /// No description provided for @confirmRemoveStaff.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {staffName} from your team? They will be marked as inactive but their work history will be preserved.'**
  String confirmRemoveStaff(Object staffName);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @staffRemovedFromTeam.
  ///
  /// In en, this message translates to:
  /// **'{staffName} removed from team'**
  String staffRemovedFromTeam(Object staffName);

  /// No description provided for @staffAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Staff Analytics'**
  String get staffAnalytics;

  /// No description provided for @totalStaff.
  ///
  /// In en, this message translates to:
  /// **'Total Staff'**
  String get totalStaff;

  /// No description provided for @activeStaff.
  ///
  /// In en, this message translates to:
  /// **'Active Staff'**
  String get activeStaff;

  /// No description provided for @inactiveStaff.
  ///
  /// In en, this message translates to:
  /// **'Inactive Staff'**
  String get inactiveStaff;

  /// No description provided for @editStaffMember.
  ///
  /// In en, this message translates to:
  /// **'Edit Staff Member'**
  String get editStaffMember;

  /// No description provided for @enterStaffMemberName.
  ///
  /// In en, this message translates to:
  /// **'Enter staff member name'**
  String get enterStaffMemberName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @specialtyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Hair Color Specialist, Nail Art'**
  String get specialtyHint;

  /// No description provided for @staffEmailHint.
  ///
  /// In en, this message translates to:
  /// **'staff@salon.com'**
  String get staffEmailHint;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'(555) 123-4567'**
  String get phoneNumberHint;

  /// No description provided for @additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional information...'**
  String get additionalInformation;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @staffUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{staffName} updated successfully'**
  String staffUpdatedSuccessfully(Object staffName);

  /// No description provided for @staffAddedToTeam.
  ///
  /// In en, this message translates to:
  /// **'{staffName} added to your team'**
  String staffAddedToTeam(Object staffName);

  /// No description provided for @showAllStaff.
  ///
  /// In en, this message translates to:
  /// **'Show All Staff'**
  String get showAllStaff;

  /// No description provided for @noServicesYet.
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get noServicesYet;

  /// No description provided for @addFirstService.
  ///
  /// In en, this message translates to:
  /// **'Add your first service to get started'**
  String get addFirstService;

  /// No description provided for @showAllServices.
  ///
  /// In en, this message translates to:
  /// **'Show All Services'**
  String get showAllServices;

  /// No description provided for @serviceAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Service Analytics'**
  String get serviceAnalytics;

  /// No description provided for @totalServices.
  ///
  /// In en, this message translates to:
  /// **'Total Services'**
  String get totalServices;

  /// No description provided for @activeServices.
  ///
  /// In en, this message translates to:
  /// **'Active Services'**
  String get activeServices;

  /// No description provided for @inactiveServices.
  ///
  /// In en, this message translates to:
  /// **'Inactive Services'**
  String get inactiveServices;

  /// No description provided for @editService.
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editService;

  /// No description provided for @serviceAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Service added successfully'**
  String get serviceAddedSuccessfully;

  /// No description provided for @serviceUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Service updated successfully'**
  String get serviceUpdatedSuccessfully;

  /// No description provided for @deleteService.
  ///
  /// In en, this message translates to:
  /// **'Delete Service'**
  String get deleteService;

  /// No description provided for @confirmDeleteService.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{serviceName}\"? This action cannot be undone.'**
  String confirmDeleteService(Object serviceName);

  /// No description provided for @serviceDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Service deleted successfully'**
  String get serviceDeletedSuccessfully;

  /// No description provided for @pleaseEnterServiceName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a service name'**
  String get pleaseEnterServiceName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
