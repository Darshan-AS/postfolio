///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'Postfolio'
	String get appTitle => 'Postfolio';

	late final TranslationsErrorsEn errors = TranslationsErrorsEn.internal(_root);
	late final TranslationsFormatEn format = TranslationsFormatEn.internal(_root);
	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
	late final TranslationsSortingEn sorting = TranslationsSortingEn.internal(_root);
	late final TranslationsFiltersEn filters = TranslationsFiltersEn.internal(_root);
	late final TranslationsProjectionEn projection = TranslationsProjectionEn.internal(_root);
	late final TranslationsNavEn nav = TranslationsNavEn.internal(_root);
	late final TranslationsCustomersEn customers = TranslationsCustomersEn.internal(_root);
	late final TranslationsDashboardEn dashboard = TranslationsDashboardEn.internal(_root);
	late final TranslationsOneTimeDepositsEn oneTimeDeposits = TranslationsOneTimeDepositsEn.internal(_root);
	late final TranslationsRecurringDepositsEn recurringDeposits = TranslationsRecurringDepositsEn.internal(_root);
	late final TranslationsNomineesEn nominees = TranslationsNomineesEn.internal(_root);
	late final TranslationsEnumsEn enums = TranslationsEnumsEn.internal(_root);
	late final TranslationsAuthEn auth = TranslationsAuthEn.internal(_root);
	late final TranslationsMigrationEn migration = TranslationsMigrationEn.internal(_root);
}

// Path: errors
class TranslationsErrorsEn {
	TranslationsErrorsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '${field} is required'
	String requiredField({required Object field}) => '${field} is required';

	/// en: '${field} must be greater than 0'
	String greaterThanZero({required Object field}) => '${field} must be greater than 0';

	/// en: 'Term cannot be negative'
	String get negativeTerm => 'Term cannot be negative';

	/// en: 'Invalid tenure of ${years} years for ${scheme}'
	String invalidTenure({required Object years, required Object scheme}) => 'Invalid tenure of ${years} years for ${scheme}';

	/// en: 'Months are not applicable for fixed tenure schemes'
	String get fixedTenureNoMonths => 'Months are not applicable for fixed tenure schemes';

	/// en: 'Maturity date cannot be before start date'
	String get invalidMaturityDate => 'Maturity date cannot be before start date';

	/// en: '${field} must be at least ${count} characters'
	String minLength({required Object field, required Object count}) => '${field} must be at least ${count} characters';

	/// en: 'Invalid email format'
	String get invalidEmail => 'Invalid email format';

	/// en: 'Invalid phone number (7-15 digits)'
	String get invalidPhone => 'Invalid phone number (7-15 digits)';

	/// en: 'Savings Account Number is required to add nominees'
	String get sbAccountRequiredForNominee => 'Savings Account Number is required to add nominees';

	/// en: 'Total nominee percentage must be exactly 100%'
	String get nomineePercentageTotal => 'Total nominee percentage must be exactly 100%';

	/// en: 'Aadhaar number must be 12 digits'
	String get invalidAadhaar => 'Aadhaar number must be 12 digits';

	/// en: 'Invalid PAN number format (e.g. ABCDE1234F)'
	String get invalidPan => 'Invalid PAN number format (e.g. ABCDE1234F)';

	/// en: 'CIF number must be at least 9 characters'
	String get invalidCif => 'CIF number must be at least 9 characters';

	/// en: 'Interest rate must be between 0 and 100'
	String get invalidInterestRate => 'Interest rate must be between 0 and 100';

	/// en: 'Percentage must be between 0 and 100'
	String get percentageRange => 'Percentage must be between 0 and 100';
}

// Path: format
class TranslationsFormatEn {
	TranslationsFormatEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'dd MMM yyyy'
	String get date => 'dd MMM yyyy';

	/// en: 'dd/MM/yyyy'
	String get dateCompact => 'dd/MM/yyyy';

	/// en: 'dd MMM yyyy, hh:mm a'
	String get dateTime => 'dd MMM yyyy, hh:mm a';

	/// en: '₹'
	String get currencySymbol => '₹';

	/// en: ' • '
	String get bulletSeparator => ' • ';
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Search...'
	String get search => 'Search...';

	late final TranslationsCommonDurationEn duration = TranslationsCommonDurationEn.internal(_root);

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Saving...'
	String get saving => 'Saving...';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Clear'
	String get clear => 'Clear';

	/// en: 'Clear Filters'
	String get clearFilters => 'Clear Filters';

	/// en: 'Details'
	String get details => 'Details';

	/// en: 'Deposit Details'
	String get depositDetails => 'Deposit Details';

	/// en: 'Error'
	String get error => 'Error';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'OK'
	String get ok => 'OK';

	/// en: '—'
	String get notProvided => '—';

	/// en: 'More options'
	String get moreOptions => 'More options';

	/// en: 'No results found'
	String get noResults => 'No results found';

	/// en: 'Demo Mode Active. Data is not saved to the cloud.'
	String get demoModeActive => 'Demo Mode Active. Data is not saved to the cloud.';

	late final TranslationsCommonSectionsEn sections = TranslationsCommonSectionsEn.internal(_root);
}

