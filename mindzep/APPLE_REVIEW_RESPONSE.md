# Guideline 5.6 — Response to App Review

## Why the first reply failed

The previous response denied the finding ("there are no mechanisms intended to
identify App Review and selectively hide functionality") and disclosed **two**
roles. The binary contains **three** (`enum UserRole { user, psychologist, admin }`).

From App Review's side, being asked about concealment and receiving an
incomplete inventory reads as confirmation. That is why the second rejection
came back word-for-word identical. **Do not deny again.** Acknowledge, give a
complete inventory, and state what changed.

---

## Reply to paste into App Store Connect

> Hello App Review Team,
>
> Thank you for the additional feedback. Our previous reply was incomplete, and
> we would like to correct that with a full account of the app's functionality.
>
> **Complete inventory of user roles**
>
> MindZep has three account roles, all determined by the authenticated user's
> role on our backend:
>
> 1. **User** — browse psychologists, book and attend video/audio sessions,
>    view wallet balance and session history, read blogs.
> 2. **Psychologist** — manage availability slots, accept and conduct sessions,
>    publish blog articles, view their own session history.
> 3. **Admin** — an internal back-office role used by our own staff to approve
>    psychologist applications, manage user and psychologist records, view
>    platform appointments, and manage blog content.
>
> The admin role was not mentioned in our earlier response. That was an
> oversight on our part, not an attempt to conceal it, and we apologise for the
> confusion it caused. Admin accounts are issued only to our internal team and
> are not obtainable through in-app registration, which is why the reviewer
> could not reach those screens. We have provided admin credentials below so
> the entire application can be examined.
>
> **Changes made in this build**
>
> - Psychologist profiles previously displayed a set of placeholder review
>   entries that were compiled into the app rather than fetched from our
>   server. These have been removed. The Reviews tab now displays only genuine
>   reviews returned by our API, and shows an empty state when a psychologist
>   has none.
> - All sample/placeholder data has been deleted from the codebase.
> - Online payment is not offered in this version of the app. The wallet
>   top-up screen has been removed, and booking and help text no longer
>   describe a charge that is not taken. Sessions are currently provided at no
>   cost. When we introduce paid sessions, we will submit that as a normal
>   feature update for review before it reaches users.
> - Non-functional placeholder controls in the admin area have been removed so
>   that every control performs a real action.
> - Help and privacy text has been corrected to describe our actual security
>   practices.
>
> **Confirmation regarding review detection**
>
> The app contains no logic that detects App Review and alters behaviour. There
> is no check on reviewer status, device, IP address, location, region, locale,
> date, or build type that changes which features are available. All users on a
> given build receive identical functionality for their account role. We are
> happy to walk through any part of the source with you.
>
> **Test accounts**
>
> User:
> Email: <USER_QA_EMAIL>
> Password: <PASSWORD>
>
> Psychologist:
> Email: qa.psychologist@mindzep.com
> Password: <PASSWORD>
>
> Admin:
> Email: qa.admin@mindzep.com
> Password: <PASSWORD>
>
> Signing in with each account gives access to that role's full set of screens.
>
> Please let us know if you would like a demo video of any workflow or any
> further information.
>
> Thank you for your time.

---

## Before you submit — checklist

- [ ] **Create the admin QA account** (`qa.admin@mindzep.com`). It must actually
      work, and it must expose the real admin screens. Verify by logging in.
- [ ] **Verify all three accounts** on the exact build you upload.
- [ ] **Use a dedicated QA user account**, not a personal address. The previous
      reply used `kchoudhary2631@gmail.com`, a personal Gmail. Create something
      like `qa.user@mindzep.com`.
- [ ] **Check the version number.** `pubspec.yaml` declares `9.0.0+9`, while App
      Store Connect shows the app as version `1.0`. Make sure the build name you
      ship matches what the listing says — a mismatch is an avoidable red flag.
- [ ] **Confirm your App Store description and screenshots** describe only what
      a User account can actually do. If the listing shows admin or
      psychologist screens the reviewer cannot reach, that reopens the same
      finding.
- [ ] **Attach a demo video** if you can. For a 5.6 rejection this
      disproportionately helps — it shows you are not hiding anything.

---

## Still open (deferred by decision, 2026-09-09)

**The backend runs over plaintext HTTP on a raw IP** (`http://150.241.245.88:8090`),
which requires `NSAllowsArbitraryLoads=true` in `ios/Runner/Info.plist` to
function on iOS. You chose to leave the API as-is for now.

Be aware of what remains exposed:

- Personal health data — session records, appointments, profile details — is
  transmitted unencrypted. This is a **Guideline 5.1.1 (Data Collection and
  Storage)** risk independent of the 5.6 rejection, and a genuine risk to your
  users today.
- A store build that talks to a raw-IP host is one of the signals that
  contributes to the "different behaviour during review" pattern.
- Because of this, the app can no longer honestly claim end-to-end encryption;
  the help and privacy copy has been corrected accordingly.

The fix requires **no API or application changes** — point a domain at the same
server and terminate TLS (Cloudflare proxy, or nginx with Let's Encrypt).
Then set `NSAllowsArbitraryLoads` to `false` and build with:

```
--dart-define=API_BASE_URL=https://<domain>
--dart-define=SOCKET_BASE_URL=https://<domain>
```

Worth doing before the next submission if time allows.
