(() => {
  const $ = id => document.getElementById(id);
  const endpoint = "/wisprflowisdead/api/session";
  let checking = false;
  let signingOut = false;

  async function checkSession() {
    if (checking) return;
    checking = true;
    $("box").hidden = true;
    $("loading").hidden = false;
    $("loading").setAttribute("aria-busy", "true");
    $("retry").hidden = true;
    $("load-status").textContent = "Checking your session…";
    try {
      const response = await fetch(endpoint, {
        credentials: "same-origin", cache: "no-store", signal: AbortSignal.timeout(15000)
      });
      if (response.status === 401) {
        location.replace("/wisprflowisdead/login?next=/wisprflowisdead/app");
        return;
      }
      if (!response.ok) throw new Error("Session unavailable");
      const me = await response.json();
      if (!me || typeof me !== "object" || Array.isArray(me)) throw new Error("Invalid session");
      $("who").textContent = typeof me.email === "string" ? "Signed in as " + me.email + "." : "";
      if (typeof me.uid === "string") globalThis.isdeadAnalytics?.identify(me.uid);
      $("loading").hidden = true;
      $("box").hidden = false;
    } catch {
      $("load-status").textContent = "We couldn't check your session. Check your connection and try again.";
      $("retry").hidden = false;
    } finally {
      checking = false;
      $("loading").setAttribute("aria-busy", "false");
    }
  }

  $("out").onclick = async () => {
    if (signingOut) return;
    signingOut = true;
    $("out").disabled = true;
    $("out").textContent = "Signing out…";
    $("signout-status").textContent = "";
    try {
      const response = await fetch(endpoint, {
        method: "DELETE", credentials: "same-origin", signal: AbortSignal.timeout(15000)
      });
      if (!response.ok) throw new Error("Sign-out failed");
      const analytics = globalThis.isdeadAnalytics;
      if (analytics) { await analytics.trackNow("app_signed_out"); analytics.reset(); }
      $("box").hidden = true;
      location.replace("/wisprflowisdead");
    } catch {
      $("signout-status").textContent = "We couldn't sign you out. Your session may still be active. Please try again.";
    } finally {
      signingOut = false;
      $("out").disabled = false;
      $("out").textContent = "Sign out";
    }
  };
  $("retry").onclick = checkSession;
  addEventListener("pageshow", event => { if (event.persisted) checkSession(); });
  checkSession();
})();
