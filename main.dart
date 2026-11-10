import 'dart:io';

class InputEndedException implements Exception {
  @override
  String toString() => 'No more input available.';
}

class InputReader {
  String readLine(String prompt) {
    stdout.write(prompt);
    final value = stdin.readLineSync();
    if (value == null) {
      print('');
      throw InputEndedException();
    }
    return value;
  }
}

final InputReader _input = InputReader();

enum RecordStatus { active, inactive, pending }

mixin Timestamped {
  DateTime? _createdAt;

  void stampCreation() => _createdAt = DateTime.now();

  String get createdAtLabel {
    final created = _createdAt;
    return created == null ? 'N/A' : created.toString().substring(0, 19);
  }
}

mixin StatusTrackable {
  RecordStatus _status = RecordStatus.pending;

  RecordStatus get status => _status;

  void updateStatus(RecordStatus newStatus) => _status = newStatus;

  String get statusLabel =>
      _status.name[0].toUpperCase() + _status.name.substring(1);
}

abstract class CenterRecord {
  final String _id;
  String _name;

  CenterRecord(String id, String name)
      : _id = id.trim(),
        _name = name.trim() {
    if (_id.isEmpty) throw ArgumentError('ID cannot be empty.');
    if (_name.isEmpty) throw ArgumentError('Name cannot be empty.');
  }

  String get id => _id;
  String get name => _name;

  set name(String value) {
    if (value.trim().isEmpty) throw ArgumentError('Name cannot be empty.');
    _name = value.trim();
  }

  String get recordType;

  void displayDetails();
}

class Participant extends CenterRecord with Timestamped, StatusTrackable {
  String _contactInfo;
  double _totalPaid = 0;
  final List<String> _enrolledResourceIds = [];

  Participant(super.id, super.name, String contactInfo, RecordStatus status)
      : _contactInfo = '' {
    this.contactInfo = contactInfo;
    updateStatus(status);
    stampCreation();
  }

  @override
  String get recordType => 'Participant';

  String get contactInfo => _contactInfo;

  set contactInfo(String value) {
    if (value.trim().length < 5) {
      throw ArgumentError('Contact info must be at least 5 characters.');
    }
    _contactInfo = value.trim();
  }

  double get totalPaid => _totalPaid;
  List<String> get enrolledResourceIds => List.unmodifiable(_enrolledResourceIds);

  void addPayment(double amount) {
    if (amount < 0) throw ArgumentError('Payment cannot be negative.');
    _totalPaid += amount;
  }

  void enroll(String resourceId) {
    if (!_enrolledResourceIds.contains(resourceId)) {
      _enrolledResourceIds.add(resourceId);
    }
  }

  @override
  void displayDetails() {
    print('[Participant] $id - $name');
    print('   Contact : $_contactInfo');
    print('   Status  : $statusLabel');
    print('   Created : $createdAtLabel');
    print('   Paid    : PHP ${_totalPaid.toStringAsFixed(2)}');
    print('   Enrolled: ${_enrolledResourceIds.isEmpty ? "none" : _enrolledResourceIds.join(", ")}');
  }
}

class LearningResource extends CenterRecord with Timestamped, StatusTrackable {
  double _fee;
  int _quantity;
  final String type;

  LearningResource(super.id, super.name, double fee, this.type, int quantity)
      : _fee = 0,
        _quantity = 0 {
    this.fee = fee;
    this.quantity = quantity;
    updateStatus(_quantity > 0 ? RecordStatus.active : RecordStatus.inactive);
    stampCreation();
  }

  @override
  String get recordType => 'Learning Resource';

  double get fee => _fee;

  set fee(double value) {
    if (value < 0) throw ArgumentError('Fee cannot be negative.');
    _fee = value;
  }

  int get quantity => _quantity;

  set quantity(int value) {
    if (value < 0) throw ArgumentError('Quantity cannot be negative.');
    _quantity = value;
  }

  bool get isAvailable => _quantity > 0;

  void reduceStock(int amount) {
    if (amount <= 0 || amount > _quantity) {
      throw StateError('Not enough slots/copies available.');
    }
    _quantity -= amount;
    if (_quantity == 0) updateStatus(RecordStatus.inactive);
  }

