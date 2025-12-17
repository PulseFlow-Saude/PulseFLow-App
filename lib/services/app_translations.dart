import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'pt_BR': {
          'menu_home': 'Início',
          'menu_history': 'Históricos',
          'menu_records': 'Registros',
          'menu_appointments': 'Consultas',
          'menu_pulse_key': 'Pulse Key',
          'menu_profile': 'Perfil',
          'menu_settings': 'Configurações',
          'menu_institutional': 'Institucional',
          'inst_about_title': 'Sobre nós',
          'inst_about_subtitle': 'Conheça o ecossistema PulseFlow',
          'inst_about_intro':
              'Cuidar da sua saúde de forma integrada é a nossa missão. Centralizamos informações clínicas, registros e alertas para que famílias e profissionais acompanhem o bem-estar em tempo real.',
          'inst_about_approach': 'Nossa abordagem',
          'inst_about_approach_desc':
              'Tecnologia centrada no paciente, dados em tempo real e segurança ponta a ponta durante toda a jornada digital.',
          'inst_about_team': 'Nossa equipe',
          'inst_about_team_desc':
              'Especialistas em saúde, engenharia e experiência do usuário trabalhando juntos para entregar acolhimento com alto padrão.',
          'inst_about_vision': 'Nossa visão',
          'inst_about_vision_desc':
              'Transformar dados em decisões inteligentes, conectando pessoas, clínicas e dispositivos em uma única plataforma.',
          'inst_faq_title': 'Perguntas frequentes',
          'inst_faq_subtitle': 'As dúvidas mais comuns sobre o PulseFlow',
          'inst_faq_q1': 'Como funciona o PulseFlow?',
          'inst_faq_a1':
              'Conectamos registros clínicos, sinais vitais e lembretes em uma única experiência para monitoramento em tempo real.',
          'inst_faq_q2': 'Meus dados estão seguros?',
          'inst_faq_a2':
              'Aplicamos criptografia ponta a ponta, autenticação reforçada e auditoria de acessos. Você consulta todo o histórico na área de segurança.',
          'inst_faq_q3': 'Consigo compartilhar informações com meu médico?',
          'inst_faq_a3':
              'Sim. Gere uma Pulse Key temporária ou convide profissionais para acessar relatórios específicos quando quiser.',
          'inst_faq_q4': 'Preciso estar online?',
          'inst_faq_a4':
              'Alguns módulos funcionam offline. Assim que a conexão retorna, sincronizamos os registros pendentes.',
          'inst_security_title': 'Segurança e privacidade',
          'inst_security_subtitle': 'Protocolos que protegem seus dados',
          'inst_security_card1': 'Criptografia',
          'inst_security_card1_desc':
              'Todo o tráfego utiliza TLS 1.3 e os dados são armazenados com criptografia AES-256.',
          'inst_security_card2': 'Controle de acesso',
          'inst_security_card2_desc':
              'Você decide quem pode visualizar ou editar informações e revoga o acesso instantaneamente.',
          'inst_security_card3': 'Conformidade',
          'inst_security_card3_desc':
              'Operamos alinhados à LGPD e às melhores práticas internacionais, com auditorias recorrentes.',
          'inst_security_card4': 'Alertas proativos',
          'inst_security_card4_desc':
              'Receba notificações quando um dispositivo ou profissional agir fora do padrão.',
          'inst_contact_title': 'Fale conosco',
          'inst_contact_subtitle': 'Canais oficiais de suporte e relacionamento',
          'inst_contact_support': 'Central de suporte',
          'inst_contact_support_desc': 'Responderemos em até 24 horas úteis.',
          'inst_contact_whatsapp': 'WhatsApp',
          'inst_contact_whatsapp_desc': 'Segunda a sexta, das 8h às 18h.',
          'inst_contact_phone': 'Telefone',
          'inst_contact_phone_desc': 'Plantão 24/7 para emergências.',
          'inst_contact_address': 'Endereço',
          'inst_contact_address_desc': 'Atendemos mediante agendamento.',
          'inst_privacy_title': 'Política de privacidade',
          'inst_privacy_subtitle': 'Veja como protegemos e tratamos seus dados',
          'inst_privacy_collect': 'Coleta de dados',
          'inst_privacy_collect_desc':
              'Utilizamos apenas dados necessários e você pode exportar ou excluir tudo na área de segurança.',
          'inst_privacy_share': 'Compartilhamento',
          'inst_privacy_share_desc':
              'Não vendemos dados. Compartilhamos apenas com profissionais autorizados ou para cumprir exigências legais.',
          'inst_privacy_store': 'Armazenamento',
          'inst_privacy_store_desc':
              'Servidores no Brasil com redundância em múltiplas zonas e backups diários criptografados.',
          'inst_privacy_rights': 'Direitos do titular',
          'inst_privacy_rights_desc':
              'Solicite correção, portabilidade ou exclusão quando quiser. Respondemos pelo canal de privacidade.',
          'inst_version_title': 'Versão do app',
          'inst_version_subtitle': 'Detalhes da release instalada e novidades',
          'inst_version_notes': 'Notas da versão',
          'inst_version_note1': 'Melhorias de estabilidade e sincronização de dispositivos.',
          'inst_version_note2': 'Novo painel institucional disponível no menu lateral.',
          'inst_version_note3': 'Correções no fluxo de notificações em tempo real.',
          'inst_version_last_update': 'Última atualização: @year',
          'inst_settings_title': 'Configurações',
          'inst_settings_subtitle':
              'Personalize notificações, privacidade e experiência',
          'inst_settings_section_notifications': 'Notificações e alertas',
          'inst_settings_alerts_label': 'Alertas críticos',
          'inst_settings_alerts_desc':
              'Avisos imediatos sobre variações importantes nos sinais vitais.',
          'inst_settings_daily_label': 'Resumo diário',
          'inst_settings_daily_desc':
              'Boletim com registros, consultas e lembretes do dia.',
          'inst_settings_smart_label': 'Lembretes inteligentes',
          'inst_settings_smart_desc':
              'Sugestões de hábitos e medicamentos com base no seu histórico.',
          'inst_settings_section_privacy': 'Privacidade e compartilhamento',
          'inst_settings_visibility_label': 'Visibilidade dos dados',
          'inst_settings_visibility_desc':
              'Defina quais módulos ficam acessíveis para convidados e médicos.',
          'inst_settings_access_label': 'Alertas de acesso',
          'inst_settings_access_desc':
              'Receba um e-mail quando alguém visualizar seus registros.',
          'inst_settings_section_experience': 'Experiência',
          'inst_settings_theme_label': 'Tema escuro',
          'inst_settings_theme_desc':
              'Ajuste o contraste do PulseFlow para ambientes com baixa luz.',
          'inst_settings_language_label': 'Idioma',
          'inst_settings_language_desc':
              'Escolha o idioma preferido para menus e alertas.',
          'inst_settings_language_pt': 'Português (BR)',
          'inst_settings_language_en': 'English',
          'inst_settings_section_account': 'Conta e segurança',
          'inst_settings_delete_label': 'Excluir conta',
          'inst_settings_delete_desc':
              'Remove definitivamente seu perfil, históricos e notificações.',
          'inst_settings_delete_button': 'Excluir minha conta',
          'inst_settings_delete_loading': 'Excluindo...',
          'inst_settings_delete_confirm_title': 'Excluir conta',
          'inst_settings_delete_confirm_desc':
              'Esta ação é permanente e não pode ser desfeita. Deseja continuar?',
          'inst_settings_delete_confirm_cancel': 'Cancelar',
          'inst_settings_delete_confirm_action': 'Excluir',
          'inst_settings_delete_success_title': 'Conta excluída',
          'inst_settings_delete_success_message': 'Seu perfil foi removido com sucesso.',
          'inst_settings_delete_error_title': 'Não foi possível excluir',
          'inst_settings_delete_error_message': 'Tente novamente em instantes.',
        },
        'en_US': {
          'menu_home': 'Home',
          'menu_history': 'History',
          'menu_records': 'Records',
          'menu_appointments': 'Appointments',
          'menu_pulse_key': 'Pulse Key',
          'menu_profile': 'Profile',
          'menu_settings': 'Settings',
          'menu_institutional': 'Institutional',
          'inst_about_title': 'About us',
          'inst_about_subtitle': 'Meet the PulseFlow ecosystem',
          'inst_about_intro':
              'Taking care of your health in an integrated way is our mission. We centralize medical records, logs and alerts so families and professionals can track well-being in real time.',
          'inst_about_approach': 'Our approach',
          'inst_about_approach_desc':
              'Patient-centered technology, real-time data and end-to-end security throughout the digital care journey.',
          'inst_about_team': 'Our team',
          'inst_about_team_desc':
              'Health, engineering and UX specialists working together to deliver a high-standard, welcoming experience.',
          'inst_about_vision': 'Our vision',
          'inst_about_vision_desc':
              'Turn data into intelligent decisions, connecting people, clinics and devices in a single platform.',
          'inst_faq_title': 'Frequently asked questions',
          'inst_faq_subtitle': 'Common doubts about PulseFlow',
          'inst_faq_q1': 'How does PulseFlow work?',
          'inst_faq_a1':
              'We connect medical records, vital signs and reminders into one experience for real-time monitoring.',
          'inst_faq_q2': 'Are my data secure?',
          'inst_faq_a2':
              'We apply end-to-end encryption, strong authentication and access auditing. You can review the history in the security area.',
          'inst_faq_q3': 'Can I share information with my doctor?',
          'inst_faq_a3':
              'Yes. Generate a temporary Pulse Key or invite professionals to access specific reports whenever you want.',
          'inst_faq_q4': 'Do I need to be online?',
          'inst_faq_a4':
              'Some modules work offline. When the connection returns, pending records are synchronized automatically.',
          'inst_security_title': 'Security and privacy',
          'inst_security_subtitle': 'Protocols that protect your data',
          'inst_security_card1': 'Encryption',
          'inst_security_card1_desc':
              'All traffic uses TLS 1.3 and data are stored with AES-256 encryption.',
          'inst_security_card2': 'Access control',
          'inst_security_card2_desc':
              'You decide who can view or edit information and revoke access instantly.',
          'inst_security_card3': 'Compliance',
          'inst_security_card3_desc':
              'We operate aligned with LGPD and international best practices, with recurring audits.',
          'inst_security_card4': 'Proactive alerts',
          'inst_security_card4_desc':
              'Receive notifications whenever a device or professional behaves outside the standard.',
          'inst_contact_title': 'Contact us',
          'inst_contact_subtitle': 'Official support and relationship channels',
          'inst_contact_support': 'Support center',
          'inst_contact_support_desc': 'We reply within 24 business hours.',
          'inst_contact_whatsapp': 'WhatsApp',
          'inst_contact_whatsapp_desc': 'Monday to Friday, 8am to 6pm.',
          'inst_contact_phone': 'Phone',
          'inst_contact_phone_desc': '24/7 on-call for emergencies.',
          'inst_contact_address': 'Address',
          'inst_contact_address_desc': 'Attendance upon appointment.',
          'inst_privacy_title': 'Privacy policy',
          'inst_privacy_subtitle': 'See how we protect and treat your data',
          'inst_privacy_collect': 'Data collection',
          'inst_privacy_collect_desc':
              'We use only the data required for monitoring. You can export or delete everything in the security area.',
          'inst_privacy_share': 'Sharing',
          'inst_privacy_share_desc':
              'We do not sell data. We only share with authorized professionals or to comply with legal requirements.',
          'inst_privacy_store': 'Storage',
          'inst_privacy_store_desc':
              'Servers located in Brazil with multi-zone redundancy and encrypted daily backups.',
          'inst_privacy_rights': 'Data subject rights',
          'inst_privacy_rights_desc':
              'Request correction, portability or deletion whenever you want through the privacy channel.',
          'inst_version_title': 'App version',
          'inst_version_subtitle': 'Installed release details and news',
          'inst_version_notes': 'Release notes',
          'inst_version_note1': 'Stability improvements and better device sync.',
          'inst_version_note2': 'New institutional hub available in the side menu.',
          'inst_version_note3': 'Fixes for the real-time notification flow.',
          'inst_version_last_update': 'Last update: @year',
          'inst_settings_title': 'Settings',
          'inst_settings_subtitle': 'Customize notifications, privacy and experience',
          'inst_settings_section_notifications': 'Notifications & alerts',
          'inst_settings_alerts_label': 'Critical alerts',
          'inst_settings_alerts_desc':
              'Immediate warnings about important changes in vital signs.',
          'inst_settings_daily_label': 'Daily summary',
          'inst_settings_daily_desc':
              'A report with your records, appointments and reminders for the day.',
          'inst_settings_smart_label': 'Smart reminders',
          'inst_settings_smart_desc':
              'Habit and medication suggestions based on your history.',
          'inst_settings_section_privacy': 'Privacy & sharing',
          'inst_settings_visibility_label': 'Data visibility',
          'inst_settings_visibility_desc':
              'Decide which modules are visible to guests and doctors.',
          'inst_settings_access_label': 'Access alerts',
          'inst_settings_access_desc':
              'Receive an e-mail when someone views your records.',
          'inst_settings_section_experience': 'Experience',
          'inst_settings_theme_label': 'Dark theme',
          'inst_settings_theme_desc':
              'Adjust PulseFlow’s contrast for low-light environments.',
          'inst_settings_language_label': 'Language',
          'inst_settings_language_desc':
              'Select your preferred language for menus and alerts.',
          'inst_settings_language_pt': 'Portuguese (BR)',
          'inst_settings_language_en': 'English',
          'inst_settings_section_account': 'Account & security',
          'inst_settings_delete_label': 'Delete account',
          'inst_settings_delete_desc':
              'Permanently removes your profile, history and notifications.',
          'inst_settings_delete_button': 'Delete my account',
          'inst_settings_delete_loading': 'Deleting...',
          'inst_settings_delete_confirm_title': 'Delete account',
          'inst_settings_delete_confirm_desc':
              'This action is permanent and cannot be undone. Do you want to proceed?',
          'inst_settings_delete_confirm_cancel': 'Cancel',
          'inst_settings_delete_confirm_action': 'Delete',
          'inst_settings_delete_success_title': 'Account deleted',
          'inst_settings_delete_success_message': 'Your profile was removed successfully.',
          'inst_settings_delete_error_title': 'Unable to delete',
          'inst_settings_delete_error_message': 'Please try again in a moment.',
        },
      };
}

