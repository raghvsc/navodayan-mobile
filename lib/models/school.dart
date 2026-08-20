class SchoolState {
  final int? id;
  final String name;

  SchoolState({this.id, required this.name});

  factory SchoolState.fromJson(Map<String, dynamic> json) {
    return SchoolState(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
    };
  }
}

class School {
  final String jnvId;
  final String name;
  final String distt;
  final SchoolState? state;

  School({
    required this.jnvId,
    required this.name,
    required this.distt,
    this.state,
  });

  String get displayName =>
      '$name, $distt${state != null && state!.name.isNotEmpty ? ' (${state!.name})' : ''}';

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      jnvId: json['jnv_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      distt: json['distt']?.toString() ?? json['district']?.toString() ?? '',
      state: json['state'] is Map<String, dynamic>
          ? SchoolState.fromJson(json['state'] as Map<String, dynamic>)
          : (json['state'] is String ? SchoolState(name: json['state'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jnv_id': jnvId,
      'name': name,
      'distt': distt,
      if (state != null) 'state': state!.toJson(),
    };
  }
}
