// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//                                                  // canvas // runtime // dom
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// BROWSER BOUNDARY: DOM runtime for Hydrogen Canvas app
//
// This module provides FFI bindings for:
// - Mounting the app to a DOM element
// - Animation frame loop
// - Event subscription wiring
// - Element rendering to DOM

// ═══════════════════════════════════════════════════════════════════════════════
//                                                    // browser boundary // mount
// ═══════════════════════════════════════════════════════════════════════════════

// Select DOM element by selector
export const selectElementImpl = (selector) => () => {
  const el = document.querySelector(selector);
  return el || null;
};

// Create text node
export const createTextNode = (text) => () => {
  return document.createTextNode(text);
};

// Create element with tag name
export const createElement = (tagName) => () => {
  return document.createElement(tagName);
};

// Create SVG element with tag name
export const createSvgElement = (tagName) => () => {
  return document.createElementNS("http://www.w3.org/2000/svg", tagName);
};

// Set attribute on element
export const setAttribute = (el) => (name) => (value) => () => {
  el.setAttribute(name, value);
};

// Set property on element
export const setProperty = (el) => (name) => (value) => () => {
  el[name] = value;
};

// Append child to parent
export const appendChild = (parent) => (child) => () => {
  parent.appendChild(child);
};

// Clear all children from element
export const clearChildren = (el) => () => {
  el.innerHTML = "";
};

// Set innerHTML (for rendered HTML string)
export const setInnerHTML = (el) => (html) => () => {
  el.innerHTML = html;
};

// ═══════════════════════════════════════════════════════════════════════════════
//                                            // browser boundary // animation loop
// ═══════════════════════════════════════════════════════════════════════════════

// Request animation frame - returns cancel function
export const requestAnimationFrameImpl = (callback) => () => {
  let lastTime = performance.now();
  let rafId = null;
  let running = true;

  const loop = (currentTime) => {
    if (!running) return;
    const deltaTime = currentTime - lastTime;
    lastTime = currentTime;
    callback(deltaTime)();
    rafId = requestAnimationFrame(loop);
  };

  rafId = requestAnimationFrame(loop);

  // Return cancel function
  return () => {
    running = false;
    if (rafId !== null) {
      cancelAnimationFrame(rafId);
    }
  };
};

// ═══════════════════════════════════════════════════════════════════════════════
//                                           // browser boundary // event listeners
// ═══════════════════════════════════════════════════════════════════════════════

// Add mouse move listener to window
export const addMouseMoveListenerImpl = (callback) => () => {
  const handler = (e) => {
    callback({ x: e.clientX, y: e.clientY })();
  };
  window.addEventListener("mousemove", handler);
  return () => window.removeEventListener("mousemove", handler);
};

// Add mouse down listener to element
export const addMouseDownListenerImpl = (el) => (callback) => () => {
  const handler = (e) => {
    const rect = el.getBoundingClientRect();
    callback({
      x: e.clientX - rect.left,
      y: e.clientY - rect.top,
      button: e.button,
      buttons: e.buttons,
      clientX: e.clientX,
      clientY: e.clientY,
    })();
  };
  el.addEventListener("mousedown", handler);
  return () => el.removeEventListener("mousedown", handler);
};

// Add mouse up listener to window
export const addMouseUpListenerImpl = (callback) => () => {
  const handler = (e) => {
    callback({
      x: e.clientX,
      y: e.clientY,
      button: e.button,
      buttons: e.buttons,
      clientX: e.clientX,
      clientY: e.clientY,
    })();
  };
  window.addEventListener("mouseup", handler);
  return () => window.removeEventListener("mouseup", handler);
};

// Add touch start listener
export const addTouchStartListenerImpl = (el) => (callback) => () => {
  const handler = (e) => {
    const rect = el.getBoundingClientRect();
    const touches = Array.from(e.touches).map((t) => ({
      identifier: t.identifier,
      x: t.clientX - rect.left,
      y: t.clientY - rect.top,
      clientX: t.clientX,
      clientY: t.clientY,
      force: t.force || 0,
      radiusX: t.radiusX || 0,
      radiusY: t.radiusY || 0,
    }));
    const changedTouches = Array.from(e.changedTouches).map((t) => ({
      identifier: t.identifier,
      x: t.clientX - rect.left,
      y: t.clientY - rect.top,
      clientX: t.clientX,
      clientY: t.clientY,
      force: t.force || 0,
      radiusX: t.radiusX || 0,
      radiusY: t.radiusY || 0,
    }));
    const targetTouches = Array.from(e.targetTouches).map((t) => ({
      identifier: t.identifier,
      x: t.clientX - rect.left,
      y: t.clientY - rect.top,
      clientX: t.clientX,
      clientY: t.clientY,
      force: t.force || 0,
      radiusX: t.radiusX || 0,
      radiusY: t.radiusY || 0,
    }));
    callback({ touches, changedTouches, targetTouches })();
  };
  el.addEventListener("touchstart", handler, { passive: true });
  return () => el.removeEventListener("touchstart", handler);
};

