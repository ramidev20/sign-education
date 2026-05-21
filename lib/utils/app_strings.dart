import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sign_education/pages/local_provider.dart';
import 'package:sign_education/l10n/ar.dart' as l10n_ar;
import 'package:sign_education/l10n/en.dart' as l10n_en;
import 'package:sign_education/l10n/fr.dart' as l10n_fr;

class AppStrings {
  AppStrings(this._languageCode);

  final String _languageCode;
  late final Map<String, String> _map = () {
    if (_languageCode == 'ar') return l10n_ar.ar;
    if (_languageCode == 'fr') return l10n_fr.fr;
    return l10n_en.en;
  }();

  bool get isArabic => _languageCode == 'ar';
  bool get isFrench => _languageCode == 'fr';

  static AppStrings of(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    return AppStrings(localeProvider.locale.languageCode);
  }

  static AppStrings read(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    return AppStrings(localeProvider.locale.languageCode);
  }

  String _t(String ar, String en, String fr) {
    if (isArabic) return ar;
    if (isFrench) return fr;
    return en;
  }

  String text(String ar, String en, String fr) => _t(ar, en, fr);

  String tr(String key) => _map[key] ?? key;

  String get profile => _t('الملف الشخصي', 'Profile', 'Profil');
  String get editProfile => _t('تعديل الملف الشخصي', 'Edit profile', 'Modifier le profil');
  String get editProfileAction => _t('تعديل', 'Edit', 'Modifier');
  String get closeEditMode => _t('إغلاق وضع التعديل', 'Close edit mode', 'Fermer le mode edition');
  String get saveChanges => _t('حفظ التغييرات', 'Save changes', 'Enregistrer les modifications');
  String get settings => _t('الإعدادات', 'Settings', 'Parametres');
  String get language => _t('اللغة', 'Language', 'Langue');
  String get appTheme => _t('الوضع الليلي', 'Dark mode', 'Mode sombre');
  String get logout => _t('تسجيل الخروج', 'Log out', 'Se deconnecter');
  String get profileSettingsSubtitle => _t(
    'عرض وتعديل معلومات الحساب',
    'View and edit account information',
    'Afficher et modifier les informations du compte',
  );
  String get languageSubtitle => _t(
    'تغيير لغة التطبيق',
    'Change app language',
    "Changer la langue de l'application",
  );
  String get themeSubtitle => _t(
    'تفعيل أو إلغاء الوضع الليلي',
    'Turn dark mode on or off',
    'Activer ou desactiver le mode sombre',
  );
  String get selectLanguage => _t('اختر اللغة', 'Choose language', 'Choisir la langue');
  String get teacher => _t('معلم', 'Teacher', 'Enseignant');
  String get student => _t('طالب', 'Student', 'Eleve');
  String get user => _t('مستخدم', 'User', 'Utilisateur');
  String get points => _t('النقاط', 'Points', 'Points');
  String get joinedOn => _t('منذ', 'Joined', 'Inscrit');
  String get teacherInfo => _t('معلومات المعلم', 'Teacher info', "Informations de l'enseignant");
  String get studentInfo => _t('معلومات الطالب', 'Student info', "Informations de l'eleve");
  String get taughtSubjects => _t('المواد التي يدرسها', 'Subjects taught', 'Matieres enseignees');
  String get academicLevel => _t('المستوى الدراسي', 'Level', 'Niveau');
  String get branch => _t('الشعبة', 'Branch', 'Filiere');
  String get group => _t('المجموعة', 'Group', 'Groupe');
  String get sharedInfo => _t('معلومات عامة', 'General info', 'Informations generales');
  String get phone => _t('رقم الهاتف', 'Phone', 'Telephone');
  String get bio => _t('نبذة', 'Bio', 'Bio');
  String get schoolName => _t('اسم المؤسسة', 'School name', "Nom de l'etablissement");
  String get city => _t('المدينة', 'City', 'Ville');
  String get specialization => _t('التخصص', 'Specialization', 'Specialisation');
  String get yearsExperience => _t('سنوات الخبرة', 'Years of experience', "Annees d'experience");
  String get officeHours => _t('ساعات التواصل', 'Office hours', 'Heures de disponibilite');
  String get guardianName => _t('اسم الولي', 'Guardian name', 'Nom du tuteur');
  String get guardianPhone => _t('هاتف الولي', 'Guardian phone', 'Telephone du tuteur');
  String get studentNumber => _t('رقم الطالب', 'Student number', "Numero de l'eleve");
  String get fullName => _t('الاسم الكامل', 'Full name', 'Nom complet');
  String get email => _t('البريد الإلكتروني', 'Email', 'Email');
  String get requiredName => _t('الاسم مطلوب', 'Name is required', 'Le nom est requis');
  String get changesSaved => _t('تم حفظ التغييرات', 'Changes saved', 'Modifications enregistrees');
  String get saveFailed => _t('تعذر حفظ التغييرات', 'Could not save changes', "Impossible d'enregistrer les modifications");
  String get lessons => _t('الدروس', 'Lessons', 'Lecons');
  String get assignments => _t('الواجبات', 'Assignments', 'Devoirs');
  String get chats => _t('المحادثات', 'Chats', 'Discussions');
  String get localeHomeLabel => _t('الرئيسية', 'Home', 'Accueil');
  String get platformTitle => _t('المنصة التعليمية', 'Learning Platform', 'Plateforme educative');
  String get welcomeBack => _t('مرحباً بعودتك', 'Welcome back', 'Bon retour');
  String get signInContinue => _t('سجّل الدخول للمتابعة', 'Sign in to continue', 'Connectez-vous pour continuer');
  String get emailInvalid => _t('أدخل بريداً إلكترونياً صالحاً', 'Enter a valid email address', 'Entrez une adresse email valide');
  String get password => _t('كلمة المرور', 'Password', 'Mot de passe');
  String get passwordMin => _t('الحد الأدنى 6 أحرف', 'Minimum 6 characters', 'Minimum 6 caracteres');
  String get signIn => _t('تسجيل الدخول', 'Sign in', 'Se connecter');
  String get signInWithGoogle => _t('تسجيل الدخول باستخدام Google', 'Continue with Google', 'Continuer avec Google');
  String get noAccountCreate => _t('لا تملك حساباً؟ أنشئ حساباً', "Don't have an account? Create one", "Vous n'avez pas de compte ? Creez-en un");
  String loginCompleteError(Object e) => _t('تعذر إكمال تسجيل الدخول: $e', 'Could not complete sign-in: $e', 'Connexion impossible : $e');
  String get userProfileNotFound => _t('لم يتم العثور على الملف الشخصي للمستخدم.', 'User profile was not found.', "Le profil utilisateur est introuvable.");
  String get invalidCredentials => _t('البريد الإلكتروني أو كلمة المرور غير صحيحة.', 'Incorrect email or password.', 'Email ou mot de passe incorrect.');
  String authWarning(String message) => _t('تنبيه: $message', 'Warning: $message', 'Alerte : $message');
  String unexpectedError(Object e) => _t('خطأ غير متوقع: $e', 'Unexpected error: $e', 'Erreur inattendue : $e');
  String googleSignInError(Object e) => _t('تعذر تسجيل الدخول عبر Google: $e', 'Google sign-in failed: $e', 'Connexion Google impossible : $e');
  String get aboutPageTitle => _t('من نحن - منصة الإشارة التعليمية', 'About Us - EduBridge', 'A propos - EduBridge');
  String get aboutVision => _t('الرؤية', 'Vision', 'Vision');
  String get aboutMission => _t('الرسالة', 'Mission', 'Mission');
  String get aboutWhatMakesUsDifferent => _t('ما الذي يميزنا؟', 'What makes us different?', 'Qu est-ce qui nous distingue ?');
  String get aboutWhoIsItFor => _t('لمن صُممت المنصة؟', 'Who is the platform for?', 'A qui est destinee la plateforme ?');
  String get aboutTeam => _t('فريق العمل', 'Team', 'Equipe');
  String get aboutHeroText => _t(
    'تعليم لغة الإشارة بأسلوب تفاعلي حديث، مع أدوات ذكية تساعد المعلم والطالب على التقدم بشكل واضح.',
    'Modern interactive sign-language learning with smart tools that help teachers and students progress clearly.',
    "Apprentissage moderne et interactif de la langue des signes avec des outils intelligents pour aider enseignants et eleves a progresser clairement.",
  );
  String get aboutVisionText => _t(
    'نحو تجربة تعليمية عربية شاملة تجعل لغة الإشارة جزءاً طبيعياً من الصف الدراسي.',
    'Toward an inclusive Arabic learning experience where sign language is a natural part of the classroom.',
    'Vers une experience educative inclusive ou la langue des signes fait naturellement partie de la classe.',
  );
  String get aboutMissionText => _t(
    'نساعد المعلم والطالب على التعلم بالممارسة عبر الدروس، الاستراتيجيات، الواجبات، والتفاعل المستمر.',
    'We help teachers and students learn by doing through lessons, strategies, assignments, and continuous interaction.',
    "Nous aidons les enseignants et les eleves a apprendre par la pratique grace aux lecons, strategies, devoirs et interactions continues.",
  );
  String get aboutDifferentiatorText => _t(
    'استراتيجيات قابلة للتحرير، واجبات ديناميكية، ودعم للتعلم دون اتصال ضمن تطبيق واحد.',
    'Editable strategies, dynamic assignments, and offline-friendly learning support in one app.',
    'Strategies modifiables, devoirs dynamiques et apprentissage hors ligne dans une seule application.',
  );
  String get aboutAudienceText => _t(
    'للمعلمين، الطلاب، والمؤسسات التعليمية التي تحتاج أدوات عملية وحديثة لتعليم لغة الإشارة.',
    'For teachers, students, and institutions that need practical modern tools for teaching sign language.',
    'Pour les enseignants, les eleves et les institutions qui ont besoin d outils modernes et pratiques pour enseigner la langue des signes.',
  );
  String get aboutTeamText => _t(
    'فريق يجمع بين التربية والتقنية والتصميم، ويتعاون مع مختصين في التربية الخاصة ومجتمع الصم.',
    'A team blending education, technology, and design, working with specialists in special education and the Deaf community.',
    'Une equipe qui reunit education, technologie et design, en collaboration avec des specialistes et la communaute sourde.',
  );
  String get interactiveLessonsChip => _t('دروس تفاعلية', 'Interactive lessons', 'Lecons interactives');
  String get smartStrategiesChip => _t('استراتيجيات ذكية', 'Smart strategies', 'Strategies intelligentes');
  String get dynamicAssignmentsChip => _t('واجبات ديناميكية', 'Dynamic assignments', 'Devoirs dynamiques');
  String get latestUpdates => _t('آخر التحديثات', 'Latest updates', 'Dernieres mises a jour');
  String get updatesStrategyEditorsTitle => _t('تحسين محررات الاستراتيجيات', 'Strategy editors improved', 'Editeurs de strategies ameliores');
  String get updatesStrategyEditorsDate => _t('18 أبريل 2026', 'April 18, 2026', '18 avril 2026');
  String get updatesStrategyEditorsDesc => _t('تحسينات على العرض البصري، الترتيب الذكي، ودعم أفضل للمخططات.', 'Visual improvements, smarter ordering, and better diagram support.', 'Ameliorations visuelles, tri intelligent et meilleur support des diagrammes.');
  String get updatesLessonsTitle => _t('تحسين تجربة الدروس', 'Lesson experience improved', 'Experience des lecons amelioree');
  String get updatesLessonsDate => _t('16 أبريل 2026', 'April 16, 2026', '16 avril 2026');
  String get updatesLessonsDesc => _t('تحديثات على واجهة المعلم والطالب لتسهيل الوصول للدروس والاستراتيجيات.', 'Teacher and student interface updates for easier access to lessons and strategies.', "Mises a jour des interfaces enseignant et eleve pour acceder plus facilement aux lecons et strategies.");
  String get updatesThemeTitle => _t('تطوير الأداء والثيم', 'Performance and theme upgrades', 'Ameliorations de performance et du theme');
  String get updatesThemeDate => _t('10 أبريل 2026', 'April 10, 2026', '10 avril 2026');
  String get updatesThemeDesc => _t('تحسين التوافق مع الوضع الداكن وتنعيم الانتقالات داخل التطبيق.', 'Better dark mode support and smoother transitions across the app.', 'Meilleure prise en charge du mode sombre et transitions plus fluides dans l application.');
  String get signDictionary => _t('قاموس لغة الإشارة', 'Sign language dictionary', 'Dictionnaire de la langue des signes');
  String get searchForWord => _t('ابحث عن كلمة', 'Search for a word', 'Rechercher un mot');
  String get noWordsFound => _t('لا توجد كلمات', 'No words found', 'Aucun mot trouve');
  String get easy => _t('سهل', 'Easy', 'Facile');
  String get medium => _t('متوسط', 'Medium', 'Moyen');
  String get hard => _t('صعب', 'Hard', 'Difficile');
  String get myGroups => _t('مجموعاتي', 'My groups', 'Mes groupes');
  String get noGroupsYet => _t('لا توجد مجموعات بعد', 'No groups yet', 'Aucun groupe pour le moment');
  String get teacherNoGroupsMessage => _t('أنشئ مجموعة وابدأ المحادثات مع طلابك.', 'Create a group and start chatting with your students.', 'Creez un groupe et commencez a discuter avec vos eleves.');
  String get studentNoGroupsMessage => _t('سيتم إضافتك إلى المجموعات من طرف المعلم.', 'Your teacher will add you to groups.', "Votre enseignant vous ajoutera a des groupes.");
  String get refresh => _t('تحديث', 'Refresh', 'Actualiser');
  String get noMessagesYet => _t('لا توجد رسائل بعد', 'No messages yet', 'Pas encore de messages');
  String get learningTypes => _t('أنواع التعلم', 'Learning types', "Types d'apprentissage");
  String get adSpace => _t('مساحة إعلانية', 'Ad space', 'Espace publicitaire');
  String get adDetails => _t('تفاصيل', 'Details', 'Details');
  String get adsSoon => _t('سيتم تفعيل إدارة الإعلانات قريباً.', 'Ad management will be enabled soon.', 'La gestion des annonces sera bientot activee.');
  String get liveQuiz => _t('اختبار مباشر', 'Live quiz', 'Quiz en direct');
  String get educationalAd => _t('إعلان تعليمي', 'Educational ad', 'Annonce educative');
  String get educationalAdDesc => _t('روّج لدورتك أو محتواك التعليمي داخل المنصة.', 'Promote your course or educational content inside the platform.', 'Faites la promotion de votre cours ou contenu educatif sur la plateforme.');
  String get sponsoredContent => _t('رعاية المحتوى', 'Sponsored content', 'Contenu sponsorise');
  String get sponsoredContentDesc => _t('مساحات رعاية للمدارس والمبادرات التعليمية.', 'Sponsored spaces for schools and educational initiatives.', 'Espaces sponsorises pour les ecoles et initiatives educatives.');
  String get languageArabicNative => 'العربية';
  String get languageEnglishNative => 'English';
  String get languageFrenchNative => 'Français';
  String get languageCurrentLabel => _t('اللغة الحالية', 'Current language', 'Langue actuelle');
  String get languageFrench => _t('الفرنسية', 'French', 'Francais');
  String get editProfileDetails => _t('تعديل المعلومات', 'Edit details', 'Modifier les informations');
  String get viewProfileDetails => _t('معلومات الحساب', 'Account details', 'Informations du compte');
  String get save => _t('حفظ', 'Save', 'Enregistrer');
  String get cancel => _t('إلغاء', 'Cancel', 'Annuler');
  String get profileUpdated => _t('تم تحديث الملف الشخصي', 'Profile updated', 'Profil mis a jour');

  String languageNameForCode(String code) {
    switch (code) {
      case 'ar':
        return languageArabicNative;
      case 'fr':
        return languageFrenchNative;
      default:
        return languageEnglishNative;
    }
  }
}
