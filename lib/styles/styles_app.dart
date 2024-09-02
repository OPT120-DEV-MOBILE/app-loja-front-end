import 'package:flutter/material.dart';

class AppStyles {
  // Cores
  static const Color backgroundColor = Colors.white;
  static const Color primaryColor = Color.fromARGB(255, 255, 135, 7);
  static const Color secondaryColor = Color.fromARGB(255, 254, 156, 51);
  static const Color textColor = Colors.white;
  static const Color textDropDownColor = Color.fromARGB(255, 255, 135, 7);
  static const Color borderColor = Colors.grey;
  static const Color shadowColor = Colors.black26;
  static const Color switchThumbColor = Color.fromARGB(255, 255, 135, 7);
  static const Color switchTrackColor = Colors.grey;

  // Fontes
  static const String fontFamily = 'Roboto'; // Nome da fonte

  // Tamanhos
  static const double smallFontSize = 12.0;
  static const double regularFontSize = 16.0;
  static const double largeFontSize = 20.0;

  // Estilos de texto
  static TextStyle smallTextStyle = const TextStyle(
    fontFamily: fontFamily,
    fontSize: smallFontSize,
    color: textColor,
  );

  static TextStyle regularTextStyle = const TextStyle(
    fontFamily: fontFamily,
    fontSize: regularFontSize,
    color: textColor,
  );

  static TextStyle largeTextStyle = const TextStyle(
    fontFamily: fontFamily,
    fontSize: largeFontSize,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: backgroundColor, backgroundColor: primaryColor,
    textStyle: regularTextStyle,
  );

  static TextStyle formTitleStyle = const TextStyle(
    fontFamily: fontFamily,
    fontSize: largeFontSize,
    fontWeight: FontWeight.bold,
    color: Color.fromARGB(255, 255, 135, 7),
  );
  
  static const TextStyle formTextStyle = TextStyle(
    fontSize: 14,
    color: Color.fromARGB(255, 255, 135, 7),
  );

  static final InputDecoration textFieldDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: secondaryColor, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: secondaryColor, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: primaryColor, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  static final CardTheme cardTheme = CardTheme(
    margin: const EdgeInsets.symmetric(vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    color: Colors.white,
  );

  static const TextStyle listItemTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle listItemSubtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey[700],
  );

  static TextStyle dropDownTextStyle = const TextStyle(
    fontFamily: fontFamily,
    fontSize: smallFontSize,
    color: textDropDownColor,
  );

  static final DropdownButtonFormFieldStyle dropdownStyle = DropdownButtonFormFieldStyle(
    hintStyle: dropDownTextStyle,
    itemStyle: const TextStyle(
      fontSize: 14,
      color: textDropDownColor,
    ),
  );

  static final SwitchThemeData switchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.all(switchThumbColor),
    trackColor: WidgetStateProperty.all(switchTrackColor),
  );
}

class DropdownButtonFormFieldStyle {
  final TextStyle hintStyle;
  final TextStyle itemStyle;

  const DropdownButtonFormFieldStyle({
    required this.hintStyle,
    required this.itemStyle,
  });
}
