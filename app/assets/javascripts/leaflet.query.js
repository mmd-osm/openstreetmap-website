L.OSM.query = function (options) {
  const control = L.control(options);

  control.onAdd = function (map) {
    const container = document.createElement("div");
    container.className = "control-query";

    const link = document.createElement("a");
    link.className = "control-button";
    link.href = "#";
    link.title = OSM.i18n.t("javascripts.site.queryfeature_tooltip");
    container.appendChild(link);

    const svg = L.SVG.create("svg");
    svg.setAttribute("class", "h-100 w-100");

    const use = L.SVG.create("use");
    use.setAttribute("href", "#icon-query");

    svg.appendChild(use);
    link.appendChild(svg);

    map.on("zoomend", update);

    function update() {
      const isDisabled = map.getZoom() < 14;
      const wasDisabled = link.classList.contains("disabled");

      if (isDisabled) {
        link.classList.add("disabled");
        link.setAttribute("data-bs-original-title", OSM.i18n.t("javascripts.site.queryfeature_disabled_tooltip"));
      } else {
        link.classList.remove("disabled");
        link.setAttribute("data-bs-original-title", OSM.i18n.t("javascripts.site.queryfeature_tooltip"));
      }

      if (isDisabled !== wasDisabled) {
        const event = new CustomEvent(isDisabled ? "disabled" : "enabled");
        link.dispatchEvent(event);
      }
    }

    update();

    return container;
  };

  return control;
};
