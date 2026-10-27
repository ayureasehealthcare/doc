# doctro (docv1) — repository notes

Flutter telehealth app for doctors. Branch: `astra-ai-integration`.

## Commands

```bash
# Flutter 3.47.4 stable. The SDK lives in /workspace, not $HOME: the
# sandbox recycles $HOME mid-session and wipes anything installed there.
export PATH="/workspace/tools/flutter/bin:$PATH"
flutter analyze                                   # expect 0 errors, 0 warnings
flutter test                                      # 232 tests
flutter build web --release
dart format lib test
```

`flutter analyze` must stay at **0 errors / 0 warnings**. The remaining
~726 `info`s are mostly style noise (`constant_identifier_names`,
`avoid_print` in CLI scripts), not app bugs.

## CI

`build-apk.yml` runs three enforcing verification steps. Do not add
`|| true` back onto them, and do not broaden the format target back to
`.`:

| Step | Command | Fails build on |
|---|---|---|
| Verify Formatting | `dart format --output=none --set-exit-if-changed lib test` | any unformatted file in `lib`/`test` |
| Analyze Code | `flutter analyze --no-fatal-infos` | errors, warnings |
| Run Tests | `flutter test` | any failing test |

`--no-fatal-infos` is a deliberate policy, not a suppression: infos are
printed but do not fail. Everything with a real severity does. These
steps were previously suffixed with `|| true`, which is how 10 analyzer
errors went unnoticed; each gate has since been verified to fail when
handed a real error, a failing assertion, and an unformatted file.

Formatting is scoped to `lib test` on purpose. Running it over `.` also
sweeps untracked scratch and CLI scripts, which would fail the build for
files nobody committed.

## Architecture

- `lib/theme/ayureze_theme.dart` — the design system. 39 colour tokens plus
  `ThemeData` for light/dark, with a full `textTheme`.
- `lib/widgets/osler_*.dart` — shared UI kit (button, card, input, hero,
  toast, modal, skeleton, dropdown, tag, tooltip, loader, status badge).
- `lib/features/<feature>/` — screens, grouped by feature. `consultation`
  is the largest (29 files, incl. chat and video call).
- `lib/core/astra/` — the AI "Astra" integration (actions, controllers,
  services, widgets). Each folder has a barrel file.

## Font and motion

The doctor app follows the patient app's **Serene Herbalist** design system
(the Stitch export plus the shipped patient `lib/theme.dart`): warm cream
canvas `#FBF9F4`, white cards with a faint sage outline, deep sage and sage
mint, turmeric and clay accents, sage-tinted dark mode, pill buttons, warm
filled inputs with a 1.5px sage focus ring, and whisper-soft ambient
shadows. Keep the two apps visually in step: when the patient design
changes, change it here too.

Fonts (bundled, SIL OFL, licences next to the files): **Inter** for all
interface text and data (`AyurezeTheme.fontFamily`, applied as the
textTheme base and by `AyurezeTheme.font(...)`), **Newsreader** serif for
greetings and headlines only (`headlineLarge`/`Medium`/`Small` - `OslerHero`
titles use `headlineSmall` - and
`AyurezeTheme.serif(...)`). Never set the serif on clinical data. Do not add
`google_fonts`; the files are bundled so text renders offline. The
purchased Uni Neue files were deleted (Oct 2026); restore
`assets/fonts/UniNeue/` and its `pubspec.yaml` block from git history to
switch back. Bundled weights: Inter 400/500/600/700, Newsreader
400/500/600/700.

Android's `pageTransitionsTheme` uses `ZoomPageTransitionsBuilder` (Flutter's
own Material 3 default) instead of the old `FadeUpwardsPageTransitionsBuilder`,
so every `Navigator.push`/named route gets the same modern transition with no
per-screen change. iOS keeps `CupertinoPageTransitionsBuilder` for its native
back-swipe gesture.

