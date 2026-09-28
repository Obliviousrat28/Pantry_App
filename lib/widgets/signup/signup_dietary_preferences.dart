import 'package:flutter/material.dart';

class SignupDietaryPreferences extends StatefulWidget
{
  final List<String> selectedPreferences;
  final Function(List<String>) onChanged;

  const SignupDietaryPreferences({
    Key? key,
    required this.selectedPreferences,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<SignupDietaryPreferences> createState() => _SignupDietaryPreferencesState();
}

class _SignupDietaryPreferencesState extends State<SignupDietaryPreferences>
{
  final List<String> dietaryOptions = [
    'Vegetarian',
    'Vegan',
    'Gluten-free',
    'Dairy-free',
    'Nut-free',
    'Halal',
    'Kosher',
    'Pescatarian',
  ];

  @override
  Widget build(BuildContext context)
  {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dietary Preferences (Optional)'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: dietaryOptions.map((dietary) {
            return FilterChip(
              label: Text(dietary),
              selected: widget.selectedPreferences.contains(dietary),
              onSelected: (selected) {
                if (selected)
                {
                  widget.selectedPreferences.add(dietary);
                } else {
                  widget.selectedPreferences.remove(dietary);
                }
                widget.onChanged(widget.selectedPreferences);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}