// Add touch move listener
export const addTouchMoveListenerImpl = (el) => (callback) => () => {
  const handler = (e) => {
    e.preventDefault(); // Prevent scrolling while painting
    const rect = el.getBoundingClientRect();
    const touches = Array.from(e.touches).map((t) => ({
      identifier: t.identifier,
      x: t.clientX - rect.left,
      y: t.clientY - rect.top,
      clientX: t.clientX,
      clientY: t.clientY,
      force: t.force || 0,
      radiusX: t.radiusX || 0,
      radiusY: t.radiusY || 0,
    }));
    const changedTouches = Array.from(e.changedTouches).map((t) => ({
      identifier: t.identifier,
      x: t.clientX - rect.left,
      y: t.clientY - rect.top,
      clientX: t.clientX,
      clientY: t.clientY,
      force: t.force || 0,
      radiusX: t.radiusX || 0,
      radiusY: t.radiusY || 0,
    }));
    const targetTouches = Array.from(e.targetTouches).map((t) => ({
      identifier: t.identifier,
      x: t.clientX - rect.left,
      y: t.clientY - rect.top,
      clientX: t.clientX,
      clientY: t.clientY,
      force: t.force || 0,
      radiusX: t.radiusX || 0,
      radiusY: t.radiusY || 0,
    }));
    callback({ touches, changedTouches, targetTouches })();
  };
  el.addEventListener("touchmove", handler, { passive: false });
  return () => el.removeEventListener("touchmove", handler);
};

// Add touch end listener
export const addTouchEndListenerImpl = (el) => (callback) => () => {
  const handler = (e) => {
    const rect = el.getBoundingClientRect();
    const touches = Array.from(e.touches).map((t) => ({
      identifier: t.identifier,
      x: t.clientX - rect.left,
      y: t.clientY - rect.top,
      clientX: t.clientX,
      clientY: t.clientY,
      force: t.force || 0,
      radiusX: t.radiusX || 0,
      radiusY: t.radiusY || 0,
    }));
    const changedTouches = Array.from(e.changedTouches).map((t) => ({
      identifier: t.identifier,
      x: t.clientX - rect.left,
      y: t.clientY - rect.top,
      clientX: t.clientX,
      clientY: t.clientY,
      force: t.force || 0,
      radiusX: t.radiusX || 0,
      radiusY: t.radiusY || 0,
    }));
    const targetTouches = Array.from(e.targetTouches).map((t) => ({
      identifier: t.identifier,
      x: t.clientX - rect.left,
      y: t.clientY - rect.top,
      clientX: t.clientX,
      clientY: t.clientY,
      force: t.force || 0,
      radiusX: t.radiusX || 0,
      radiusY: t.radiusY || 0,
    }));
    callback({ touches, changedTouches, targetTouches })();
  };
  el.addEventListener("touchend", handler);
  return () => el.removeEventListener("touchend", handler);
};

// Add device orientation listener
// Listens to both real device orientation AND virtual orientation events
export const addDeviceOrientationListenerImpl = (callback) => () => {
  const handler = (e) => {
    callback({
      alpha: e.alpha || 0,
      beta: e.beta || 0,
      gamma: e.gamma || 0,
      absolute: e.absolute || false,
    })();
  };
  
  // Handle virtual orientation from the roller ball controller
  const virtualHandler = (e) => {
    callback({
      alpha: e.detail.alpha || 0,
      beta: e.detail.beta || 0,
      gamma: e.detail.gamma || 0,
      absolute: e.detail.absolute || false,
    })();
  };
  
  window.addEventListener("deviceorientation", handler);
  window.addEventListener("virtualorientation", virtualHandler);
  
  return () => {
    window.removeEventListener("deviceorientation", handler);
    window.removeEventListener("virtualorientation", virtualHandler);
  };
};

