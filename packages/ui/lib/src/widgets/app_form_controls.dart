import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// Multiline form input with the same decoration as [AppTextField].
class AppTextArea extends StatelessWidget {
  const AppTextArea({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.maxLines = 5,
    this.maxLength,
    this.validator,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => AppTextField(
        controller: controller,
        label: label,
        hint: hint,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
        onChanged: onChanged,
      );
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.validator,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? label;
  final String? hint;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(labelText: label, hintText: hint),
      );
}

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.subtitle,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label),
        subtitle: subtitle == null ? null : Text(subtitle!),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      );
}

class AppRadio<T> extends StatelessWidget {
  const AppRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) => RadioListTile<T>(
        value: value,
        // The shared control keeps its existing standalone API for callers.
        // ignore: deprecated_member_use
        groupValue: groupValue,
        // ignore: deprecated_member_use
        onChanged: onChanged,
        title: Text(label),
        contentPadding: EdgeInsets.zero,
      );
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.subtitle,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label),
        subtitle: subtitle == null ? null : Text(subtitle!),
        contentPadding: EdgeInsets.zero,
      );
}
