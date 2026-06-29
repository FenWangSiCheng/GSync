# User Profile Flow

## Goal

Verify that a user can open the user profile page and switch between mock users.

## Preconditions

- Run the `dev` flavor.
- The app uses `assets/mock/users.json` for mock API responses.
- For Android, the app under test is installed with app id
  `com.example.basic_demo.dev`.
- For iOS, the app under test is installed with bundle id
  `cn.com.fenrir-inc.iosAppTest.dev`.

## Steps

1. Launch the app.
2. Confirm the home page is visible.
3. Open the bottom navigation `User` tab.
4. Confirm the `User Info` page is visible.
5. Confirm a user name and email are visible.
6. Tap `User 2`.
7. Confirm `Name: Jane Smith` and `Email: jane.smith@example.com` are visible.
8. Tap `User 3`.
9. Confirm `Name: 张三` and `Email: zhangsan@example.com` are visible.

## Evidence

- The executable flows live at `.maestro/android/user_profile_flow.yaml` and
  `.maestro/ios/user_profile_flow.yaml`.
- Runtime events use the `flow.user_profile.*` prefix.
- Maestro pass/fail output and screenshots belong under `build/harness/evidence/`
  when collected.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED` instead of
  generating a guessed Maestro command.
