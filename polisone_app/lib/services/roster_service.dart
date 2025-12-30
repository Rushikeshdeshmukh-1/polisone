import 'package:cloud_firestore/cloud_firestore.dart';

class RosterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate optimal shift assignments for a date
  Future<void> generateSchedule(DateTime date) async {
    try {
      print('🔄 Starting schedule generation for ${date.toString()}');
      
      // Get all available officers (not on leave)
      final officers = await _getAvailableOfficers(date);
      print('✅ Found ${officers.length} available officers');
      
      // Define shift requirements
      final shifts = [
        {'name': 'Morning Shift', 'start': '06:00', 'end': '14:00', 'required': 45},
        {'name': 'Afternoon Shift', 'start': '14:00', 'end': '22:00', 'required': 52},
        {'name': 'Night Shift', 'start': '22:00', 'end': '06:00', 'required': 38},
      ];

      // Assign officers to shifts
      for (var shift in shifts) {
        final assigned = _assignOfficersToShift(officers, shift['required'] as int);
        
        print('📝 Creating shift: ${shift['name']} with ${assigned.length} officers');
        
        final docRef = await _firestore.collection('shifts').add({
          'name': shift['name'],
          'startTime': shift['start'],
          'endTime': shift['end'],
          'date': Timestamp.fromDate(date),
          'requiredOfficers': shift['required'],
          'assignedOfficers': assigned,
          'status': _getShiftStatus(date, shift['start'] as String),
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Shift created with ID: ${docRef.id}');
      }
      
      print('🎉 Schedule generation completed successfully!');
    } catch (e) {
      print('❌ Error generating schedule: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Get officers available on a specific date
  Future<List<String>> _getAvailableOfficers(DateTime date) async {
    final officers = await _firestore
        .collection('officers')
        .where('userId', isNotEqualTo: null)
        .get();

    final available = <String>[];
    
    for (var doc in officers.docs) {
      final userId = doc.data()['userId'] as String;
      
      // Check if officer has approved leave on this date
      final hasLeave = await _hasLeaveOnDate(userId, date);
      
      if (!hasLeave) {
        available.add(userId);
      }
    }
    
    return available;
  }

  // Check if officer has leave on specific date
  Future<bool> _hasLeaveOnDate(String userId, DateTime date) async {
    final leaves = await _firestore
        .collection('leave_requests')
        .where('officerId', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .get();

    for (var doc in leaves.docs) {
      final data = doc.data();
      final startDate = (data['startDate'] as Timestamp).toDate();
      final endDate = (data['endDate'] as Timestamp).toDate();
      
      if (date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)))) {
        return true;
      }
    }
    
    return false;
  }

  // Assign officers to a shift with workload balancing
  List<String> _assignOfficersToShift(List<String> officers, int required) {
    if (officers.length <= required) {
      return officers;
    }
    
    // Simple round-robin assignment
    // In production, this would consider workload, preferences, etc.
    return officers.sublist(0, required);
  }

  // Determine shift status based on current time
  String _getShiftStatus(DateTime date, String startTime) {
    final now = DateTime.now();
    final shiftDate = DateTime(date.year, date.month, date.day);
    
    if (shiftDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return 'completed';
    } else if (shiftDate.isAfter(DateTime(now.year, now.month, now.day))) {
      return 'upcoming';
    } else {
      // Today - check time
      final hour = int.parse(startTime.split(':')[0]);
      if (now.hour >= hour && now.hour < hour + 8) {
        return 'active';
      } else if (now.hour < hour) {
        return 'upcoming';
      } else {
        return 'completed';
      }
    }
  }

  // Process leave request
  Future<void> processLeaveRequest(String requestId, bool approve, {String? reason}) async {
    await _firestore.collection('leave_requests').doc(requestId).update({
      'status': approve ? 'approved' : 'rejected',
      'processedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
  }

  // Get officer workload for current week
  Future<int> getOfficerWorkload(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final shifts = await _firestore
        .collection('shifts')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('date', isLessThan: Timestamp.fromDate(weekEnd))
        .where('assignedOfficers', arrayContains: userId)
        .get();

    return shifts.docs.length * 8; // 8 hours per shift
  }

  // Check if officer is available for a shift
  Future<bool> isOfficerAvailable(String userId, DateTime date, String shiftName) async {
    // Check leave
    if (await _hasLeaveOnDate(userId, date)) {
      return false;
    }

    // Check if already assigned to another shift on same date
    final existingShifts = await _firestore
        .collection('shifts')
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .where('assignedOfficers', arrayContains: userId)
        .get();

    return existingShifts.docs.isEmpty;
  }
}