  @override
  void displayDetails() {
    print('[Resource] $id - $name');
    print('   Type    : $type');
    print('   Fee     : PHP ${_fee.toStringAsFixed(2)}');
    print('   Slots   : $_quantity');
    print('   Status  : $statusLabel');
    print('   Created : $createdAtLabel');
  }
}

class CenterManager {
  final List<CenterRecord> _records = [];
  final Map<String, CenterRecord> _recordMap = {};

  List<CenterRecord> get records => List.unmodifiable(_records);

  bool containsId(String id) => _recordMap.containsKey(id.trim().toUpperCase());

  bool addRecord(CenterRecord record) {
    final key = record.id.toUpperCase();
    if (_recordMap.containsKey(key)) return false;
    _records.add(record);
    _recordMap[key] = record;
    return true;
  }

  CenterRecord? findById(String id) => _recordMap[id.trim().toUpperCase()];

  Participant? findParticipant(String id) {
    final record = findById(id);
    return record is Participant ? record : null;
  }

  LearningResource? findResource(String id) {
    final record = findById(id);
    return record is LearningResource ? record : null;
  }
}

double calculateDiscountRate(bool isActiveMember, double subtotal) {
  double rate = 0;
  if (isActiveMember) rate += 0.10;
  if (subtotal >= 1000) rate += 0.05;
  return rate;
}

double calculateTotal(double fee, int quantity, double discountRate) {
  final subtotal = fee * quantity;
  return subtotal - (subtotal * discountRate);
}

String readRequired(String prompt) {
  while (true) {
    final value = _input.readLine(prompt).trim();
    if (value.isNotEmpty) return value;
    print('  ! Input cannot be empty. Please try again.');
  }
}

int readInt(String prompt, {int min = 0, int max = 1000000}) {
  while (true) {
    try {
      final value = int.parse(_input.readLine(prompt).trim());
      if (value < min || value > max) {
        print('  ! Enter a whole number from $min to $max.');
        continue;
      }
      return value;
    } on FormatException {
      print('  ! Invalid number. Please enter a whole number.');
    }
  }
}

double readDouble(String prompt, {double min = 0}) {
  while (true) {
    try {
      final value = double.parse(_input.readLine(prompt).trim());
      if (value < min) {
        print('  ! Value must be at least $min.');
        continue;
      }
      return value;
    } on FormatException {
      print('  ! Invalid amount. Please enter a number (e.g., 500 or 99.50).');
    }
  }
}

void registerParticipant(CenterManager manager) {
  print('\n--- Register New Participant ---');
  final name = readRequired('Full name: ');
  final id = readRequired('Participant ID: ');
  if (manager.containsId(id)) {
    print('  ! ID "$id" already exists. Registration cancelled.');
    return;
  }
  final contact = readRequired('Contact info (phone/email): ');
  final statusChoice = readInt('Status (1=Active, 2=Inactive, 3=Pending): ', min: 1, max: 3);

  RecordStatus status;
  switch (statusChoice) {
    case 1:
      status = RecordStatus.active;
      break;
    case 2:
      status = RecordStatus.inactive;
      break;
    default:
      status = RecordStatus.pending;
  }

  try {
    manager.addRecord(Participant(id, name, contact, status));
    print('  Participant "$name" registered successfully.');
  } on ArgumentError catch (e) {
    print('  ! Could not register participant: ${e.message}');
  }
}

void addLearningResource(CenterManager manager) {
  print('\n--- Add New Learning Resource ---');
  final id = readRequired('Resource ID: ');
  if (manager.containsId(id)) {
    print('  ! ID "$id" already exists. Operation cancelled.');
    return;
  }
  final title = readRequired('Title: ');
  final fee = readDouble('Fee (PHP): ');
  final typeChoice = readInt('Type (1=Workshop, 2=Book, 3=Online Course): ', min: 1, max: 3);
  final quantity = readInt('Available slots/copies: ', min: 1);

  String type;
  switch (typeChoice) {
    case 1:
      type = 'Workshop';
      break;
    case 2:
      type = 'Book';
      break;
    default:
      type = 'Online Course';
  }

  try {
    manager.addRecord(LearningResource(id, title, fee, type, quantity));
    print('  Resource "$title" added successfully.');
  } on ArgumentError catch (e) {
    print('  ! Could not add resource: ${e.message}');
  }
}

