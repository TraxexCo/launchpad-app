function removeSplashFromWeb() {
  document.getElementById("splash")?.remove();
  document.getElementById("splash-branding")?.remove();
  document.body.style.background = "transparent";
}

// Flutter's web engine currently rewrites this tag to disable browser zoom.
// Keep zoom available for users who rely on magnification and large text.
function keepViewportZoomable() {
  const viewport = document.querySelector('meta[name="viewport"]');
  const accessibleValue = "width=device-width, initial-scale=1.0";
  if (viewport && viewport.content !== accessibleValue) {
    viewport.content = accessibleValue;
  }
}

new MutationObserver(keepViewportZoomable).observe(document.head, {
  attributes: true,
  childList: true,
  subtree: true,
  attributeFilter: ["content"],
});
keepViewportZoomable();
