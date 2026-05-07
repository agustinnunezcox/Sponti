import 'package:flutter/material.dart';

/// Minimal bilingual string table. Extend when new screens need translation.
class AppStrings {
  const AppStrings._();

  static final _locale = ValueNotifier<Locale>(const Locale('es'));

  static ValueNotifier<Locale> get localeNotifier => _locale;

  static void setLanguage(String language) {
    _locale.value =
        language == 'English' ? const Locale('en') : const Locale('es');
  }

  static AppStrings get current =>
      _locale.value.languageCode == 'en' ? _en : _es;

  static const _es = AppStrings._();
  static const _en = _EnStrings();

  // ── Bottom nav ──────────────────────────────────────────────────────────────
  String get navPlans   => 'Planes';
  String get navMap     => 'Mapa';
  String get navProfile => 'Perfil';

  // ── HomeScreen ──────────────────────────────────────────────────────────────
  String get todayLabel      => 'Hoy';
  String get noPlansTitle    => 'No hay planes por aquí';
  String get noPlansSubtitle => '¡Sé el primero en crear uno!';

  // ── ProfileScreen ───────────────────────────────────────────────────────────
  String get myInterests  => 'Mis intereses';
  String get editLabel    => 'Editar';
  String get recentPlans  => 'Planes recientes';
  String get menuGroups   => 'Mis grupos';
  String get menuSettings => 'Configuración';
  String get menuSignOut  => 'Cerrar sesión';
  String get addWhatsapp  => 'Agregar teléfono WhatsApp';

  // ── GroupsScreen ────────────────────────────────────────────────────────────
  String get tabGroups  => 'Grupos';
  String get tabMyPlans => 'Mis Planes';
  String get waitingQuorum  => 'Esperando quorum';
  String get confirming     => 'Confirmando…';
  String get confirmed      => 'Confirmado';

  // ── SettingsScreen ──────────────────────────────────────────────────────────
  String get settingsTitle         => 'Configuración';
  String get sectionProfile        => 'PERFIL';
  String get sectionInterests      => 'INTERESES';
  String get sectionWhatsapp       => 'WHATSAPP';
  String get sectionNotifications  => 'NOTIFICACIONES';
  String get sectionLanguage       => 'IDIOMA';
  String get sectionAccount        => 'CUENTA';
  String get saveProfile           => 'Guardar perfil';
  String get saveInterests         => 'Guardar intereses';
  String get savePhone             => 'Guardar teléfono';
  String get interestsHint         => 'Selecciona todo lo que te gusta hacer';
  String get phoneHint             =>
      'Tu número recibe notificaciones cuando un plan se confirma.';
  String get notificationsLabel    => 'Activar notificaciones';
  String get notificationsSubtitle => 'Recibe alertas de planes y quorum';
  String get deleteAccount         => 'Eliminar cuenta';
  String get deleteAccountBody     =>
      'Esta acción no se puede deshacer. Todos tus datos serán eliminados permanentemente.';
  String get cancel => 'Cancelar';
  String get delete => 'Eliminar';

  // ── PlanDetailScreen ────────────────────────────────────────────────────────
  String get descriptionLabel      => 'Descripción';
  String get quorumLabel           => 'Quorum';
  String get participantsLabel     => 'Participantes';
  String get dateLabel             => 'Fecha';
  String get timeLabel             => 'Hora';
  String get priceLabel            => 'Precio';
  String get peopleLabel           => 'Personas';
  String get reserveButton         => 'Reservar';
  String get reservedButton        => '¡Reservado! Solo se cobra al confirmar';
  String get onlyChargedIfConfirmed => 'Solo se cobra si el plan se confirma';
}

class _EnStrings extends AppStrings {
  const _EnStrings() : super._();

  @override String get navPlans   => 'Plans';
  @override String get navMap     => 'Map';
  @override String get navProfile => 'Profile';

  @override String get todayLabel      => 'Today';
  @override String get noPlansTitle    => 'No plans around here';
  @override String get noPlansSubtitle => 'Be the first to create one!';

  @override String get myInterests  => 'My interests';
  @override String get editLabel    => 'Edit';
  @override String get recentPlans  => 'Recent plans';
  @override String get menuGroups   => 'My groups';
  @override String get menuSettings => 'Settings';
  @override String get menuSignOut  => 'Sign out';
  @override String get addWhatsapp  => 'Add WhatsApp number';

  @override String get tabGroups  => 'Groups';
  @override String get tabMyPlans => 'My Plans';
  @override String get waitingQuorum => 'Waiting for quorum';
  @override String get confirming    => 'Confirming…';
  @override String get confirmed     => 'Confirmed';

  @override String get settingsTitle         => 'Settings';
  @override String get sectionProfile        => 'PROFILE';
  @override String get sectionInterests      => 'INTERESTS';
  @override String get sectionWhatsapp       => 'WHATSAPP';
  @override String get sectionNotifications  => 'NOTIFICATIONS';
  @override String get sectionLanguage       => 'LANGUAGE';
  @override String get sectionAccount        => 'ACCOUNT';
  @override String get saveProfile           => 'Save profile';
  @override String get saveInterests         => 'Save interests';
  @override String get savePhone             => 'Save phone';
  @override String get interestsHint         => 'Select everything you enjoy doing';
  @override String get phoneHint             =>
      'Your number receives notifications when a plan is confirmed.';
  @override String get notificationsLabel    => 'Enable notifications';
  @override String get notificationsSubtitle => 'Receive plan and quorum alerts';
  @override String get deleteAccount         => 'Delete account';
  @override String get deleteAccountBody     =>
      'This action cannot be undone. All your data will be permanently deleted.';
  @override String get cancel => 'Cancel';
  @override String get delete => 'Delete';

  @override String get descriptionLabel      => 'Description';
  @override String get quorumLabel           => 'Quorum';
  @override String get participantsLabel     => 'Participants';
  @override String get dateLabel             => 'Date';
  @override String get timeLabel             => 'Time';
  @override String get priceLabel            => 'Price';
  @override String get peopleLabel           => 'People';
  @override String get reserveButton         => 'Reserve';
  @override String get reservedButton        => 'Reserved! Only charged on confirmation';
  @override String get onlyChargedIfConfirmed => 'Only charged if the plan is confirmed';
}
