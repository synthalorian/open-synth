class Envelope {
  final double attack; // ms (0 - 5000)
  final double decay; // ms (0 - 5000)
  final double sustain; // level (0.0 - 1.0)
  final double release; // ms (0 - 10000)
  final double delay; // ms (0 - 2000)
  final double hold; // ms (0 - 2000)
  final int attackCurve; // 0=linear, 1=exp, 2=log
  final int decayCurve; // 0=linear, 1=exp, 2=log
  final int releaseCurve; // 0=linear, 1=exp, 2=log

  const Envelope({
    this.attack = 10.0,
    this.decay = 100.0,
    this.sustain = 0.7,
    this.release = 300.0,
    this.delay = 0.0,
    this.hold = 0.0,
    this.attackCurve = 0,
    this.decayCurve = 0,
    this.releaseCurve = 0,
  });

  Envelope copyWith({
    double? attack,
    double? decay,
    double? sustain,
    double? release,
    double? delay,
    double? hold,
    int? attackCurve,
    int? decayCurve,
    int? releaseCurve,
  }) {
    return Envelope(
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
      delay: delay ?? this.delay,
      hold: hold ?? this.hold,
      attackCurve: attackCurve ?? this.attackCurve,
      decayCurve: decayCurve ?? this.decayCurve,
      releaseCurve: releaseCurve ?? this.releaseCurve,
    );
  }

  Map<String, dynamic> toJson() => {
        'attack': attack,
        'decay': decay,
        'sustain': sustain,
        'release': release,
        'delay': delay,
        'hold': hold,
        'attackCurve': attackCurve,
        'decayCurve': decayCurve,
        'releaseCurve': releaseCurve,
      };

  factory Envelope.fromJson(Map<String, dynamic> json) => Envelope(
        attack: (json['attack'] as num).toDouble(),
        decay: (json['decay'] as num).toDouble(),
        sustain: (json['sustain'] as num).toDouble(),
        release: (json['release'] as num).toDouble(),
        delay: (json['delay'] as num?)?.toDouble() ?? 0.0,
        hold: (json['hold'] as num?)?.toDouble() ?? 0.0,
        attackCurve: (json['attackCurve'] as int?) ?? 0,
        decayCurve: (json['decayCurve'] as int?) ?? 0,
        releaseCurve: (json['releaseCurve'] as int?) ?? 0,
      );
}
