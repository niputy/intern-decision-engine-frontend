// This file defines a `LoanForm` widget which is a stateful widget
// that displays a loan application form.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:inbank_frontend/fonts.dart';
import 'package:inbank_frontend/widgets/national_id_field.dart';

import '../api_service.dart';
import '../colors.dart';

// LoanForm is a StatefulWidget that displays a loan application form.
class LoanForm extends StatefulWidget {
  const LoanForm({Key? key}) : super(key: key);

  @override
  _LoanFormState createState() => _LoanFormState();
}

class _LoanFormState extends State<LoanForm> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  String _nationalId = '';
  int _loanAmount = 2500;
  int _loanPeriod = 36;
  int _loanAmountResult = 0;
  int _loanPeriodResult = 0;
  String _errorMessage = '';

  // Submit the form and update the state with the loan decision results.
  // Only submits if the form inputs are validated.
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final result = await _apiService.requestLoanDecision(
          _nationalId, _loanAmount, _loanPeriod);
      setState(() {
        final approvedAmount = int.parse(result['loanAmount'].toString());
        final approvedPeriod = int.parse(result['loanPeriod'].toString());

        _loanAmountResult = min(approvedAmount, _loanAmount);
        _loanPeriodResult = max(approvedPeriod, _loanPeriod);

        _errorMessage = result['errorMessage'].toString();
      });
    } else {
      _loanAmountResult = 0;
      _loanPeriodResult = 0;
    }
  }


  // Builds the application form widget.
  // The widget automatically queries the endpoint for the latest data
  // when a field is changed.
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final formWidth = screenWidth / 3;
    const minWidth = 500.0;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: max(minWidth, formWidth),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  FormField<String>(
                    builder: (state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NationalIdTextFormField(
                            onChanged: (value) {
                              setState(() {
                                _nationalId = value ?? '';
                                _submitForm();
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 60.0),
                  _buildSlider(
                    label: 'Loan Amount',
                    value: _loanAmount,
                    unit: '€',
                    min: 2000,
                    max: 10000,
                    divisions: 80,
                    onChanged: (newValue) {
                      setState(() {
                        _loanAmount = ((newValue.floor() / 100).round() * 100);
                      });
                    },
                  ),
                  const SizedBox(height: 24.0),
                  _buildSlider(
                    label: 'Loan Period',
                    value: _loanPeriod,
                    unit: 'months',
                    min: 12,
                    max: 60,
                    divisions: 40,
                    onChanged: (newValue) {
                      setState(() {
                        _loanPeriod = ((newValue.floor() / 6).round() * 6);
                      });
                    },
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Column(
            children: [
              Text(
                  'Approved Loan Amount: ${_loanAmountResult != 0 ? _loanAmountResult : "--"} €'),
              const SizedBox(height: 8.0),
              Text(
                  'Approved Loan Period: ${_loanPeriodResult != 0 ? _loanPeriodResult : "--"} months'),
              Visibility(
                  visible: _errorMessage != '',
                  child: Text(_errorMessage, style: errorMedium))
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSlider({
  required String label,
  required int value,
  required String unit,
  required double min,
  required double max,
  required int divisions,
  required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Text('$label: $value $unit'),
        const SizedBox(height: 8),
        Slider.adaptive(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: '$value $unit',
          activeColor: AppColors.secondaryColor,
          onChanged: onChanged,
          onChangeEnd: (newValue) {
            setState(() {
              _submitForm();
            });
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('$min $unit'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('$max $unit'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