// Path: sorting
class TranslationsSortingEn {
	TranslationsSortingEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sort By'
	String get title => 'Sort By';

	Map<String, String> get options => {
		'newest': 'Newest First',
		'oldest': 'Oldest First',
		'nameAsc': 'Name (A-Z)',
		'nameDesc': 'Name (Z-A)',
		'highestAmount': 'Highest Amount',
		'maturityAsc': 'Maturity (Sooner)',
		'maturityDesc': 'Maturity (Later)',
		'serialNoAsc': 'Serial No (Asc)',
		'serialNoDesc': 'Serial No (Desc)',
	};
}

// Path: filters
class TranslationsFiltersEn {
	TranslationsFiltersEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Filters'
	String get title => 'Filters';

	late final TranslationsFiltersSectionsEn sections = TranslationsFiltersSectionsEn.internal(_root);

	/// en: 'Status'
	String get status => 'Status';
}

// Path: projection
class TranslationsProjectionEn {
	TranslationsProjectionEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Live Projection'
	String get title => 'Live Projection';

	/// en: 'Total Invested'
	String get totalInvested => 'Total Invested';

	/// en: 'Projected Interest'
	String get totalInterestEarned => 'Projected Interest';

	/// en: 'Total Return'
	String get totalReturn => 'Total Return';

	/// en: 'Estimated Maturity'
	String get estimatedMaturity => 'Estimated Maturity';

	/// en: 'Maturity Date'
	String get maturityDate => 'Maturity Date';

	/// en: 'Payout (${frequency})'
	String payout({required Object frequency}) => 'Payout (${frequency})';

	/// en: 'Doubles In'
	String get doublesIn => 'Doubles In';
}

// Path: nav
class TranslationsNavEn {
	TranslationsNavEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Dashboard'
	String get dashboard => 'Dashboard';

	/// en: 'One-Time'
	String get oneTimeDeposits => 'One-Time';

	/// en: 'Recurring'
	String get recurringDeposits => 'Recurring';

	/// en: 'Customers'
	String get customers => 'Customers';
}

// Path: customers
class TranslationsCustomersEn {
	TranslationsCustomersEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Customers'
	String get title => 'Customers';

	/// en: 'Customer Details'
	String get customerDetails => 'Customer Details';

	/// en: 'New Customer'
	String get newCustomer => 'New Customer';

	/// en: 'Edit Customer'
	String get editCustomer => 'Edit Customer';

	/// en: 'Save Customer'
	String get saveCustomer => 'Save Customer';

	/// en: 'No customers found. Add one!'
	String get noCustomersFound => 'No customers found. Add one!';

	/// en: 'Select Customer'
	String get selectCustomer => 'Select Customer';

	/// en: 'Search by name, phone, CIF, Aadhaar or PAN...'
	String get searchHint => 'Search by name, phone, CIF, Aadhaar or PAN...';

	/// en: 'Customer not found'
	String get customerNotFound => 'Customer not found';

	/// en: 'Delete Customer'
	String get deleteCustomer => 'Delete Customer';

	/// en: 'Are you sure you want to delete this customer?'
	String get deleteCustomerConfirmation => 'Are you sure you want to delete this customer?';

	/// en: 'Failed to save customer: ${error}'
	String failedToSaveCustomer({required Object error}) => 'Failed to save customer: ${error}';

	/// en: 'Failed to delete customer: ${error}'
	String failedToDeleteCustomer({required Object error}) => 'Failed to delete customer: ${error}';

	late final TranslationsCustomersActionsEn actions = TranslationsCustomersActionsEn.internal(_root);
	late final TranslationsCustomersSectionsEn sections = TranslationsCustomersSectionsEn.internal(_root);
	late final TranslationsCustomersFieldsEn fields = TranslationsCustomersFieldsEn.internal(_root);

	/// en: 'Custom Relationship'
	String get customRelationship => 'Custom Relationship';
}

// Path: dashboard
class TranslationsDashboardEn {
	TranslationsDashboardEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Dashboard Charts Go Here'
	String get charts => 'Dashboard Charts Go Here';
}

// Path: oneTimeDeposits
class TranslationsOneTimeDepositsEn {
	TranslationsOneTimeDepositsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'One-Time Deposits'
	String get title => 'One-Time Deposits';

	/// en: 'New Deposit'
	String get newDeposit => 'New Deposit';

	/// en: 'Edit Deposit'
	String get editDeposit => 'Edit Deposit';

	/// en: 'Save Deposit'
	String get saveDeposit => 'Save Deposit';

	/// en: 'No one-time deposits found. Add one!'
	String get noDepositsFound => 'No one-time deposits found. Add one!';

	/// en: 'Deposit not found'
	String get depositNotFound => 'Deposit not found';

	/// en: 'Search by account, customer or scheme...'
	String get searchHint => 'Search by account, customer or scheme...';

	/// en: 'Delete Deposit'
	String get deleteDeposit => 'Delete Deposit';

	/// en: 'Are you sure you want to delete this deposit?'
	String get deleteDepositConfirmation => 'Are you sure you want to delete this deposit?';

	/// en: 'Failed to save deposit: ${error}'
	String failedToSaveDeposit({required Object error}) => 'Failed to save deposit: ${error}';

