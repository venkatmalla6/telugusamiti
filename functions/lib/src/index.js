"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onNotificationCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
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