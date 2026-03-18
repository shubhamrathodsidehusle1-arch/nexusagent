/// NexusAgent SSO/SAML Integration
/// Enterprise Single Sign-On support

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

enum SSOProvider {
  google,
  microsoft,
  github,
  slack,
  okta,
  genericSAML,
}

class SSOConfig {
  final SSOProvider provider;
  final String clientId;
  final String clientSecret;
  final String? tenantId; // For Microsoft
  final String? domain; // For Google
  final List<String> allowedDomains;
  final List<String> allowedEmails;
  final bool autoProvisionUsers;

  SSOConfig({
    required this.provider,
    required this.clientId,
    required this.clientSecret,
    this.tenantId,
    this.domain,
    this.allowedDomains = const [],
    this.allowedEmails = const [],
    this.autoProvisionUsers = true,
  });
}

class SAMLConfig {
  final String entityId;
  final String ssoUrl;
  final String certificate;
  final String? attributeConsumingService;
  final List<String> allowedDomains;

  SAMLConfig({
    required this.entityId,
    required this.ssoUrl,
    required this.certificate,
    this.attributeConsumingService,
    this.allowedDomains = const [],
  });
}

class SSOUser {
  final String id;
  final String email;
  final String name;
  final String? picture;
  final String provider;
  final String? accessToken;
  final DateTime createdAt;

  SSOUser({
    required this.id,
    required this.email,
    required this.name,
    this.picture,
    required this.provider,
    this.accessToken,
    required this.createdAt,
  });
}

class SSOService {
  static final SSOService _instance = SSOService._internal();
  factory SSOService() => _instance;
  SSOService._internal();

  SSOConfig? _config;
  SAMLConfig? _samlConfig;
  final Map<String, String> _sessions = {}; // code -> userId

  /// Initialize SSO
  void initialize(SSOConfig config) {
    _config = config;
    print('SSO initialized: ${config.provider.name}');
  }

  /// Initialize SAML
  void initializeSAML(SAMLConfig config) {
    _samlConfig = config;
    print('SAML initialized: ${config.entityId}');
  }

  /// Get authorization URL
  String getAuthUrl(String redirectUri, String state) {
    switch (_config?.provider) {
      case SSOProvider.google:
        return 'https://accounts.google.com/o/oauth2/v2/auth?'
            'client_id=${_config?.clientId}&'
            'redirect_uri=${Uri.encodeComponent(redirectUri)}&'
            'response_type=code&'
            'scope=openid email profile&'
            'state=$state';

      case SSOProvider.microsoft:
        return 'https://login.microsoftonline.com/${_config?.tenantId}/oauth2/v2.0/authorize?'
            'client_id=${_config?.clientId}&'
            'redirect_uri=${Uri.encodeComponent(redirectUri)}&'
            'response_type=code&'
            'scope=openid email profile User.Read&'
            'state=$state';

      case SSOProvider.github:
        return 'https://github.com/login/oauth/authorize?'
            'client_id=${_config?.clientId}&'
            'redirect_uri=${Uri.encodeComponent(redirectUri)}&'
            'scope=read:user user:email&'
            'state=$state';

      case SSOProvider.slack:
        return 'https://slack.com/oauth/v2/authorize?'
            'client_id=${_config?.clientId}&'
            'redirect_uri=${Uri.encodeComponent(redirectUri)}&'
            'scope=identity.basic,identity.email&'
            'state=$state';

      default:
        return '';
    }
  }

  /// Exchange code for user
  Future<SSOUser?> exchangeCode(String code, String redirectUri) async {
    if (_config == null) return null;

    switch (_config!.provider) {
      case SSOProvider.google:
        return _exchangeGoogle(code, redirectUri);
      case SSOProvider.microsoft:
        return _exchangeMicrosoft(code, redirectUri);
      case SSOProvider.github:
        return _exchangeGithub(code, redirectUri);
      case SSOProvider.slack:
        return _exchangeSlack(code, redirectUri);
      default:
        return null;
    }
  }

  Future<SSOUser?> _exchangeGoogle(String code, String redirectUri) async {
    // In production, exchange code for tokens
    // Return mock user for demo
    return SSOUser(
      id: 'google-' + DateTime.now().millisecondsSinceEpoch.toString(),
      email: 'user@example.com',
      name: 'Google User',
      provider: 'google',
      createdAt: DateTime.now(),
    );
  }

  Future<SSOUser?> _exchangeMicrosoft(String code, String redirectUri) async {
    return SSOUser(
      id: 'microsoft-' + DateTime.now().millisecondsSinceEpoch.toString(),
      email: 'user@company.com',
      name: 'Microsoft User',
      provider: 'microsoft',
      createdAt: DateTime.now(),
    );
  }

  Future<SSOUser?> _exchangeGithub(String code, String redirectUri) async {
    return SSOUser(
      id: 'github-' + DateTime.now().millisecondsSinceEpoch.toString(),
      email: 'user@github.com',
      name: 'GitHub User',
      provider: 'github',
      createdAt: DateTime.now(),
    );
  }

  Future<SSOUser?> _exchangeSlack(String code, String redirectUri) async {
    return SSOUser(
      id: 'slack-' + DateTime.now().millisecondsSinceEpoch.toString(),
      email: 'user@company.slack.com',
      name: 'Slack User',
      provider: 'slack',
      createdAt: DateTime.now(),
    );
  }

  /// Validate email against allowlist
  bool validateEmail(String email) {
    if (_config == null) return true;

    // Check exact emails
    if (_config!.allowedEmails.contains(email)) return true;

    // Check domains
    final domain = email.split('@').last;
    if (_config!.allowedDomains.contains(domain)) return true;

    return false;
  }

  /// Generate SAML metadata
  String getSAMLMetadata() {
    if (_samlConfig == null) return '';

    return '''<?xml version="1.0" encoding="UTF-8"?>
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
    entityID="${_samlConfig!.entityId}">
  <md:IDPSSODescriptor WantAuthnRequestsSigned="false"
      protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
    <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
        Location="${_samlConfig!.ssoUrl}"/>
    <md:KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:X509Data>
          <ds:X509Certificate>${_samlConfig!.certificate}</ds:X509Certificate>
        </ds:X509Data>
      </ds:KeyInfo>
    </md:KeyDescriptor>
  </md:IDPSSODescriptor>
</md:EntityDescriptor>''';
  }

  /// Process SAML response
  Future<SSOUser?> processSAMLResponse(String samlResponse) async {
    // In production, validate and parse SAML response
    // For demo, return mock user
    return SSOUser(
      id: 'saml-' + DateTime.now().millisecondsSinceEpoch.toString(),
      email: 'saml-user@company.com',
      name: 'SAML User',
      provider: 'saml',
      createdAt: DateTime.now(),
    );
  }

  /// Get provider logo
  static String getProviderLogo(SSOProvider provider) {
    switch (provider) {
      case SSOProvider.google:
        return 'https://www.google.com/favicon.ico';
      case SSOProvider.microsoft:
        return 'https://www.microsoft.com/favicon.ico';
      case SSOProvider.github:
        return 'https://github.com/favicon.ico';
      case SSOProvider.slack:
        return 'https://slack.com/favicon.ico';
      default:
        return '';
    }
  }
}
