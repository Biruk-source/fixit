import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../services/firebase_service.dart';

class PaymentScreen extends StatefulWidget {
  final Job job;

  const PaymentScreen({Key? key, required this.job}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedPaymentMethod = 'Credit Card';

  // Payment info controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Simulate payment processing
        await Future.delayed(const Duration(seconds: 2));

        // Update job status to paid
        await _firebaseService.updateJobStatus(
            widget.job.id, widget.job.clientId, widget.job.seekerId, 'paid');

        // Create payment record
        await _firebaseService.createPaymentRecord(
          jobId: widget.job.id,
          amount: widget.job.budget,
          paymentMethod: _selectedPaymentMethod,
          status: 'success',
        );

        if (!mounted) return;

        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildOrderItem(
                            'Job',
                            widget.job.title,
                          ),
                          const Divider(),
                          _buildOrderItem(
                            'Service Fee',
                            '\$${(widget.job.budget * 0.1).toStringAsFixed(2)}',
                          ),
                          const Divider(),
                          _buildOrderItem(
                            'Total',
                            '\$${(widget.job.budget * 1.1).toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment method selection
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment methods
                  _buildPaymentMethodTile(
                    'Credit Card',
                    Icons.credit_card,
                    'Pay with your credit or debit card',
                  ),

                  const SizedBox(height: 8),
                  _buildPaymentMethodTile(
                    'PayPal',
                    Icons.account_balance_wallet,
                    'Pay with your PayPal account',
                    enabled: false,
                  ),

                  const SizedBox(height: 8),
                  _buildPaymentMethodTile(
                    'Bank Transfer',
                    Icons.account_balance,
                    'Pay directly from your bank account',
                    enabled: false,
                  ),

                  const SizedBox(height: 24),

                  // Credit card form
                  if (_selectedPaymentMethod == 'Credit Card')
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Card Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Card number field
                          TextFormField(
                            controller: _cardNumberController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Card Number',
                              hintText: 'XXXX XXXX XXXX XXXX',
                              prefixIcon: Icon(Icons.credit_card),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your card number';
                              }
                              // Simple check for demo
                              if (value.replaceAll(' ', '').length != 16) {
                                return 'Please enter a valid 16-digit card number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Card holder field
                          TextFormField(
                            controller: _cardHolderController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Card Holder Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter card holder name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Expiry date and CVV
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _expiryDateController,
                                  keyboardType: TextInputType.datetime,
                                  decoration: const InputDecoration(
                                    labelText: 'Expiry Date',
                                    hintText: 'MM/YY',
                                    prefixIcon: Icon(Icons.date_range),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    // Simple check for demo
                                    if (!RegExp(r'^\d{2}/\d{2}$')
                                        .hasMatch(value)) {
                                      return 'Use MM/YY format';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _cvvController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'CVV',
                                    hintText: 'XXX',
                                    prefixIcon: Icon(Icons.security),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (value.length < 3 || value.length > 4) {
                                      return 'Invalid CVV';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Pay \$${(widget.job.budget * 1.1).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Secure checkout info
                  const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Secure Checkout',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderItem(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(String title, IconData icon, String subtitle,
      {bool enabled = true}) {
    return Card(
      elevation: _selectedPaymentMethod == title ? 2 : 0,
      color: enabled
          ? (_selectedPaymentMethod == title
              ? Colors.blue.withOpacity(0.1)
              : null)
          : Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedPaymentMethod == title
              ? Colors.blue
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: enabled
            ? () {
                setState(() {
                  _selectedPaymentMethod = title;
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: enabled ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: enabled ? Colors.black : Colors.grey,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: enabled ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedPaymentMethod == title && enabled)
                const Icon(Icons.check_circle, color: Colors.blue),
              if (!enabled)
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
