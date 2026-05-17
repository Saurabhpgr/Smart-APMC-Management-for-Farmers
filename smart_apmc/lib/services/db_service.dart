import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DBService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic method to get a user from any collection
  Future<AppUser?> getUser(String uid) async {
    // Check farmers
    var doc = await _firestore.collection('farmers').doc(uid).get();
    if (doc.exists) return AppUser.fromMap(doc.data()!, uid);

    // Check traders
    doc = await _firestore.collection('traders').doc(uid).get();
    if (doc.exists) return AppUser.fromMap(doc.data()!, uid);

    // Check admins
    doc = await _firestore.collection('admins').doc(uid).get();
    if (doc.exists) return AppUser.fromMap(doc.data()!, uid);

    return null;
  }

  Future<void> createUser(AppUser user) async {
    String collection = '${user.role}s';
    await _firestore.collection(collection).doc(user.uid).set(user.toMap());
  }

  // Common slots stream
  Stream<QuerySnapshot> getSlots() {
    return _firestore.collection('slots').orderBy('date').snapshots();
  }

  // ---- PRODUCE & BIDDING ----

  Future<void> addProduce(Map<String, dynamic> produceData) async {
    await _firestore.collection('produce').add(produceData);
  }

  Stream<QuerySnapshot> getFarmerProduce(String farmerId) {
    // Sort locally to avoid Firebase composite index errors
    return _firestore.collection('produce')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots();
  }

  Stream<QuerySnapshot> getAvailableProduce() {
    // Fetch all produce. Filtering (available, in_auction vs sold) is done on the client side.
    return _firestore.collection('produce')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getTraderActiveBids(String traderId) {
    // Only return in_auction items where trader is participating
    return _firestore.collection('produce')
        .where('participants', arrayContains: traderId)
        .where('status', isEqualTo: 'in_auction')
        .snapshots();
  }

  Stream<QuerySnapshot> getAllLiveAuctions() {
    return _firestore.collection('produce')
        .where('status', isEqualTo: 'in_auction')
        .snapshots();
  }

  Future<void> adminUpdateAuctionStatus(String produceId, String newStatus) async {
    Map<String, dynamic> updates = {'status': newStatus};
    if (newStatus == 'sold') {
      updates['paymentStatus'] = 'pending'; // Requires payment
    } else if (newStatus == 'cancelled') {
      updates['paymentStatus'] = 'none';
    }
    
    await _firestore.collection('produce').doc(produceId).update(updates);
  }

  // ---- PAYMENTS ----

  Stream<QuerySnapshot> getTraderPendingPayments(String traderId) {
    return _firestore.collection('produce')
        .where('highestBidderId', isEqualTo: traderId)
        .where('status', isEqualTo: 'sold')
        .snapshots();
  }

  Future<void> processTraderPayment(String produceId) async {
    await _firestore.collection('produce').doc(produceId).update({
      'paymentStatus': 'verification_pending',
    });
  }

  Stream<QuerySnapshot> getAdminPendingVerifications() {
    return _firestore.collection('produce')
        .where('paymentStatus', isEqualTo: 'verification_pending')
        .snapshots();
  }

  Future<void> adminVerifyPayment(String produceId, bool isApproved) async {
    await _firestore.collection('produce').doc(produceId).update({
      'paymentStatus': isApproved ? 'completed' : 'failed',
    });
  }

  Future<bool> placeBid(String produceId, String traderId, double bidAmount) async {
    DocumentReference produceRef = _firestore.collection('produce').doc(produceId);

    try {
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(produceRef);

        if (!snapshot.exists) {
          throw Exception("Produce not found!");
        }

        String status = snapshot.get('status') ?? 'available';
        if (status == 'sold') {
          throw Exception("Produce is already sold!");
        }

        double currentHighestBid = (snapshot.get('currentHighestBid') ?? 0).toDouble();
        if (bidAmount <= currentHighestBid) {
          throw Exception("Bid must be higher than current highest bid.");
        }

        // Add the bid to a subcollection (optional but good for history)
        DocumentReference bidRef = produceRef.collection('bids').doc();
        transaction.set(bidRef, {
          'traderId': traderId,
          'amount': bidAmount,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Prepare updates
        Map<String, dynamic> updates = {
          'currentHighestBid': bidAmount,
          'highestBidderId': traderId,
          'participants': FieldValue.arrayUnion([traderId]),
        };

        // If this is the very first bid, start the 2-hour countdown timer
        if (status == 'available') {
          updates['status'] = 'in_auction';
          updates['auctionEndTime'] = DateTime.now().add(const Duration(hours: 2));
        }

        // Update the main document
        transaction.update(produceRef, updates);

        return true;
      });
    } catch (e) {
      print("Bid transaction failed: $e");
      return false;
    }
  }

  Stream<QuerySnapshot> getMarketPrices() {
    return _firestore.collection('market_prices').orderBy('date', descending: true).snapshots();
  }

  Future<void> createMarketPrice(Map<String, dynamic> priceData) async {
    await _firestore.collection('market_prices').add(priceData);
  }

  Future<void> updateMarketPrice(String priceId, Map<String, dynamic> priceData) async {
    await _firestore.collection('market_prices').doc(priceId).update(priceData);
  }

  Future<void> deleteMarketPrice(String priceId) async {
    await _firestore.collection('market_prices').doc(priceId).delete();
  }

  // Get pending users by collection
  Stream<QuerySnapshot> getPendingUsers(String collection) {
    return _firestore.collection(collection).where('status', isEqualTo: 'pending').snapshots();
  }

  // Update user status
  Future<void> updateUserStatus(String uid, String role, String status) async {
    String collection = '${role}s';
    await _firestore.collection(collection).doc(uid).update({'status': status});
  }

  // ---- SLOT MANAGEMENT (ADMIN) ----

  Future<void> createSlot(Map<String, dynamic> slotData) async {
    await _firestore.collection('slots').add(slotData);
  }

  Future<void> updateSlot(String slotId, Map<String, dynamic> slotData) async {
    await _firestore.collection('slots').doc(slotId).update(slotData);
  }

  Future<void> deleteSlot(String slotId) async {
    await _firestore.collection('slots').doc(slotId).delete();
  }

  // ---- BOOKING (FARMER) ----

  Stream<QuerySnapshot> getOpenSlots() {
    // Only return slots that are open
    // Note: removed .orderBy('date') to avoid Firebase composite index errors.
    // Sorting will be done on the client side.
    return _firestore.collection('slots')
        .where('status', isEqualTo: 'open')
        .snapshots();
  }

  Future<bool> bookSlot(String farmerId, String slotId, String crop, double quantity, String vehicleNumber) async {
    DocumentReference slotRef = _firestore.collection('slots').doc(slotId);
    DocumentReference bookingRef = _firestore.collection('bookings').doc();

    try {
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot slotSnapshot = await transaction.get(slotRef);

        if (!slotSnapshot.exists) {
          throw Exception("Slot does not exist!");
        }

        int capacity = slotSnapshot.get('capacity') ?? 0;
        int bookedCount = slotSnapshot.get('bookedCount') ?? 0;
        String status = slotSnapshot.get('status') ?? 'open';

        if (status != 'open') {
          throw Exception("Slot is no longer open!");
        }

        if (bookedCount >= capacity) {
          throw Exception("Slot is already full!");
        }

        // Increment booked count
        int newBookedCount = bookedCount + 1;
        String newStatus = (newBookedCount >= capacity) ? 'full' : 'open';

        // Update slot
        transaction.update(slotRef, {
          'bookedCount': newBookedCount,
          'status': newStatus,
        });

        // Create booking
        transaction.set(bookingRef, {
          'farmerId': farmerId,
          'slotId': slotId,
          'crop': crop,
          'quantity': quantity,
          'vehicleNumber': vehicleNumber,
          'status': 'confirmed',
          'bookedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      print("Transaction failed: $e");
      return false;
    }
  }
}
