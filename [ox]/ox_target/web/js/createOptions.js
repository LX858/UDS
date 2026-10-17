import { fetchNui } from "./fetchNui.js";

const SVG_NS = "http://www.w3.org/2000/svg";
let uid = 0;

function gradient(id, x2, y2, stopClasses) {
  const grad = document.createElementNS(SVG_NS, "linearGradient");
  grad.setAttribute("id", id);
  grad.setAttribute("x1", "0");
  grad.setAttribute("y1", "0");
  grad.setAttribute("x2", x2);
  grad.setAttribute("y2", y2);

  stopClasses.forEach((className, i) => {
    const stop = document.createElementNS(SVG_NS, "stop");
    stop.setAttribute("offset", (i / (stopClasses.length - 1)).toFixed(2));
    stop.setAttribute("class", className);
    grad.appendChild(stop);
  });

  return grad;
}

/**
 * Builds a single option element. The caller owns insertion and numbering so
 * layout/hotkeys stay in one place (main.js).
 */
export function buildOption(type, data, id, zoneId) {
  if (data.hide) return null;

  const option = document.createElement("div");
  option.className = "option";
  option.targetType = type;
  option.targetId = id;
  option.zoneId = zoneId;

  if (type === "zones") option.classList.add("is-zone");
  if (data.name === "builtin:goback" || data.goBack) option.classList.add("is-back");
  if (data.description) option.classList.add("has-desc");

  const n = ++uid;
  const svg = document.createElementNS(SVG_NS, "svg");
  svg.setAttribute("class", "blob-svg");

  const defs = document.createElementNS(SVG_NS, "defs");
  defs.appendChild(gradient(`blobFill${n}`, "0.35", "1", ["fill-0", "fill-1", "fill-2"]));
  defs.appendChild(gradient(`blobLine${n}`, "1", "1", ["line-0", "line-1"]));
  svg.appendChild(defs);

  const blobPath = document.createElementNS(SVG_NS, "path");
  blobPath.setAttribute("class", "blob-path");
  blobPath.setAttribute("fill", `url(#blobFill${n})`);
  blobPath.setAttribute("stroke", `url(#blobLine${n})`);
  svg.appendChild(blobPath);
  option.appendChild(svg);

  const content = document.createElement("div");
  content.className = "option-content";

  const icon = document.createElement("i");
  icon.className = `fa-fw option-icon ${data.icon || "fa-solid fa-circle-dot"}`;
  if (data.iconColor) icon.style.color = data.iconColor;
  content.appendChild(icon);

  const text = document.createElement("div");
  text.className = "option-text";

  const label = document.createElement("p");
  label.className = "option-label";
  label.textContent = data.label ?? "";
  text.appendChild(label);

  if (data.description) {
    const desc = document.createElement("p");
    desc.className = "option-desc";
    desc.textContent = data.description;
    text.appendChild(desc);
  }

  content.appendChild(text);

  const key = document.createElement("span");
  key.className = "option-key empty";
  content.appendChild(key);

  option.appendChild(content);

  option._blobPath = blobPath;
  option._blobSvg = svg;
  option._content = content;
  option._key = key;
  option._blobTarget = 0;
  option._isHovered = false;
  option._focusScale = 1;

  option.addEventListener("mouseenter", () => {
    option._blobTarget = 4.5;
    option._isHovered = true;
    option.classList.add("hovered");
  });

  option.addEventListener("mouseleave", () => {
    option._blobTarget = 0;
    option._isHovered = false;
    option.classList.remove("hovered");
  });

  option.addEventListener("click", () => selectOption(option));

  return option;
}

/** Fires the option and plays the pick feedback. Shared by clicks and hotkeys. */
export function selectOption(option) {
  if (!option || option._picked) return;

  option._picked = true;
  option.classList.add("picked");
  // When nui focus drops after a click the hover event is never released.
  option.style.pointerEvents = "none";

  fetchNui("select", [option.targetType, option.targetId, option.zoneId]);

  setTimeout(() => {
    option._picked = false;
    option.classList.remove("picked");
    option.style.pointerEvents = "";
  }, 140);
}
