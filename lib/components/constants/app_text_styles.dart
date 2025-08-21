import 'package:flutter/material.dart';
import 'app_color.dart';

class AppTextStyles {
  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColor.text,
  );
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColor.text,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColor.text,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColor.text,
  );
}
