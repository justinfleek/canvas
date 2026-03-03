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

// ═══════════════════════════════════════════════════════════════════════════════
//                                                // browser boundary // haptics
// ═══════════════════════════════════════════════════════════════════════════════

// Trigger haptic feedback if supported
const triggerHaptic = (pattern) => {
  if (navigator.vibrate) {
    navigator.vibrate(pattern);
  }
};

// Haptic patterns for paint interactions (in milliseconds)
const HAPTIC_PAINT_DAB = [15];
const HAPTIC_PAINT_STROKE = [5, 10, 5];
const HAPTIC_PAINT_RELEASE = [10];
const HAPTIC_CANVAS_TEXTURE = [3, 5, 3];

// Add pointer down listener to element (stylus/touch/mouse down)
// Triggers haptic feedback for paint dab
export const addPointerDownListenerImpl = (el) => (callback) => () => {
  const handler = (e) => {
    const rect = el.getBoundingClientRect();
    const input = extractPointerInput(e, rect);
    
    // Trigger haptic feedback for paint dab (scaled by pressure)
    const pressure = input.pressure || 0.5;
    const duration = Math.round(15 * (0.5 + pressure));
    triggerHaptic([duration]);
    
    callback(input)();
  };
  el.addEventListener("pointerdown", handler);
  return () => el.removeEventListener("pointerdown", handler);
};

// Track last haptic time to avoid excessive vibrations during move
let lastHapticTime = 0;
const HAPTIC_THROTTLE_MS = 50;

// Add pointer move listener to element (stylus/touch/mouse move)
// Triggers subtle haptic feedback for canvas texture feel
export const addPointerMoveListenerImpl = (el) => (callback) => () => {
  const handler = (e) => {
    const rect = el.getBoundingClientRect();
    const input = extractPointerInput(e, rect);
    
    // Throttled haptic feedback for painting motion (canvas texture feel)
    const now = performance.now();
    if (e.buttons > 0 && now - lastHapticTime > HAPTIC_THROTTLE_MS) {
      // Subtle texture feedback while painting
      triggerHaptic([3]);
      lastHapticTime = now;
    }
    
    callback(input)();
  };
  el.addEventListener("pointermove", handler);
  return () => el.removeEventListener("pointermove", handler);
};

