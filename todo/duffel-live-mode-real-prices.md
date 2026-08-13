# Real flight prices: switch Duffel from test mode to live mode

## The finding
The app has been showing **Duffel test-mode prices**, not real ones. This
was not obvious: the API calls genuinely succeed, the response is complete
and realistic (correct airports, plausible times, real airline names), and
earlier verification only confirmed "a real Duffel response arrives" - which
it does. But every offer in it carries `"live_mode": false`, and one of the
40 carriers returned for CDG->CMN was literally **"Duffel Airways"**,
Duffel's own fictional test airline. The prices are simulated.

The cause is simply the token: `duffel_test_...` tokens can only ever reach
Duffel's sandbox. Nothing in this repo is wrong or broken.

## Done (code side - no further code changes needed to go live)
1. **The app now knows the difference.** `DuffelOffer` parses Duffel's
   `live_mode` flag; `DuffelFlightPriceSource` records whether the prices it
   just served were `live`, `sandbox`, or fell back to `mock`
   (`FlightDataMode`, in `flight_price_source.dart`), surfaced up through
   `FlightSearchService.lastDataMode` -> `SearchProvider.dataMode`.
2. **The app now says so.** A banner above the search results warns that the
   prices are test data and shouldn't be booked on (all 5 languages,
   `testPricesWarning`). It renders nothing at all once real live prices
   flow, so **it disappears by itself** the moment a live token is set - no
   code change, no redeploy needed for it to go away.
3. **Fixed a real-money bug that only shows up in live mode.** The old code
   took Duffel's cheapest offer and displayed its amount as euros
   regardless of `total_currency`. Sandbox data happens to be all-EUR so it
   never surfaced, but live data is priced in whatever currency the airline
   used - "90 GBP" would have been shown to users as "€90". It now prefers
   genuine EUR offers, and falls back rather than relabelling a foreign
   amount. Covered by `test/duffel_flight_price_source_test.dart`.
4. The deploy workflow's Duffel smoke test now prints the `live_mode` flag,
   so this can never silently regress unnoticed again.

## Still needed: activate live mode on your Duffel account (Bakr)
Same shape as getting the test token, a few more steps. In Duffel
(app.duffel.com), toggle **Test mode OFF** - it will then walk you through
whatever is still missing:

1. Verify your email address (if not already).
2. Fill in company information - **"Personal use" is a valid answer**, you
   don't need a company.
3. Add payment information. Duffel requires a card on file to unlock live
   mode, but **searching prices does not charge anything** - charges only
   happen if an actual ticket is issued, which this app never does (it
   hands off to booking links).
4. Click **"Agree and Submit"**.
5. Then: **More -> Developer -> Create Live Token**, and copy it (it starts
   with `duffel_live_` instead of `duffel_test_`).

Then swap it into the same GitHub secret as before - it's the only thing
that needs to change:
`github.com/bakr1100-cyber/Bakr/settings/secrets/actions` ->
`DUFFEL_API_KEY` -> Update -> paste the `duffel_live_...` token.

The next deploy of `cloudflare-worker/**` picks it up and real prices start
flowing, the warning banner disappears on its own, and the scheduled
price-drop notifications start comparing real prices too (they use the same
key).

### Worth knowing before you do it
Duffel live mode gives real prices and real availability. Actually *selling*
tickets through Duffel is a separate, much bigger step (airline
accreditation) - not needed here, since this app sends people to booking
links rather than issuing tickets itself. So: live mode = real prices to
show, no obligation to sell anything.
