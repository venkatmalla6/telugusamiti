import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onNotificationCreated = functions.firestore
  .document("notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return;

    const title = data.title || "New Notification";
    const body = data.body || "";
    // If the notification specifies a topic, use it. Otherwise default to all_users.
    const topic = data.topic || "all_users";

    const payload = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: data.type || "adminBroadcast",
        targetUid: data.targetUid || "",
      },
      topic: topic,
    };

    try {
      const response = await admin.messaging().send(payload);
      functions.logger.info("Successfully sent FCM message:", response);
    } catch (error) {
      functions.logger.error("Error sending FCM message:", error);
    }
  });
