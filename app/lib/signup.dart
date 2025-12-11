import 'package:app/api/account.dart';
import 'package:app/components/buttons.dart';
import 'package:app/util/util.dart';
import 'package:flutter/material.dart';

enum UserType { client, caseWorker, admin }

typedef DatePickerMock = DateTime? Function();

DatePickerMock? _datePickerMock;
void setDatePickerMock(DatePickerMock? mock) {
  _datePickerMock = mock;
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$';
  // Password = least 8 characters long, include an uppercase letter, a lowercase letter, a number, and a special character
  final passwordPattern = r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W_]).{8,}$';

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  UserType userType = UserType.client; // Default user type
  DateTime? dateOfBirth;

  void getDateOfBirth(BuildContext context) async {
    final today = DateTime.now();
    final dob = _datePickerMock != null
        ? _datePickerMock!()
        : await showDatePicker(
            context: context,
            firstDate: DateTime(1900),
            lastDate: DateTime(today.year - 18, today.month, today.day),
          );

    setState(() {
      dateOfBirth = dob;
    });
  }

  String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void register() async {
    List<String> errors = [];
    final passwordRegex = RegExp(passwordPattern);
    final emailRegex = RegExp(emailPattern);

    final firstName = firstNameController.text;
    final lastName = lastNameController.text;
    final email = emailController.text;
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Errors
    // First Name
    if (firstName.isEmpty) {
      errors.add('First Name is required.');
    }

    // Last Name
    if (lastName.isEmpty) {
      errors.add('Last Name is required.');
    }

    // Email
    if (email.isEmpty) {
      errors.add('Email is required.');
    } else if (!emailRegex.hasMatch(email)) {
      errors.add('Invalid email address.');
    }

    // Password
    if (password.isEmpty) {
      errors.add('Password is required.');
    } else if (!passwordRegex.hasMatch(password)) {
      errors.add(
          'Password must be at least 8 characters long, include an uppercase letter, a lowercase letter, a number, and a special character.');
    }
    if (confirmPassword.isEmpty) {
      errors.add('Confirm Password is required.');
    } else if (password != confirmPassword) {
      errors.add('Passwords do not match.');
    }

    if (dateOfBirth == null) {
      errors.add('Date of birth is required.');
    }

    // Print errors
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors.join('\n')),
          backgroundColor: Colors.red[400],
        ),
      );
      return; // do not continue if there are errors!
    }

    final errorMsg = await createAccount(
      firstName,
      lastName,
      email,
      password,
      userType,
      dateOfBirth!,
    );

    if (errorMsg != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account Created!'),
            backgroundColor: Colors.green[400],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4169E1),
        title: const Text(
          'Sign Up',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            spacing: 10.0,
            children: [
              Row(
                spacing: 10.0,
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'First Name',
                      ),
                      controller: firstNameController,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Last Name',
                      ),
                      controller: lastNameController,
                    ),
                  ),
                ],
              ),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Email',
                ),
                controller: emailController,
              ),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Password',
                ),
                controller: passwordController,
              ),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Confirm Password',
                ),
                controller: confirmPasswordController,
              ),
              Row(
                spacing: 10.0,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<UserType>(
                      value: userType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'User Type',
                      ),
                      items: [UserType.client, UserType.caseWorker]
                          .map((UserType type) {
                        return DropdownMenuItem<UserType>(
                          value: type,
                          child: Text(type.name.capitalize()),
                        );
                      }).toList(),
                      onChanged: (UserType? newValue) {
                        setState(() {
                          userType = newValue!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => getDateOfBirth(context),
                      child: Text(
                        dateOfBirth != null
                            ? 'DoB - ${formatDate(dateOfBirth!)}'
                            : 'Set Date of Birth',
                      ),
                    ),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: 100, maxWidth: 300),
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: QFilledButton(
                    onPressed: register,
                    text: 'Sign Up',
                    qStyle: QFilledButtonStyle.kConfirm,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to Login page
                },
                child: const Text(
                  'Already have an account? Log in',
                  style: TextStyle(color: Color(0xFF75A9F9)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