void processTransaction(CenterManager manager) {
  print('\n--- Process Transaction / Calculate Fees ---');
  final participant = manager.findParticipant(readRequired('Participant ID: '));
  if (participant == null) {
    print('  ! Participant not found.');
    return;
  }
  if (participant.status != RecordStatus.active) {
    print('  ! ${participant.name} is ${participant.statusLabel}. Only Active participants can transact.');
    return;
  }

  final resource = manager.findResource(readRequired('Resource ID: '));
  if (resource == null) {
    print('  ! Resource not found.');
    return;
  }
  if (!resource.isAvailable) {
    print('  ! "${resource.name}" has no slots/copies left.');
    return;
  }

  final quantity = readInt('Quantity (1-${resource.quantity}): ', min: 1, max: resource.quantity);
  final subtotal = resource.fee * quantity;
  final rate = calculateDiscountRate(participant.status == RecordStatus.active, subtotal);
  final total = calculateTotal(resource.fee, quantity, rate);

  print('  Subtotal : PHP ${subtotal.toStringAsFixed(2)}');
  print('  Discount : ${(rate * 100).toStringAsFixed(0)}%');
  print('  Total due: PHP ${total.toStringAsFixed(2)}');

  final paid = readDouble('Amount paid (PHP): ');
  if (paid < total) {
    print('  ! Insufficient payment. Short by PHP ${(total - paid).toStringAsFixed(2)}. Transaction cancelled.');
    return;
  }

  try {
    resource.reduceStock(quantity);
    participant.addPayment(total);
    participant.enroll(resource.id);
    print('  Transaction complete. Change: PHP ${(paid - total).toStringAsFixed(2)}');
  } on StateError catch (e) {
    print('  ! Transaction failed: ${e.message}');
  }
}

void viewAndSearchRecords(CenterManager manager) {
  print('\n--- View / Search Records ---');
  final choice = readInt('1=View all records, 2=Search by ID: ', min: 1, max: 2);

  if (choice == 1) {
    if (manager.records.isEmpty) {
      print('  No records yet.');
      return;
    }
    print('');
    for (final CenterRecord record in manager.records) {
      record.displayDetails();
      print('');
    }
    print('  Total records: ${manager.records.length}');
  } else {
    final record = manager.findById(readRequired('Enter ID to search: '));
    if (record == null) {
      print('  ! No record found with that ID.');
    } else {
      print('');
      record.displayDetails();
    }
  }
}

void printMenu() {
  print('\n==============================================');
  print('  COMMUNITY LEARNING CENTER MANAGEMENT SYSTEM');
  print('==============================================');
  print('  1. Register a new Participant');
  print('  2. Add a new Learning Resource');
  print('  3. Process Transaction / Calculate Fees');
  print('  4. View All Records & Search by ID');
  print('  5. Exit');
  print('----------------------------------------------');
}

void main() {
  final manager = CenterManager();
  bool running = true;

  while (running) {
    try {
      printMenu();
      int choice;
      try {
        choice = int.parse(_input.readLine('Choose an option (1-5): ').trim());
      } on FormatException {
        print('  ! Invalid input. Please enter a number from 1 to 5.');
        continue;
      }

      switch (choice) {
        case 1:
          registerParticipant(manager);
          break;
        case 2:
          addLearningResource(manager);
          break;
        case 3:
          processTransaction(manager);
          break;
        case 4:
          viewAndSearchRecords(manager);
          break;
        case 5:
          print('\nThank you for using the system. Goodbye!');
          running = false;
          break;
        default:
          print('  ! Invalid option. Please choose 1-5.');
      }
    } on InputEndedException {
      print('\nInput ended. Exiting program.');
      running = false;
    } catch (e) {
      print('  ! Unexpected error: $e');
    }
  }
}