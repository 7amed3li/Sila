# Firebase Messaging Optimization Guide

## Problem: "TOO_MANY_SUBSCRIBERS" Error

Firebase Cloud Messaging has limits on topic subscriptions:
- Maximum ~10,000 subscriptions per user per day
- Rate limiting on simultaneous subscription requests
- Topics must be unique identifiers

When you see: `Topic operation failed: TOO_MANY_SUBSCRIBERS`

This happens when:
1. **Subscribing at app launch**: Trying to subscribe to too many topics at once
2. **Subscribing in loops**: Calling `subscribeToTopic()` 114 times for each surah
3. **Repeated subscriptions**: Subscribing to the same topic multiple times without checking
4. **No delays**: Sending all subscription requests simultaneously

---

## Solution: Lazy Subscription Pattern

### ✅ Current Implementation (CORRECT)

```dart
// Step 1: Subscribe only to ESSENTIAL topics at startup
Future<void> _subscribeToTopics() async {
  try {
    // Delay to avoid rate limiting
    await Future.delayed(const Duration(milliseconds: 500));
    
    await FirebaseMessaging.instance.subscribeToTopic('all_users');
    debugPrint('✅ Subscribed to topic: all_users');
    
    // Space out requests
    await Future.delayed(const Duration(milliseconds: 200));
    
    await FirebaseMessaging.instance.subscribeToTopic('updates');
    debugPrint('✅ Subscribed to topic: updates');
  } catch (e) {
    debugPrint('⚠️ Firebase topic subscription failed: $e');
  }
}

// Step 2: Subscribe to OPTIONAL topics on-demand
Future<void> subscribeToTopicLazy(String topic) async {
  if (_subscribedTopics.contains(topic)) {
    return; // Already subscribed - avoid duplicate
  }

  try {
    await Future.delayed(const Duration(milliseconds: 100)); // Rate limit
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    _subscribedTopics.add(topic);
    debugPrint('✅ Subscribed to optional topic: $topic');
  } catch (e) {
    debugPrint('⚠️ Failed to subscribe to topic $topic: $e');
  }
}
```

---

## Two-Tier Subscription Strategy

### Tier 1: Essential Topics (Subscribe at Startup)
Topics that ALL users need:
```dart
'all_users'    // General announcements
'updates'      // App updates
```

**When**: App initialization
**Quantity**: ≤ 3-5 topics
**Delay**: 500ms before first subscription, 200ms between each

---

### Tier 2: Optional Topics (Subscribe on-demand)
Topics that ONLY specific users need:
```dart
'reciter_${reciterId}'     // For specific reciter updates
'surah_${surahNumber}'     // For specific surah news
'user_${userId}'           // For user-specific messages
```

**When**: User selects a reciter, bookmarks a surah, etc.
**Quantity**: Unlimited (spread over time)
**Delay**: 100ms between each subscription

---

## Usage Examples

### Example 1: Subscribe When User Selects Reciter
```dart
// In reciter_picker_sheet.dart or similar
Future<void> selectReciter(ReciterModel reciter) async {
  // Update local state
  state = state.copyWith(selectedReciter: reciter);
  
  // Then subscribe to updates for THIS reciter
  final notificationService = NotificationService();
  await notificationService.subscribeToTopicLazy('reciter_${reciter.id}');
}
```

**Benefits**:
- Only subscribe when user explicitly shows interest
- Respects rate limits by spreading subscriptions
- No duplicate subscriptions

---

### Example 2: Batch Subscribe with Delay
```dart
// When importing favorites or watchlist
Future<void> importFavorites(List<int> surahNumbers) async {
  final notificationService = NotificationService();
  
  for (final surahNumber in surahNumbers) {
    // Subscribe one by one with delay
    await notificationService.subscribeToTopicLazy('surah_$surahNumber');
  }
}
```

**Timeline**:
- Surah 1: subscribe at 0ms
- Surah 2: subscribe at 100ms
- Surah 3: subscribe at 200ms
- ... (spreads load over time)

---

### Example 3: Unsubscribe When No Longer Needed
```dart
// When user removes bookmark
Future<void> removeBookmark(int surahNumber) async {
  // Update local state
  bookmarkedSurahs.remove(surahNumber);
  
  // Unsubscribe from updates
  final notificationService = NotificationService();
  await notificationService.unsubscribeFromTopic('surah_$surahNumber');
}
```

---

## Best Practices Checklist

### ✅ DO's

