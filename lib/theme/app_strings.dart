/// BJBank Design System Strings
/// All user-facing text strings centralized here
class AppStrings {
  AppStrings._();

  // ─── App ───
  static const String appName = 'BJBank';
  static const String appTagline = 'Quantum Security';
  static const String appVersion = '1.0.0';

  // ─── Assets ───
  static const String logo = 'assets/logo.png';
  static const String logoAsset = 'assets/logo_bjbank.png';
  static const String logoDarkAsset = 'assets/logo_escuro.png';

  // ─── Splash ───
  static const String splashLoading = 'A carregar...';

  // ─── PIN Setup ───
  static const String pinSetupTitle = 'Crie o seu PIN';
  static const String pinSetupSubtitle =
      'Escolha um PIN de 6 dígitos para proteger a sua conta';
  static const String pinConfirmTitle = 'Confirme o PIN';
  static const String pinConfirmSubtitle =
      'Insira o mesmo PIN para confirmar';
  static const String pinMismatchError =
      'Os PINs não coincidem. Tente novamente.';
  static const String pinSaveError = 'Erro ao guardar PIN';
  static const String pinSetupSuccess = 'PIN configurado!';
  static const String pinSetupSuccessMessage =
      'O seu PIN foi configurado com sucesso.';
  static const String pinPqcKeysGenerated =
      'Chaves PQC geradas para máxima segurança';
  static const String pinGeneratingKeys = 'A gerar chaves PQC...';
  static const String pinStepCreate = 'Criar';
  static const String pinStepConfirm = 'Confirmar';
  static const String pinTipCreate =
      'Escolha um PIN que não seja fácil de adivinhar. Evite sequências como 123456.';
  static const String pinTipConfirm =
      'Introduza o mesmo PIN que escolheu no passo anterior para confirmar.';

  // ─── PIN Verify ───
  static const String pinVerifyTitle = 'Insira o seu PIN';
  static const String pinVerifySubtitle =
      'Introduza o PIN de 6 dígitos para aceder à sua conta';
  static const String pinTooManyAttempts =
      'Demasiadas tentativas. Tente novamente mais tarde.';
  static const String pinUseBiometrics = 'Usar biometria';
  static const String pinQuantumBadge = 'Protegido com Quantum Security';

  // ─── Onboarding ───
  static const String onboardingSkip = 'Pular';
  static const String onboardingNext = 'Próximo';
  static const String onboardingStart = 'Começar';

  // Onboarding Page 1 - Welcome
  static const String onboarding1Image = 'assets/onboarding/welcome.png';
  static const String onboarding1Title = 'Bem-vindo ao BJ Bank';
  static const String onboarding1Description =
      'O seu parceiro bancário seguro com tecnologia de ponta em criptografia quântica.';

  // Onboarding Page 2 - Quantum Security
  static const String onboarding2Image = 'assets/onboarding/security.png';
  static const String onboarding2Title = 'Segurança Quântica';
  static const String onboarding2Description =
      'Protegido por algoritmos de Criptografia Pós-Quântica: CRYSTALS-Kyber e Dilithium.';

  // Onboarding Page 3 - Transactions
  static const String onboarding3Image = 'assets/onboarding/transactions.png';
  static const String onboarding3Title = 'Transações Simples';
  static const String onboarding3Description =
      'MB WAY, transferências e pagamentos com criptografia de ponta a ponta.';

  // Onboarding Page 4 - Get Started
  static const String onboarding4Image = 'assets/onboarding/start.png';
  static const String onboarding4Title = 'Comece Agora';
  static const String onboarding4Description =
      'Experimente o futuro da segurança bancária hoje mesmo.';

  // ─── Login ───
  static const String loginTitle = 'Bem-vindo de volta';
  static const String loginSubtitle = 'Inicie sessão para continuar';
  static const String loginEmailLabel = 'Email';
  static const String loginEmailHint = 'seu@email.com';
  static const String loginPasswordLabel = 'Palavra-passe';
  static const String loginForgotPassword = 'Esqueceu a palavra-passe?';
  static const String loginButton = 'Entrar';
  static const String loginNoAccount = 'Não tem conta?';
  static const String loginRegister = 'Registe-se';
  static const String loginOr = 'ou';
  static const String loginEmailRequired = 'Por favor insira o seu email';
  static const String loginEmailInvalid = 'Por favor insira um email válido';
  static const String loginPasswordRequired = 'Por favor insira a sua palavra-passe';
  static const String loginPasswordMinLength = 'A palavra-passe deve ter pelo menos 6 caracteres';
  static const String loginPqcBadge = 'Protegido por Criptografia Pós-Quântica';

