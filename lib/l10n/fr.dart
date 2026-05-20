const Map<String, String> fr = {
  'app.settings': 'Parametres',
  'app.language': 'Langue',
  'app.save': 'Enregistrer',
  'app.cancel': 'Annuler',
  'app.refresh': 'Actualiser',
  'app.error': 'Erreur',
  'nav.assignments': 'Devoirs',
  'nav.live_quiz': 'Quiz en direct',
  'pricing.title': 'Tarifs',
  'pricing.teacher_plans': 'Offres enseignants',
  'pricing.tap_to_view': 'Touchez une offre pour voir les details.',
  'pricing.note':
      'Note : cette page est informative. Les paiements/abonnements peuvent etre ajoutes plus tard.',
  'pricing.show_details': 'Afficher les details',
  'pricing.hide_details': 'Masquer les details',
  'plan.free': 'Offre gratuite',
  'plan.default': 'Offre standard',
  'plan.pro': 'Offre Pro',

  'lessons.title': 'Lecons',
  'lessons.load_failed_internet': "Impossible de charger les lecons en ligne",
  'lessons.load_failed': "Impossible de charger les lecons",
  'lessons.choose_subject': 'Choisir la matiere',
  'lessons.teacher.add_lesson': 'Ajouter une lecon',
  'lessons.teacher.archive': 'Archive des lecons',
  'lessons.teacher.strategy_guide': "Strategies d'apprentissage",
  'lessons.student.no_group.title': "Vous n'etes inscrit dans aucun groupe",
  'lessons.student.no_group.message':
      "Demandez a l'enseignant de vous ajouter a un groupe.",
  'lessons.student.empty_offline': "Aucune lecon sauvegardee hors ligne",
  'lessons.student.empty_online': "Aucune lecon disponible pour le moment",
  'lessons.archive.load_failed': "Impossible de charger l'archive",
  'lessons.archive.retry': 'Reessayer',
  'lessons.archive.empty': 'Aucune lecon pour le moment',
  'lessons.archive.offline_banner':
      'Archive telechargee (mode hors ligne).',
  'lessons.archive.offline_banner_error':
      "Impossible de charger l'archive en ligne. Affichage des lecons telechargees.",
  'lessons.archive.retry_online': 'Reessayer en ligne',
  'lessons.all_subjects': 'Toutes les matieres',
  'lessons.subject.empty': 'Aucune lecon pour cette matiere',
  'lessons.subjects.empty': 'Aucune matiere disponible',
  'lessons.lesson_fallback_title': 'Lecon',
  'lessons.subject_label': 'Matiere',
  'lessons.delete.id_missing':
      "Impossible de supprimer cette lecon: identifiant manquant",
  'lessons.delete.fallback_title': 'Cette lecon',
  'lessons.delete.title': 'Supprimer la lecon',
  'lessons.delete.confirm': 'Voulez-vous vraiment supprimer',
  'lessons.delete.action': 'Supprimer',
  'lessons.delete.success': 'Lecon supprimee',
  'lessons.delete.failed': "Impossible de supprimer la lecon",

  'lesson_select_group.title': 'Choisir un groupe',
  'lesson_select_group.confirm': 'Confirmer',
  'lesson_select_group.empty': 'Aucun groupe disponible.',
  'lesson_select_group.hint':
      'Choisissez le groupe avec lequel vous voulez partager la lecon.',
  'lesson_select_group.member_count': '{n} eleves',
  'lesson_select_group.choose': 'Selectionner ce groupe',

  'lesson_edit.title': 'Modifier la lecon',
  'lesson_edit.lesson_title': 'Titre de la lecon',
  'lesson_edit.subject': 'Matiere',
  'lesson_edit.lesson_text': 'Texte de la lecon',
  'lesson_edit.validation.title': 'Entrez un titre',
  'lesson_edit.validation.text': 'Entrez le texte de la lecon',
  'lesson_edit.saving': 'Enregistrement...',

  'teacher_lesson_strategies.title': 'Strategies des lecons',
  'teacher_lesson_strategies.load_failed': "Impossible de charger les lecons",
  'teacher_lesson_strategies.empty.title': 'Aucune lecon pour le moment',
  'teacher_lesson_strategies.empty.message':
      'Ajoutez une lecon, puis creez ses strategies.',

  'strategy_guide.title': 'Guide des strategies',

  'strategy.mind_map': 'Carte mentale',
  'strategy.timeline': 'Chronologie',
  'strategy.hierarchy': 'Hierarchie',
  'strategy.colored_cards': 'Cartes colorees',
  'strategy.comparison_table': 'Tableau comparatif',
  'strategy.triangle': 'Triangle',
  'strategy.six_hats': 'Six chapeaux',
  'strategy.journalistic_questions': 'Questions journalistiques',
  'strategy.educational_story': 'Histoire educative',
  'strategy.unsupported': 'Strategie non prise en charge',

  'strategy_desc.mind_map':
      "Organiser les idees de la lecon dans une carte mentale.",
  'strategy_desc.timeline':
      'Afficher les evenements ou idees dans une chronologie visuelle.',
  'strategy_desc.hierarchy':
      'Classer les concepts du plus simple au plus avance.',
  'strategy_desc.colored_cards':
      'Decouper le contenu en cartes courtes pour mieux memoriser.',
  'strategy_desc.comparison_table':
      'Comparer les concepts et mettre en evidences les differences.',
  'strategy_desc.triangle':
      'Expliquer un concept avec trois axes relies dans un triangle.',
  'strategy_desc.six_hats':
      'Reflechir selon plusieurs points de vue avec les six chapeaux.',
  'strategy_desc.journalistic_questions':
      'Questions (Qui, Quoi, Quand, Ou, Pourquoi, Comment) avec reponses.',
  'strategy_desc.educational_story':
      'Transformer la lecon en une courte histoire educative.',

  'lesson_strategy_editor.add_title': 'Ajouter une strategie',
  'lesson_strategy_editor.edit_title': 'Modifier la strategie',
  'lesson_strategy_editor.strategy': 'Strategie',
  'lesson_strategy_editor.custom_title': 'Titre (optionnel)',
  'lesson_strategy_editor.lesson_text': 'Texte de la lecon (coller ici)',
  'lesson_strategy_editor.generating': 'Generation...',
  'lesson_strategy_editor.create': 'Creer',
  'lesson_strategy_editor.update': 'Mettre a jour',
  'lesson_strategy_editor.note':
      'Note: une strategie JSON sera generee et enregistree pour les eleves.',
  'lesson_strategy_editor.validation.pick': 'Veuillez choisir une strategie',
  'lesson_strategy_editor.validation.text': 'Entrez le texte de la lecon',

  'strategy_json.title': 'Modification manuelle',
  'strategy_json.format': 'Formater JSON',
  'strategy_json.invalid_json': 'JSON invalide',
  'strategy_json.must_be_object': 'Le JSON doit etre un objet (Map)',
  'strategy_json.hint.type_0':
      'Carte mentale: modifiez les noeuds et liens dans le JSON.',
  'strategy_json.hint.type_5':
      'Chronologie: modifiez les elements (titre/description/ordre) dans le JSON.',
  'strategy_json.hint.type_6':
      'Hierarchie: modifiez les noeuds et enfants dans le JSON.',
  'strategy_json.hint.type_9':
      'Cartes colorees: modifiez cartes/titres/contenu dans le JSON.',
  'strategy_json.hint.type_10':
      'Tableau comparatif: modifiez colonnes/lignes/cellules dans le JSON.',
  'strategy_json.hint.type_11':
      'Triangle: modifiez les parties du triangle dans le JSON.',
  'strategy_json.hint.type_13':
      'Questions journalistiques: modifiez questions et reponses (qui/quoi/quand/ou/pourquoi/comment).',
  'strategy_json.hint.type_14':
      'Histoire educative: modifiez titre, personnages, evenements et resume.',
  'strategy_json.hint.default': 'Modifiez le JSON puis enregistrez.',

  'lesson_view.offline.save': 'Sauvegarder hors ligne',
  'lesson_view.offline.remove': 'Retirer hors ligne',
  'lesson_view.offline.saved': 'Lecon sauvegardee ({n} strategies).',
  'lesson_view.offline.save_failed': 'Impossible de sauvegarder hors ligne',
  'lesson_view.offline.removed': 'Telechargement hors ligne retire',
  'lesson_view.offline.remove_failed': 'Impossible de retirer hors ligne',
  'lesson_view.strategies.offline_banner':
      'Affichage des strategies sauvegardees (hors ligne).',
  'lesson_view.strategies.offline_banner_error':
      "Impossible de charger en ligne. Affichage des donnees sauvegardees.",
  'lesson_view.strategies.load_failed': 'Impossible de charger les strategies',
  'lesson_view.strategies.empty':
      "Aucune strategie ou contenu pour cette lecon",
  'lesson_view.more': 'Plus',
  'lesson_view.edit_json': 'Modification manuelle (JSON)',
  'lesson_view.strategy_delete.title': 'Supprimer la strategie ?',
  'lesson_view.strategy_delete.warning':
      "Elle sera supprimee et n'apparaitra plus pour les eleves.",
  'lesson_view.strategy_delete.action': 'Supprimer',

  'subject.math': 'Mathematiques',
  'subject.physics': 'Physique',
  'subject.chemistry': 'Chimie',
  'subject.natural_sciences': 'Sciences naturelles',
  'subject.history': 'Histoire',
  'subject.geography': 'Geographie',
  'subject.philosophy': 'Philosophie',
  'subject.arabic': 'Arabe',
  'subject.french': 'Francais',
  'subject.english': 'Anglais',
};
