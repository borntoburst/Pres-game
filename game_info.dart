import 'package:flutter/material.dart';

/// Metadata for each mini-game shown on the home screen.
class GameInfo {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final Color color;

  const GameInfo({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.color,
  });
}

/// All available games registry.
const List<GameInfo> allGames = [
  GameInfo(
    id: 'connect_pairs',
    title: 'Nối Cặp',
    emoji: '🎈',
    description: 'Nối các bong bóng cùng màu!',
    color: Color(0xFFFF6B35),
  ),
  GameInfo(
    id: 'counting',
    title: 'Đếm Số',
    emoji: '⭐',
    description: 'Đếm xem có bao nhiêu vật?',
    color: Color(0xFF4ECDC4),
  ),
  GameInfo(
    id: 'shortest',
    title: 'Ngắn Nhất',
    emoji: '📏',
    description: 'Tìm vật ngắn nhất!',
    color: Color(0xFFFF6B9D),
  ),
  GameInfo(
    id: 'classification',
    title: 'Phân Loại',
    emoji: '🐾',
    description: 'Sắp xếp vào đúng nhóm!',
    color: Color(0xFF6BCB77),
  ),
];
