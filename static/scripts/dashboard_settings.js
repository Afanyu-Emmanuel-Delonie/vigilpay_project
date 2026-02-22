(function () {
  function byId(id) {
    return document.getElementById(id);
  }

  function openModal(id) {
    const el = byId(id);
    if (!el) return;
    el.classList.add("open");
    document.body.style.overflow = "hidden";
  }

  function closeModal(id) {
    const el = byId(id);
    if (!el) return;
    el.classList.remove("open");
    document.body.style.overflow = "";
  }

  function closeIfBackdrop(event, id) {
    const el = byId(id);
    if (el && event.target === el) closeModal(id);
  }

  function checkClearConfirm() {
    const input = byId("clearConfirmInput");
    const btn = byId("clearConfirmBtn");
    if (!input || !btn) return;
    const ready = input.value === "DELETE";
    btn.disabled = !ready;
    btn.classList.toggle("ready", ready);
  }

  function openClearModal() {
    const input = byId("clearConfirmInput");
    if (input) input.value = "";
    checkClearConfirm();
    openModal("clearModal");
  }

  function executeClear() {
    const form = byId("clearDatasetForm");
    if (!form) return;
    closeModal("clearModal");
    form.submit();
  }

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeModal("clearModal");
  });

  window.openModal = openModal;
  window.closeModal = closeModal;
  window.closeIfBackdrop = closeIfBackdrop;
  window.checkClearConfirm = checkClearConfirm;
  window.openClearModal = openClearModal;
  window.executeClear = executeClear;
})();
