# Push Notification Setup Guide

This guide explains how to enable push notifications for the feedback system so you receive instant alerts when users submit feedback.

## Prerequisites

1. Firebase project (or create one at https://console.firebase.google.com)
2. Admin Android device for receiving notifications
3. Firebase Admin SDK service account key

## Android Setup

### Step 1: Add Firebase to Android Project

1. Go to Firebase Console: https://console.firebase.google.com
2. Add Android app to your project
3. Package name: `com.statshark.nfl`
4. Download `google-services.json`
5. Place in: `StatSharkAndroid/app/google-services.json`

### Step 2: Update Android Dependencies

The `app/build.gradle.kts` already has the required dependencies commented out. Uncomment these lines:

```kotlin
// Firebase dependencies (uncomment when google-services.json is added)
implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
implementation("com.google.firebase:firebase-messaging-ktx")
implementation("com.google.firebase:firebase-analytics-ktx")
```

### Step 3: Apply Google Services Plugin

In `app/build.gradle.kts`, uncomment:

```kotlin
plugins {
    // ...
    id("com.google.gms.google-services") // Uncomment this
}
```

In `build.gradle.kts` (project root), add:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

### Step 4: Register Your Admin Device Token

Run the app on your Android device and check logcat for:
```
🔔 FCM Token: <your-device-token>
```

Save this token - you'll need it for the backend.

### Step 5: Set Environment Variable

On the backend server, set:
```bash
export ADMIN_FCM_TOKEN="<your-device-token-from-step-4>"
export ADMIN_USER_ID="<your-admin-user-id>"
```

## Backend Setup

### Step 1: Get Firebase Admin SDK Key

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Download the JSON file
4. Save as: `firebase-admin-key.json` (add to .gitignore!)

### Step 2: Add Firebase Admin SDK to Backend

Update `Package.swift` to add Firebase Admin dependency:

```swift
dependencies: [
    // ... existing dependencies
    .package(url: "https://github.com/firebase/firebase-admin-swift.git", from: "1.2.0")
]

// In NFLServer target:
.executableTarget(
    name: "NFLServer",
    dependencies: [
        // ... existing
        .product(name: "FirebaseAdmin", package: "firebase-admin-swift"),
    ]
)
```

### Step 3: Initialize Firebase in Server

In `Sources/NFLServer/main.swift`, add initialization:

```swift
import FirebaseAdmin

// In configure() function:
let serviceAccountPath = Environment.get("FIREBASE_ADMIN_KEY_PATH") ?? "firebase-admin-key.json"
try FirebaseApp.initialize(serviceAccountCredentialFile: serviceAccountPath)
```

### Step 4: Update Notification Function

The `sendAdminNotification()` function in `main.swift` needs to be implemented with FCM:

```swift
func sendAdminNotification(feedback: Feedback) async {
    guard let adminToken = Environment.get("ADMIN_FCM_TOKEN") else {
        print("⚠️ ADMIN_FCM_TOKEN not set - notification not sent")
        return
    }

    do {
        let message = Message(
            token: adminToken,
            notification: Notification(
                title: "New Feedback from \(feedback.platform)",
                body: "\(feedback.userId) on \(feedback.page): \(feedback.feedbackText.prefix(100))..."
            ),
            data: [
                "feedbackId": feedback.id?.uuidString ?? "",
                "userId": feedback.userId,
                "page": feedback.page,
                "platform": feedback.platform
            ]
        )

        let messageId = try await Messaging.messaging().send(message)
        print("✅ Push notification sent: \(messageId)")
    } catch {
        print("❌ Failed to send push notification: \(error)")
    }
}
```

## Android Notification Handler

Create `NotificationService.kt` in `app/src/main/kotlin/com/statshark/nfl/services/`:

```kotlin
package com.statshark.nfl.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.statshark.nfl.MainActivity
import com.statshark.nfl.R

class FeedbackNotificationService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        println("🔔 FCM Token: $token")
        // TODO: Send token to your server if needed
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        val notification = message.notification ?: return
        val data = message.data

        showNotification(
            title = notification.title ?: "New Feedback",
            body = notification.body ?: "",
            data = data
        )
    }

    private fun showNotification(title: String, body: String, data: Map<String, String>) {
        val channelId = "feedback_channel"
        val notificationManager = getSystemService(NotificationManager::class.java)

        // Create notification channel (Android 8.0+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Feedback Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for new user feedback"
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Intent to open admin screen
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("openAdmin", true)
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Build notification
        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }
}
```

### Register Service in AndroidManifest.xml:

```xml
<service
    android:name=".services.FeedbackNotificationService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

## Testing Push Notifications

### Test from Firebase Console:

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and text
4. Click "Send test message"
5. Paste your FCM token from Step 4
6. Send

### Test from Backend:

1. Submit feedback from iOS or Android app
2. Check server logs for push notification confirmation
3. Check admin Android device for notification
4. Tap notification to open admin panel

## Environment Variables Summary

Set these on your backend server:

```bash
# Database
export DATABASE_PATH="db.sqlite"  # Or path to your database

# Admin Configuration
export ADMIN_USER_ID="your-admin-id"  # Your admin identifier
export ADMIN_FCM_TOKEN="your-device-fcm-token"  # From Android logcat

# Firebase
export FIREBASE_ADMIN_KEY_PATH="firebase-admin-key.json"  # Path to service account key

# API Keys (existing)
export ODDS_API_KEY="your-odds-api-key"
export NEWS_API_KEY="your-news-api-key"
export API_SPORTS_KEY="your-api-sports-key"
```

## Security Notes

1. **Never commit** `google-services.json` or `firebase-admin-key.json` to version control
2. Add to `.gitignore`:
   ```
   google-services.json
   firebase-admin-key.json
   db.sqlite
   ```
3. Rotate FCM tokens periodically
4. Use environment variables for all secrets
5. Consider implementing proper authentication (JWT, OAuth) for production

## Troubleshooting

### Notifications Not Received:

1. Check server logs for push notification errors
2. Verify ADMIN_FCM_TOKEN is set correctly
3. Verify Firebase Admin SDK is initialized
4. Check Android notification permissions are granted
5. Ensure app is not in battery optimization

### Authentication Failures:

1. Verify ADMIN_USER_ID environment variable matches your input
2. Check server logs for authentication attempts
3. Clear SharedPreferences in app and re-authenticate

### Database Issues:

1. Check DATABASE_PATH is writable
2. Verify Fluent migrations ran successfully
3. Check server startup logs for migration errors

## Current Status

✅ Backend database and API - **Complete**
✅ iOS feedback system - **Complete**
✅ Android feedback system - **Complete**
⏳ Push notifications - **Requires Firebase setup (follow guide above)**

The feedback system is fully functional. Push notifications require Firebase project configuration which must be done manually through the Firebase Console.
