import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';
import 'datacap_text_field.dart';

class MediaInputForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController classLabelController;
  final TextEditingController datasetNameController;
  final bool enabled;

  const MediaInputForm({
    super.key,
    required this.formKey,
    required this.classLabelController,
    required this.datasetNameController,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DataCapTextField(
            controller: classLabelController,
            label: 'Class Label *',
            hint: 'e.g., cat, dog, car',
            prefixIcon: Icons.label_outline,
            enabled: enabled,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Class label is required';
              }
              if (value.contains('/') || value.contains('\\')) {
                return 'Class label cannot contain / or \\';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.formFieldSpacing),
          DataCapTextField(
            controller: datasetNameController,
            label: 'Dataset Name *',
            hint: 'e.g., pets-dataset, vehicle-detection',
            prefixIcon: Icons.folder_outlined,
            enabled: enabled,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Dataset name is required';
              }
              if (value.contains('/') || value.contains('\\')) {
                return 'Dataset name cannot contain / or \\';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
