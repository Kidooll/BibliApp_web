import 'package:flutter/material.dart';
import 'package:bibli_app/core/constants/app_constants.dart';

class CustomSnackBar {
  /// SnackBar de sucesso (verde)
  static SnackBar success(String message, {IconData? icon}) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon ?? Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF2F5E5B),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// SnackBar de erro (vermelho)
  static SnackBar error(String message, {IconData? icon}) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon ?? Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE15B5B),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// SnackBar de recompensa/XP (amarelo/dourado)
  static SnackBar reward(String message, {IconData? icon}) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon ?? Icons.star, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// SnackBar de informação (azul)
  static SnackBar info(String message, {IconData? icon}) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon ?? Icons.info_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF3B5E5C),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
