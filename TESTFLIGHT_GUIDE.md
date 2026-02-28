# TestFlight Distribution Guide — BrainQuizLiquidLLM

A step-by-step walkthrough for publishing a new iOS app to TestFlight for internal family testing.
Written based on first-time deployment of BrainQuizLiquidLLM (LeapDemo) in February 2026.

---

## Overview of the Full Process

```
1. Register App ID (Apple Developer portal)
2. Create App Store Connect record
3. Set Bundle ID in Xcode
4. Add App Icon to asset catalog
5. Archive and upload from Xcode
6. Resolve Export Compliance on Apple's side
7. Create Internal Testing Group
8. Add Testers to the group
9. Testers accept invite and install via TestFlight app
```

---

## Step 1 — Register an App ID

**Where:** https://developer.apple.com → Certificates, Identifiers & Profiles → Identifiers

**What to do:**
1. Click the **+** button next to "Identifiers"
2. Select **App IDs** → Continue
3. Select **App** → Continue
4. Fill in:
   - **Description:** e.g. `BrainQuizLiquidLLM`
   - **Bundle ID:** Select "Explicit", enter e.g. `ai.liquid.LeapDemo`
     - Format: reverse-domain notation, must be unique across all of Apple
     - This must match exactly what you set in Xcode later
5. Scroll down, enable any capabilities needed (none required for a basic app)
6. Click **Continue** → **Register**

> **Confusion point:** The App ID registration is separate from App Store Connect. You must do this first before creating the app record. The Bundle ID you enter here is permanent and links everything together.

---

## Step 2 — Create the App Record in App Store Connect

**Where:** https://appstoreconnect.apple.com → My Apps

**What to do:**
1. Click the **+** button (top-left area near "My Apps")
2. Select **New App** from the dropdown
3. Fill in the form:
   - **Platforms:** iOS
   - **Name:** e.g. `BrainQuizLiquidLLM` (this is the display name on the App Store)
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select the App ID you just registered from the dropdown
   - **SKU:** A unique internal identifier, e.g. `BrainQuizLiquidLLM` (only you see this)
   - **User Access:** Select **Full Access** unless you want to restrict which team members can see it
4. Click **Create**

> **Confusion point 1:** The "New App" option is in a small dropdown — click the **+** button and look for it in the menu.

> **Confusion point 2:** "User Access" is just about which members of your developer team can see the app in App Store Connect. It is NOT about TestFlight testers. Choose **Full Access** to keep it simple.

---

## Step 3 — Set the Bundle ID in Xcode

**Where:** Xcode → Project Navigator → Select the app target → Signing & Capabilities tab

**What to do:**
1. Open the `.xcworkspace` in Xcode
2. Click on the project root in the navigator
3. Select the **app target** (not the package)
4. Go to **Signing & Capabilities** tab
5. Under **Bundle Identifier**, enter the exact same value you registered:
   - e.g. `ai.liquid.LeapDemo`
6. Make sure **Automatically manage signing** is checked
7. Select your **Team** from the dropdown

> **Confusion point:** The Bundle ID must be typed into the **Signing & Capabilities** tab of the **app target** (the top-level project target, not the Swift Package). The field is editable — just click it and type.

---

## Step 4 — Add an App Icon

Xcode requires app icons before it will accept an archive for upload. Missing icons cause validation errors like:
```
ERROR ITMS-90704: Missing required icon file.
The bundle does not contain an app icon for iPad of exactly '152x152' pixels.
```

**What to do:**
1. Open `Assets.xcassets` in the app target
2. Select **AppIcon**
3. You need a **1024×1024 PNG** (no transparency, no rounded corners — Apple applies the rounding)
4. Drag the image into the **App Store (1024×1024)** slot
5. If using a "Single Size" asset catalog (Xcode 14+), one 1024×1024 image is sufficient

**Quick placeholder generation (Python):**
```python
#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os

size = 1024
img = Image.new("RGB", (size, size), color=(15, 23, 42))  # dark navy
draw = ImageDraw.Draw(img)
draw.ellipse([212, 212, 812, 812], outline=(99, 179, 237), width=12)
draw.text((512, 512), "BQ", fill=(99, 179, 237), anchor="mm")
img.save("/tmp/AppIcon.png")
```
Then drag `/tmp/AppIcon.png` into the AppIcon slot in Xcode.

> **Confusion point:** The archive will succeed, but the **upload step** will fail validation if icons are missing. Xcode won't warn you until you try to distribute.

---

## Step 5 — Archive and Upload from Xcode

**What to do:**
1. In Xcode, set the scheme destination to **Any iOS Device (arm64)** (not a simulator)
2. Menu → **Product → Archive**
3. Wait for the build to complete. The **Organizer** window opens automatically.
4. Select your archive → Click **Distribute App**
5. On the destination screen, select **App Store Connect** → **Next**
   - (This is the correct path for TestFlight — do NOT look for a separate "TestFlight" button)
6. Select **Upload** → **Next**
7. Leave distribution options at defaults → **Next**
8. Review signing, make sure the correct provisioning profile and certificate are shown → **Next**
9. Click **Upload**

