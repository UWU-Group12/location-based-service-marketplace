import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/provider_model.dart';
import '../../services/ai_service.dart';


class CreateRequestScreen extends StatefulWidget {

  final ProviderModel provider;

  const CreateRequestScreen({
    super.key,
    required this.provider,
  });


  @override
  State<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();

}



class _CreateRequestScreenState
    extends State<CreateRequestScreen> {


  final AIService _aiService = AIService();


  final _formKey = GlobalKey<FormState>();


  final titleController =
      TextEditingController();


  final descriptionController =
      TextEditingController();

  final locationController =
      TextEditingController();

  bool isEnhancing = false;

  String? selectedDate;

  String? selectedTime;

  Future<void> _enhanceDescription() async {

    if (descriptionController.text.trim().isEmpty) {


      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content:
              Text(
                'Please enter a description first.',
              ),

        ),

      );


      return;

    }

    setState(() {

      isEnhancing = true;

    });

    final improvedDescription =
        await _aiService.improveDescription(
          descriptionController.text.trim(),
        );

    if (!mounted) return;

    setState(() {

      isEnhancing = false;

      if (improvedDescription != null &&
          improvedDescription.isNotEmpty) {

        descriptionController.text =
            improvedDescription;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content:
                Text(
                  'Unable to enhance description. Try again.',
                ),

          ),
        );
      }
    });

  }

  @override
  void dispose() {


    titleController.dispose();

    descriptionController.dispose();

    locationController.dispose();


    super.dispose();

  }

  @override
  Widget build(BuildContext context) {

    final textTheme =
        Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(

        title:
            const Text(
              'Create Request',
            ),

      ),

      body:

          SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),
        child:

            Form(

          key:
              _formKey,
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(

                widget.provider.displayName,

                style:
                    textTheme.titleLarge,

              ),
              Text(

                widget.provider.categoryIds[0],

                style:
                    textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),

              ),

              const SizedBox(height:25),

              TextFormField(

                controller:
                    titleController,


                decoration:
                    const InputDecoration(

                      labelText:
                          'Service Title',

                      hintText:
                          'Example: Fix water leakage',

                    ),
                validator: (value) {


                  if(value == null ||
                     value.trim().isEmpty) {


                    return 'Enter a service title';

                  }
                  return null;
                },
              ),
              const SizedBox(height:16),
              TextFormField(
                controller:
                    descriptionController,

                maxLines:
                    4,

                decoration:
                    const InputDecoration(

                      labelText:
                          'Problem Description',
                      hintText:
                          'Explain your issue',
                    ),

              ),

              Align(

                alignment:
                    Alignment.centerRight,

                child:

                    TextButton.icon(

                  onPressed:

                      isEnhancing

                          ? null

                          : _enhanceDescription,

                  icon:

                      isEnhancing

                          ? const SizedBox(

                              height:16,

                              width:16,
                              child:
                                  CircularProgressIndicator(

                                    strokeWidth:2,

                                  ),

                            )
                          : const Icon(

                              Icons.auto_awesome,

                            ),
                  label:

                      Text(

                        isEnhancing

                            ? 'Enhancing...'

                            : 'Enhance Description',

                      ),
                ),

              ),

              const SizedBox(height:16),

              TextFormField(

                controller:
                    locationController,

                decoration:
                    const InputDecoration(
                      labelText:
                          'Service Location',
                      prefixIcon:
                          Icon(

                            Icons.location_on_outlined,

                          ),
                    ),

                validator: (value) {
                  if(value == null ||
                     value.trim().isEmpty) {

                    return 'Enter service location';
                  }
                  return null;
                },
              ),

              const SizedBox(height:16),
              ListTile(

                contentPadding:
                    EdgeInsets.zero,
                leading:
                    const Icon(
                      Icons.calendar_month,
                    ),

                title:
                    Text(
                      selectedDate ??
                      'Select preferred date',
                    ),
                onTap:

                    () async {

                  final date =

                      await showDatePicker(

                    context:
                        context,

                    firstDate:
                        DateTime.now(),

                    lastDate:
                        DateTime(2030),

                    initialDate:
                        DateTime.now(),

                  );

                  if(date != null) {

                    setState(() {
                      selectedDate =

                          '${date.day}/${date.month}/${date.year}';

                    });

                  }

                },

              ),

              ListTile(
                contentPadding:
                    EdgeInsets.zero,

                leading:
                    const Icon(
                      Icons.access_time,
                    ),

                title:

                    Text(

                      selectedTime ??

                      'Select preferred time',

                    ),

                onTap:

                    () async {

                  final time =

                      await showTimePicker(

                    context:
                        context,
                    initialTime:
                        TimeOfDay.now(),

                  );

                  if(time != null) {
                    setState(() {

                      selectedTime =

                          time.format(context);
                    });
                  }
                },

              ),

              const SizedBox(height:30),

              SizedBox(
                width:
                    double.infinity,
                child:

                    ElevatedButton(

                  onPressed: () {

                    if(_formKey.currentState!
                        .validate()) {

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content:

                              Text(

                                'Request created',

                              ),
                        ),

                      );
                    }
                  },

                  child:
                      const Text(
                        'Submit Request',
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}