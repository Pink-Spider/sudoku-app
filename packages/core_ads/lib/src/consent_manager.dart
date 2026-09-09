import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP (User Messaging Platform) consent flow.
///
/// Required for EEA/UK users under GDPR and, since 2024, for AdMob to
/// serve at all in those regions. Call [gatherConsent] before
/// [AdService.initialize]; it is a no-op outside consent regions.
///
/// Configure the actual message in AdMob → Privacy & messaging. For iOS
/// also enable the IDFA explainer there so the ATT prompt is shown.
class ConsentManager {
  ConsentManager({this.forceEea = false, this.testDeviceIds = const []});

  /// Force EEA behaviour on a test device (dev flavor only) so the consent
  /// form can be exercised from anywhere.
  final bool forceEea;
  final List<String> testDeviceIds;

  /// Resolves `true` when ads may be requested.
  Future<bool> gatherConsent() async {
    final done = Completer<bool>();
    final params = ConsentRequestParameters(
      consentDebugSettings: !forceEea
          ? null
          : ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
              testIdentifiers: testDeviceIds,
            ),
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        unawaited(ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            debugPrint('[consent] form error: ${formError.message}');
          }
          done.complete(await ConsentInformation.instance.canRequestAds());
        }));
      },
      (error) async {
        debugPrint('[consent] update error: ${error.message}');
        // Outside consent regions canRequestAds() is still true.
        done.complete(await ConsentInformation.instance.canRequestAds());
      },
    );
    return done.future;
  }

  /// Show the privacy options form (settings screen link) if the user is
  /// in a region where it is required.
  Future<void> showPrivacyOptions() async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    if (status == PrivacyOptionsRequirementStatus.required) {
      unawaited(ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          debugPrint('[consent] privacy options error: ${formError.message}');
        }
      }));
    }
  }

  /// Dev only: forget consent so the form shows again.
  Future<void> reset() => ConsentInformation.instance.reset();
}
