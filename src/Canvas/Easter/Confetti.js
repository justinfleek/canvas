// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//                                              // canvas // easter // confetti
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Unsafe array index - assumes bounds already checked
export const unsafeIndex = (idx) => (arr) => {
  if (idx >= 0 && idx < arr.length) {
    return { tag: "Just", _1: arr[idx] };
  }
  return { tag: "Nothing" };
};
