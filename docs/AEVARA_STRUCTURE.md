\# Aevara – Project Structure (Canonical Map)



\*\*Owner:\*\* Aevara Engineering  

\*\*Last updated:\*\* 2025‑08‑18  

\*\*Purpose:\*\* Single source of truth for how `lib/` is organized, what each module owns, and how routing/data/state tie together. Update this file whenever folders/files are added/renamed.



---



\## 0) Design System (reference)

\- Colors, type, emojis, spacing, a11y: see `/docs/4\_design\_system.md`

\- Tiles use \*\*titleMedium (medium)\*\* for numeric values (not heavy bold)

\- Emojis/icons set: Sleep 💤 • HRV 💓 • RHR 🫀 • Steps 👣 • Mood 🙂→😖 • Stress 🌪️ • Confidence 🔎 • Info ℹ️ • Sync 🔄 • ✅ ⚠️ ⛔



---



\## 1) High-level tree (lib/)

lib/

app.dart

main.dart

routing/

routes.dart

route\_paths.dart

shell/

app\_shell.dart

nav\_observer.dart

theme/

aevara\_theme.dart

color\_tokens.dart

text\_styles.dart

icons.dart

lottie.dart

core/

constants.dart

env.dart

error\_strings.dart

permissions.dart

telemetry.dart

guards/

auth\_guard.dart

calibration\_guard.dart

profile\_min\_guard.dart

subscription\_guard.dart

services/

analytics\_service.dart

deeplink\_service.dart

haptic\_service.dart

logger.dart

remote\_config.dart

time\_service.dart

utils/

async\_value.dart

formatters.dart

haptics.dart

platform\_x.dart

validators.dart

widgets/

app\_appbar.dart

app\_bottom\_nav.dart

app\_side\_drawer.dart

confirm\_dialog.dart

empty\_state.dart

info\_sheet.dart

loading\_overlay.dart

toast.dart

avatar/

coach\_avatar.dart

user\_avatar.dart

buttons/

chip\_toggle.dart

icon\_button\_lite.dart

primary\_button.dart

text\_link.dart

cards/

gauge\_placeholder\_card.dart

hero\_header\_card.dart

peek\_card.dart

tiles/

metric\_tile.dart

provider\_tile.dart

settings\_tile.dart

sync\_status\_dot.dart

data/

contracts/

firestore\_contracts\_v1.dart

methods\_contracts.dart

models/

daily\_metrics.dart

device\_source.dart

experiment.dart

export\_request.dart

leaderboard.dart

notification.dart

user\_profile.dart

vitality\_metrics.dart

challenge.dart

services/

auth\_service.dart

challenges\_service.dart

community\_feed\_service.dart

compute\_service.dart

daily\_service.dart

devices\_service.dart

experiments\_service.dart

export\_service.dart

leaderboard\_service.dart

notifications\_service.dart

subscription\_service.dart

user\_profile\_service.dart

adapters/

firestore/

auth\_service\_fs.dart

challenges\_service\_fs.dart

community\_feed\_service\_fs.dart

daily\_service\_fs.dart

devices\_service\_fs.dart

experiments\_service\_fs.dart

export\_service\_fs.dart

leaderboard\_service\_fs.dart

notifications\_service\_fs.dart

subscription\_service\_fs.dart

user\_profile\_service\_fs.dart

mock/

auth\_service\_mock.dart

challenges\_service\_mock.dart

community\_feed\_service\_mock.dart

daily\_service\_mock.dart

devices\_service\_mock.dart

experiments\_service\_mock.dart

export\_service\_mock.dart

leaderboard\_service\_mock.dart

notifications\_service\_mock.dart

subscription\_service\_mock.dart

user\_profile\_service\_mock.dart

state/

app\_providers.dart

challenges\_providers.dart

community\_providers.dart

daily\_providers.dart

devices\_providers.dart

experiments\_providers.dart

insights\_providers.dart

leaderboards\_providers.dart

subscription\_providers.dart

user\_providers.dart

