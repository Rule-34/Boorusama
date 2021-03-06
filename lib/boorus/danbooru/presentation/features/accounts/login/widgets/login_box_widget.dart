// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/authentication/authentication_state_notifier.dart';
import 'package:boorusama/generated/i18n.dart';

final _showPasswordProvider = StateProvider<bool>((ref) => false);
final _userNameHasTextProvider = StateProvider<bool>((ref) => false);

class LoginBox extends HookWidget {
  const LoginBox({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final animationController = useAnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 150));
    final _formKey = useState(GlobalKey<FormState>());
    final _isValidUsernameAndPassword = useState(true);

    final usernameTextController = useTextEditingController();
    final passwordTextController = useTextEditingController();
    final authStatus = useProvider(accountStateProvider);
    final showPassword = useProvider(_showPasswordProvider);
    final usernameHasText = useProvider(_userNameHasTextProvider);

    usernameTextController.addListener(() {
      if (usernameTextController.text.isNotEmpty) {
        animationController.forward();
        usernameHasText.state = usernameTextController.text.isNotEmpty;
      } else {
        animationController.reverse();
      }
    });

    void onTextChanged() {
      _isValidUsernameAndPassword.value = true;
    }

    return ProviderListener<AccountState>(
      provider: accountStateProvider,
      onChange: (context, status) => status.maybeWhen(
          // ignore: missing_return
          loggedIn: () {
            _isValidUsernameAndPassword.value = true;
            Navigator.of(context).pop();
          },
          // ignore: missing_return
          error: (type) {
            type.when(
              invalidUsernameOrPassword: () {
                _isValidUsernameAndPassword.value = false;
                _formKey.value.currentState.validate();
              },
              unknown: () {
                final snackbar = SnackBar(
                  behavior: SnackBarBehavior.floating,
                  elevation: 6.0,
                  content: Text(
                    'Something went wrong, please try again later',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackbar);
              },
            );
          },
          // ignore: missing_return
          orElse: () {}),
      child: Form(
        autovalidateMode: AutovalidateMode.disabled,
        key: _formKey.value,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LoginField(
                labelText: I18n.of(context).loginFormUsername,
                validator: (value) {
                  if (value.isEmpty) {
                    return I18n.of(context).loginErrorsMissingUsername;
                  }

                  if (!_isValidUsernameAndPassword.value) {
                    return I18n.of(context)
                        .loginErrorsInvalidUsernameOrPassword;
                  }
                  return null;
                },
                onChanged: (text) => onTextChanged(),
                controller: usernameTextController,
                suffixIcon: usernameHasText.state
                    ? ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animationController,
                          curve: Interval(0.0, 1.0, curve: Curves.linear),
                        ),
                        child: IconButton(
                            splashColor: Colors.transparent,
                            color:
                                Theme.of(context).appBarTheme.iconTheme.color,
                            icon: FaIcon(FontAwesomeIcons.solidTimesCircle),
                            onPressed: () => usernameTextController.clear()),
                      )
                    : null,
              ),
              SizedBox(height: 20),
              LoginField(
                labelText: I18n.of(context).loginFormPassword,
                obscureText: !showPassword.state,
                validator: (value) {
                  if (value.isEmpty) {
                    return I18n.of(context).loginErrorsMissingPassword;
                  }
                  if (!_isValidUsernameAndPassword.value) {
                    return I18n.of(context)
                        .loginErrorsInvalidUsernameOrPassword;
                  }
                  return null;
                },
                onChanged: (text) => onTextChanged(),
                controller: passwordTextController,
                suffixIcon: IconButton(
                    splashColor: Colors.transparent,
                    color: Theme.of(context).appBarTheme.iconTheme.color,
                    icon: showPassword.state
                        ? FaIcon(FontAwesomeIcons.solidEyeSlash)
                        : FaIcon(FontAwesomeIcons.solidEye),
                    onPressed: () => showPassword.state = !showPassword.state),
              ),
              SizedBox(height: 20),
              authStatus.maybeWhen(
                authenticating: () => CircularProgressIndicator(),
                orElse: () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).accentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0)),
                  ),
                  child: Text(I18n.of(context).loginFormLogin),
                  onPressed: () {
                    if (_formKey.value.currentState.validate()) {
                      context.read(authenticationStateNotifierProvider).logIn(
                          usernameTextController.text,
                          passwordTextController.text);
                      FocusScope.of(context).unfocus();
                    } else {
                      _isValidUsernameAndPassword.value = true;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginField extends HookWidget {
  const LoginField({
    Key key,
    @required this.validator,
    @required this.controller,
    @required this.labelText,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
  }) : super(key: key);

  final TextEditingController controller;
  final ValueChanged<String> validator;
  final Widget suffixIcon;
  final String labelText;
  final bool obscureText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final _controller = useTextEditingController();

    return TextFormField(
      onChanged: onChanged,
      obscureText: obscureText,
      validator: validator,
      controller: controller ?? _controller,
      decoration: InputDecoration(
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).accentColor, width: 2.0),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).errorColor),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).errorColor, width: 2.0),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        contentPadding: EdgeInsets.all(12.0),
        labelText: labelText,
      ),
    );
  }
}
