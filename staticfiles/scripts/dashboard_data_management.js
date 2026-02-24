(function () {
  const zone = document.getElementById("uploadZone");
  const fileInput = document.getElementById("fileInput");
  const preflight = document.getElementById("preflight");
  const btnUpload = document.getElementById("btnUpload");
  const processor = document.getElementById("processor");
  const procFill = document.getElementById("procFill");
  const procPct = document.getElementById("procPct");
  const procLabel = document.getElementById("procLabel");
  const logWindow = document.getElementById("logWindow");
  const auditSearch = document.getElementById("auditSearch");

  if (!zone || !fileInput || !btnUpload) return;

  let selectedFile = null;

  const appendLog = (text, cls = "log-info") => {
    const span = document.createElement("span");
    span.className = `${cls} log-line`;
    span.textContent = text;
    logWindow.appendChild(document.createElement("br"));
    logWindow.appendChild(span);
    logWindow.scrollTop = logWindow.scrollHeight;
  };

  const formatBytes = (bytes) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const getCookie = (name) => {
    let cookieValue = null;
    if (document.cookie && document.cookie !== "") {
      const cookies = document.cookie.split(";");
      for (let i = 0; i < cookies.length; i += 1) {
        const cookie = cookies[i].trim();
        if (cookie.substring(0, name.length + 1) === `${name}=`) {
          cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
          break;
        }
      }
    }
    return cookieValue;
  };

  const setProgress = (value, label) => {
    const clamped = Math.max(0, Math.min(100, value));
    procFill.style.width = `${clamped}%`;
    procPct.textContent = `${Math.round(clamped)}%`;
    procLabel.textContent = label;
  };

  const bindFile = (file) => {
    const isCsv = file.name.toLowerCase().endsWith(".csv");
    if (!isCsv) {
      appendLog("Only CSV files are accepted.", "log-warn");
      return;
    }
    selectedFile = file;
    document.getElementById("preflightFile").textContent = file.name;
    document.getElementById("metaName").textContent = file.name;
    document.getElementById("metaSize").textContent = formatBytes(file.size);
    document.getElementById("metaType").textContent = "text/csv";
    preflight.classList.add("visible");
    btnUpload.classList.add("visible");
  };

  zone.addEventListener("dragover", (event) => {
    event.preventDefault();
    zone.classList.add("dragover");
  });

  zone.addEventListener("dragleave", () => {
    zone.classList.remove("dragover");
  });

  zone.addEventListener("drop", (event) => {
    event.preventDefault();
    zone.classList.remove("dragover");
    const file = event.dataTransfer.files[0];
    if (file) bindFile(file);
  });

  fileInput.addEventListener("change", (event) => {
    const file = event.target.files[0];
    if (file) bindFile(file);
  });

  btnUpload.addEventListener("click", async () => {
    if (!selectedFile) {
      appendLog("Select a CSV file before upload.", "log-warn");
      return;
    }

    const uploadUrl = btnUpload.dataset.uploadUrl;
    if (!uploadUrl) {
      appendLog("Upload endpoint not configured.", "log-warn");
      return;
    }

    btnUpload.disabled = true;
    processor.classList.add("visible");
    setProgress(10, "Validating file...");
    appendLog("Upload started.");

    const formData = new FormData();
    formData.append("file", selectedFile);

    try {
      setProgress(35, "Sending file to backend...");
      const response = await fetch(uploadUrl, {
        method: "POST",
        headers: {
          "X-CSRFToken": getCookie("csrftoken") || "",
        },
        body: formData,
      });

      const payload = await response.json();
      if (!response.ok) {
        setProgress(100, "Upload failed");
        appendLog(payload.error || "Upload failed.", "log-warn");
        btnUpload.disabled = false;
        return;
      }

      setProgress(100, "Completed");
      appendLog(`Upload complete. Rows prepared: ${payload.rows_prepared || 0}`, "log-success");
      setTimeout(() => {
        window.location.reload();
      }, 700);
    } catch (_error) {
      setProgress(100, "Upload failed");
      appendLog("Upload failed due to network/server error.", "log-warn");
      btnUpload.disabled = false;
    }
  });

  auditSearch?.addEventListener("input", (event) => {
    const query = (event.target.value || "").toLowerCase();
    document.querySelectorAll("#auditTable tbody tr").forEach((row) => {
      const haystack = `${row.dataset.name || ""} ${row.textContent || ""}`.toLowerCase();
      row.style.display = haystack.includes(query) ? "" : "none";
    });
  });
})();
