(function() {
  function loadMap() {
    var projection = d3.geo.mercator();
    var path = d3.geo.path().projection(projection);
    var tooltip = document.getElementById('tooltip');

    var initialScale = 3.5;
    var initialPosition = [-100, -175];

    var zoom = d3.behavior.zoom()
      .scaleExtent([1, 20])
      .scale(initialScale).translate(initialPosition)
      .on("zoom", function() {
        setZoom(d3.event.translate, d3.event.scale);
      });

    function setZoom(translate, scale) {
        container.attr("transform", "translate(" + translate + ") scale(" + scale + ")").attr('data-scale', scale);
    }

    var container = d3.select('#map').call(zoom).insert('g', ':first-child').attr('class', 'map');

    setZoom(initialPosition, initialScale);

    container.append("path")
      .datum(d3.geo.graticule())
      .attr("class", "graticule")
      .attr("d", path);

    d3.selection.prototype.moveToFront = function() {
      return this.each(function(){
        this.parentNode.appendChild(this);
      });
    };

    d3.json('/assets/world-110m.json', function(error, world) {
      if (error) {
        throw error;
      }

      container.selectAll('path')
        .data(topojson.feature(world, world.objects.countries).features)
        .enter()
        .append('path')
        .attr('d', path)
        .attr('class', 'country');

      var year = (new Date()).getFullYear();
      var conferences = document.querySelectorAll('#conferences .conference');
      var conference_path = []

      for (var i = 0; i < conferences.length; i++) {
        var d = conferences[i];
        if (d.getAttribute('data-t') === 'annual') {
          var coords = projection([d.getAttribute('data-o'), d.getAttribute('data-a')]);
          if (conference_path.length) {
            conference_path[conference_path.length - 1].x2 = coords[0];
            conference_path[conference_path.length - 1].y2 = coords[1];
          }
          conference_path.push({
            x1: coords[0],
            y1: coords[1]
          });
        }
      }

      container.append('defs').html('<filter id="svg-gooey-filter"><feGaussianBlur in="SourceGraphic" stdDeviation="3" result="blur"></feGaussianBlur><feColorMatrix in="blur" mode="matrix" values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 18 -7" result="svg-gooey-filter"></feColorMatrix><feComposite in="SourceGraphic" in2="svg-gooey-filter" operator="atop"></feComposite></filter>')

      var regionalConferences = container.append('g').attr('filter', 'url(#svg-gooey-filter)').attr('class', 'cities regional-conferences');
      var annualConferences = container.append('g').attr('filter', 'url(#svg-gooey-filter)').attr('class', 'cities annual-conferences');

      function mouseover(e) {
        c = document.getElementById('conference-' + d3.event.target.getAttribute('data-c'));
        tooltip.innerHTML = '<h3>' + c.querySelector('.title').innerHTML + '</h3>' +
                            '<div class="conference-details">' + c.querySelector('.conference-details').innerHTML + '</div>';
        tooltip.className = 'open';
      }

      function mouseout(e) {
        tooltip.className = '';
      }

      function click(e) {
        l = document.querySelector('#conference-' + d3.event.target.getAttribute('data-c') + ' .conference-link');
        window.location.href = l.getAttribute('href');
      }

      for (var i = conferences.length - 1; i >= 0; i--) {
        var c = conferences[i];
        var type = c.getAttribute('data-t');
        var coords = projection([c.getAttribute('data-o'), c.getAttribute('data-a')]);

        (type === 'annual' ? annualConferences : regionalConferences)
          .append('circle')
          .attr('class', 'city type-' + type)
          .attr('data-c', c.id.replace(/^conference\-/, ''))
          .attr('cx', function(d) { return coords[0]; })
          .attr('cy', function(d) { return coords[1]; })
          .attr('r', Math.max(3,
              (15 - (
                (year - parseInt(c.getAttribute('data-y'))) * 2.5)) * 1.125)
            )
          .on('mouseover', mouseover)
          .on('mouseout', mouseout)
          .on('click', click);
      }
    });

    d3.select("#map").attr('class', 'loaded');
  }

  document.onreadystatechange = function () {
    if (document.readyState == 'complete') {
      loadMap();
    }
  };
})();
