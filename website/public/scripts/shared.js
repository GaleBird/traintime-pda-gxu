const FALLBACK_DOWNLOADS = [
  { id: "arm64-v8a", label: "Android arm64", href: "/download/arm64-v8a" },
  { id: "armeabi-v7a", label: "Android 32-bit", href: "/download/armeabi-v7a" },
  { id: "x86_64", label: "Android x86_64", href: "/download/x86_64" },
];

const GALLERY_INTERVAL_MS = 3600;
const numberFormatter = new Intl.NumberFormat("zh-CN");
const SIGNATURE_COPY = {
  verified: {
    label: "已验签",
    message: "当前清单已通过服务端验签。",
  },
  disabled: {
    label: "未启用",
    message: "当前官网未启用清单验签。",
  },
  missing_signature: {
    label: "缺少签名",
    message: "公钥已配置，但线上清单缺少签名。",
  },
  unsupported_algorithm: {
    label: "算法不符",
    message: "线上清单使用了当前服务不支持的签名算法。",
  },
  key_id_mismatch: {
    label: "Key 不符",
    message: "线上清单 key_id 与当前服务配置不一致。",
  },
  invalid_signature: {
    label: "签名异常",
    message: "线上清单签名与当前公钥不匹配。",
  },
  verification_error: {
    label: "校验失败",
    message: "服务端执行验签时发生异常。",
  },
};

function setText(selector, value) {
  document.querySelectorAll(selector).forEach((element) => {
    element.textContent = value;
  });
}

function setLink(selector, href, label) {
  document.querySelectorAll(selector).forEach((element) => {
    element.href = href;
    if (label) {
      element.textContent = label;
    }
  });
}

function fetchJson(url) {
  return fetch(url, {
    headers: { Accept: "application/json" },
  }).then((response) => {
    if (!response.ok) {
      throw new Error(`${url} returned ${response.status}`);
    }
    return response.json();
  });
}

function renderDownloadMatrix(downloads) {
  const items = downloads.length > 0 ? downloads : FALLBACK_DOWNLOADS;
  const html = items.map((item) => `<a href="${item.href}">${item.label}</a>`).join("");
  document.querySelectorAll("[data-site-download-matrix]").forEach((element) => {
    element.innerHTML = html;
  });
}

function renderNotes(notes) {
  const items = notes.length > 0 ? notes : ["当前发布未附带额外更新说明。"];
  const html = items.map((item) => `<li>${item}</li>`).join("");
  document.querySelectorAll("[data-site-release-notes]").forEach((element) => {
    element.innerHTML = html;
  });
  setText("[data-site-note-count]", `${notes.length}`);
}

function renderUpdate(update) {
  setText("[data-site-version]", update.version);
  setText("[data-site-summary]", update.summary);
  setText("[data-site-release-label]", update.releaseLabel);
  setLink("[data-site-release-link]", update.releaseUrl, update.releaseLabel);
  setLink("[data-site-github-link]", "/download/github", "GitHub 备用下载");
  renderNotes(update.notes);
  renderDownloadMatrix(update.downloads);
  renderSignature(update.signature);
}

function renderStats(stats) {
  setText("[data-site-download-total]", numberFormatter.format(stats.totalDownloads));
}

function renderSignature(signature) {
  const status = signature?.status ?? "disabled";
  const copy = SIGNATURE_COPY[status] ?? {
    label: "状态未知",
    message: signature?.message || "当前清单验签状态未知。",
  };

  document.querySelectorAll("[data-site-signature-status]").forEach((element) => {
    element.textContent = copy.label;
    element.dataset.signatureState = status;
  });

  setText(
    "[data-site-signature-message]",
    signature?.message || copy.message,
  );
}

function markCurrentNav() {
  const currentPage = document.body.dataset.page;
  document.querySelectorAll("[data-nav-link]").forEach((element) => {
    if (element.dataset.navLink === currentPage) {
      element.classList.add("is-current");
      element.setAttribute("aria-current", "page");
    }
  });
}

function setupRevealObserver() {
  const items = document.querySelectorAll(".reveal");
  if (!("IntersectionObserver" in window)) {
    items.forEach((element) => {
      element.dataset.visible = "true";
    });
    return;
  }
  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.dataset.visible = "true";
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });
  items.forEach((element) => observer.observe(element));
}

function setupGallery() {
  document.querySelectorAll("[data-gallery]").forEach((gallery) => {
    const track = gallery.querySelector("[data-gallery-track]");
    const slides = Array.from(gallery.querySelectorAll(".gallery-shot"));
    const dots = Array.from(gallery.querySelectorAll(".gallery-dot"));

    if (!track || slides.length === 0 || slides.length !== dots.length) {
      throw new Error("Gallery markup is incomplete");
    }

    let currentIndex = 0;
    let timerId = 0;

    const render = (nextIndex) => {
      currentIndex = (nextIndex + slides.length) % slides.length;
      track.style.transform = `translateX(-${currentIndex * 100}%)`;
      slides.forEach((slide, index) => {
        slide.classList.toggle("is-active", index === currentIndex);
      });
      dots.forEach((dot, index) => {
        dot.classList.toggle("is-active", index === currentIndex);
        dot.setAttribute("aria-current", index === currentIndex ? "true" : "false");
      });
    };

    const stopTimer = () => {
      if (timerId) {
        window.clearInterval(timerId);
        timerId = 0;
      }
    };

    const startTimer = () => {
      stopTimer();
      timerId = window.setInterval(() => {
        render(currentIndex + 1);
      }, GALLERY_INTERVAL_MS);
    };

    dots.forEach((dot, index) => {
      dot.addEventListener("click", () => {
        render(index);
        startTimer();
      });
    });

    gallery.addEventListener("mouseenter", stopTimer);
    gallery.addEventListener("mouseleave", startTimer);
    gallery.addEventListener("focusin", stopTimer);
    gallery.addEventListener("focusout", startTimer);

    render(0);
    startTimer();
  });
}

function renderFailureState() {
  setText("[data-site-version]", "暂不可用");
  setText("[data-site-summary]", "线上清单暂时不可达，但备用下载入口仍可使用。");
  setText("[data-site-note-count]", "--");
  setText("[data-site-download-total]", "--");
  setText("[data-site-release-label]", "备用下载");
  setLink("[data-site-release-link]", "/download/github", "备用下载");
  renderDownloadMatrix([]);
  renderNotes([]);
  renderSignature({
    status: "verification_error",
    message: "当前无法读取线上清单，暂时无法判断签名状态。",
  });
}

function loadSiteData() {
  return Promise.all([fetchJson("/api/update"), fetchJson("/api/stats")]).then(([update, stats]) => {
    renderUpdate(update);
    renderStats(stats);
  });
}

function initSite() {
  document.body.classList.add("is-ready");
  markCurrentNav();
  setupRevealObserver();
  setupGallery();
  loadSiteData().catch((error) => {
    console.error(error);
    renderFailureState();
  });
}

window.addEventListener("DOMContentLoaded", initSite);
