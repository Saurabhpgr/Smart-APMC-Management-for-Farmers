import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../models/slot_model.dart';

class AdminManageSlotsScreen extends StatefulWidget {
  const AdminManageSlotsScreen({Key? key}) : super(key: key);

  @override
  State<AdminManageSlotsScreen> createState() => _AdminManageSlotsScreenState();
}

class _AdminManageSlotsScreenState extends State<AdminManageSlotsScreen> {
  final DBService _dbService = DBService();

  void _showSlotDialog({SlotModel? existingSlot}) {
    final isEditing = existingSlot != null;
    
    final _formKey = GlobalKey<FormState>();
    final _cropTypeController = TextEditingController(text: existingSlot?.cropType ?? '');
    final _capacityController = TextEditingController(text: existingSlot?.capacity.toString() ?? '');
    final _marketYardController = TextEditingController(text: existingSlot?.marketYard ?? 'Nashik APMC');
    
    DateTime? _selectedDate = existingSlot != null ? DateFormat('yyyy-MM-dd').parse(existingSlot.date) : DateTime.now();
    TimeOfDay? _startTime = existingSlot != null ? TimeOfDay(hour: int.parse(existingSlot.startTime.split(':')[0]), minute: int.parse(existingSlot.startTime.split(':')[1])) : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay? _endTime = existingSlot != null ? TimeOfDay(hour: int.parse(existingSlot.endTime.split(':')[0]), minute: int.parse(existingSlot.endTime.split(':')[1])) : const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Slot' : 'Create Slot'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Date'),
                        subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate!,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Start'),
                              subtitle: Text(_startTime!.format(context)),
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: _startTime!);
                                if (picked != null) setState(() => _startTime = picked);
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('End'),
                              subtitle: Text(_endTime!.format(context)),
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: _endTime!);
                                if (picked != null) setState(() => _endTime = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _cropTypeController,
                        decoration: const InputDecoration(labelText: 'Produce Type (e.g., Onion)'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _capacityController,
                        decoration: const InputDecoration(labelText: 'Max Capacity (Farmers)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _marketYardController,
                        decoration: const InputDecoration(labelText: 'Market Yard'),
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
                      final slotData = {
                        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        'startTime': '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                        'endTime': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
                        'cropType': _cropTypeController.text.trim(),
                        'capacity': int.parse(_capacityController.text.trim()),
                        'marketYard': _marketYardController.text.trim(),
                        'bookedCount': existingSlot?.bookedCount ?? 0,
                        'status': existingSlot?.status ?? 'open',
                      };

                      if (isEditing) {
                        await _dbService.updateSlot(existingSlot.id, slotData);
                      } else {
                        await _dbService.createSlot(slotData);
                      }
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Slot updated' : 'Slot created')));
                      }
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _closeSlot(String id) async {
    await _dbService.updateSlot(id, {'status': 'closed'});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot closed')));
  }

  void _deleteSlot(String id) async {
    await _dbService.deleteSlot(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Slots'),
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSlotDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getSlots(), // using existing getSlots method
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No slots found. Create one!'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final slot = SlotModel.fromMap(data, docs[index].id);

              Color statusColor = Colors.green;
              if (slot.status == 'full') statusColor = Colors.orange;
              if (slot.status == 'closed') statusColor = Colors.red;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${slot.date}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(slot.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Time: ${slot.startTime} - ${slot.endTime}'),
                      Text('Crop: ${slot.cropType} | Yard: ${slot.marketYard}'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: slot.capacity > 0 ? slot.bookedCount / slot.capacity : 0,
                        backgroundColor: Colors.grey.shade200,
                        color: statusColor,
                      ),
                      const SizedBox(height: 4),
                      Text('Booked: ${slot.bookedCount} / ${slot.capacity}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showSlotDialog(existingSlot: slot),
                          ),
                          if (slot.status != 'closed')
                            IconButton(
                              icon: const Icon(Icons.lock, color: Colors.orange),
                              tooltip: 'Emergency Close',
                              onPressed: () => _closeSlot(slot.id),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSlot(slot.id),
                          ),
                        ],
                      )
                    ],
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
