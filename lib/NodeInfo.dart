import 'dart:convert';

class NodeInfo {
  int id;
  String hostname;
  int port;
  NodeInfo({
    this.id,
    this.hostname,
    this.port,
  });
  

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostname': hostname,
      'port': port,
    };
  }

  static NodeInfo fromMap(Map<String, dynamic> map) {
    if (map == null) return null;
  
    return NodeInfo(
      id: map['id'],
      hostname: map['hostname'],
      port: map['port'],
    );
  }

  String toJson() => json.encode(toMap());

  static NodeInfo fromJson(String source) => fromMap(json.decode(source));

  @override
  String toString() => 'NodeInfo(id: $id, hostname: $hostname, port: $port)';
}
