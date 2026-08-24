# Two new city photos couldn't be uploaded

The user tried repeatedly (single image, following the same steps that
worked for the Fès/Casablanca/Marrakech photos and the new logo) but the
files never arrived as real attachments - only as inline-pasted images I
can see but can't save. Not a user-error issue at this point; looks like a
transient upload problem on the platform side.

## What the photos show

1. Agadir beach, wide sandy crescent with white apartment blocks along the
   shore, and - the unmistakable identifier - the "الله، الوطن، الملك"
   (Allah, Al Watan, Al Malik) inscription on the Agadir Oufella hillside
   above the city, with the old kasbah ruins visible on top of the hill.
   This is genuinely, unambiguously Agadir.
2. A kasbah/fortress at golden hour, mountains in the background - possibly
   the same Agadir Oufella kasbah from a different angle, but less certain
   without a clearer/uploaded copy to inspect closely.

## What to do once the files actually arrive

Same pattern as the other three verified city photos (see
`lib/widgets/city_hero_header.dart` `_cityImages`... now
`lib/widgets/city_hero_header.dart`'s `heroImages` list and
`lib/widgets/popular_destinations.dart`'s `_images` map):
1. Crop/scale to the app's 1024x800 hero-image convention (see the ffmpeg
   commands used for `hero_fes.jpg`/`hero_casablanca.jpg`/
   `hero_marrakech.jpg` for the pattern).
2. Save as `assets/images/hero_agadir.jpg` (airport code `AGA`).
3. Add `'assets/images/hero_agadir.jpg'` to the `heroImages` list in
   `city_hero_header.dart` (used by the random-photo header everywhere).
4. Add `'AGA': 'assets/images/hero_agadir.jpg'` to `PopularDestinations`'s
   `_images` map so the Agadir destination card gets its own photo instead
   of the gradient placeholder.
5. Update `city_hero_header_test.dart`'s verified-photo list/tests
   accordingly.
