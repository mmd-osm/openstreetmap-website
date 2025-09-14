//= require download_util

OSM.Export = function (map) {
  const page = {};

  const locationFilter = new L.LocationFilter({
    enableButton: false,
    adjustButton: false
  }).on("change", update);

  function getBounds() {
    return L.latLngBounds(
      L.latLng($("#minlat").val(), $("#minlon").val()),
      L.latLng($("#maxlat").val(), $("#maxlon").val()));
  }

  function boundsChanged() {
    const bounds = getBounds();
    map.fitBounds(bounds);
    locationFilter.setBounds(bounds);
    locationFilter.enable();
    validateControls();
  }

  function enableFilter(e) {
    e.preventDefault();

    $("#drag_box").hide();

    locationFilter.setBounds(map.getBounds().pad(-0.2));
    locationFilter.enable();
    validateControls();
  }

  function update() {
    setBounds(locationFilter.isEnabled() ? locationFilter.getBounds() : map.getBounds());
    validateControls();
  }

  async function showConfirmationModal(message = "Are you sure?") {
    return new Promise((resolve) => {
      // Create modal HTML dynamically
      const modalHtml = `
          <div class="modal fade" tabindex="-1" id="dynamicConfirmModal">
              <div class="modal-dialog modal-dialog-centered">
                  <div class="modal-content">
                      <div class="modal-header">
                          <h5 class="modal-title">Confirm</h5>
                          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                      </div>
                      <div class="modal-body">
                          <p>${message}</p>
                      </div>
                      <div class="modal-footer">
                          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                          <button type="button" class="btn btn-primary" id="confirmYesBtn">Yes</button>
                      </div>
                  </div>
              </div>
          </div>`;

      // Insert into body
      document.body.insertAdjacentHTML("beforeend", modalHtml);

      const modalElement = document.getElementById("dynamicConfirmModal");
      const modal = new bootstrap.Modal(modalElement, {
        backdrop: "static",
        keyboard: false
      });

      modal.show();

      // Confirm or cancel
      modalElement.querySelector("#confirmYesBtn").addEventListener("click", () => {
        resolve(true);
        modal.hide();
      });

      modalElement.addEventListener("hidden.bs.modal", () => {
        resolve(false);
        modalElement.remove(); // Clean up DOM
      });
    });
  }

  function setBounds(bounds) {
    const truncated = [bounds.getSouthWest(), bounds.getNorthEast()]
      .map(c => OSM.cropLocation(c, map.getZoom()));
    $("#minlon").val(truncated[0][1]);
    $("#minlat").val(truncated[0][0]);
    $("#maxlon").val(truncated[1][1]);
    $("#maxlat").val(truncated[1][0]);

    $("#export_overpass").attr("href",
                               "https://overpass-api.de/api/map?bbox=" +
                               truncated.map(p => p.reverse()).join());
  }

  function validateControls() {
    $("#export_osm_too_large").toggle(getBounds().getSize() > OSM.MAX_REQUEST_AREA);
    $("#export_commit").toggle(getBounds().getSize() < OSM.MAX_REQUEST_AREA);
  }

  function checkSubmit(e) {
    if (getBounds().getSize() > OSM.MAX_REQUEST_AREA) e.preventDefault();
  }

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    map
      .addLayer(locationFilter)
      .on("moveend", update);

    $("#maxlat, #minlon, #maxlon, #minlat").change(boundsChanged);
    $("#drag_box").click(enableFilter);
    $(".export_form").on("submit", checkSubmit);

    document.querySelector(".export_form")
      .addEventListener("turbo:submit-end", OSM.getTurboBlobHandler("map.osm"));

    document.querySelector(".export_form")
      .addEventListener("turbo:before-fetch-response", OSM.turboHtmlResponseHandler);

    document.querySelector(".export_form")
      .addEventListener("turbo:before-fetch-request", function (event) {
        event.detail.fetchOptions.headers.Accept = "application/xml";
      });

    $("#export_overpass").on("click", async function (event) {
      event.preventDefault();

      const downloadUrl = $(this).attr("href");

      const confirmed = await showConfirmationModal("Do you want to export and download the data?");
      if (confirmed) {
        // Start download
        window.location.href = downloadUrl;
      }
    });

    update();
    return map.getState();
  };

  page.unload = function () {
    map
      .removeLayer(locationFilter)
      .off("moveend", update);
  };

  return page;
};
