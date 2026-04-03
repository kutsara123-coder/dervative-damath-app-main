/// Predefined capture scenarios for testing Dama capture rules
/// All positions are diagonal (as per Damath rules)
/// 
/// Rules:
/// 1. Block if chip is between D and O (any chip - team or opponent)
/// 2. Block if chip is immediately after O (no empty landing space)
/// 3. Allow if chip is 2+ spaces after O (has empty landing space)
library;

class CaptureScenario {
  final String name;
  final String description;
  final bool isAllowed;
  final List<Map<String, dynamic>> chips;

  const CaptureScenario({
    required this.name,
    required this.description,
    required this.isAllowed,
    required this.chips,
  });
}

/// List of all capture test scenarios (diagonal positions)
final List<CaptureScenario> captureScenarios = [
  // ============ ALLOWED SCENARIOS ============
  
  CaptureScenario(
    name: 'Allowed: D - O',
    description: 'Empty space immediately after O (diagonal) - ALLOWED',
    isAllowed: true,
    chips: [
      {'x': 0, 'y': 0, 'owner': 1, 'isDama': true, 'terms': {0: 1}},
      {'x': 2, 'y': 2, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O
    ],
  ),
  
  CaptureScenario(
    name: 'Allowed: D - O - T',
    description: 'Team chip 2+ spaces after O (diagonal) - ALLOWED',
    isAllowed: true,
    chips: [
      {'x': 0, 'y': 0, 'owner': 1, 'isDama': true, 'terms': {0: 1}},
      {'x': 2, 'y': 2, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O
      {'x': 4, 'y': 4, 'owner': 1, 'isDama': false, 'terms': {0: 1}}, // T
    ],
  ),
  
  CaptureScenario(
    name: 'Allowed: D - O - O',
    description: 'Opponent chip 2+ spaces after O (diagonal) - ALLOWED',
    isAllowed: true,
    chips: [
      {'x': 0, 'y': 0, 'owner': 1, 'isDama': true, 'terms': {0: 1}},
      {'x': 2, 'y': 2, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O (to capture)
      {'x': 4, 'y': 4, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O (other)
    ],
  ),
  
  CaptureScenario(
    name: 'Allowed: D - - O',
    description: 'O further away with empty space (diagonal) - ALLOWED',
    isAllowed: true,
    chips: [
      {'x': 0, 'y': 0, 'owner': 1, 'isDama': true, 'terms': {0: 1}},
      {'x': 3, 'y': 3, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O
    ],
  ),

  // ============ NOT ALLOWED SCENARIOS ============
  
  CaptureScenario(
    name: 'Not Allowed: D - O T',
    description: 'Team chip immediately after O (diagonal) - BLOCKED',
    isAllowed: false,
    chips: [
      {'x': 0, 'y': 0, 'owner': 1, 'isDama': true, 'terms': {0: 1}},
      {'x': 2, 'y': 2, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O
      {'x': 3, 'y': 3, 'owner': 1, 'isDama': false, 'terms': {0: 1}}, // T
    ],
  ),
  
  CaptureScenario(
    name: 'Not Allowed: D - O O',
    description: 'Opponent chip immediately after O (diagonal) - BLOCKED',
    isAllowed: false,
    chips: [
      {'x': 0, 'y': 0, 'owner': 1, 'isDama': true, 'terms': {0: 1}},
      {'x': 2, 'y': 2, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O
      {'x': 3, 'y': 3, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O
    ],
  ),
  
  CaptureScenario(
    name: 'Not Allowed: D T O',
    description: 'Team chip between D and O (diagonal) - BLOCKED',
    isAllowed: false,
    chips: [
      {'x': 0, 'y': 0, 'owner': 1, 'isDama': true, 'terms': {0: 1}},
      {'x': 1, 'y': 1, 'owner': 1, 'isDama': false, 'terms': {0: 1}}, // T
      {'x': 2, 'y': 2, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O
    ],
  ),
  
  CaptureScenario(
    name: 'Not Allowed: D - T - O',
    description: 'Team chip between D and O with gap (diagonal) - BLOCKED',
    isAllowed: false,
    chips: [
      {'x': 0, 'y': 0, 'owner': 1, 'isDama': true, 'terms': {0: 1}},
      {'x': 2, 'y': 2, 'owner': 1, 'isDama': false, 'terms': {0: 1}}, // T
      {'x': 4, 'y': 4, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O
    ],
  ),
  
  CaptureScenario(
    name: 'Not Allowed: D - - O T',
    description: 'Team chip immediately after O (diagonal) - BLOCKED',
    isAllowed: false,
    chips: [
      {'x': 0, 'y': 0, 'owner': 1, 'isDama': true, 'terms': {0: 1}},
      {'x': 3, 'y': 3, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O
      {'x': 4, 'y': 4, 'owner': 1, 'isDama': false, 'terms': {0: 1}}, // T
    ],
  ),
  
  CaptureScenario(
    name: 'Not Allowed: D - - O O',
    description: 'Opponent chip immediately after O (diagonal) - BLOCKED',
    isAllowed: false,
    chips: [
      {'x': 0, 'y': 0, 'owner': 1, 'isDama': true, 'terms': {0: 1}},
      {'x': 3, 'y': 3, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O
      {'x': 4, 'y': 4, 'owner': 2, 'isDama': false, 'terms': {0: 1}}, // O
    ],
  ),
];

/// Get scenarios grouped by allowed/not allowed
Map<String, List<CaptureScenario>> getScenariosByCategory() {
  return {
    'Allowed': captureScenarios.where((s) => s.isAllowed).toList(),
    'Not Allowed': captureScenarios.where((s) => !s.isAllowed).toList(),
  };
}