> **Confusion point:** There is no separate "TestFlight" destination in the distribute dialog. You upload to **App Store Connect** and then manage TestFlight distribution from the website.

**dSYM warnings during upload:**
You may see warnings like:
```
Warning: unable to find Swift standard libraries for...
dSYM file missing for...
```
These are harmless for TestFlight testing — they only affect crash symbolication in production. Click through and proceed.

---

## Step 6 — Resolve Export Compliance

After upload, Apple requires you to declare whether your app uses encryption.

**Where:** App Store Connect → TestFlight → iOS (left sidebar) → find your build

**What to do:**
1. Wait for the build status to show **"Ready to Submit"** — this means Apple has finished processing
2. The build will have a compliance warning — click **Manage** next to it
3. Answer: **"Does your app use encryption?"**
   - If your app only uses standard HTTPS/TLS (which iOS handles automatically), answer **No**
   - Most apps answer No
4. Click **Save**
5. Status changes to **"Ready to Test"** — testers are notified automatically

> **Confusion point:** The build will not appear for testers until compliance is resolved. If you skip this step, nothing will work.

> **Status sequence:** Uploading → Processing → Ready to Submit (resolve compliance here) → Ready to Test

---

## Step 7 — Create an Internal Testing Group

**Where:** App Store Connect → TestFlight → (left sidebar, under Internal Testing, click +)

**What to do:**
1. Click the **+** next to "Internal Testing" in the left sidebar
2. Enter a group name, e.g. `FamilyAndGuests`
3. Check **Enable automatic distribution**
   - This means every future build you upload will automatically be added to this group
   - Without this, you must manually add each new build
4. Click **Create**

> **Key setting:** Always enable **automatic distribution** on your primary testing group. Otherwise after every upload you must remember to manually link the new build.

---

## Step 8 — Add Testers to the Group

**Where:** App Store Connect → TestFlight → FamilyAndGuests → Testers tab → + button

**What to do:**
1. Click the **+** button on the Testers tab
2. For **internal testers** (people in your Apple Developer team):
   - Select from the list of team members
3. For **people NOT on your developer team** (external testers like family):
   - They must be added via email as **External Testers** (different process — see note below)
   - OR: Add them to your Apple Developer team as "App Manager" or lower role first
4. Click **Add**

Testers will receive an email invitation. They must:
1. Install the **TestFlight app** from the App Store
2. Accept the email invitation (tap the link on their iPhone)
3. The app appears in TestFlight and they can install it

> **Note on External vs Internal testers:**
> - **Internal:** Must be members of your Apple Developer account (added via Users and Access)
> - **External:** Anyone with an email address; requires a separate external testing group and App Review for the first build
> - For family testing, the easiest approach is to add family members as internal testers with a limited role

**Adding more testers in the future:**
1. Go to App Store Connect → Users and Access
2. Invite them as a team member (e.g. role: "App Manager" or "Developer")
3. Once they accept, go to TestFlight → FamilyAndGuests → Testers → + → select them

---

## Step 9 — Tester's Installation Flow

Each tester receives an email:
```
Subject: [Developer Name] has invited you to test BrainQuizLiquidLLM
```

Steps for the tester:
1. Open the email **on their iPhone** (or tap the link from any device, then open on iPhone)
2. Tap **"Start Testing"** in the email
3. If TestFlight is not installed: redirected to App Store to install it first
4. Open TestFlight → the app appears
5. Tap **Install** or **Accept** → **Install**

The app now installs just like a regular App Store app. No developer account needed.

---

## Future Builds (Subsequent Releases)

For every new version:

1. Bump the **Build Number** in Xcode (must be higher than the previous build)
   - Version: e.g. `1.0` (can stay the same for bug fixes)
   - Build: e.g. `2`, `3`, ... (must always increment)
2. Archive → Distribute → App Store Connect → Upload (same as Step 5)
3. If **automatic distribution** is enabled: build automatically appears in FamilyAndGuests
4. Resolve Export Compliance if prompted (usually only needed once per app, or after changing network/encryption settings)
5. Wait ~5–15 minutes for processing; testers get a notification in TestFlight

---

## Quick Reference — Key URLs

| Purpose | URL |
|---------|-----|
| Apple Developer Portal | https://developer.apple.com/account |
| Certificates, IDs & Profiles | https://developer.apple.com/account/resources/identifiers/list |
| App Store Connect | https://appstoreconnect.apple.com |
| My Apps | https://appstoreconnect.apple.com/apps |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Build shows "Missing Compliance" | Click Manage → answer encryption question → Save |
| Testers see "No Builds Available" | They haven't accepted the invite email yet; resend from Testers tab |
| Upload fails with icon errors | Add 1024×1024 PNG to AppIcon in Assets.xcassets |
| Build stuck in "Processing" | Normal; wait 5–30 minutes. Check App Store Connect for progress |
| Bundle ID mismatch | Must be identical in: Developer Portal → App Record → Xcode target |
| Archive option greyed out | Destination must be "Any iOS Device", not a simulator |
| dSYM warnings during upload | Harmless — proceed without concern |

---

*Last updated: February 2026. App: BrainQuizLiquidLLM (ai.liquid.LeapDemo), Build 1.0(1).*
