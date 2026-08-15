// ponytail: native builds have no browser OAuth — buttons hidden entirely
String? oauthReadToken() => null;

void oauthClearToken() {}

void oauthStart(String provider, String baseUrl) {}

List<String> oauthProvidersFromJson(String body) => [];
