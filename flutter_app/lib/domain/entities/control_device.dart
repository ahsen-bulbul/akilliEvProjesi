class ControlDevice {
  final int id;
  final int? roomId;
  final String name;
  final String type;
  final bool status;

  const ControlDevice({
    required this.id,
    required this.roomId,
    required this.name,
    required this.type,
    required this.status,
  });

  ControlDevice copyWith({bool? status}) {
    return ControlDevice(
      id: id,
      roomId: roomId,
      name: name,
      type: type,
      status: status ?? this.status,
    );
  }
}