	/// en: 'Failed to delete deposit: ${error}'
	String failedToDeleteDeposit({required Object error}) => 'Failed to delete deposit: ${error}';

	/// en: 'Please select a customer'
	String get selectCustomerPrompt => 'Please select a customer';

	late final TranslationsOneTimeDepositsSectionsEn sections = TranslationsOneTimeDepositsSectionsEn.internal(_root);
	late final TranslationsOneTimeDepositsFieldsEn fields = TranslationsOneTimeDepositsFieldsEn.internal(_root);
}

// Path: recurringDeposits
class TranslationsRecurringDepositsEn {
	TranslationsRecurringDepositsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Recurring Deposits'
	String get title => 'Recurring Deposits';

	/// en: 'New RD'
	String get newDeposit => 'New RD';

	/// en: 'Edit RD'
	String get editDeposit => 'Edit RD';

	/// en: 'Save RD'
	String get saveDeposit => 'Save RD';

	/// en: 'No recurring deposits found. Add one!'
	String get noDepositsFound => 'No recurring deposits found. Add one!';

	/// en: 'RD not found'
	String get depositNotFound => 'RD not found';

	/// en: 'Search by account, serial, customer or scheme...'
	String get searchHint => 'Search by account, serial, customer or scheme...';

	/// en: 'Delete RD'
	String get deleteDeposit => 'Delete RD';

	/// en: 'Are you sure you want to delete this RD?'
	String get deleteDepositConfirmation => 'Are you sure you want to delete this RD?';

	/// en: 'Failed to save RD: ${error}'
	String failedToSaveDeposit({required Object error}) => 'Failed to save RD: ${error}';

	/// en: 'Failed to delete RD: ${error}'
	String failedToDeleteDeposit({required Object error}) => 'Failed to delete RD: ${error}';

	/// en: 'Please select a customer'
	String get selectCustomerPrompt => 'Please select a customer';

	late final TranslationsRecurringDepositsSectionsEn sections = TranslationsRecurringDepositsSectionsEn.internal(_root);
	late final TranslationsRecurringDepositsFieldsEn fields = TranslationsRecurringDepositsFieldsEn.internal(_root);
}

// Path: nominees
class TranslationsNomineesEn {
	TranslationsNomineesEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Nominees'
	String get title => 'Nominees';

	/// en: 'Add Nominee'
	String get addNominee => 'Add Nominee';

	/// en: 'Edit Nominee'
	String get editNominee => 'Edit Nominee';

	/// en: 'Delete Nominee'
	String get deleteNominee => 'Delete Nominee';

	/// en: 'Nominee Name'
	String get name => 'Nominee Name';

	/// en: 'Relationship'
	String get relationship => 'Relationship';

	/// en: 'Percentage (%)'
	String get percentage => 'Percentage (%)';

	/// en: 'Custom Relationship'
	String get customRelationship => 'Custom Relationship';

	/// en: 'No nominees added yet.'
	String get noNominees => 'No nominees added yet.';
}

// Path: enums
class TranslationsEnumsEn {
	TranslationsEnumsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	Map<String, String> get payoutFrequency => {
		'monthly': 'Monthly',
		'quarterly': 'Quarterly',
		'annually': 'Annually',
	};
	Map<String, String> get depositStatus => {
		'active': 'Active',
		'matured': 'Matured',
		'closed': 'Closed',
	};
	Map<String, String> get oneTimeSchemeType => {
		'timeDeposit': 'Time Deposit (TD)',
		'monthlyIncomeScheme': 'Monthly Income Scheme (MIS)',
		'nationalSavingsCertificate': 'National Savings Certificate (NSC)',
		'kisanVikasPatra': 'Kisan Vikas Patra (KVP)',
	};
	Map<String, String> get recurringSchemeType => {
		'recurringDeposit': 'Recurring Deposit (RD)',
	};
	Map<String, String> get maturityUrgency => {
		'normal': 'Normal',
		'maturingSoon': 'Maturing Soon',
		'overdue': 'Overdue',
		'closed': 'Closed',
	};
	late final TranslationsEnumsMaturityRelativeTimeEn maturityRelativeTime = TranslationsEnumsMaturityRelativeTimeEn.internal(_root);
	Map<String, String> get nomineeRelationship => {
		'husband': 'Husband',
		'wife': 'Wife',
		'son': 'Son',
		'daughter': 'Daughter',
		'father': 'Father',
		'mother': 'Mother',
		'brother': 'Brother',
		'sister': 'Sister',
		'grandfather': 'Grandfather',
		'grandmother': 'Grandmother',
		'grandson': 'Grandson',
		'granddaughter': 'Granddaughter',
		'fatherInLaw': 'Father-in-law',
		'motherInLaw': 'Mother-in-law',
		'sonInLaw': 'Son-in-law',
		'daughterInLaw': 'Daughter-in-law',
		'brotherInLaw': 'Brother-in-law',
		'sisterInLaw': 'Sister-in-law',
		'nephew': 'Nephew (Sibling\'s son)',
		'niece': 'Niece (Sibling\'s daughter)',
		'uncle': 'Uncle',
		'aunt': 'Aunt',
		'cousin': 'Cousin',
		'other': 'Other',
	};
}

