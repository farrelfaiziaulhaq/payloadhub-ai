class Mahasiswa {
  const Mahasiswa({
    this.id,
    required this.nim,
    required this.nama,
    required this.prodi,
  });

  final int? id;
  final String nim;
  final String nama;
  final String prodi;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'nim': nim,
      'nama': nama,
      'prodi': prodi,
    };
  }

  factory Mahasiswa.fromMap(Map<String, Object?> map) {
    return Mahasiswa(
      id: map['id'] as int?,
      nim: map['nim'] as String,
      nama: map['nama'] as String,
      prodi: map['prodi'] as String,
    );
  }

  Mahasiswa copyWith({int? id, String? nim, String? nama, String? prodi}) {
    return Mahasiswa(
      id: id ?? this.id,
      nim: nim ?? this.nim,
      nama: nama ?? this.nama,
      prodi: prodi ?? this.prodi,
    );
  }
}
