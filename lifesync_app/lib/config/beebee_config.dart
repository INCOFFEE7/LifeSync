import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/core/theme/beebee_theme.dart';

class BeebeeConfig {
  static AppConfig get config => AppConfig(
        variant: AppVariant.beebee,
        appName: 'BeeNest',
        logoPath: 'assets/images/logobeebee.png',
        logoFullPath: 'assets/images/BeeNestLightBG.png',
        logoDarkPath: 'assets/images/logobeebee.png',
        logoDarkFullPath: 'assets/images/BeeNestDarkBG.png',
        lightTheme: BeebeeTheme.lightTheme,
        darkTheme: BeebeeTheme.darkTheme,
        enabledModules: [
          'fasting_tracker',
          'menstrual_tracker',
        ],
      );
}