  // ─── Register ───
  static const String registerTitle = 'Criar conta';
  static const String registerSubtitle = 'Preencha os seus dados para começar';
  static const String registerNameLabel = 'Nome completo';
  static const String registerNameHint = 'João Silva';
  static const String registerNameRequired = 'Por favor insira o seu nome';
  static const String registerNameMinLength = 'O nome deve ter pelo menos 3 caracteres';
  static const String registerPhoneLabel = 'Telemóvel';
  static const String registerPhoneHint = '912 345 678';
  static const String registerPhoneRequired = 'Por favor insira o seu número de telemóvel';
  static const String registerPhoneInvalid = 'O número deve ter 9 dígitos';
  static const String registerPhonePrefix = '+351 ';
  static const String registerPasswordLabel = 'Palavra-passe';
  static const String registerPasswordHelper = 'Mínimo 6 caracteres';
  static const String registerPasswordRequired = 'Por favor insira uma palavra-passe';
  static const String registerPasswordMinLength = 'A palavra-passe deve ter pelo menos 6 caracteres';
  static const String registerConfirmPasswordLabel = 'Confirmar palavra-passe';
  static const String registerConfirmPasswordRequired = 'Por favor confirme a palavra-passe';
  static const String registerPasswordMismatch = 'As palavras-passe não coincidem';
  static const String registerTermsRequired = 'Por favor aceite os termos e condições';
  static const String registerTermsPrefix = 'Li e aceito os ';
  static const String registerTermsLink = 'Termos e Condições';
  static const String registerTermsMiddle = ' e a ';
  static const String registerPrivacyLink = 'Política de Privacidade';
  static const String registerButton = 'Criar conta';
  static const String registerHasAccount = 'Já tem conta?';
  static const String registerLoginLink = 'Iniciar sessão';
  static const String registerSuccessTitle = 'Conta criada!';
  static const String registerSuccessMessage =
      'A sua conta foi criada com sucesso. Enviámos um email de verificação para o seu endereço.\n\nPode configurar o PIN de segurança nas Definições.';

  // ─── Home ───
  static const String homeGreetingMorning = 'Bom dia';
  static const String homeGreetingAfternoon = 'Boa tarde';
  static const String homeGreetingEvening = 'Boa noite';
  static const String homeBalanceLabel = 'Saldo Disponível';
  static const String homeAccountType = 'Conta à Ordem';
  static const String homeQuickActions = 'Ações Rápidas';
  static const String homeRecentTransactions = 'Transações Recentes';
  static const String homeViewAll = 'Ver todas';
  static const String homeNoTransactions = 'Nenhuma transação recente';
  static const String homeComingSoon = 'Em breve!';
  static const String homeMbWay = 'MB WAY';
  static const String homeTransfer = 'Transferir';
  static const String homePay = 'Pagar';
  static const String homeQrCode = 'QR Code';
  static const String homeQuantumSafe = 'Quantum Safe';

  // ─── Common ───
  static const String continueButton = 'Continuar';
  static const String cancelButton = 'Cancelar';

  /// Returns PIN error message with remaining attempts
  static String pinIncorrectAttempts(int remaining) =>
      'PIN incorreto. $remaining tentativas restantes.';

  // ─── Deposit / Open Banking ───
  static const String depositTitle = 'Depositar';
  static const String depositSubtitle = 'Adicione dinheiro via Open Banking';
  static const String depositConnectBank = 'Conectar Banco';
  static const String depositSelectBank = 'Selecionar Banco';
  static const String depositLinkedAccounts = 'Contas Conectadas';
  static const String depositNoAccounts = 'Nenhuma conta conectada';
  static const String depositConnectFirst = 'Conecte um banco para depositar';
  static const String depositAmount = 'Valor do Deposito';
  static const String depositConfirm = 'Confirmar Deposito';
  static const String depositSuccess = 'Deposito Concluido!';
  static const String depositProcessing = 'Deposito em Processamento';
  static const String depositHistory = 'Historico de Depositos';
  static const String depositSecure = 'Transacao Segura';
  static const String depositPsd2Info = 'Protegida por PSD2 e criptografia PQC';
  static const String depositQuickAmounts = 'Valores rapidos';
  static const String homeDeposit = 'Depositar';
}
