# Signing and notarization

Releases are signed ad-hoc today, so macOS shows "can't verify the developer" the first time an app opens, and the user has to click **Open Anyway** in Privacy & Security. A Developer ID removes that dialog for every download, and `brew install` and the install script stop needing to clear the quarantine flag. The pipeline is ready for it: `scripts/notarize` signs and notarizes whenever its six environment variables exist, and does nothing (with a message) when they don't. Nothing here is faked; until the secrets exist, every release says `not notarizing`.

## What it costs

- The Apple Developer Program: **US$99 a year**, as an individual. Enrolment needs an Apple Account with two-factor authentication and usually clears within 48 hours; Apple sometimes asks for identity documents and takes longer.
- Nothing else. Notarization itself is free and takes a few minutes per upload.

## Steps

1. **Enrol**: <https://developer.apple.com/programs/enroll/>. Wait for the welcome email.
2. **Make the certificate**, without Xcode:
   1. Keychain Access › Keychain Access menu › Certificate Assistant › **Request a Certificate From a Certificate Authority…**. Your email, your name, *Saved to disk*. Keep the private key it creates in the login keychain.
   2. <https://developer.apple.com/account/resources/certificates/add> › **Developer ID Application** › upload the request › download the `.cer` › double-click it to install. Only the account holder can create Developer ID certificates.
   3. Check: `security find-identity -v -p codesigning` lists `"Developer ID Application: Your Name (TEAMID)"`. That whole string is `DEVELOPER_ID_APPLICATION`.
3. **Export it for CI**: Keychain Access › My Certificates › the Developer ID Application certificate (expand it so the private key is included) › right-click › **Export…** › `.p12` with a password of your choosing. That password is `APPLE_CERTIFICATE_PASSWORD`; the file's base64 is `APPLE_CERTIFICATE`.
4. **An app-specific password**: <https://account.apple.com> › Sign-In and Security › App-Specific Passwords. That is `APPLE_APP_PASSWORD`; `APPLE_ID` is the account's email.
5. **The team ID**: <https://developer.apple.com/account> › Membership details. That is `APPLE_TEAM_ID`.
6. **Set the secrets** on the repository:

   ```sh
   gh secret set DEVELOPER_ID_APPLICATION --body "Developer ID Application: Your Name (TEAMID)"
   gh secret set APPLE_ID --body "you@example.com"
   gh secret set APPLE_TEAM_ID --body "TEAMID"
   gh secret set APPLE_APP_PASSWORD --body "xxxx-xxxx-xxxx-xxxx"
   gh secret set APPLE_CERTIFICATE --body "$(base64 -i ~/Desktop/developer-id.p12)"
   gh secret set APPLE_CERTIFICATE_PASSWORD --body "the export password"
   rm ~/Desktop/developer-id.p12
   ```

7. **Try it locally first**, with the certificate already in the login keychain (so no `APPLE_CERTIFICATE` needed):

   ```sh
   DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)" APPLE_ID=you@example.com \
   APPLE_TEAM_ID=TEAMID APPLE_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx scripts/task package bar
   spctl --assess --type execute --verbose "build/bar/Common Bar.app"   # accepted, source=Notarized Developer ID
   ```

   If Apple rejects the upload, `scripts/notarize` prints the notarization log; the usual causes are a missing `--timestamp` or hardened runtime, both of which the script sets.

8. **Release** as usual: `scripts/release bar 0.5.0`. The Release workflow's Package step has the secrets in its environment, so the zip, the command-line tools, and the disk image are all signed, notarized, and stapled.

## After the first notarized release

- Remove the Open Anyway text from the site: `site/src/lib/OpenAnyway.svelte` and the sentence about re-allowing permissions after each update in `Install.svelte`. With a stable signature, Accessibility and Screen Recording grants survive updates.
- Drop the quarantine step from `scripts/cask` (`postflight_steps`) and from `site/static/install.sh`; neither hurts, but neither is needed.
- `scripts/dev-cert` stays as it is: development builds keep using the development identity so permission grants survive rebuilds, and only `scripts/task package` re-signs with the Developer ID.

## What `scripts/notarize` does

For each path: `codesign --force --timestamp --options runtime --sign "$DEVELOPER_ID_APPLICATION"`, keeping the identifier the build set; `xcrun notarytool submit --wait` on a zip of the app (or the tool), or on the disk image itself; `xcrun stapler staple` on the app and the image (a bare tool can't carry a ticket); then `spctl --assess` to prove the result passes Gatekeeper. In CI the certificate is imported into a keychain of its own, once per job, from `APPLE_CERTIFICATE`.
