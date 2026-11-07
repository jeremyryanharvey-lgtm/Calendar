# Our Family Calendar

Installable family calendar (chores, homework, events, piggy banks). Hosted on GitHub Pages, shared through Supabase.

## What is in this folder
| Path | What it is | Goes on GitHub? |
|---|---|---|
| index.html, manifest.json, service-worker.js, icon-*.png, apple-touch-icon.png | The app (stage 1, works today) | Yes, repo root |
| config.js | Your Supabase address and publishable key (empty for now) | Yes, repo root |
| database.js, notifications.js | Sync and push code, switched off until later stages | Yes, repo root |
| README.md, SECURITY.md | These notes | Optional |
| supabase/sql/ | Setup code you paste into Supabase | Optional copy |
| supabase/functions/ | Server functions for the Apple link and reminders (built in stages 3 and 4) | Optional copy |

Nothing here changes how the app behaves yet.

## Setup order
1. GitHub: new repo, upload the root files, Settings -> Pages -> Deploy from branch (main, / root). Note the address.
2. Supabase: new project. SQL Editor: run supabase/sql/01_schema.sql, then 02_security.sql.
3. Supabase -> Authentication -> URL Configuration: set Site URL to your GitHub Pages address.
4. Supabase -> Project Settings -> API Keys: copy the Project URL and the publishable key into config.js (edit it on GitHub with the pencil icon). Never the secret key.
5. Tell Claude when done: stage 2 wires the app to Supabase.

Tip: parents sign in with their own email. For the kids' tablet or wall display, make a separate "device" login with a spare address (a Gmail "you+tablet@gmail.com" alias reaches the same inbox).
