import 'dart:collection';

void main() {
  List<HashMap<String, int>> timestamp = List<HashMap<String, int>>();
  HashMap<String, int> firstFileTimestamps = HashMap<String, int>();
  firstFileTimestamps.putIfAbsent(
      "clientId", () => DateTime.now().millisecondsSinceEpoch);
  timestamp.add(firstFileTimestamps);
  print(timestamp.toString());
}
