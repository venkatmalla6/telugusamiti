"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onNotificationCreated = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
exports.onNotificationCreated = functions.firestore
    .document("notifications/{notifId}")
    .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data)
        return;
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
    }
    catch (error) {
        functions.logger.error("Error sending FCM message:", error);
    }
});
//# sourceMappingURL=index.js.map