// Add pointer up listener to window (stylus/touch/mouse up)
// Triggers haptic feedback for stroke completion
export const addPointerUpListenerImpl = (callback) => () => {
  const handler = (e) => {
    // Light haptic for stroke end
    triggerHaptic([10]);
    
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
//                                                    // browser boundary // ui ops
// ═══════════════════════════════════════════════════════════════════════════════

// Set GPU backend status text in the UI
export const setGPUStatusTextImpl = (text) => () => {
  const el = document.getElementById("gpu-backend");
  if (el) {
    el.textContent = text;
  }
};

// Global unmount function for cleanup/hot reload
// Call window.__canvasUnmount() to stop the animation loop
export const setGlobalUnmountImpl = (unmountFn) => () => {
  window.__canvasUnmount = () => {
    console.log("Canvas: Unmounting...");
    unmountFn();
    console.log("Canvas: Animation loop stopped");
  };
};

// ═══════════════════════════════════════════════════════════════════════════════
//                                      // browser boundary // keyboard shortcuts
// ═══════════════════════════════════════════════════════════════════════════════

// Keyboard shortcut handler callback (set by PureScript)
let keyboardShortcutCallback = null;

// Add keyboard shortcut listener with full modifier support
export const addKeyboardShortcutListenerImpl = (callback) => () => {
  keyboardShortcutCallback = callback;
  
  const handler = (e) => {
    // Build shortcut object with modifiers
    const shortcut = {
      key: e.key,
      ctrlKey: e.ctrlKey || e.metaKey,  // Handle both Ctrl and Cmd (macOS)
      shiftKey: e.shiftKey,
      altKey: e.altKey,
    };
    
    // Prevent default for common shortcuts we handle
    if (shortcut.ctrlKey) {
      const key = e.key.toLowerCase();
      if (key === "z" || key === "y" || key === "s" || key === "e") {
        e.preventDefault();
      }
    }
    
    callback(shortcut)();
  };
  
  document.addEventListener("keydown", handler);
  
  return () => {
    document.removeEventListener("keydown", handler);
    keyboardShortcutCallback = null;
  };
};

// ═══════════════════════════════════════════════════════════════════════════════
//                                                // browser boundary // canvas export
// ═══════════════════════════════════════════════════════════════════════════════

// Export canvas as PNG and trigger download
export const exportCanvasPNGImpl = (canvasId) => () => {
  const canvas = document.getElementById(canvasId);
  if (!canvas) {
    console.error("Canvas not found:", canvasId);
    return;
  }
  
  try {
    const dataURL = canvas.toDataURL("image/png");
    const link = document.createElement("a");
    link.download = "canvas-export.png";
    link.href = dataURL;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    console.log("Canvas exported as PNG");
  } catch (err) {
    console.error("Failed to export canvas as PNG:", err);
  }
};

// Export canvas as SVG (renders SVG fallback layer)
export const exportCanvasSVGImpl = (svgId) => () => {
  const svg = document.getElementById(svgId);
  if (!svg) {
    console.error("SVG element not found:", svgId);
    return;
  }
  
  try {
    // Clone the SVG and make it visible for export
    const svgClone = svg.cloneNode(true);
    svgClone.style.display = "block";
    
    // Serialize to string
    const serializer = new XMLSerializer();
    const svgString = serializer.serializeToString(svgClone);
    
    // Create download
    const blob = new Blob([svgString], { type: "image/svg+xml" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.download = "canvas-export.svg";
    link.href = url;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
    console.log("Canvas exported as SVG");
  } catch (err) {
    console.error("Failed to export canvas as SVG:", err);
  }
};

// ═══════════════════════════════════════════════════════════════════════════════
//                                          // browser boundary // canvas texture
// ═══════════════════════════════════════════════════════════════════════════════

// Generate procedural linen/cloth canvas texture.
// This creates a realistic canvas surface that looks like real artist canvas.
// The texture is generated once and cached as a pattern for efficient rendering.

let canvasTexturePattern = null;

// Generate the linen texture pattern
const generateLinenTexture = (width, height) => {
  const offscreen = document.createElement("canvas");
  offscreen.width = width;
  offscreen.height = height;
  const ctx = offscreen.getContext("2d");
  
  // Base canvas color (warm off-white like real linen)
  ctx.fillStyle = "#f5f0e6";
  ctx.fillRect(0, 0, width, height);
  
  // Linen weave pattern - horizontal threads
  ctx.strokeStyle = "rgba(200, 190, 170, 0.3)";
  ctx.lineWidth = 1;
  for (let y = 0; y < height; y += 3) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    // Slight wave for natural look
    for (let x = 0; x < width; x += 4) {
      const offset = Math.sin(x * 0.1 + y * 0.05) * 0.5;
      ctx.lineTo(x, y + offset);
    }
    ctx.stroke();
  }
  
  // Vertical threads (cross-weave)
  ctx.strokeStyle = "rgba(180, 170, 150, 0.25)";
  for (let x = 0; x < width; x += 3) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    for (let y = 0; y < height; y += 4) {
      const offset = Math.sin(y * 0.1 + x * 0.05) * 0.5;
      ctx.lineTo(x + offset, y);
    }
    ctx.stroke();
  }
  
  // Add subtle noise for natural texture variation
  const imageData = ctx.getImageData(0, 0, width, height);
  const data = imageData.data;
  for (let i = 0; i < data.length; i += 4) {
    // Small random variation in brightness
    const noise = (Math.random() - 0.5) * 8;
    data[i] = Math.min(255, Math.max(0, data[i] + noise));     // R
    data[i + 1] = Math.min(255, Math.max(0, data[i + 1] + noise)); // G
    data[i + 2] = Math.min(255, Math.max(0, data[i + 2] + noise)); // B
  }
  ctx.putImageData(imageData, 0, 0);
  
  return offscreen;
};

// Initialize canvas texture and apply it to the paint canvas
export const initCanvasTextureImpl = (canvasId) => () => {
  const canvas = document.getElementById(canvasId);
  if (!canvas) {
    console.warn("Canvas texture: element not found:", canvasId);
    return;
  }
  
  console.log("Canvas texture: Generating linen texture...");
  
  // Generate a tileable 128x128 texture
  const textureSize = 128;
  const textureCanvas = generateLinenTexture(textureSize, textureSize);
  
  // Create a pattern from the texture
  const ctx = canvas.getContext("2d");
  if (ctx) {
    canvasTexturePattern = ctx.createPattern(textureCanvas, "repeat");
    console.log("Canvas texture: Linen texture initialized");
  }
};

// Render the canvas texture background
export const renderCanvasTextureImpl = (canvasId) => () => {
  const canvas = document.getElementById(canvasId);
  if (!canvas || !canvasTexturePattern) {
    return;
  }
  
  const ctx = canvas.getContext("2d");
  if (!ctx) return;
  
  // Fill with linen texture pattern
  ctx.fillStyle = canvasTexturePattern;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
};

// Get whether canvas texture is initialized
export const hasCanvasTextureImpl = () => {
  return canvasTexturePattern !== null;
};
