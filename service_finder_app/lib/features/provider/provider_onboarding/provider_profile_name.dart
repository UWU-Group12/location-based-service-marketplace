import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';


class ProviderProfileName extends StatefulWidget {
  const ProviderProfileName({super.key});

  @override
  State<ProviderProfileName> createState() =>
      _ProviderProfileNameState();
}


class _ProviderProfileNameState extends State<ProviderProfileName> {

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();


  bool get canContinue {

    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty;

  }


  @override
  void initState() {
    super.initState();

    _firstNameController.addListener(_refresh);
    _lastNameController.addListener(_refresh);
  }


  void _refresh() {

    setState(() {});

  }


  @override
  void dispose() {

    _firstNameController.dispose();
    _lastNameController.dispose();

    super.dispose();

  }



  void _continue() {

    if (!canContinue) return;


    AppRouter.goToProviderProfileContact(context);

  }



  @override
  Widget build(BuildContext context) {

    final textTheme = Theme.of(context).textTheme;


    return Scaffold(

      backgroundColor: AppColors.background,


      appBar: AppBar(

        backgroundColor: AppColors.background,

        elevation: 0,

        leading: IconButton(

          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primary,
            size: 20,
          ),


          onPressed: () {

            if (Navigator.canPop(context)) {

              Navigator.pop(context);

            }

          },

        ),

      ),



      body: SingleChildScrollView(

        child: Padding(

          padding:
          const EdgeInsets.symmetric(horizontal: 24),



          child: Column(

            crossAxisAlignment:
            CrossAxisAlignment.stretch,


            children: [

              const SizedBox(height:20),


              // Big Profile Icon Card
              // SVG Illustration
              Center(
                child: SvgPicture.asset(
                  'assets/onboardingsvg/provider_name.svg',
                  width:200,
                  height:200,
                  fit: BoxFit.contain,
                ),
              ),



              const SizedBox(height:35),



              Text(

                "Create your provider profile",

                textAlign:TextAlign.center,


                style:
                textTheme.headlineMedium?.copyWith(

                  fontSize:40,

                  color:AppColors.textPrimary,

                ),

              ),



              const SizedBox(height:12),



              const SizedBox(height:35),



              TextField(
                controller:_firstNameController,
                decoration:
                InputDecoration(

                  labelText:"First Name",
                  prefixIcon:
                  const Icon(
                    Icons.person_outline,
                  ),


                  filled:true,

                  fillColor:
                  AppColors.background,


                  border:
                  OutlineInputBorder(

                    borderRadius:
                    BorderRadius.circular(30),

                  ),

                ),

              ),

              const SizedBox(height:16),

                            TextField(
                controller:_lastNameController,
                decoration:
                InputDecoration(

                  labelText:"Last Name",
                  prefixIcon:
                  const Icon(
                    Icons.person_outline,
                  ),


                  filled:true,

                  fillColor:
                  AppColors.background,


                  border:
                  OutlineInputBorder(

                    borderRadius:
                    BorderRadius.circular(30),

                  ),

                ),

              ),



              const SizedBox(height:35),



              ElevatedButton(

                onPressed:
                canContinue
                    ? _continue
                    : null,


                child:
                Text(

                  "Continue",

                  style:textTheme.headlineMedium?.copyWith(
                    fontSize:16,
                    color:AppColors.background,

                  ),

                ),

              ),



              const SizedBox(height:30),


            ],

          ),

        ),

      ),

    );

  }

}