// Path: auth
class TranslationsAuthEn {
	TranslationsAuthEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Welcome to Postfolio'
	String get welcome => 'Welcome to Postfolio';

	/// en: 'Sign in to manage your deposits securely'
	String get signInSubtitle => 'Sign in to manage your deposits securely';

	/// en: 'Sign in with Google'
	String get signInWithGoogle => 'Sign in with Google';

	/// en: 'Try Demo Mode'
	String get tryDemoMode => 'Try Demo Mode';

	/// en: 'Sign Out'
	String get signOut => 'Sign Out';
}

// Path: migration
class TranslationsMigrationEn {
	TranslationsMigrationEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Emulator Migration Test'
	String get title => 'Emulator Migration Test';

	/// en: 'Sign In'
	String get signIn => 'Sign In';

	/// en: 'Migrate Batch'
	String get migrateBatch => 'Migrate Batch';

	/// en: 'Migrate All'
	String get migrateAll => 'Migrate All';

	/// en: 'Delete All'
	String get deleteAll => 'Delete All';

	/// en: 'Batch: ${processed}/${total}, Migrated: ${migrated}, Duplicates: ${duplicates}'
	String summaryBatch({required Object processed, required Object total, required Object migrated, required Object duplicates}) => 'Batch: ${processed}/${total}, Migrated: ${migrated}, Duplicates: ${duplicates}';

	/// en: 'Total: ${total}, Migrated: ${migrated}, Missing Cust: ${missingCust}, Duplicates: ${duplicates}'
	String summaryAll({required Object total, required Object migrated, required Object missingCust, required Object duplicates}) => 'Total: ${total}, Migrated: ${migrated}, Missing Cust: ${missingCust}, Duplicates: ${duplicates}';

	/// en: 'Target User ID (UID)'
	String get targetUid => 'Target User ID (UID)';

	/// en: 'Enter your Firebase Auth UID to migrate data into your account.'
	String get targetUidHelper => 'Enter your Firebase Auth UID to migrate data into your account.';

	/// en: 'Batch Size'
	String get batchSize => 'Batch Size';
}

// Path: common.duration
class TranslationsCommonDurationEn {
	TranslationsCommonDurationEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Term (Years)'
	String get termYears => 'Term (Years)';

	/// en: 'Term (Months)'
	String get termMonths => 'Term (Months)';

	/// en: '(one) {1 Yr} (other) {${n} Yrs}'
	String yearAbbreviation({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 Yr',
		other: '${n} Yrs',
	);
}

// Path: common.sections
class TranslationsCommonSectionsEn {
	TranslationsCommonSectionsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Linked Accounts'
	String get linkedAccounts => 'Linked Accounts';
}

// Path: filters.sections
class TranslationsFiltersSectionsEn {
	TranslationsFiltersSectionsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Status'
	String get status => 'Status';

	/// en: 'Urgency'
	String get urgency => 'Urgency';

	/// en: 'Scheme Type'
	String get scheme => 'Scheme Type';
}

// Path: customers.actions
class TranslationsCustomersActionsEn {
	TranslationsCustomersActionsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Call'
	String get call => 'Call';

	/// en: 'SMS'
	String get sms => 'SMS';

	/// en: 'WhatsApp'
	String get whatsapp => 'WhatsApp';

	/// en: 'Location'
	String get location => 'Location';
}

// Path: customers.sections
class TranslationsCustomersSectionsEn {
	TranslationsCustomersSectionsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Personal Information'
	String get personalInfo => 'Personal Information';

	/// en: 'Identity Documents'
	String get identityDocuments => 'Identity Documents';

	/// en: 'Savings Bank'
	String get savingsBank => 'Savings Bank';
}

// Path: customers.fields
class TranslationsCustomersFieldsEn {
	TranslationsCustomersFieldsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Full Name'
	String get fullName => 'Full Name';

	/// en: 'Phone Number'
	String get phoneNumber => 'Phone Number';

	/// en: 'Email Address'
	String get emailAddress => 'Email Address';

	/// en: 'Home Address'
	String get homeAddress => 'Home Address';

	/// en: 'CIF'
	String get cif => 'CIF';

	/// en: 'Aadhaar Number'
	String get aadhaarNumber => 'Aadhaar Number';

	/// en: 'PAN Number'
	String get panNumber => 'PAN Number';

	/// en: 'SB Account No.'
	String get sbAccountNumber => 'SB Account No.';

	/// en: 'SB Nominee Name'
	String get sbNomineeName => 'SB Nominee Name';

	/// en: 'SB Nominee Relationship'
	String get sbNomineeRelationship => 'SB Nominee Relationship';

	/// en: 'Date of Birth'
	String get dateOfBirth => 'Date of Birth';

	/// en: 'Nominees'
	String get nominees => 'Nominees';

	/// en: 'Add Nominee'
	String get addNominee => 'Add Nominee';

	/// en: 'Nominee Name'
	String get nomineeName => 'Nominee Name';

	/// en: 'Relationship'
	String get relationship => 'Relationship';

