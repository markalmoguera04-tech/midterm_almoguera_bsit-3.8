# Community Learning Center Management System

**Name:** Almoguera, Mark John Riel A.
**Section:** BSIT-3.8
**Course:** Mobile Development - Midterm Laboratory Examination (Weeks 7-10, CO3)

A single-file Dart console application (`main.dart`) that registers learning center participants and learning resources, processes fee transactions with discounts, and displays organized records. All input is typed by the user at the console.

## Application Features

| Menu | Feature |
|------|---------|
| 1 | Register a new Participant (name, ID, contact info, status) |
| 2 | Add a new Learning Resource (ID, title, fee, type, available slots) |
| 3 | Process Transaction / Calculate Fees (discount, payment check, stock update) |
| 4 | View all records, or search a record by ID |
| 5 | Exit |

The menu repeats until the user chooses option 5.

### Fee rules

- Active participants receive a 10% discount.
- An additional 5% discount applies when the subtotal is PHP 1,000 or more.
- Only participants with Active status can make a transaction.
- The amount paid must cover the total due; change is computed and shown.
- A successful transaction reduces the resource's available slots and records the payment and enrollment on the participant.

### Status and types

- Participant status: Active, Inactive, or Pending.
- Resource types: Workshop, Book, or Online Course.
- IDs must be unique across all records (case-insensitive).

## Code Structure

| Requirement | Implementation |
|-------------|----------------|
| Abstract class | `CenterRecord` (shared `id`, `name`, abstract `displayDetails()`) |
| Subclasses | `Participant` and `LearningResource`, each overriding `displayDetails()` |
| Polymorphism | Option 4 loops over `List<CenterRecord>` and calls `displayDetails()` |
| Mixins | `Timestamped` (creation time) and `StatusTrackable` (status tracking), applied to both subclasses |
| Encapsulation | Private fields `_contactInfo`, `_totalPaid`, `_fee`, `_quantity`, `_id`, `_name` with validated getters/setters |
| Collections | `List<CenterRecord>` for iteration and `Map<String, CenterRecord>` for lookup by ID, managed by `CenterManager` |
| User-defined functions | `calculateDiscountRate()`, `calculateTotal()`, `readRequired()`, `readInt()`, `readDouble()` |
| Control flow | `while` loop for the menu, `switch` for routing, `if`/`else` for rules |
| Error handling | `try`/`catch` for `FormatException`, `ArgumentError`, `StateError`, and unexpected errors |

## How to Run

Requires the [Dart SDK](https://dart.dev/get-dart).

```bash
dart run main.dart
```

Type your answer at each prompt and press Enter.

> Note: this version uses `dart:io` for keyboard input, so it cannot run in DartPad's Dart (console) mode, which does not support typed input.

## Test Scenarios

1. **Invalid menu input:** enter `9` or `abc` at the main menu. An error message is shown and the menu reappears.
2. **Invalid data:**
   - Leave the name empty when registering. It is re-prompted.
   - Register an ID that already exists. The registration is cancelled.
   - Enter `free` as a fee. It is rejected and re-prompted.
   - Enter `-1` as a quantity. It is rejected and re-prompted.
3. **Successful transaction:**
   - Register participant `P001` as Active.
   - Add resource `R001` (fee 500, 10 slots).
   - Buy 2 units of `R001` as `P001`: subtotal 1000, 15% discount, total PHP 850. Pay 1200 to receive PHP 350 change.
4. **Insufficient payment:** buy 1 unit (total PHP 450) and pay 100. The transaction is cancelled and the shortfall is shown.
5. **Access rule:** register `P002` with Pending status and try a transaction. It is denied.
6. **View and search:** option 4 lists all records, finds `P001`, and reports "no record found" for an unknown ID such as `X999`.
