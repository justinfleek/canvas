// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//                                                // canvas // runtime // input
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// BROWSER BOUNDARY: Input runtime for Canvas stylus/touch handling
//
// This module provides FFI bindings for:
// - Haptic feedback (vibration)
// - Pointer event handlers for stylus input

// ═══════════════════════════════════════════════════════════════════════════════
//                                               // browser boundary // haptics
// ═══════════════════════════════════════════════════════════════════════════════

// Vibrate with pattern (array of durations in milliseconds)
export const vibratePattern = (pattern) => () => {
  if (navigator.vibrate) {
    navigator.vibrate(pattern);
  }
};

// Check if device supports haptics
export const supportsHapticsImpl = () => {
  return typeof navigator.vibrate === "function";
};

// Convert Int to Number
export const fromIntImpl = (n) => n;

// ═══════════════════════════════════════════════════════════════════════════════
//                                        // browser boundary // pointer events
// ═══════════════════════════════════════════════════════════════════════════════

// Extract full pointer input data from PointerEvent
const extractPointerInput = (e, rect) => ({
  pointerId: e.pointerId,
  pointerType: e.pointerType, // "mouse" | "pen" | "touch"
  x: rect ? e.clientX - rect.left : e.clientX,
  y: rect ? e.clientY - rect.top : e.clientY,
  pressure: e.pressure, // 0.0-1.0 (0.5 default for mouse)
  tiltX: e.tiltX || 0, // -90 to 90 degrees
  tiltY: e.tiltY || 0, // -90 to 90 degrees
  twist: e.twist || 0, // 0-359 degrees (barrel rotation)
  width: e.width || 1, // Contact geometry
  height: e.height || 1,
  isPrimary: e.isPrimary,
  buttons: e.buttons,
  clientX: e.clientX,
  clientY: e.clientY,
});

// Add pointer down listener
// Note: This version attaches to document for global capture
export const onPointerDownImpl = (selector) => (callback) => () => {
  const el = document.querySelector(selector);
  if (!el) {
    console.warn("onPointerDownImpl: element not found:", selector);
    return () => {};
  }
  const handler = (e) => {
    const rect = el.getBoundingClientRect();
    callback(extractPointerInput(e, rect))();
  };
  el.addEventListener("pointerdown", handler);
  return () => el.removeEventListener("pointerdown", handler);
};

// Add pointer move listener
export const onPointerMoveImpl = (selector) => (callback) => () => {
  const el = document.querySelector(selector);
  if (!el) {
    console.warn("onPointerMoveImpl: element not found:", selector);
    return () => {};
  }
  const handler = (e) => {
    const rect = el.getBoundingClientRect();
    callback(extractPointerInput(e, rect))();
  };
  el.addEventListener("pointermove", handler);
  return () => el.removeEventListener("pointermove", handler);
};

// Add pointer up listener (to window for reliable capture)
export const onPointerUpImpl = (callback) => () => {
  const handler = (e) => {
    callback(extractPointerInput(e, null))();
  };
  window.addEventListener("pointerup", handler);
  return () => window.removeEventListener("pointerup", handler);
};

// Add pointer cancel listener (to window)
export const onPointerCancelImpl = (callback) => () => {
  const handler = (e) => {
    callback(extractPointerInput(e, null))();
  };
  window.addEventListener("pointercancel", handler);
  return () => window.removeEventListener("pointercancel", handler);
};