// ═══════════════════════════════════════════════════════════════════════════════
//                                        // browser boundary // pointer events
// ═══════════════════════════════════════════════════════════════════════════════

// PointerEvent provides unified input for mouse, touch, and stylus with full
// pressure/tilt data. This is the preferred API for professional art tools.

// Extract full pointer input data from PointerEvent
const extractPointerInput = (e, rect) => ({
  pointerId: e.pointerId,
  pointerType: e.pointerType,  // "mouse" | "pen" | "touch"
  x: rect ? e.clientX - rect.left : e.clientX,
  y: rect ? e.clientY - rect.top : e.clientY,
  pressure: e.pressure,        // 0.0-1.0 (0.5 default for mouse)
  tiltX: e.tiltX || 0,         // -90 to 90 degrees
  tiltY: e.tiltY || 0,         // -90 to 90 degrees
  twist: e.twist || 0,         // 0-359 degrees (barrel rotation)
  width: e.width || 1,         // Contact geometry
  height: e.height || 1,
  isPrimary: e.isPrimary,
  buttons: e.buttons,
  clientX: e.clientX,
  clientY: e.clientY,
});

// Add pointer down listener to element (stylus/touch/mouse down)
export const addPointerDownListenerImpl = (el) => (callback) => () => {
  const handler = (e) => {
    const rect = el.getBoundingClientRect();
    callback(extractPointerInput(e, rect))();
  };
  el.addEventListener("pointerdown", handler);
  return () => el.removeEventListener("pointerdown", handler);
};

// Add pointer move listener to element (stylus/touch/mouse move)
export const addPointerMoveListenerImpl = (el) => (callback) => () => {
  const handler = (e) => {
    const rect = el.getBoundingClientRect();
    callback(extractPointerInput(e, rect))();
  };
  el.addEventListener("pointermove", handler);
  return () => el.removeEventListener("pointermove", handler);
};

// Add pointer up listener to window (stylus/touch/mouse up)
export const addPointerUpListenerImpl = (callback) => () => {
  const handler = (e) => {
    callback(extractPointerInput(e, null))();
  };
  window.addEventListener("pointerup", handler);
  return () => window.removeEventListener("pointerup", handler);
};

// Add pointer cancel listener to window (interrupted input)
export const addPointerCancelListenerImpl = (callback) => () => {
  const handler = (e) => {
    callback(extractPointerInput(e, null))();
  };
  window.addEventListener("pointercancel", handler);
  return () => window.removeEventListener("pointercancel", handler);
};

// Coalesce pointer events for high-frequency stylus input
// Returns array of all coalesced events since last frame
export const addCoalescedPointerMoveListenerImpl = (el) => (callback) => () => {
  const handler = (e) => {
    const rect = el.getBoundingClientRect();
    // getCoalescedEvents() returns all events since last frame
    // This is crucial for smooth stylus input at high sample rates
    const events = e.getCoalescedEvents ? e.getCoalescedEvents() : [e];
    const inputs = events.map((ev) => extractPointerInput(ev, rect));
    callback(inputs)();
  };
  el.addEventListener("pointermove", handler);
  return () => el.removeEventListener("pointermove", handler);
};

// ═══════════════════════════════════════════════════════════════════════════════
//                                               // browser boundary // ref system
// ═══════════════════════════════════════════════════════════════════════════════

// Create mutable ref
export const newRef = (initial) => () => {
  return { value: initial };
};

// Read ref
export const readRef = (ref) => () => {
  return ref.value;
};

// Write ref
export const writeRef = (ref) => (value) => () => {
  ref.value = value;
};

// Modify ref
export const modifyRef = (ref) => (f) => () => {
  ref.value = f(ref.value);
};

// ═══════════════════════════════════════════════════════════════════════════════
//                                               // browser boundary // unsafe ops
// ═══════════════════════════════════════════════════════════════════════════════

// UNSAFE: Coerce a number to a Tick message
// This assumes the app's Msg type has a Tick constructor that takes Number
// In production, we'd have proper message routing
export const unsafeCoerceTick = (deltaTime) => {
  // Return an object that matches the Tick constructor structure
  // PureScript ADTs are represented as { tag: "ConstructorName", _1: arg1, ... }
  return { tag: "Tick", _1: deltaTime };
};

// Set GPU backend status text in the UI
export const setGPUStatusTextImpl = (text) => () => {
  const el = document.getElementById("gpu-backend");
  if (el) {
    el.textContent = text;
  }
};
