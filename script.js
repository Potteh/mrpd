const RESOURCE_NAME = typeof GetParentResourceName === "function" ? GetParentResourceName() : "reaper_elevator";

const app = document.getElementById("app");
const floorList = document.getElementById("floorList");
const closeBtn = document.getElementById("closeBtn");
const statusText = document.getElementById("statusText");
const statusDot = document.getElementById("statusDot");
const panelKicker = document.getElementById("panelKicker");
const panelTitle = document.getElementById("panelTitle");
const panelSubtitle = document.getElementById("panelSubtitle");

let isOpen = false;
let closeTimer = null;
let isMoving = false;
let uiText = {
  kicker: "Vinewood Avenue",
  subtitleSelect: "Select destination floor",
  subtitleCurrentPrefix: "Current floor:",
  statusMoving: "Moving..."
};

const defaultFloors = [
  { id: "lobby", code: "L1", label: "Lobby", description: "Main entrance", current: true },
  { id: "parking", code: "P", label: "Parking", description: "Underground garage", current: false }
];

function sanitizeFloors(floors) {
  if (!Array.isArray(floors) || floors.length === 0) return defaultFloors;

  return floors.map((floor, index) => ({
    id: String(floor?.id ?? `floor_${index + 1}`),
    code: String(floor?.code ?? floor?.id ?? index + 1),
    label: String(floor?.label ?? `Floor ${index + 1}`),
    description: String(floor?.description ?? "No description"),
    featured: Boolean(floor?.featured),
    locked: Boolean(floor?.locked),
    current: Boolean(floor?.current)
  }));
}

function setStatusMoving(moving) {
  isMoving = moving;
  if (moving) {
    if (statusText) statusText.textContent = uiText.statusMoving || "Moving...";
    if (statusDot) statusDot.classList.add("is-moving");
  } else {
    if (statusText) statusText.textContent = "";
    if (statusDot) statusDot.classList.remove("is-moving");
  }
}

function renderFloors(floors) {
  floorList.innerHTML = "";

  floors.forEach((floor) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = `floor-btn${floor.current ? " is-current" : ""}`;
    if (floor.locked) {
      button.classList.add("is-locked");
      button.disabled = true;
      button.setAttribute("aria-disabled", "true");
      button.tabIndex = -1;
    }
    if (floor.featured) {
      button.classList.add("is-single");
    }
    button.dataset.floorId = floor.id;

    button.innerHTML = `
      <span class="floor-meta">
        <span class="floor-id">${floor.code}</span>
      </span>
      <span class="floor-main">
        <span class="floor-label">${floor.label}</span>
        <span class="floor-desc">${floor.description}</span>
      </span>
    `;

    if (!floor.locked) {
      button.addEventListener("click", () => handleSelectFloor(floor.id, button));
    }
    floorList.appendChild(button);
  });
}

function openElevator(payloadFloors, elevatorLabel = "Elevator", nextUiText = null) {
  const floors = sanitizeFloors(payloadFloors);
  const currentFloor = floors.find((floor) => floor.current);
  uiText = {
    ...uiText,
    ...(nextUiText && typeof nextUiText === "object" ? nextUiText : {})
  };

  clearTimeout(closeTimer);
  setStatusMoving(false);
  renderFloors(floors);
  if (panelKicker) panelKicker.textContent = uiText.kicker || "";
  if (panelTitle) panelTitle.textContent = elevatorLabel;
  if (panelSubtitle) {
    panelSubtitle.textContent = currentFloor
      ? `${uiText.subtitleCurrentPrefix || "Current floor:"} ${currentFloor.label}`
      : uiText.subtitleSelect || "Select destination floor";
  }
  isOpen = true;
  app.classList.remove("app--hidden");
  app.setAttribute("aria-hidden", "false");
}

function closeElevator(sendCallback = true) {
  if (!isOpen) return;

  clearTimeout(closeTimer);
  isOpen = false;
  setStatusMoving(false);
  app.classList.add("app--hidden");
  app.setAttribute("aria-hidden", "true");

  if (sendCallback) {
    // Lua callback bridge: informs resource that UI was closed by player/UI action.
    fetch(`https://${RESOURCE_NAME}/closeElevator`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({})
    }).catch(() => {});
  }
}

function handleSelectFloor(floorId, clickedButton) {
  if (isMoving) return;
  setStatusMoving(true);

  document.querySelectorAll(".floor-btn").forEach((btn) => btn.classList.remove("is-current"));
  clickedButton.classList.add("is-current");

  // Lua callback bridge: sends selected floor id back to client script.
  fetch(`https://${RESOURCE_NAME}/selectFloor`, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify({ id: floorId })
  }).catch(() => {});

  const delay = 500 + Math.floor(Math.random() * 301);
  closeTimer = setTimeout(() => closeElevator(false), delay);
}

window.addEventListener("message", (event) => {
  const data = event.data;
  if (!data || typeof data !== "object") return;

  if (data.action === "openElevator") {
    openElevator(data.floors, data.elevatorLabel, data.uiText);
  }

  if (data.action === "closeElevator") {
    closeElevator(false);
  }
});

window.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && isOpen) {
    closeElevator(true);
  }
});

if (closeBtn) {
  closeBtn.addEventListener("click", () => closeElevator(true));
}

if (app) {
  app.classList.add("app--hidden");
  app.setAttribute("aria-hidden", "true");
}