	/// en: 'Percentage (%)'
	String get percentage => 'Percentage (%)';
}

// Path: oneTimeDeposits.sections
class TranslationsOneTimeDepositsSectionsEn {
	TranslationsOneTimeDepositsSectionsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Investment Details'
	String get investmentDetails => 'Investment Details';

	/// en: 'Timeline'
	String get timeline => 'Timeline';

	/// en: 'Account Information'
	String get accountInformation => 'Account Information';
}

// Path: oneTimeDeposits.fields
class TranslationsOneTimeDepositsFieldsEn {
	TranslationsOneTimeDepositsFieldsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Status'
	String get status => 'Status';

	/// en: 'Account No.'
	String get accountNo => 'Account No.';

	/// en: 'Principal Amount'
	String get principalAmount => 'Principal Amount';

	/// en: 'Term (Years)'
	String get termYears => 'Term (Years)';

	/// en: 'Term (Months)'
	String get termMonths => 'Term (Months)';

	/// en: '(one) {1 Yr} (other) {${n} Yrs}'
	String yearAbbreviation({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 Yr',
		other: '${n} Yrs',
	);

	/// en: 'Customer'
	String get customerId => 'Customer';

	/// en: 'Scheme Type'
	String get schemeType => 'Scheme Type';

	/// en: 'Interest Rate (%)'
	String get interestRate => 'Interest Rate (%)';

	/// en: 'Maturity Amount'
	String get maturityAmount => 'Maturity Amount';

	/// en: 'Periodic Payout'
	String get periodicPayoutAmount => 'Periodic Payout';

	/// en: 'Payout Frequency'
	String get payoutFrequency => 'Payout Frequency';

	/// en: 'Start Date'
	String get startDate => 'Start Date';

	/// en: 'Maturity Date'
	String get maturityDate => 'Maturity Date';

	/// en: 'Deposit Date'
	String get depositDate => 'Deposit Date';

	/// en: 'Linked Savings Account'
	String get linkedSavingsAccountNo => 'Linked Savings Account';
}

// Path: recurringDeposits.sections
class TranslationsRecurringDepositsSectionsEn {
	TranslationsRecurringDepositsSectionsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Investment Details'
	String get investmentDetails => 'Investment Details';

	/// en: 'Timeline'
	String get timeline => 'Timeline';

	/// en: 'Account Information'
	String get accountInformation => 'Account Information';
}

// Path: recurringDeposits.fields
class TranslationsRecurringDepositsFieldsEn {
	TranslationsRecurringDepositsFieldsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Status'
	String get status => 'Status';

	/// en: 'Serial No.'
	String get serialNo => 'Serial No.';

	/// en: 'Account No.'
	String get accountNo => 'Account No.';

	/// en: 'Installment Amount'
	String get installmentAmount => 'Installment Amount';

	/// en: 'Term (Years)'
	String get termYears => 'Term (Years)';

	/// en: 'Term (Months)'
	String get termMonths => 'Term (Months)';

	/// en: '(one) {1 Yr} (other) {${n} Yrs}'
	String yearAbbreviation({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 Yr',
		other: '${n} Yrs',
	);

	/// en: 'Interest Rate (%)'
	String get interestRate => 'Interest Rate (%)';

	/// en: 'Customer'
	String get customerId => 'Customer';

	/// en: 'Scheme Type'
	String get schemeType => 'Scheme Type';

	/// en: 'Maturity Amount'
	String get maturityAmount => 'Maturity Amount';

	/// en: 'Start Date'
	String get startDate => 'Start Date';

	/// en: 'Maturity Date'
	String get maturityDate => 'Maturity Date';

	/// en: 'Linked Savings Account'
	String get linkedSavingsAccount => 'Linked Savings Account';

	/// en: 'Linked Auto Debit Account'
	String get linkedAutoDebitAccountNo => 'Linked Auto Debit Account';
}

// Path: enums.maturityRelativeTime
class TranslationsEnumsMaturityRelativeTimeEn {
	TranslationsEnumsMaturityRelativeTimeEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Maturing in $days d'
	String maturingIn({required Object days}) => 'Maturing in ${days} d';

	/// en: 'Maturing today'
	String get maturingToday => 'Maturing today';

