enum Flavor { dev, stg, prod }

class AppConfig {
  const AppConfig({required this.currentFlavor});

  factory AppConfig.fromEnvironment() {
    const flavorString = String.fromEnvironment('flavor', defaultValue: 'prod');
    return AppConfig(currentFlavor: _parseFlavorFromString(flavorString));
  }

  final Flavor currentFlavor;

  String get appName => switch (currentFlavor) {
    Flavor.dev => 'GitSync 开发版',
    Flavor.stg => 'GitSync 预发布版',
    Flavor.prod => 'GitSync',
  };

  String get baseUrl => switch (currentFlavor) {
    Flavor.dev => 'https://api-dev.example.com',
    Flavor.stg => 'https://api-staging.example.com',
    Flavor.prod => 'https://api.example.com',
  };

  bool get mockApiDataSource => switch (currentFlavor) {
    Flavor.dev => true,
    Flavor.stg || Flavor.prod => false,
  };

  bool get isNeedProxy => switch (currentFlavor) {
    Flavor.dev || Flavor.stg => true,
    Flavor.prod => false,
  };

  String get flavorName => currentFlavor.name;

  String get flavorTitle => switch (currentFlavor) {
    Flavor.dev => 'template dev',
    Flavor.stg => 'template stg',
    Flavor.prod => 'template prod',
  };

  bool get isProduction => currentFlavor == Flavor.prod;

  Map<String, Object?> get harnessContext => {
    'flavor': flavorName,
    'app_name': appName,
    'base_url': baseUrl,
    'mock_api_data_source': mockApiDataSource,
    'is_need_proxy': isNeedProxy,
    'is_production': isProduction,
  };
}

Flavor _parseFlavorFromString(String flavorString) =>
    switch (flavorString.toLowerCase()) {
      'dev' => Flavor.dev,
      'stg' => Flavor.stg,
      'prod' => Flavor.prod,
      _ => Flavor.prod,
    };