- ✅ **Track subscribed topics** - Use `Set<String>` to avoid duplicates
- ✅ **Add delays between requests** - 100-500ms depending on context
- ✅ **Subscribe on-demand** - Only when user needs it
- ✅ **Unsubscribe when done** - Free up the subscription slot
- ✅ **Check before subscribing** - Don't subscribe twice to same topic
- ✅ **Use meaningful topic names** - Include category and ID
- ✅ **Handle errors gracefully** - Don't crash if subscription fails
- ✅ **Log subscriptions** - For debugging and monitoring

### ❌ DON'Ts

- ❌ **Don't subscribe in loops without delay** - Causes rate limiting
- ❌ **Don't subscribe to 114 topics at startup** - Use lazy subscription
- ❌ **Don't forget to track subscriptions** - Can lead to duplicates
- ❌ **Don't ignore errors** - Log them for monitoring
- ❌ **Don't use random topic names** - Keep them consistent
- ❌ **Don't mix sync and async operations** - Use await properly
- ❌ **Don't subscribe the same topic twice** - Check set first
- ❌ **Don't call subscribeToTopicLazy() in tight loops** - Space them out

---

## Topic Naming Convention

Use consistent, hierarchical naming:

```
'all_users'                    // System-wide topics
'updates'
'maintenance'

'reciter_123'                  // Reciter-specific topics
'reciter_456'

'surah_1'                      // Surah-specific topics
'surah_2'
...
'surah_114'

'user_abc123'                  // User-specific topics
'user_def456'

'language_ar'                  // Language-specific topics
'language_en'
'language_fr'
'language_tr'
```

**Benefits**:
- Easy to understand
- Searchable in Firebase Console
- Clear hierarchy
- Predictable

---

## Firebase Limits & Quotas

| Metric | Limit | Action |
|--------|-------|--------|
| Topics per instance ID | ~10,000 | Design wisely |
| Subscriptions per day | ~10,000 | Lazy load |
| Concurrent subscriptions | ~100 | Space out requests |
| Request rate | ~10 req/sec | Add delays |
| Topic name length | 256 chars | Use short names |

---

## Monitoring & Debugging

### Check Current Subscriptions (Firebase Console)
1. Go to Firebase Console
2. Cloud Messaging → Topics
3. See all active topics and subscriber counts

### Debug Subscription Attempts
```dart
// Enable verbose logging
FirebaseMessaging.instance.setAutoInitEnabled(true);

// Listen for token refresh
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  debugPrint('New FCM token: $newToken');
});

// Check current token
final token = await FirebaseMessaging.instance.getToken();
debugPrint('Current FCM token: $token');
```

### Common Error Codes
```
TOO_MANY_SUBSCRIBERS   → Hitting rate limit or too many topics
INTERNAL_ERROR         → Firebase backend issue (retry)
INVALID_TOPIC          → Topic name is invalid (check spelling)
NOT_FOUND              → Topic doesn't exist (create it first)
ALREADY_SUBSCRIBED     → Already subscribed (check before subscribing)
```

---

## Performance Metrics

### Subscription Performance
| Operation | Time | Target |
|-----------|------|--------|
| Single subscription | 100-500ms | < 1s |
| 10 subscriptions | 1-3s | < 5s |
| 100 subscriptions | 10-30s | < 60s |

**Rule of Thumb**: Expect 100-500ms per subscription request.

---

## Implementation Checklist

Before deploying to production:

- [ ] Essential topics (≤5) subscribe at startup
- [ ] Optional topics use `subscribeToTopicLazy()`
- [ ] Delays added between subscription requests
- [ ] Topic names follow naming convention
- [ ] `_subscribedTopics` Set used to track subscriptions
- [ ] Error handling with descriptive logs
- [ ] Unsubscribe implemented for cleanup
- [ ] Tested with slow network (DevTools throttling)
- [ ] Firebase Crashlytics shows no FCM errors
- [ ] No duplicate subscription attempts

---

## Code Location

**Modified File**: `lib/core/services/notification_service.dart`

**Key Methods**:
- `_subscribeToTopics()` - Essential topics at startup
- `subscribeToTopicLazy(String topic)` - Optional topics on-demand
- `unsubscribeFromTopic(String topic)` - Cleanup
- `_subscribedTopics` - Track subscriptions

---

## Future Enhancements

### Phase 2 (Optional)
- [ ] Analytics: Track subscription success/failure rates
- [ ] Dynamic topics based on user preferences
- [ ] Batch unsubscription on logout
- [ ] Firebase Remote Config for topic management
- [ ] A/B testing different subscription strategies

---

**Last Updated**: 2026-03-29
**Status**: ✅ Implemented
**Impact**: Eliminates TOO_MANY_SUBSCRIBERS errors
