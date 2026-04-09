const searchInput = document.getElementById("searchInput");
const categorySelect = document.getElementById("categorySelect");
const promptGrid = document.getElementById("promptGrid");
const stats = document.getElementById("stats");
const template = document.getElementById("promptCardTemplate");

const state = {
  allPrompts: [],
  query: "",
  category: "all",
};

init();

async function init() {
  bindEvents();
  await loadPrompts();
  render();
}

function bindEvents() {
  searchInput.addEventListener("input", (event) => {
    state.query = event.target.value.trim().toLowerCase();
    render();
  });

  categorySelect.addEventListener("change", (event) => {
    state.category = event.target.value;
    render();
  });

  promptGrid.addEventListener("click", async (event) => {
    const button = event.target.closest("button[data-action]");
    if (!button) return;

    const card = button.closest(".card");
    if (!card) return;

    const promptId = card.dataset.id;
    const promptItem = state.allPrompts.find((item) => item.id === promptId);
    if (!promptItem) return;

    const action = button.dataset.action;
    if (action === "toggle") {
      toggleFullPrompt(card, button);
      return;
    }
    if (action === "copy") {
      await copyPrompt(promptItem.prompt, button);
    }
  });
}

async function loadPrompts() {
  try {
    const response = await fetch("../prompts/prompts.json");
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    const prompts = await response.json();
    state.allPrompts = Array.isArray(prompts) ? prompts : [];
    buildCategoryOptions();
  } catch (error) {
    stats.textContent = `Failed to load prompts: ${String(error.message || error)}`;
    state.allPrompts = [];
  }
}

function buildCategoryOptions() {
  const categories = [...new Set(state.allPrompts.map((item) => item.category))].sort();
  for (const category of categories) {
    const option = document.createElement("option");
    option.value = category;
    option.textContent = category;
    categorySelect.appendChild(option);
  }
}

function filterPrompts() {
  return state.allPrompts.filter((item) => {
    const categoryMatch = state.category === "all" || item.category === state.category;
    if (!categoryMatch) return false;

    if (!state.query) return true;

    const haystack = `${item.title} ${item.category} ${item.source} ${item.prompt}`.toLowerCase();
    return haystack.includes(state.query);
  });
}

function render() {
  const filtered = filterPrompts();
  stats.textContent = `${filtered.length} / ${state.allPrompts.length} prompts`;
  promptGrid.innerHTML = "";

  if (filtered.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.textContent = "No prompts matched current filters.";
    promptGrid.appendChild(empty);
    return;
  }

  for (const item of filtered) {
    const node = template.content.firstElementChild.cloneNode(true);
    node.dataset.id = item.id;
    node.querySelector(".card-title").textContent = item.title;
    node.querySelector(".card-category").textContent = item.category;
    node.querySelector(".card-source").textContent = `Source: ${item.source}`;
    node.querySelector(".card-preview").textContent = toPreview(item.prompt);
    node.querySelector(".card-full").textContent = item.prompt;
    promptGrid.appendChild(node);
  }
}

function toPreview(text, maxLength = 240) {
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength)}...`;
}

function toggleFullPrompt(card, button) {
  const full = card.querySelector(".card-full");
  const hidden = full.classList.toggle("hidden");
  button.textContent = hidden ? "View Full" : "Collapse";
}

async function copyPrompt(promptText, button) {
  const original = button.textContent;
  try {
    await navigator.clipboard.writeText(promptText);
    button.textContent = "Copied";
  } catch {
    button.textContent = "Copy Failed";
  }
  window.setTimeout(() => {
    button.textContent = original;
  }, 1200);
}
