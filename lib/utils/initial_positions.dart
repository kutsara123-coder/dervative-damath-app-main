import '../models/chip_model.dart';

List<ChipModel> getInitialChips() {
  final List<Map<String, Object>> data = [
    // 🔵 Player 1 (top)
    {'owner': 1, 'x': 1, 'y': 0, 'poly': {1: -55}},
    {'owner': 1, 'x': 3, 'y': 0, 'poly': {2: -45}},
    {'owner': 1, 'x': 5, 'y': 0, 'poly': {3: 66}},
    {'owner': 1, 'x': 7, 'y': 0, 'poly': {4: 78}},
    {'owner': 1, 'x': 0, 'y': 1, 'poly': {4: -21}},
    {'owner': 1, 'x': 2, 'y': 1, 'poly': {1: -15}},
    {'owner': 1, 'x': 4, 'y': 1, 'poly': {2: 28}},
    {'owner': 1, 'x': 6, 'y': 1, 'poly': {4: 36}},
    {'owner': 1, 'x': 1, 'y': 2, 'poly': {3: -3}},
    {'owner': 1, 'x': 3, 'y': 2, 'poly': {4: -1}},
    {'owner': 1, 'x': 5, 'y': 2, 'poly': {1: 6}},
    {'owner': 1, 'x': 7, 'y': 2, 'poly': {2: 10}},

    // 🔴 Player 2 (bottom)
    {'owner': 2, 'x': 0, 'y': 7, 'poly': {4: 78}},
    {'owner': 2, 'x': 2, 'y': 7, 'poly': {3: 66}},
    {'owner': 2, 'x': 4, 'y': 7, 'poly': {2: -45}},
    {'owner': 2, 'x': 6, 'y': 7, 'poly': {1: -55}},
    {'owner': 2, 'x': 1, 'y': 6, 'poly': {4: 36}},
    {'owner': 2, 'x': 3, 'y': 6, 'poly': {2: 28}},
    {'owner': 2, 'x': 5, 'y': 6, 'poly': {1: -15}},
    {'owner': 2, 'x': 7, 'y': 6, 'poly': {4: -21}},
    {'owner': 2, 'x': 0, 'y': 5, 'poly': {2: 10}},
    {'owner': 2, 'x': 2, 'y': 5, 'poly': {1: 6}},
    {'owner': 2, 'x': 4, 'y': 5, 'poly': {4: -1}},
    {'owner': 2, 'x': 6, 'y': 5, 'poly': {3: -3}},
  ];

  return data.asMap().entries
      .map((entry) => ChipModel(
            id: entry.key,
            owner: entry.value['owner'] as int,
            x: entry.value['x'] as int,
            y: entry.value['y'] as int,
            terms: entry.value['poly'] as Map<int, int>,
          ))
      .toList();
}
