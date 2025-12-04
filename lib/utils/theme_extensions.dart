import 'package:flutter/material.dart';

/// Extension على ThemeData لتسهيل الوصول لألوان التصميم
extension ThemeColors on ThemeData {
  // ألوان التصميم الحديث
  Color get expenseColor => const Color(0xFFEF5350); // أحمر للمصروفات
  Color get incomeColor => const Color(0xFF66BB6A); // أخضر للإيرادات
  Color get darkCardColor => const Color(0xFF1E1E1E); // لون البطاقات الداكنة
  Color get gradientStart => const Color(0xFFE8F5E9); // بداية التدرج (أخضر فاتح)
  Color get gradientEnd => const Color(0xFFFFF9C4); // نهاية التدرج (أصفر فاتح)
}

