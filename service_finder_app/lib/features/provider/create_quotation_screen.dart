import 'package:flutter/material.dart';

import '../../models/quotation_model.dart';
import '../../models/service_request_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/request_widgets.dart';

class CreateQuotationScreen extends StatefulWidget {
  final ServiceRequestModel request;
  const CreateQuotationScreen({super.key, required this.request});

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _charge = TextEditingController();
  final _inspection = TextEditingController();
  final _materials = TextEditingController();
  final _message = TextEditingController();
  DateTime? _availableAt;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _charge.dispose();
    _inspection.dispose();
    _materials.dispose();
    _message.dispose();
    super.dispose();
  }

  static String? validateAmount(String? value, {bool optional = false}) {
    final text = value?.trim() ?? '';
    if (optional && text.isEmpty) return null;
    final amount = double.tryParse(text);
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text) ||
        amount == null ||
        !amount.isFinite ||
        (optional ? amount < 0 : amount <= 0)) {
      return optional
          ? 'Enter a valid fee (0 or more, up to 2 decimals).'
          : 'Enter a charge greater than 0 (up to 2 decimals).';
    }
    return null;
  }

  double get _total =>
      (double.tryParse(_charge.text.trim()) ?? 0) +
      (double.tryParse(_inspection.text.trim()) ?? 0);

  Future<void> _selectAvailability() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _availableAt != null && _availableAt!.isAfter(now)
          ? _availableAt
          : now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _availableAt == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(_availableAt!),
    );
    if (!mounted || time == null) return;
    setState(
      () => _availableAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _send() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    if (_availableAt != null && !_availableAt!.isAfter(DateTime.now())) {
      setState(() => _error = 'Choose a future available date and time.');
      return;
    }
    if (!_total.isFinite) {
      setState(() => _error = 'The total is too large. Check the amounts.');
      return;
    }
    // Lock the form through confirmation and submission to prevent double sends.
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Send quotation?'),
          content: Text(
            'Send an estimated total of Rs. ${_total.toStringAsFixed(2)} for "${widget.request.title}" to the customer for approval?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Review'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send quotation'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final now = DateTime.now();
      await FirestoreService().sendQuotation(
        QuotationModel(
          quotationId: widget.request.requestId,
          requestId: widget.request.requestId,
          customerId: widget.request.customerId,
          providerId: widget.request.providerId,
          serviceCharge: double.parse(_charge.text.trim()),
          inspectionFee: double.tryParse(_inspection.text.trim()) ?? 0,
          materialCostNote: _materials.text.trim().isEmpty
              ? null
              : _materials.text.trim(),
          estimatedTotal: _total,
          availableAt: _availableAt,
          message: _message.text.trim().isEmpty ? null : _message.text.trim(),
          status: 'sent',
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      setState(() => _sending = false);
      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message.toString());
    } catch (error) {
      debugPrint('Quotation submission failed: $error');
      if (mounted) {
        setState(
          () => _error =
              'Unable to send quotation. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: Scaffold(
      appBar: AppBar(title: const Text('Create quotation')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.request.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Review the request and send your estimate for customer approval.',
              ),
              const SizedBox(height: 20),
              RequestDetailCard(
                title: 'Charges',
                children: [
                  TextFormField(
                    controller: _charge,
                    enabled: !_sending,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Service charge (Rs.)',
                      helperText: 'Required',
                    ),
                    validator: (value) => validateAmount(value),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _inspection,
                    enabled: !_sending,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Inspection fee (Rs.)',
                      helperText: 'Optional; leave blank for no fee',
                    ),
                    validator: (value) => validateAmount(value, optional: true),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  RequestDetailField(
                    'Estimated total',
                    _total.isFinite
                        ? 'Rs. ${_total.toStringAsFixed(2)}'
                        : 'Check the amounts',
                  ),
                  const Text(
                    'Total includes the service charge and inspection fee. Explain any additional material costs below.',
                  ),
                ],
              ),
              RequestDetailCard(
                title: 'Visit and quotation details',
                children: [
                  TextFormField(
                    controller: _materials,
                    enabled: !_sending,
                    maxLines: 3,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Material cost note (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Available date and time (optional)'),
                    subtitle: Text(requestDateTimeLabel(context, _availableAt)),
                    onTap: _sending ? null : _selectAvailability,
                    trailing: _availableAt == null
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            tooltip: 'Clear available time',
                            onPressed: _sending
                                ? null
                                : () => setState(() => _availableAt = null),
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _message,
                    enabled: !_sending,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Message to customer (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    semanticsLabel: _error,
                  ),
                ),
              ElevatedButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Sending quotation...'),
                        ],
                      )
                    : const Text('Send quotation'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}
