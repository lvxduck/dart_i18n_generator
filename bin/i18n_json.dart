import 'package:i18n_json/i18n_json.dart' as i18n_json;
import 'package:yaml/yaml.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

void main(List<String> arguments) {
  var isNullSafeFuture = i18n_json.getProjectNullSafety();
  var configFile = i18n_json.getConfigFile();

  configFile.then((config) async {
    Directory(config['generatedPath']).create(recursive: true);

    var defaultLocale = config['defaultLocale'] as String;
    var localeList = config['locales'] as List<dynamic>;

    var localeMap = Map.fromEntries(localeList.map((locale) => MapEntry(
        locale as String,
        i18n_json
            .readJsonFile(path.join(config['localePath'], '$locale.json')))));

    Map<String, Map<String, i18n_json.TranslationEntry>>
        localeTranslationListMap = {};
    //var localeTranslationListMap = {};
    List<Future<Null>> futureList = [];
    localeMap.forEach((localeName, jsonTree) {
      var retFuture = jsonTree.then((content) {
        Map<String, i18n_json.TranslationEntry> translationsList = {};
        i18n_json.buildTranslationEntriesArray(content, '', translationsList);
        localeTranslationListMap[localeName] = translationsList;
      });
      futureList.add(retFuture);
    });
    bool isNullSafetyOn = false;
    await isNullSafeFuture.then((value) => isNullSafetyOn = value);
    await Future.wait(futureList);


    var defaultLocaleTranslation = localeTranslationListMap[defaultLocale];
    localeTranslationListMap.remove(defaultLocale);
    {
      localeTranslationListMap.forEach((locale, translationsMap) {
        var toBeRemoved = [];
        translationsMap.keys.forEach((varname) {
          if (!defaultLocaleTranslation.containsKey(varname)) {
            defaultLocaleTranslation[varname] = translationsMap[varname];
            toBeRemoved.add(varname);
          }
        });
        toBeRemoved.forEach((element) {
          translationsMap.remove(element);
        });
      });
    }
    var writeSink =
        File(path.join(config['generatedPath'], "i18n.dart")).openWrite();
    writeSink.write('''
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: camel_case_types
// ignore_for_file: prefer_single_quotes
// ignore_for_file: unnecessary_brace_in_string_interps

//WARNING: This file is automatically generated. DO NOT EDIT, all your changes would be lost.

typedef LocaleChangeCallback = void Function(Locale locale);

class I18n implements WidgetsLocalizations {
  const I18n();
  static Locale${isNullSafetyOn ? "?" : ""} _locale;
  static bool _shouldReload = false;
  static Locale${isNullSafetyOn ? "?" : ""} get locale => _locale;
  static set locale(Locale${isNullSafetyOn ? "?" : ""} newLocale) {
    _shouldReload = true;
    I18n._locale = newLocale;
  }

  static const GeneratedLocalizationsDelegate delegate = GeneratedLocalizationsDelegate();

  /// function to be invoked when changing the language
  static LocaleChangeCallback${isNullSafetyOn ? "?" : ""} onLocaleChanged;

  static I18n${isNullSafetyOn ? "?" : ""} of(BuildContext context) =>
    Localizations.of<I18n>(context, WidgetsLocalizations);
  @override
  TextDirection get textDirection => TextDirection.${i18n_json.getTextDirection(config, defaultLocale)};
${defaultLocaleTranslation.values.map((element) => "\t" + element.comment() + "\n\t" + element.toString()).join("\n")}
}
class _I18n_${defaultLocale.replaceAll("-", "_")} extends I18n {
  const _I18n_${defaultLocale.replaceAll("-", "_")}();
}
''');

    localeTranslationListMap.forEach((locale, translationList) {
      writeSink.write('''
class _I18n_${locale.replaceAll("-", "_")} extends I18n {
  const _I18n_${locale.replaceAll("-", "_")}();
  @override
  TextDirection get textDirection => TextDirection.${i18n_json.getTextDirection(config, locale)};
${translationList.values.map((element) => "\t" + element.comment() + "\n\t@override\n\t" + element.toString()).join("\n")}
}
''');
    });
    writeSink.write('''
class GeneratedLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const GeneratedLocalizationsDelegate();
  List<Locale> get supportedLocales {
    return const <Locale>[
      ${localeList.map((e) => "Locale(" + (e as String).split("-").map((e) => '"' + e + '"').join(", ") + ")").join(",\n\t\t\t")}
    ];
  }

  LocaleResolutionCallback resolution({Locale${isNullSafetyOn ? "?" : ""} fallback}) {
    return (Locale${isNullSafetyOn ? "?" : ""} locale, Iterable<Locale> supported) {
      if (${isNullSafetyOn ? "locale != null && " : ""}isSupported(locale)) {
        return locale;
      }
      final Locale fallbackLocale = fallback ?? supported.first;
      return fallbackLocale;
    };
  }

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    I18n._locale ??= locale;
    I18n._shouldReload = false;
    final String lang = I18n._locale != null ? I18n._locale.toString() : "";
    final String languageCode = I18n._locale != null ? I18n._locale${isNullSafetyOn ? "!" : ""}.languageCode : "";
    ${localeList.map((e) => 'if ("' + (e as String).replaceAll('-', '_') + '" == lang) {\n\t\t\treturn SynchronousFuture<WidgetsLocalizations>(const _I18n_' + e.replaceAll("-", "_") + '());\n\t\t}').join('\n\t\telse ')}
    else ${localeList.map((e) => 'if ("' + (e as String).split('-')[0] + '" == languageCode) {\n\t\t\treturn SynchronousFuture<WidgetsLocalizations>(const _I18n_' + e.replaceAll("-", "_") + '());\n\t\t}').join('\n\t\telse ')}

    return SynchronousFuture<WidgetsLocalizations>(const I18n());
  }

  @override
  bool isSupported(Locale locale) {
    for (var i = 0; i < supportedLocales.length && locale != null; i++) {
      final l = supportedLocales[i];
      if (l.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldReload(GeneratedLocalizationsDelegate old) => I18n._shouldReload;
}
''');

    await writeSink.close();
  });
}
