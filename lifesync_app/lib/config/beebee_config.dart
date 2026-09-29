import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/core/theme/beebee_theme.dart';

class BeebeeConfig {
  static AppConfig get config => AppConfig(
        variant: AppVariant.beebee,
        appName: 'LifeSync for Beebee',
        logoPath: 'assets/images/logobeebee.png',
        logoFullPath: 'assets/images/logolifesyncbeebeefull.png',
        lightTheme: BeebeeTheme.lightTheme,
        darkTheme: BeebeeTheme.darkTheme,
        enabledModules: [
          'fasting_tracker',
          'menstrual_tracker',
        ],
      );
}
