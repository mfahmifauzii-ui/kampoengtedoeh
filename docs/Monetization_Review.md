# Monetization Review — run before every release

Tick every box. One "no" = fix before shipping.

## Calm & fair
- [ ] Nothing paid **blocks** core progression (farm, fish, decorate, orders, Book all reachable free).
- [ ] No item that affects progress is sold for **Bunga only** (Koin route always exists).
- [ ] No **popups**: the store / purchase prompts open only from a player tap.
- [ ] No **fake urgency**: no countdowns on offers, no "only X left", no streak loss pressure.
- [ ] Event bundles are **cosmetic** and are announced as returning in later years.
- [ ] Instant Grow is capped (**3/day**) and can't be stockpiled beyond today's cap.
- [ ] Premium perks stay **small** (+10% order Koin, +1 reroll) and never required.

## Roblox policy
- [ ] **No paid random items** (loot boxes). If ever added: odds shown, PolicyService checked, age rules followed.
- [ ] Product names/descriptions/icons are accurate (what you buy is exactly what you get).
- [ ] No off-platform payment references; no trading of paid items.
- [ ] Age questionnaire answers still match the content (no new violence/romance/gambling-like mechanics).

## Technical
- [ ] Every pass/product **id** in `Shared/Config/Monetization.luau` is set and matches the dashboard.
- [ ] `!receipt bunga_s` in Studio: receipt #1 = `PurchaseGranted`, #2 (same id) grants **nothing** extra.
- [ ] Test purchase of each pass in Studio → perk applies **without rejoin** (bag slots, pond cap, decor limit, tiles).
- [ ] Rejoin → owned passes still applied.
- [ ] Instant Grow: 4th use on the same day is refused; buying when at the cap is refused before the prompt.
- [ ] Analytics: economy events + onboarding funnel visible in Creator Dashboard (live server, not Studio).

## Numbers sanity (vs. Phase 0)
- [ ] A Koin pack never buys more than ~1 day of active play for its price tier.
- [ ] Bunga packs vs. free Bunga (~3–5/day) — free players can still afford a Bunga decor within ~2 weeks.
