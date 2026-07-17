import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';
import '../provider_onboarding_provider.dart';
import '../../../services/pref_service.dart';

class ProviderProfileSummary extends StatefulWidget {
  const ProviderProfileSummary({super.key});

  @override
  State<ProviderProfileSummary> createState() =>
      _ProviderProfileSummaryState();
}

class _ProviderProfileSummaryState
    extends State<ProviderProfileSummary> {

  bool confirmed = false;

  bool get canSubmit =>
      confirmed;

  void _submit() async {
  if (!canSubmit) return;
  await PrefService.setProviderOnboardingCompleted();
  if (!mounted) return;
  AppRouter.goToProviderDashboard(context);
}


  Widget _buildSummaryCard({
    required String title,
    required List<String> details,
  }) {

    final textTheme =
        Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom:16),
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.providerCard,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            title,
            style:textTheme.titleMedium?.copyWith(
              fontWeight:FontWeight.w800,
              color:AppColors.textPrimary,
            ),
          ),

          const SizedBox(height:12),

          ...details.map(
            (detail) => Padding(
              padding:
              const EdgeInsets.only(bottom:6),

              child: Text(
                detail,
                style:textTheme.bodyMedium?.copyWith(
                  color:AppColors.textSecondary,
                ),
              ),
            ),
          ),

        ],
      ),
    );

  }


  @override
  Widget build(BuildContext context) {

    final textTheme =
        Theme.of(context).textTheme;


    final provider =
        Provider.of<ProviderOnboardingProvider>(
          context,
        );


    return Scaffold(

      backgroundColor:
      AppColors.background,


      appBar: AppBar(

        backgroundColor:
        AppColors.background,

        elevation:0,

        leading:IconButton(

          icon:const Icon(
            Icons.arrow_back_ios_new,
            color:AppColors.primary,
            size:20,
          ),

          onPressed:(){

            if(Navigator.canPop(context)){
              Navigator.pop(context);
            }

          },

        ),

      ),



      body:SingleChildScrollView(

        padding:
        const EdgeInsets.symmetric(
          horizontal:24,
        ),


        child:Column(

          crossAxisAlignment:
          CrossAxisAlignment.stretch,


          children:[


            const SizedBox(height:10),



            Center(

              child:SvgPicture.asset(

                'assets/onboardingsvg/provider_summary.svg',

                width:220,

                fit:BoxFit.contain,

              ),

            ),



            const SizedBox(height:25),



            Text(

              "Review your profile",

              textAlign:
              TextAlign.center,


              style:
              textTheme.headlineMedium?.copyWith(

                fontSize:32,

                fontWeight:
                FontWeight.w800,

                color:
                AppColors.textPrimary,

              ),

            ),



            const SizedBox(height:12),



            Text(

              "Please check your information before submitting for verification.",

              textAlign:
              TextAlign.center,


              style:
              textTheme.bodyLarge?.copyWith(

                color:
                AppColors.textSecondary,

              ),

            ),



            const SizedBox(height:35),



            _buildSummaryCard(

              title:"Personal Details",

              details:[

                "${provider.firstName} ${provider.lastName}",

                provider.email.isEmpty
                    ? "No email provided"
                    : provider.email,

                provider.phone,

                provider.homeAddress ?? "",

                provider.about ?? "",

              ],

            ),



            _buildSummaryCard(

              title:"Service Information",

              details:[

                provider.selectedService,

                "${provider.experienceYears} years experience",

              ],

            ),



            _buildSummaryCard(

              title:"Working Area",

              details:[

                provider.location,

                "${provider.workingRadius.toInt()} km radius",

                provider.workingDays.join(", "),

                provider.workingHours,

              ],

            ),



            _buildSummaryCard(

              title:"Verification Documents",

              details:[

                "National ID Front Uploaded",

                "National ID Back Uploaded",

              ],

            ),



            const SizedBox(height:10),



            CheckboxListTile(

              contentPadding:
              EdgeInsets.zero,

              value:confirmed,


              onChanged:(value){

                setState(() {

                  confirmed =
                      value ?? false;

                });

              },


              title:const Text(

                "I confirm that the provided information is accurate.",

              ),

            ),



            const SizedBox(height:20),



            ElevatedButton(

              onPressed:
              canSubmit
                  ? _submit
                  : null,


              child:
              const Text(
                "Submit for verification",
              ),

            ),



            const SizedBox(height:30),


          ],

        ),

      ),

    );

  }

}