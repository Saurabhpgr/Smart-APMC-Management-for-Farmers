import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/db_service.dart';
import '../models/slot_model.dart';
import '../providers/auth_provider.dart';

class FarmerBookSlotScreen extends StatefulWidget {
  const FarmerBookSlotScreen({Key? key}) : super(key: key);

  @override
  State<FarmerBookSlotScreen> createState() => _FarmerBookSlotScreenState();
}

class _FarmerBookSlotScreenState extends State<FarmerBookSlotScreen> {
  final DBService _dbService = DBService();

  void _showBookingDialog(SlotModel slot) {
    final _formKey = GlobalKey<FormState>();
    final _cropController = TextEditingController(text: slot.cropType);
    final _qtyController = TextEditingController();
    final _vehicleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Book Slot: ${slot.startTime} - ${slot.endTime}'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${slot.date}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cropController,
                    decoration: const InputDecoration(labelText: 'Crop Name'),
                    readOnly: true, // Tied to the slot
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _qtyController,
                    decoration: const InputDecoration(labelText: 'Quantity (Quintal)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: const InputDecoration(labelText: 'Vehicle Number (e.g. MH15AB1234)'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final farmerId = Provider.of<AuthProvider>(context, listen: false).appUser!.uid;
                  
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  bool success = await _dbService.bookSlot(
                    farmerId,
                    slot.id,
                    _cropController.text.trim(),
                    double.parse(_qtyController.text.trim()),
                    _vehicleController.text.trim(),
                  );

                  // Pop loading
                  Navigator.pop(context);
                  // Pop form
                  Navigator.pop(context);

                  if (success && mounted) {
                    _showConfirmation(slot);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to book slot. It might be full!')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Confirm Booking'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmation(SlotModel slot) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Booking Confirmed! ✅', style: TextStyle(color: Colors.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Token No: APMC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'),
            const SizedBox(height: 8),
            Text('Arrival Time: ${slot.startTime}'),
            Text('Date: ${slot.date}'),
            Text('Crop: ${slot.cropType}'),
            const SizedBox(height: 16),
            const Text('Please show this token at the APMC gate.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Slot'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getOpenSlots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          var docs = snapshot.data?.docs.toList() ?? [];
          if (docs.isEmpty) return const Center(child: Text('No open slots available at the moment.'));

          // Sort by date and then time to avoid Firebase index requirement
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            int dateComp = (dataA['date'] as String? ?? '').compareTo(dataB['date'] as String? ?? '');
            if (dateComp != 0) return dateComp;
            return (dataA['startTime'] as String? ?? '').compareTo(dataB['startTime'] as String? ?? '');
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final slot = SlotModel.fromMap(data, docs[index].id);

              final available = slot.capacity - slot.bookedCount;

              // Extra safeguard (should be filtered by stream anyway, but just in case)
              if (available <= 0) return const SizedBox.shrink();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text('${slot.startTime} - ${slot.endTime}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Date: ${slot.date}'),
                      Text('Crop: ${slot.cropType}'),
                      const SizedBox(height: 8),
                      Text('$available Left', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _showBookingDialog(slot),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Book'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
