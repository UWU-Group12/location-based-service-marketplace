import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';


class ProviderProfilePassword extends StatefulWidget {
  const ProviderProfilePassword({super.key});

  @override
  State<ProviderProfilePassword> createState() =>
      _ProviderProfilePasswordState();
}


class _ProviderProfilePasswordState
    extends State<ProviderProfilePassword> {

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();


  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;


  bool get canContinue {

    return _passwordController.text.trim().length >= 6 &&
        _confirmPasswordController.text.trim().isNotEmpty &&
        _passwordController.text.trim() ==
            _confirmPasswordController.text.trim();

  }


  @override
  void initState() {
    super.initState();

    _passwordController.addListener(_refresh);
    _confirmPasswordController.addListener(_refresh);
  }


  void _refresh() {

    setState(() {});

  }


  @override
  void dispose() {

    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();

  }



  void _continue() {

    if (!canContinue) return;


    AppRouter.goToBuildProfessionalProfile(context);

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

        padding:
        const EdgeInsets.symmetric(horizontal: 24),


        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.stretch,


          children: [

            const SizedBox(height:20),

            Center(

              child: SvgPicture.asset(

                'assets/onboardingsvg/provider_password.svg',

                width:200,

                height:200,

                fit:BoxFit.contain,

              ),

            ),

            const SizedBox(height:35),
            Text(

              "Create your password",

              textAlign:TextAlign.center,


              style:
              textTheme.headlineMedium?.copyWith(

                fontSize:40,

                color:AppColors.textPrimary,

              ),

            ),



            const SizedBox(height:12),



            // Text(
            //   "Secure your account with a strong password.",
            //   textAlign:TextAlign.center,
            //   style:
            //   textTheme.bodyLarge?.copyWith(
            //     color:AppColors.textSecondary,
            //   ),
            // ),



            const SizedBox(height:35),

            TextField(
              controller:_passwordController,
              obscureText: !_passwordVisible,
              decoration:
              InputDecoration(
                labelText:"Password",
                prefixIcon:
                const Icon(
                  Icons.lock_outline,
                ),

                suffixIcon:
                IconButton(
                  icon: Icon(
                    _passwordVisible

                        ? Icons.visibility_off_outlined

                        : Icons.visibility_outlined,

                  ),

                  onPressed:(){

                    setState(() {

                      _passwordVisible =
                      !_passwordVisible;

                    });

                  },

                ),


                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(30),

                ),

              ),

            ),



            const SizedBox(height:16),



            TextField(

              controller:_confirmPasswordController,

              obscureText: !_confirmPasswordVisible,


              decoration:
              InputDecoration(
                labelText:"Confirm Password",
                prefixIcon:
                const Icon(
                  Icons.lock_outline,
                ),
                suffixIcon:
                IconButton(

                  icon: Icon(

                    _confirmPasswordVisible

                        ? Icons.visibility_off_outlined

                        : Icons.visibility_outlined,

                  ),


                  onPressed:(){

                    setState(() {

                      _confirmPasswordVisible =
                      !_confirmPasswordVisible;

                    });

                  },

                ),


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


              child: Text(

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

    );

  }

}