features/

auth/

signin\_page.dart

signup\_page.dart

verify\_email\_page.dart

forgot\_password\_page.dart

onboarding/

identity\_page.dart

demographics\_page.dart

consent\_page.dart

connect\_page.dart

ready\_page.dart

components/

connect\_provider\_grid.dart

consent\_checkbox\_list.dart

step\_header.dart

home/

dashboard\_page.dart

components/

hero\_header.dart

metrics\_row.dart

synced\_metrics\_row.dart

vitality\_age\_gauge.dart

healthy\_days\_mini\_bar.dart

confidence\_chip.dart

coach\_prompt\_card.dart

peeks\_row.dart

sheets/

input\_sleep\_sheet.dart

input\_hrv\_sheet.dart

input\_steps\_sheet.dart

input\_mood\_sheet.dart

input\_stress\_sheet.dart

date\_picker\_sheet.dart

connect\_providers\_sheet.dart

vitality\_info\_sheet.dart

healthy\_days\_info\_sheet.dart

confidence\_info\_sheet.dart

data\_hub/

data\_hub\_page.dart

components/

snapshot\_card.dart

sources\_status\_row.dart

sync\_timeline.dart

sheets/

metric\_details\_sheet.dart

source\_details\_sheet.dart

insights/

insights\_page.dart

why\_change\_page.dart

methods\_doc\_page.dart

components/

confidence\_panel.dart

drivers\_breakdown.dart

export\_cta.dart

trend\_charts.dart

experiments/

experiments\_page.dart

experiment\_start\_page.dart

experiment\_detail\_page.dart

experiment\_active\_page.dart

experiment\_progress\_page.dart

components/

experiment\_card.dart

experiment\_filters.dart

experiment\_progress\_bar.dart

experiment\_result\_summary.dart

sheets/

what\_is\_experiment\_sheet.dart

how\_results\_calculated\_sheet.dart

limitations\_sheet.dart

notes\_context\_sheet.dart

community/

community\_page.dart

friends\_page.dart

friend\_profile\_page.dart

groups\_page.dart

badges\_page.dart

components/

feed\_post\_card.dart

friend\_finder\_field.dart

invite\_friend\_dialog.dart

reaction\_bar.dart

challenges/

challenges\_page.dart

challenge\_detail\_page.dart

components/

challenge\_card.dart

challenge\_status\_chip.dart

participant\_avatars\_row.dart

sheets/

challenge\_create\_sheet.dart

challenge\_invite\_sheet.dart

leaderboards/

leaderboards\_page.dart

components/

weekly\_steps\_board.dart

sleep\_streaks\_board.dart

experiment\_gains\_board.dart

leaderboard\_entry\_tile.dart

profile/

profile\_page.dart

privacy\_dashboard\_page.dart

export\_page.dart

delete\_account\_page.dart

components/

account\_tile\_list.dart

stats\_panel.dart

streaks\_panel.dart

settings/

devices\_page.dart

notifications\_page.dart

about/

about\_page.dart

privacy\_policy\_page.dart

terms\_page.dart

charts/

donut\_gauge.dart

mini\_bar.dart

time\_series\_line.dart

copy/

microcopy.dart

info\_copy.dart

methods\_copy.dart



---



\## 2) Ownership \& responsibilities



\- \*\*routing/\*\*: Sole source of routes (`routes.dart`) and paths (`route\_paths.dart`). No second router elsewhere.

\- \*\*shell/\*\*: Global layout (app shell with side drawer / bottom nav), navigation observer for analytics.

\- \*\*theme/\*\*: Design tokens and `AevaraTheme`. All colors/fonts come from here; no hard-coded styling in widgets.

\- \*\*core/\*\*:

&nbsp; - \*\*guards/\*\*: Route guards (`auth\_guard`, `profile\_min\_guard`, `calibration\_guard`, `subscription\_guard`).

&nbsp; - \*\*services/\*\*: App-wide services (analytics, deeplink, haptic, logger, remote config, time).

