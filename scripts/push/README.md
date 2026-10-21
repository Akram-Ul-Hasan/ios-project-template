# Sample push payloads

One per deep-linkable screen (rule 16). Every push carries a single `deeplink` field, parsed by `DeepLinkParser`.

```sh
xcrun simctl push booted scripts/push/order.apns
```

Then tap the notification: the app opens the order with Orders behind it, including from a cold start.
Allow notifications first (finish onboarding, or Settings → Notifications).
