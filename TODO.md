# TODO

- [ ] Fix README typo (`field validation.qq`) in README.md

## TODO - Signup integration

- [x] Create `lib/views/signup_view.dart` implementing the provided Signup screen UI + validation.
- [x] Update `lib/viewmodels/auth_viewmodel.dart` with `Future<bool> signUp(...)` using Supabase `auth.signUp` and `data: {'full_name': name}`.
- [x] Update `lib/main.dart` to register `/signup` route.
- [x] Update `lib/views/login_view.dart` to navigate to `/signup` from the footer Sign Up button.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test` (if applicable).
- [ ] Manual verification: navigation + form validation + loading + snackbars.