&nbsp; - \*\*utils/\*\*: Pure helper utilities (formatting, platform checks, validators).

&nbsp; - \*\*widgets/\*\*: App-level reusable UI pieces (app bars, drawers, buttons, tiles).

&nbsp; - \*\*env.dart\*\*: Chooses adapters (firestore vs mock), API endpoints (compute function), feature flags.

\- \*\*data/\*\*:

&nbsp; - \*\*contracts/\*\*: Firestore shapes and method contracts (v1); updating these requires migration notes.

&nbsp; - \*\*models/\*\*: Pure data classes.

&nbsp; - \*\*services/\*\*: Abstract service interfaces used by UI/state layers.

&nbsp; - \*\*adapters/\*\*: Concrete implementations, split by `firestore/` and `mock/`.

\- \*\*state/\*\*: Riverpod providers and notifiers; inject \*\*services\*\* (not adapters) based on `env.dart`.

\- \*\*features/\*\*: Page groups with `components/` and `sheets/` subfolders; no cross-feature imports of UI.

\- \*\*charts/\*\*: Chart widgets used by features (donut, mini bar, time series).

\- \*\*copy/\*\*: Text blocks / microcopy separate from widgets for easy edits.



---



\## 3) Routing surface (public pages)

\- `/auth/\*`: sign in/up, verify email, forgot password

\- `/onboarding/\*`: identity, demographics, consent, connect device, ready

\- `/app/home`: Dashboard (HeroHeader, KeyGaugesRow, Metrics Row, CoachPrompt, Peeks)

\- `/app/data-hub`: Sources status, snapshot cards, sync timeline

\- `/insights`, `/insights/why\_change`, `/info/methods\_doc`

\- `/experiments/\*`: catalog, start, detail, active, progress

\- `/community/\*`: feed, friends, friend profile, groups, badges

\- `/challenges/\*`: list, detail, create/invite sheets

\- `/leaderboards/\*`: weekly steps, sleep streaks, experiment gains

\- `/profile/\*`: profile, privacy dashboard, export, delete account

\- `/settings/\*`: devices, notifications

\- `/about/\*`: about, privacy policy, terms



---



\## 4) Data contracts (top-level notes)

\- Daily doc path: `user\_daily/{uid}/days/{YYYY-MM-DD}`  

&nbsp; Fields: raw inputs (`sleep\_total\_hours`, `hrv\_rmssd\_ms`, `steps\_count`, …), computed (`risk\_index`, `vitality\_age`, `healthy\_days\_30`, `score\_confidence`), provenance maps (`sources.\*`), freshness (`stale\_days.\*`), EMAs (`ema7.\*`), notes fields (`notes\_mood`, `notes\_energy`), `calibration\_status`, `model\_version`.

\- Compute endpoint (`computeDailyHttp`) updates Risk/Vitality/HealthyDays + logs to `user\_events`.

\- Leaderboards: `leaderboards/weekly\_steps/entries/{uid}` with rolling 7-day sums.



(See `data/contracts/\*.dart` for exact shapes; changes here require a migration entry.)



---



\## 5) Conventions

\- \*\*Imports:\*\* UI imports \*\*services\*\* from `data/services/\*` via \*\*providers\*\*; UI never imports adapters directly.

\- \*\*Styling:\*\* Use `AevaraTheme` + tokens; never hardcode colors/fonts in leaf widgets.

\- \*\*Accessibility:\*\* ≥44×44 tap targets; AA contrast; semantics on dynamic values (“value updated”); don't rely on color alone to indicate state.

\- \*\*UTF‑8:\*\* All files UTF‑8 with LF line endings.

\- \*\*Naming:\*\* `\*\_page.dart` for pages, `\*\_sheet.dart` for modals, `\*\_card.dart` and `\*\_tile.dart` for compact components.



---



\## 6) Recent changes (log here)

\- 2025‑08‑18: Locked single router (`routing/`), deprecated `app\_routes.dart`. Added this structure map.



---



