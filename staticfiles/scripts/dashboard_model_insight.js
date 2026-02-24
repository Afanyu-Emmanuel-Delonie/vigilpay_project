(function () {
  if (typeof Chart === "undefined") return;

  Chart.defaults.font.family = "'Poppins', system-ui, sans-serif";
  Chart.defaults.font.size = 11;
  Chart.defaults.color = "#aaa";
  Chart.defaults.plugins.legend.display = false;

  const RED = "#8C1515";
  const GOLD = "#C9A84C";

  let insightData = null;
  const dataNode = document.getElementById("model-insight-data");
  if (dataNode) {
    try {
      insightData = JSON.parse(dataNode.textContent);
    } catch (_e) {
      insightData = null;
    }
  }

  const donutLabels = insightData?.donut?.labels || [];
  const donutValues = insightData?.donut?.values || [];
  const scatterHigh = insightData?.scatter?.high || [];
  const scatterRetained = insightData?.scatter?.retained || [];

  // Feature importance bar animation
  const fiList = document.getElementById("fiList");
  if (fiList) {
    const io = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          document.querySelectorAll(".fi-fill[data-w]").forEach((bar) => {
            bar.style.width = `${bar.dataset.w}%`;
          });
          io.disconnect();
        }
      },
      { threshold: 0.2 },
    );
    io.observe(fiList);
  }

  const donutCanvas = document.getElementById("chartDonut");
  if (donutCanvas) {
    new Chart(donutCanvas, {
      type: "doughnut",
      data: {
        labels: donutLabels,
        datasets: [
          {
            data: donutValues,
            backgroundColor: [RED, GOLD, "#374151", "#0f766e", "#7c3aed", "#2563eb"],
            borderColor: "#fff",
            borderWidth: 3,
            hoverOffset: 7,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: "70%",
        plugins: {
          legend: {
            display: true,
            position: "bottom",
            labels: { boxWidth: 10, boxHeight: 10, borderRadius: 3, padding: 16, font: { weight: "600" } },
          },
          tooltip: {
            callbacks: {
              label: (ctx) => ` ${ctx.label}: ${ctx.parsed}% of at-risk customers`,
            },
          },
        },
      },
    });
  }

  const scatterCanvas = document.getElementById("chartScatter");
  if (scatterCanvas) {
    new Chart(scatterCanvas, {
      type: "scatter",
      data: {
        datasets: [
          { label: "High Risk", data: scatterHigh, backgroundColor: "rgba(140,21,21,0.6)", pointRadius: 4, pointHoverRadius: 7 },
          { label: "Retained", data: scatterRetained, backgroundColor: "rgba(196,187,176,0.45)", pointRadius: 3, pointHoverRadius: 5 },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: {
            title: { display: true, text: "Customer Age", font: { weight: "700", size: 11 }, color: "#bbb" },
            grid: { color: "#f0ece7" },
            border: { display: false },
          },
          y: {
            title: { display: true, text: "Account Balance ($)", font: { weight: "700", size: 11 }, color: "#bbb" },
            grid: { color: "#f0ece7" },
            border: { display: false },
            ticks: { callback: (v) => `$${(v / 1000).toFixed(0)}k` },
          },
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: (ctx) => ` ${ctx.dataset.label} - Age ${ctx.parsed.x}, Balance $${ctx.parsed.y.toLocaleString()}`,
            },
          },
        },
      },
    });
  }
})();

function runSim() {
  const credit = +document.getElementById("slCredit").value;
  const balance = +document.getElementById("slBalance").value;
  const age = +document.getElementById("slAge").value;
  const prods = +document.getElementById("slProds").value;

  document.getElementById("lblCredit").textContent = credit;
  document.getElementById("lblBalance").textContent = `$${balance.toLocaleString()}`;
  document.getElementById("lblAge").textContent = age;
  document.getElementById("lblProds").textContent = prods;

  let risk = 52;
  risk += ((850 - credit) / 850) * 24;
  risk -= Math.min((balance / 200000) * 20, 20);
  if (age > 45 || age < 27) risk += 10;
  risk -= (prods - 1) * 12;
  risk = Math.max(4, Math.min(97, Math.round(risk)));

  const circ = 339.29;
  const offset = circ - (risk / 100) * circ;
  const fill = document.getElementById("gFill");
  fill.style.strokeDashoffset = offset;
  fill.style.stroke = risk >= 70 ? "#8C1515" : risk >= 40 ? "#C9A84C" : "#059669";
  document.getElementById("gPct").textContent = `${risk}%`;

  const verdict = document.getElementById("gVerdict");
  const action = document.getElementById("simAction");
  if (risk >= 70) {
    verdict.textContent = "High";
    verdict.style.color = "#f87171";
    action.textContent = "Initiate immediate phone outreach with a tailored retention offer.";
  } else if (risk >= 40) {
    verdict.textContent = "Medium";
    verdict.style.color = "#fbbf24";
    action.textContent = "Schedule a product upgrade outreach within 14 days.";
  } else {
    verdict.textContent = "Low";
    verdict.style.color = "#34d399";
    action.textContent = "No action required. Redirect retention budget to higher-risk segments.";
  }
}

runSim();
