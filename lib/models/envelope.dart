class Envelope {
  final double attack; // ms (0 - 5000)
  final double decay; // ms (0 - 5000)
  final double sustain; // level (0.0 - 1.0)
  final double release; // ms (0 - 10000)

  const Envelope({
    this.attack = 10.0,
    this.decay = 100.0,
    this.sustain = 0.7,
    this.release = 300.0,
  });

  Envelope copyWith({
    double? attack,
    double? decay,
    double? sustain,
    double? release,
  }) {
    return Envelope(
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
    );
  }

  Map<String, dynamic> toJson() => {
        'attack': attack,
        'decay': decay,
        'sustain': sustain,
        'release': release,
      };

  factory Envelope.fromJson(Map<String, dynamic> json) => Envelope(
        attack: (json['attack'] as num).toDouble(),
        decay: (json['decay'] as num).toDouble(),
        sustain: (json['sustain'] as num).toDouble(),
        release: (json['release'] as num).toDouble(),
      );
}
