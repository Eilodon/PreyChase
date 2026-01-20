import 'dart:convert';

class PlayerProgress {
  final int totalScore; // Currency
  final int highScore;
  final List<String> unlockedFuryTypes;
  final Map<String, int> preyKills; // "angryApple": 10

  const PlayerProgress({
    this.totalScore = 0,
    this.highScore = 0,
    this.unlockedFuryTypes = const ['classic'],
    this.preyKills = const {},
  });

  PlayerProgress copyWith({
    int? totalScore,
    int? highScore,
    List<String>? unlockedFuryTypes,
    Map<String, int>? preyKills,
  }) {
    return PlayerProgress(
      totalScore: totalScore ?? this.totalScore,
      highScore: highScore ?? this.highScore,
      unlockedFuryTypes: unlockedFuryTypes ?? this.unlockedFuryTypes,
      preyKills: preyKills ?? this.preyKills,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalScore': totalScore,
      'highScore': highScore,
      'unlockedFuryTypes': unlockedFuryTypes,
      'preyKills': preyKills,
    };
  }

  factory PlayerProgress.fromJson(Map<String, dynamic> map) {
    return PlayerProgress(
      totalScore: map['totalScore'] ?? 0,
      highScore: map['highScore'] ?? 0,
      unlockedFuryTypes: List<String>.from(map['unlockedFuryTypes'] ?? ['classic']),
      preyKills: Map<String, int>.from(map['preyKills'] ?? {}),
    );
  }

  String toJsonString() => json.encode(toJson());

  factory PlayerProgress.fromJsonString(String source) => 
      PlayerProgress.fromJson(json.decode(source));
}