	/// en: 'Matured $days d ago'
	String maturedAgo({required Object days}) => 'Matured ${days} d ago';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle' => 'Postfolio',
			'errors.requiredField' => ({required Object field}) => '${field} is required',
			'errors.greaterThanZero' => ({required Object field}) => '${field} must be greater than 0',
			'errors.negativeTerm' => 'Term cannot be negative',
			'errors.invalidTenure' => ({required Object years, required Object scheme}) => 'Invalid tenure of ${years} years for ${scheme}',
			'errors.fixedTenureNoMonths' => 'Months are not applicable for fixed tenure schemes',
			'errors.invalidMaturityDate' => 'Maturity date cannot be before start date',
			'errors.minLength' => ({required Object field, required Object count}) => '${field} must be at least ${count} characters',
			'errors.invalidEmail' => 'Invalid email format',
			'errors.invalidPhone' => 'Invalid phone number (7-15 digits)',
			'errors.sbAccountRequiredForNominee' => 'Savings Account Number is required to add nominees',
			'errors.nomineePercentageTotal' => 'Total nominee percentage must be exactly 100%',
			'errors.invalidAadhaar' => 'Aadhaar number must be 12 digits',
			'errors.invalidPan' => 'Invalid PAN number format (e.g. ABCDE1234F)',
			'errors.invalidCif' => 'CIF number must be at least 9 characters',
			'errors.invalidInterestRate' => 'Interest rate must be between 0 and 100',
			'errors.percentageRange' => 'Percentage must be between 0 and 100',
			'format.date' => 'dd MMM yyyy',
			'format.dateCompact' => 'dd/MM/yyyy',
			'format.dateTime' => 'dd MMM yyyy, hh:mm a',
			'format.currencySymbol' => '₹',
			'format.bulletSeparator' => ' • ',
			'common.search' => 'Search...',
			'common.duration.termYears' => 'Term (Years)',
			'common.duration.termMonths' => 'Term (Months)',
			'common.duration.yearAbbreviation' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 Yr', other: '${n} Yrs', ), 
			'common.loading' => 'Loading...',
			'common.saving' => 'Saving...',
			'common.edit' => 'Edit',
			'common.delete' => 'Delete',
			'common.cancel' => 'Cancel',
			'common.clear' => 'Clear',
			'common.clearFilters' => 'Clear Filters',
			'common.details' => 'Details',
			'common.depositDetails' => 'Deposit Details',
			'common.error' => 'Error',
			'common.retry' => 'Retry',
			'common.ok' => 'OK',
			'common.notProvided' => '—',
			'common.moreOptions' => 'More options',
			'common.noResults' => 'No results found',
			'common.demoModeActive' => 'Demo Mode Active. Data is not saved to the cloud.',
			'common.sections.linkedAccounts' => 'Linked Accounts',
			'sorting.title' => 'Sort By',
			'sorting.options.newest' => 'Newest First',
			'sorting.options.oldest' => 'Oldest First',
			'sorting.options.nameAsc' => 'Name (A-Z)',
			'sorting.options.nameDesc' => 'Name (Z-A)',
			'sorting.options.highestAmount' => 'Highest Amount',
			'sorting.options.maturityAsc' => 'Maturity (Sooner)',
			'sorting.options.maturityDesc' => 'Maturity (Later)',
			'sorting.options.serialNoAsc' => 'Serial No (Asc)',
			'sorting.options.serialNoDesc' => 'Serial No (Desc)',
			'filters.title' => 'Filters',
			'filters.sections.status' => 'Status',
			'filters.sections.urgency' => 'Urgency',
			'filters.sections.scheme' => 'Scheme Type',
			'filters.status' => 'Status',
			'projection.title' => 'Live Projection',
			'projection.totalInvested' => 'Total Invested',
			'projection.totalInterestEarned' => 'Projected Interest',
			'projection.totalReturn' => 'Total Return',
			'projection.estimatedMaturity' => 'Estimated Maturity',
			'projection.maturityDate' => 'Maturity Date',
			'projection.payout' => ({required Object frequency}) => 'Payout (${frequency})',
			'projection.doublesIn' => 'Doubles In',
			'nav.dashboard' => 'Dashboard',
			'nav.oneTimeDeposits' => 'One-Time',
			'nav.recurringDeposits' => 'Recurring',
			'nav.customers' => 'Customers',
			'customers.title' => 'Customers',
			'customers.customerDetails' => 'Customer Details',
			'customers.newCustomer' => 'New Customer',
			'customers.editCustomer' => 'Edit Customer',
			'customers.saveCustomer' => 'Save Customer',
			'customers.noCustomersFound' => 'No customers found. Add one!',
			'customers.selectCustomer' => 'Select Customer',
			'customers.searchHint' => 'Search by name, phone, CIF, Aadhaar or PAN...',
			'customers.customerNotFound' => 'Customer not found',
			'customers.deleteCustomer' => 'Delete Customer',
			'customers.deleteCustomerConfirmation' => 'Are you sure you want to delete this customer?',
			'customers.failedToSaveCustomer' => ({required Object error}) => 'Failed to save customer: ${error}',
			'customers.failedToDeleteCustomer' => ({required Object error}) => 'Failed to delete customer: ${error}',
			'customers.actions.call' => 'Call',
			'customers.actions.sms' => 'SMS',
			'customers.actions.whatsapp' => 'WhatsApp',
			'customers.actions.location' => 'Location',
			'customers.sections.personalInfo' => 'Personal Information',
			'customers.sections.identityDocuments' => 'Identity Documents',
			'customers.sections.savingsBank' => 'Savings Bank',
			'customers.fields.fullName' => 'Full Name',
			'customers.fields.phoneNumber' => 'Phone Number',
			'customers.fields.emailAddress' => 'Email Address',
			'customers.fields.homeAddress' => 'Home Address',
			'customers.fields.cif' => 'CIF',
			'customers.fields.aadhaarNumber' => 'Aadhaar Number',
			'customers.fields.panNumber' => 'PAN Number',
			'customers.fields.sbAccountNumber' => 'SB Account No.',
			'customers.fields.sbNomineeName' => 'SB Nominee Name',
			'customers.fields.sbNomineeRelationship' => 'SB Nominee Relationship',
			'customers.fields.dateOfBirth' => 'Date of Birth',
			'customers.fields.nominees' => 'Nominees',
			'customers.fields.addNominee' => 'Add Nominee',
			'customers.fields.nomineeName' => 'Nominee Name',
			'customers.fields.relationship' => 'Relationship',
			'customers.fields.percentage' => 'Percentage (%)',
			'customers.customRelationship' => 'Custom Relationship',
			'dashboard.charts' => 'Dashboard Charts Go Here',
			'oneTimeDeposits.title' => 'One-Time Deposits',
			'oneTimeDeposits.newDeposit' => 'New Deposit',
			'oneTimeDeposits.editDeposit' => 'Edit Deposit',
			'oneTimeDeposits.saveDeposit' => 'Save Deposit',
			'oneTimeDeposits.noDepositsFound' => 'No one-time deposits found. Add one!',
			'oneTimeDeposits.depositNotFound' => 'Deposit not found',
			'oneTimeDeposits.searchHint' => 'Search by account, customer or scheme...',
			'oneTimeDeposits.deleteDeposit' => 'Delete Deposit',
			'oneTimeDeposits.deleteDepositConfirmation' => 'Are you sure you want to delete this deposit?',
			'oneTimeDeposits.failedToSaveDeposit' => ({required Object error}) => 'Failed to save deposit: ${error}',
			'oneTimeDeposits.failedToDeleteDeposit' => ({required Object error}) => 'Failed to delete deposit: ${error}',
			'oneTimeDeposits.selectCustomerPrompt' => 'Please select a customer',
			'oneTimeDeposits.sections.investmentDetails' => 'Investment Details',
			'oneTimeDeposits.sections.timeline' => 'Timeline',
			'oneTimeDeposits.sections.accountInformation' => 'Account Information',
			'oneTimeDeposits.fields.status' => 'Status',
			'oneTimeDeposits.fields.accountNo' => 'Account No.',
			'oneTimeDeposits.fields.principalAmount' => 'Principal Amount',
			'oneTimeDeposits.fields.termYears' => 'Term (Years)',
			'oneTimeDeposits.fields.termMonths' => 'Term (Months)',
			'oneTimeDeposits.fields.yearAbbreviation' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 Yr', other: '${n} Yrs', ), 
			'oneTimeDeposits.fields.customerId' => 'Customer',
			'oneTimeDeposits.fields.schemeType' => 'Scheme Type',
			'oneTimeDeposits.fields.interestRate' => 'Interest Rate (%)',
			'oneTimeDeposits.fields.maturityAmount' => 'Maturity Amount',
			'oneTimeDeposits.fields.periodicPayoutAmount' => 'Periodic Payout',
			'oneTimeDeposits.fields.payoutFrequency' => 'Payout Frequency',
			'oneTimeDeposits.fields.startDate' => 'Start Date',
			'oneTimeDeposits.fields.maturityDate' => 'Maturity Date',
			'oneTimeDeposits.fields.depositDate' => 'Deposit Date',
			'oneTimeDeposits.fields.linkedSavingsAccountNo' => 'Linked Savings Account',
			'recurringDeposits.title' => 'Recurring Deposits',
			'recurringDeposits.newDeposit' => 'New RD',
			'recurringDeposits.editDeposit' => 'Edit RD',
			'recurringDeposits.saveDeposit' => 'Save RD',
			'recurringDeposits.noDepositsFound' => 'No recurring deposits found. Add one!',
			'recurringDeposits.depositNotFound' => 'RD not found',
			'recurringDeposits.searchHint' => 'Search by account, serial, customer or scheme...',
			'recurringDeposits.deleteDeposit' => 'Delete RD',
			'recurringDeposits.deleteDepositConfirmation' => 'Are you sure you want to delete this RD?',
			'recurringDeposits.failedToSaveDeposit' => ({required Object error}) => 'Failed to save RD: ${error}',
			'recurringDeposits.failedToDeleteDeposit' => ({required Object error}) => 'Failed to delete RD: ${error}',
			'recurringDeposits.selectCustomerPrompt' => 'Please select a customer',
			'recurringDeposits.sections.investmentDetails' => 'Investment Details',
			'recurringDeposits.sections.timeline' => 'Timeline',
			'recurringDeposits.sections.accountInformation' => 'Account Information',
			'recurringDeposits.fields.status' => 'Status',
			'recurringDeposits.fields.serialNo' => 'Serial No.',
			'recurringDeposits.fields.accountNo' => 'Account No.',
			'recurringDeposits.fields.installmentAmount' => 'Installment Amount',
			'recurringDeposits.fields.termYears' => 'Term (Years)',
			'recurringDeposits.fields.termMonths' => 'Term (Months)',
			'recurringDeposits.fields.yearAbbreviation' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 Yr', other: '${n} Yrs', ), 
			'recurringDeposits.fields.interestRate' => 'Interest Rate (%)',
			'recurringDeposits.fields.customerId' => 'Customer',
			'recurringDeposits.fields.schemeType' => 'Scheme Type',
			'recurringDeposits.fields.maturityAmount' => 'Maturity Amount',
			'recurringDeposits.fields.startDate' => 'Start Date',
			'recurringDeposits.fields.maturityDate' => 'Maturity Date',
			'recurringDeposits.fields.linkedSavingsAccount' => 'Linked Savings Account',
			'recurringDeposits.fields.linkedAutoDebitAccountNo' => 'Linked Auto Debit Account',
			'nominees.title' => 'Nominees',
			'nominees.addNominee' => 'Add Nominee',
			'nominees.editNominee' => 'Edit Nominee',
			'nominees.deleteNominee' => 'Delete Nominee',
			'nominees.name' => 'Nominee Name',
			'nominees.relationship' => 'Relationship',
			'nominees.percentage' => 'Percentage (%)',
			'nominees.customRelationship' => 'Custom Relationship',
			'nominees.noNominees' => 'No nominees added yet.',
			'enums.payoutFrequency.monthly' => 'Monthly',
			'enums.payoutFrequency.quarterly' => 'Quarterly',
			'enums.payoutFrequency.annually' => 'Annually',
			'enums.depositStatus.active' => 'Active',
			'enums.depositStatus.matured' => 'Matured',
			'enums.depositStatus.closed' => 'Closed',
			'enums.oneTimeSchemeType.timeDeposit' => 'Time Deposit (TD)',
			'enums.oneTimeSchemeType.monthlyIncomeScheme' => 'Monthly Income Scheme (MIS)',
			'enums.oneTimeSchemeType.nationalSavingsCertificate' => 'National Savings Certificate (NSC)',
			'enums.oneTimeSchemeType.kisanVikasPatra' => 'Kisan Vikas Patra (KVP)',
			'enums.recurringSchemeType.recurringDeposit' => 'Recurring Deposit (RD)',
			'enums.maturityUrgency.normal' => 'Normal',
			'enums.maturityUrgency.maturingSoon' => 'Maturing Soon',
			'enums.maturityUrgency.overdue' => 'Overdue',
			'enums.maturityUrgency.closed' => 'Closed',
			'enums.maturityRelativeTime.maturingIn' => ({required Object days}) => 'Maturing in ${days} d',
			'enums.maturityRelativeTime.maturingToday' => 'Maturing today',
			'enums.maturityRelativeTime.maturedAgo' => ({required Object days}) => 'Matured ${days} d ago',
			'enums.nomineeRelationship.husband' => 'Husband',
			'enums.nomineeRelationship.wife' => 'Wife',
			'enums.nomineeRelationship.son' => 'Son',
			'enums.nomineeRelationship.daughter' => 'Daughter',
			'enums.nomineeRelationship.father' => 'Father',
			'enums.nomineeRelationship.mother' => 'Mother',
			'enums.nomineeRelationship.brother' => 'Brother',
			'enums.nomineeRelationship.sister' => 'Sister',
			'enums.nomineeRelationship.grandfather' => 'Grandfather',
			'enums.nomineeRelationship.grandmother' => 'Grandmother',
			'enums.nomineeRelationship.grandson' => 'Grandson',
			'enums.nomineeRelationship.granddaughter' => 'Granddaughter',
			'enums.nomineeRelationship.fatherInLaw' => 'Father-in-law',
			'enums.nomineeRelationship.motherInLaw' => 'Mother-in-law',
			'enums.nomineeRelationship.sonInLaw' => 'Son-in-law',
			'enums.nomineeRelationship.daughterInLaw' => 'Daughter-in-law',
			'enums.nomineeRelationship.brotherInLaw' => 'Brother-in-law',
			'enums.nomineeRelationship.sisterInLaw' => 'Sister-in-law',
			'enums.nomineeRelationship.nephew' => 'Nephew (Sibling\'s son)',
			'enums.nomineeRelationship.niece' => 'Niece (Sibling\'s daughter)',
			'enums.nomineeRelationship.uncle' => 'Uncle',
			'enums.nomineeRelationship.aunt' => 'Aunt',
			'enums.nomineeRelationship.cousin' => 'Cousin',
			'enums.nomineeRelationship.other' => 'Other',
			'auth.welcome' => 'Welcome to Postfolio',
			'auth.signInSubtitle' => 'Sign in to manage your deposits securely',
			'auth.signInWithGoogle' => 'Sign in with Google',
			'auth.tryDemoMode' => 'Try Demo Mode',
			'auth.signOut' => 'Sign Out',
			'migration.title' => 'Emulator Migration Test',
			'migration.signIn' => 'Sign In',
			'migration.migrateBatch' => 'Migrate Batch',
			'migration.migrateAll' => 'Migrate All',
			'migration.deleteAll' => 'Delete All',
			'migration.summaryBatch' => ({required Object processed, required Object total, required Object migrated, required Object duplicates}) => 'Batch: ${processed}/${total}, Migrated: ${migrated}, Duplicates: ${duplicates}',
			'migration.summaryAll' => ({required Object total, required Object migrated, required Object missingCust, required Object duplicates}) => 'Total: ${total}, Migrated: ${migrated}, Missing Cust: ${missingCust}, Duplicates: ${duplicates}',
			'migration.targetUid' => 'Target User ID (UID)',
			'migration.targetUidHelper' => 'Enter your Firebase Auth UID to migrate data into your account.',
			'migration.batchSize' => 'Batch Size',
			_ => null,
		};
	}
}
