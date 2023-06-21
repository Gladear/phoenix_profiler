const SHOW = "phxprof-toolbar-show";

const toolbar = document.querySelector(".phxprof-toolbar");

function toggleToolbar(open) {
  toolbar.classList.toggle("miniaturized", !open);
  localStorage.setItem(SHOW, String(open));
}

toolbar
  .querySelector(".show-button")
  .addEventListener("click", () => toggleToolbar(true));
toolbar
  .querySelector(".hide-button")
  .addEventListener("click", () => toggleToolbar(false));

toggleToolbar(localStorage.getItem(SHOW) === "true");

window.getPhxProfToken = () => toolbar.dataset.token;
