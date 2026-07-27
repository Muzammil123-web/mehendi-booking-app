const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Sends a push notification to a user's saved FCM token, if they have one.
 * Silently does nothing if the user never granted notification permission
 * (no token saved) — this is expected and not an error.
 */
async function notifyUser(userId, title, body) {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  const token = userDoc.data()?.fcmToken;
  if (!token) return;

  try {
    await admin.messaging().send({
      token,
      notification: { title, body },
    });
  } catch (err) {
    // A token can go stale (app uninstalled, etc.) — log and move on rather
    // than crashing the function.
    console.error(`Failed to send notification to user ${userId}:`, err);
  }
}

// Fires whenever a booking document is updated — e.g. when the admin taps
// Accept or Decline in the Manage Bookings screen.
exports.onBookingStatusChange = onDocumentUpdated("bookings/{bookingId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return; // no status change, nothing to notify

  const serviceName = after.serviceName || "your henna appointment";

  if (after.status === "confirmed") {
    await notifyUser(
      after.userId,
      "Booking Confirmed! 🎉",
      `Your ${serviceName} booking on ${after.date?.split("T")[0] || ""} has been confirmed.`
    );
  } else if (after.status === "cancelled") {
    await notifyUser(
      after.userId,
      "Booking Update",
      `Your ${serviceName} booking request was declined. Please try another slot.`
    );
  } else if (after.status === "completed") {
    await notifyUser(
      after.userId,
      "Hope you loved it! ✨",
      `Your ${serviceName} appointment is marked complete. Leave a review in the app!`
    );
  }
});

// Fires whenever an order document is updated — e.g. admin moves it from
// Placed -> Packed -> Shipped -> Delivered in the Cone Orders screen.
exports.onOrderStatusChange = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return;

  const statusMessages = {
    packed: "Your henna cone order has been packed and will ship soon.",
    shipped: "Your henna cone order is on its way!",
    delivered: "Your henna cone order has been delivered. Enjoy!",
    cancelled: "Your henna cone order was cancelled.",
  };

  const body = statusMessages[after.status];
  if (body) {
    await notifyUser(after.userId, "Order Update", body);
  }
});