`lib/theme/app_motion.dart` holds the shared motion vocabulary:
- `AppMotion` - duration/curve constants. Use these instead of inventing a
  new duration per screen.
- `AnimatedTapScale` - wraps a tappable widget with a press-in scale.
  `OslerButton` and `OslerCard` already use it (plus `HapticFeedback`); reach
  for it directly on anything else tappable.
- `ScreenEntrance` - fades/slides a section in, with a `stagger`-per-`index`
  cascade for lists/grids (see `_buildStatCard`/`_buildAppointmentCard` in
  `login_home.dart`).

`AyurezeTheme.heroDecoration()` paints `auroraGradient`, deep forest to
primary sage (the patient app's "Talk to Astra" card); white text clears AA
on every stop. It is shared by ~12 screens
(SignIn, signup, profile, settings, notifications, schedule,
appointment_history, dashboard, the drawer, `osler_hero.dart` ...), so this
one change reaches all of them without per-screen edits. `glassDecoration()`
(behind every `GlassSurface`) is now a near-opaque Tier-1 card - the old 14%
frost was near-invisible on cream. Every glass panel's content uses
dark-aware ink; keep it that way (no white text inside a `GlassSurface`).

## Swastu

Swastu is AyurEze's companion character, shared with the patient app
(where it is the face of Astra). `lib/widgets/swastu.dart` has the
character (`Swastu`, 12 `SwastuMood`s, one PNG each in `assets/swastu/`),
`SwastuWordmark`, `SwastuNameTag` and `SwastuSays`. It breathes and floats
when idle, squishes on tap, stays still for calm moods (urgent, concerned)
and for reduced motion. No sounds: this is a clinical tool.

Where it appears, and in which mood (match the patient app):
- `OslerStateView` - every empty/error state: idle when empty, concerned on
  error, or the `mood:` you pass (review queue empty: happy). The state's
  icon stays as a small badge beside Swastu.
- `OslerLoadingView` - thinking, over a small spinner.
- `ErrorUtilityScreen` - offline/maintenance sleepy, errors concerned, 404
  thinking.
- Startup intro (waking), sign-in hero and dashboard hero (greeting),
  Astra chat app bar (listening) and welcome (greeting), Astra floating
  buttons (happy, `idleMotion: false` - they sit on many screens).

**Testing:** a screen showing an idle Swastu never "settles", so
`pumpAndSettle` times out. Turn on reduced motion for that test (see the
`_reduceMotion` helper in `test/widgets/search_screen_test.dart`): Swastu
honours it. If the screen also has a wall-clock Timer (the startup intro),
advance time past it before settling - see `_settle` in
`test/startup/startup_gate_test.dart`.

Formatting caveat: this sandbox's `dart format` (freshly downloaded "latest
stable") disagrees with the repo's checked-in style on ~136 of 217 files -
almost certainly a local toolchain/style-version mismatch, not a real
formatting debt (CI's own Verify Formatting step was green on the commit
right before this). Do not bulk-run `dart format` across `lib test` to "fix"
this; it will produce a massive, unreviewable diff. Format only files you
hand-edit, and if in doubt, match the surrounding code's existing style
rather than trusting a freshly-fetched formatter's opinion wholesale.

## Layout tokens

`AyurezeTheme` has a named radius scale (`radiusXs` 6, `radiusSm` 8,
`radiusMd` 12, `radiusLg` 16, `radiusCard` 20 - the design's card radius,
`radiusXl` 24, `radius2xl` 28, `radiusPill` 999) and a 4pt spacing scale (`spaceXs`..`space3xl`). Use these instead of
literal `BorderRadius.circular(16)` or ad-hoc `EdgeInsets`.

Before the scale existed the UI used 14 different radii with no shared
vocabulary, so two surfaces meant to match could be 12, 16 or 24
depending on who wrote them. The Osler kit was migrated to the tokens;
feature screens still largely hardcode, so expect mixed usage and
converge on the tokens when you touch a file.

## Screen layout and the Osler kit

31 files have a `Scaffold`. All feature screens now build their loading,
empty and error states, cards, toasts and overlay loaders from the kit
(`OslerLoadingView`, `OslerStateView`, `OslerCard`, `OslerToast`,
`OslerOverlayLoader`). Two use no Osler widgets, by design: `video_Call`
(call controls over live video) and `app_shell` (a container). Do not
hand-roll a spinner, empty state or toast in a screen - reach for the kit.

`CommonFunction.toastMessage` (fired by `ServerError` with no context)
routes to `OslerToast` through `navigatorKey` when the app is mounted, and
only falls back to Fluttertoast (an off-theme gradient on web) before then.
When a screen's `FutureBuilder` gets a failed `BaseModel` (`data == null`),
show `OslerStateView.error` with a retry, as `ScheduleTimings` does - not an
empty form that looks like real data.

`profile.dart` is ~2,200 lines - by far the largest file. Treat edits
there carefully and prefer extracting a section over growing it.

Drift, measured (Oct 2026): **no** literal font sizes or radii remain
outside `lib/theme/` - every `fontSize:`, `AyurezeTheme.font(<size>)` and
`(Border)Radius.circular(<n>)` uses a token. Inside the theme, ten radii
were off-scale `20`s; they are now `radiusCard`, which the Serene
Herbalist spec makes the master card radius. `EdgeInsets` in shared widgets
and `lib/core/astra` use the `space*` tokens; the dozen left as numbers are
deliberate half-steps (2, 6, 10, 14) for chip, badge and button padding,
where snapping to the 4px scale would change their height.

## Conventions

- Use `AyurezeTheme` tokens rather than `Color(0xFF...)` literals.
  Hardcoded `Colors.white` is *not* automatically a dark-mode bug here:
  most screens open with white text on an `AyurezeTheme.heroDecoration()`
  gradient, which is correct in both themes. It is only a bug when used
  as a **surface** (card, tray, avatar background). Judging these by
  count rather than by role led to an overstated bug list once already -
  see the Dark mode section for the test that actually decides it.
- The theme defines text styles (`headlineLarge` … `labelLarge`), built on
  a size scale (`textXs` 11, `textSm` 12, `textMd` 14, `textBase` 15,
  `textLg` 16, `textXl` 20, `text2xl` 24, `text3xl` 32). Prefer
  `Theme.of(context).textTheme.*`; where there is no context (const
  styles, painters) use `fontSize: AyurezeTheme.textMd` - never a bare
  number. `theme_contrast_test.dart` checks the textTheme matches the scale.
- The video call screen is dark in both themes on purpose. Use the
  `call*` tokens there (`callBackground`, `callWaitingGradient`,
  `callForeground`), never `textPrimary`, which is dark ink in light mode.
- Guard `BuildContext` use after any `await` with `if (!mounted) return;`
  (or `context.mounted` in view models). This was a genuine crash source
  across the auth and video-call flows.
- Barrel files that start with a `///` doc comment need a `library;`
  directive, otherwise `dangling_library_doc_comments` fires.
- `SharedPreferenceHelper.getString` returns the `'N_A'` sentinel for a
  missing key. For anything shown or sent (`currency_symbol`, `doctorId`)
  use `getStringOrNull` - the sentinel once showed as "N_A0.00" and was
  posted as a payout doctor id.
- Empty `catch` blocks should keep a comment explaining why swallowing is
  correct, otherwise it reads as a bug.

## Dark mode

`AyurezeTheme` mixes two kinds of token, and picking the wrong one is the
main source of dark-mode bugs:

- **Dark-aware getters** — `surface`, `surfaceMuted`, `canvas`, `border`,
  `textPrimary`, `textSecondary`, `iconPrimary`. These read
  `_isDark` and are the correct choice for any background, border, or
  body text. `updateThemeMode()` is driven by `ThemeProvider`.
- **Light-only constants** — `lightSurface`, `healingGreen10`,
  `oslerGray10`, `lightGreenSoft`, `forestDeep`, `healingGreen100`, etc.
  These keep their light value in dark mode. They are fine as *brand
  accents* (a badge, an icon on a pale chip) but wrong as a page or card
  background, where they strand pale fills behind themed text.

The mirror-image bug is the commoner one: `forestDeep` / `healingGreen100`
(the same `#1A2E05`) used as **ink** - text, icons, spinners, focus
borders - straight on `canvas`/`surface`/`surfaceMuted`/glass. 12-14:1 in
light mode, 1.06-1.35:1 in dark mode, i.e. invisible. ~90 such uses were
fixed across 25+ screens and widgets (back arrows, app bars, the bottom
nav's selected tab, the date picker's OK button, the live signature pad).
Use `iconPrimary` (identical to `forestDeep` in light mode, white in dark)
for icons and ink, `textPrimary` for text. Keep the dark constant only as
a **fill** under white content, as the 100 shade on its own 10 tint, or as
ink on a fixed bright fill (the sage-mint `healingGreen50` header/avatars).

Token names predate the rebrand: `healingGreen*` are now sage
(`100` deep sage ink `#1E4F3C`, `Fill` primary sage `#3F6F5A`, `50` sage mint
`#8FC7AC`, `10` sage tint), `sunshineYellow*` turmeric, `remoteRed*` clay
red. They were remapped by role, so the rules in this section still hold.
For an accent drawn straight on the page (spinner, progress) use the
dark-aware `accent` getter, not `healingGreen50` (only ~1.8:1 on cream).

`test/theme/dark_ink_guard_test.dart` enforces this with a reviewed count
of the remaining uses per file in `lib/features` and `lib/widgets`. If it
fails because a count went up, check the new use rather than just bumping
the number. `mock_flow/main.dart` builds with `--dart-define=MOCK_DARK=true`
to eyeball screens in dark mode. Tiles 9-13 mount the real sign-in,
dashboard, Astra chat, schedule and payments screens with a stored profile
and no backend, so their loading, empty and error states can be checked
in a browser. The harness stores a demo doctor id and currency; to see
screens with data, answer `astra.ayureze.in` requests with Playwright
`page.route` mocks (reply to the CORS preflight too). The payments list
cannot show entries in any build: there is no per-transaction endpoint,
so `paymentsFunction` returns an empty list on purpose.

Where such a fill already carries the accent 100 shade as foreground
(`healingGreen100` on `healingGreen10` is 14:1), the pairing is
intentional and readable in both modes — leave it alone. It only breaks
when the foreground is a *dark-aware* text token, because then the
foreground flips and the background does not.

`Colors.white` as a foreground is usually correct here: most feature
screens open with white text on an `AyurezeTheme.heroDecoration()`
gradient. Only treat it as a bug when it is a **surface** colour (a card,
tray, or avatar background), where it produces white-on-white in dark
mode.

### White content on a green fill

Use `healingGreenFill` (not `healingGreen50`) whenever a filled control
carries a white glyph or label: FAB, checkbox, circular play/AI/record
buttons, success discs. `healingGreen50` is the light sage mint and reaches
only 1.92:1 against white, failing WCAG AA (4.5:1) and the 3:1
UI-component threshold in *both* modes. `healingGreenFill` is primary sage
at 5.78:1.

`healingGreen50` remains correct as a bare accent: an icon or border on a
neutral surface, or the 10%-alpha tint used behind an idle control.

Accent-on-tint pairs follow a shade 10 background with a shade 100
foreground (`healingGreen10`/`healingGreen100` and the equivalents for
red, yellow, blue, violet). Those pairings are all 13:1 or better and are
the intended pattern; the contrast test covers them.

Body text must clear WCAG AA (4.5:1) on its surface.
`test/theme/theme_contrast_test.dart` enforces this for the theme's text
and surface tokens using a self-contained contrast-ratio helper; add a
case there when introducing a new text/surface pair. `darkTextSecondary`
(`#A5B4AB`) scores 6.81:1 on `darkSurfaceMuted`.

## Testing notes

- Widgets that depend on wall-clock time take an injectable clock rather
  than calling `DateTime.now()` inline, so behavior is deterministic in
  tests (see `lib/widgets/session_timeout_handler.dart`).
- Parse/transform logic belongs in a pure function or factory (e.g.
  `UserChat.fromMap`) so it can be unit-tested without Firestore. Do not
  implement `DocumentSnapshot` in a test — it is a sealed class and the
  analyzer flags it.
- **Screen size comes from `tester.view`, not `setSurfaceSize`.**
  `tester.view.physicalSize` (with `devicePixelRatio`) is what drives
  `MediaQuery`; `setSurfaceSize` leaves it at the default 800x600, so a
  width-dependent layout bug silently cannot reproduce. Always pair them
  with `addTearDown(tester.view.resetPhysicalSize)`.
- **One `testWidgets` per file per app boot.** Booting a `MaterialApp`
  with an async `LocalizationsDelegate` works in the first `testWidgets`
  of a file and silently builds *no child* in the rest, so assertions
  see an empty tree. Re-pump at different sizes inside one test body
  instead of adding more `testWidgets`.
- The `_locale == null` branch in `main.dart` is unreachable (`_locale`
  is initialised to `en_US`); it is defensive only. It must return
  `ColoredBox`, never a bare `SizedBox`: with no `Material` or
  `Directionality` ancestor it has nothing to paint.

## Build configuration

All runtime configuration resolves through `Env` in `lib/core/config/env.dart`.
Never read `dotenv` or `String.fromEnvironment` directly elsewhere; add a getter
to `Env` instead, so there is one precedence rule rather than several.

Precedence is `--dart-define` first, then `.env`, then empty string. The
resolver never throws, because it is called on release paths where `dotenv.load`
has not run.

`.env` is deliberately NOT declared under `assets:` in pubspec.yaml. Adding it
would ship the file inside every APK, where it can be extracted from the bundle.
It is loaded in debug builds only. For local work that matches a release build,
use `flutter run --dart-define-from-file=.env.json`; that file is gitignored.

Keys split into two groups:

- Required and public by design: `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
  `FIREBASE_API_KEY`. Safe to embed; they identify the project rather than
  authorising anything on their own. Missing values are reported once at
  startup by `Env.missingKeys()`.
- Server authority, must not ship in a client build: `FIREBASE_SERVER_KEY`,
  `ASTRA_API_KEY`, `SARVAM_API_KEY`. `--dart-define` embeds values in the
  binary and they are recoverable from a release APK. The legacy FCM server key
  can push to every device in the project. Do not add these to the CI build
  step; move the calls that need them to the backend.

CI (`build-apk.yml`) passes only the public keys. If you add a new key, decide
which group it belongs to before wiring it up.

`test/core/env_test.dart` asserts behavior under both configured and
unconfigured builds, so CI runs the suite twice (see the two "Run Tests"
steps). Adding a test that only makes sense in one mode will fail the other;
branch on `String.fromEnvironment` in the test instead.

## Startup flow

`main()` initializes `SharedPreferences` before `runApp`, and `StartupGate`
(`lib/features/startup_gate.dart`) reads `Preferences.is_logged_in`
synchronously in `initState` to pick the first screen: `LoginHomeScreen` when
a session is stored, `SignIn` otherwise. That destination is mounted
underneath from the very first frame - not after a wait - so its own startup
work (view model init, API calls) runs immediately.

A short animated logo reveal (`_BrandIntro` in the same file) plays over the
destination for a fixed ~900ms via a `Timer`, then removes itself from the
tree. This is intentionally not the old timed splash screen it replaced (that
one held the *destination itself* undecided for 3s): the intro only affects
what's drawn on top, never which screen the user lands on or when its data
starts loading.

Three things to keep true if you touch this:

- Never make the destination itself depend on the intro's Timer, an `await`,
  or anything else. It must be chosen synchronously and mounted on the first
  frame; only the logo overlay may be timed.
- The native launch window (Android `launch_background.xml`, iOS
  `LaunchScreen.storyboard`) still paints a flat background only, not the
  logo. `flutter_native_splash` was removed; the animated intro is drawn by
  Flutter itself once it's already running, not by the native splash system,
  so do not re-add that package to "fix" a brief flat flash before Flutter
  paints - that flash is the native window, not `StartupGate`.
- `test/startup/startup_gate_test.dart` covers both: the destination present
  on frame one, and the intro overlay (a `Positioned.fill`) removing itself
  once `pumpAndSettle` drains its `Timer`. Update it if you change either.

## Android signing and Google Sign-In

`android/app/build.gradle` signs `release` with `signingConfigs.debug`, and
that config now points at a fixed, checked-in `android/app/debug.keystore`
(storePassword/keyPassword `android`, alias `androiddebugkey`) rather than
AGP's default `~/.android/debug.keystore`.

This matters because CI (`build-apk.yml`) builds on ephemeral GitHub Actions
runners: without a fixed keystore file, every run generated a brand-new
random debug key, so every build had a different signing certificate. Google
Sign-In validates the app's SHA-1 fingerprint against the ones registered for
the OAuth client in Firebase/Google Cloud Console (see the
`certificate_hash` entries in `android/app/google-services.json`); a moving
fingerprint can never match, and it fails with `ApiException: 10`
(`DEVELOPER_ERROR`), which the app then shows as a generic
"Google Sign In Error" (see `handleGoogleSignIn` in
`lib/features/authentication/view_models/signin_view_model.dart`).

If you regenerate `debug.keystore`, its SHA-1 must be re-registered in
Firebase Console under the Android app (`com.ayureze.ayureze`) → Add
fingerprint, or Google Sign-In breaks again on every subsequent build.
`AuthProvider.signInWithGoogle` (`lib/features/consultation/chat/providers/auth_provider.dart`)
logs the real exception via `debugPrint` on failure - check logcat/CI logs
there before assuming a new failure is code, not a fingerprint mismatch.

## Companion features awaiting astra endpoints

Four doctor-side counterparts of patient-app features are built against
stubs in `AstraApiService`, because the backend routes don't exist yet
(the astra repo is empty and the live OpenAPI spec was not reachable when
they were written). Each stub makes **no request** and is marked
`TODO(astra-backend)`. Do not "fix" them by guessing a route.

| Feature | Stub | Today | To light up |
|---|---|---|---|
| Wellness section (patient screen, illness tab) | `getPatientWellness` | `null` -> "Not available yet" | flip `wellnessEndpointLive`; check `PatientWellness.fromJson` keys |
| Sharing consent | `getSharingConsent` | `unknown` -> limited-sharing banner | call the real route, parse with `SharingConsent.fromJson` |
| Review queue (`ReviewQueueScreen`) | `getPendingAutopilotActions`, `acknowledge…`, `dismiss…` | `[]` / `false` | add routes + `AutopilotAction.fromJson` |

Only the wellness path (`Apis.astra_companion_wellness`) exists as a
constant, because the brief named it. Model parsers mirror the patient
app's local JSON keys (`sleep_hours`, `share_full_record`, ...) and are
unconfirmed against any server.

Consent rules: `SharingConsentGuard` wraps the patient detail body and is
the single place consent is checked. Anything other than an explicit
`SharingConsent.full` (loading, limited, unknown, failure, missing ids)
shows the banner, and descendants read it via `SharingConsentScope.of`,
which defaults to `unknown` with no guard above. Keep failures mapping to
`unknown`, never `full`.

Content origin: label Astra output with `ContentOriginBadge` (same
"Astra suggestion" / "Doctor-approved" wording as the patient app), once
per card or screen, not per line. For a field Astra pre-fills, use
`ContentOrigin.forDraft` so the label flips when the doctor edits it.
