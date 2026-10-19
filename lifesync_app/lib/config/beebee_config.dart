import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/core/theme/beebee_theme.dart';

class BeebeeConfig {
  static AppConfig get config => AppConfig(
        variant: AppVariant.beebee,
        appName: 'BeeHappy',
        logoPath: 'assets/images/BeeHappyLightBG.png',
        logoFullPath: 'assets/images/BeeHappyLightBG.png',
        logoDarkPath: 'assets/images/BeeHappyDarkBG.png',
        logoDarkFullPath: 'assets/images/BeeHappyDarkBG.png',
        lightTheme: BeebeeTheme.lightTheme,
        darkTheme: BeebeeTheme.darkTheme,
        enabledModules: [
          'fasting_tracker',
          'menstrual_tracker',
        ],
      );
}
