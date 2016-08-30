(function() {
	function closeWorkshopSelector() {
		document.getElementById('workshop-selector').classList.remove('open');
		document.body.classList.remove('modal-open');
	}
	document.getElementById('workshop-selector').addEventListener('click', function(event) {
		if (event.target.id == 'workshop-selector') {
			closeWorkshopSelector();
		}
	});
	function _post(form, params, f) {
		var request = new XMLHttpRequest();
		request.onreadystatechange = function() {
			if (request.readyState == 4) {
				if (request.status == 200) {
					f(request.responseText);
				}
			}
		}
		request.open('POST', form.getAttribute('action'), true);
		request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
		params['authenticity_token'] = form.querySelector('[name="authenticity_token"]').value;
		var data = [];
		for (var key in params) {
			data.push(key + '=' + params[key]);
		}
		request.send(data.join('&'));
	}
	function selectorMatches(el, selector) {
		var p = Element.prototype;
		var f = p.matches || p.webkitMatchesSelector || p.mozMatchesSelector || p.msMatchesSelector || function(s) {
			return [].indexOf.call(document.querySelectorAll(s), this) !== -1;
		};
		return f.call(el, selector);
	}
	function updateSchedule(html) {
		var schedule = document.getElementById('schedule-preview');
		var s = document.createElement('div');
		s.innerHTML = html;
		schedule.innerHTML = s.children[0].innerHTML;
		schedule.classList.remove('requesting');
	}

	document.body.addEventListener('submit', function (event) {
		if (event.target.classList.contains('deschedule-workshop')) {
			event.preventDefault();
			var schedule = document.getElementById('schedule-preview');
			var form = event.target;
			schedule.classList.add('requesting');
			_post(
					form,
					{
						id: form.querySelector('[name="id"]').value,
						button: 'deschedule_workshop'
					},
					updateSchedule
				);
		}
	});
	document.body.addEventListener('click', function (event) {
		//console.log(event.target);
		
		if (selectorMatches(event.target, 'td.workshop.open, td.workshop.open *')) {
			//event.stopPropagation();
			var button = event.target;
			while (button && button.tagName && button.tagName !== 'TD') {
				button = button.parentElement;
			}

			document.getElementById('workshop-selector').classList.add('open');
			var table = document.getElementById('table');
			table.classList.add('loading');
			document.body.classList.add('modal-open');

			var block = button.getAttribute('data-block');
			var day = button.getAttribute('data-day');
			var location = button.getAttribute('data-location');
			
			_post(
					document.getElementById('workshop-table-form'),
					{
						block: block,
						day: day,
						location: location,
						button: 'get-workshop-list'
					},
					function (response) {
						var table = document.getElementById('table');
						table.innerHTML = response;
						table.classList.remove('loading');
						forEachElement('tr.selectable', function(row) {
							row.addEventListener('click', function(event) {
								var schedule = document.getElementById('schedule-preview');
								schedule.classList.add('requesting');
								closeWorkshopSelector();
								var form = document.getElementById('workshop-table-form');
								_post(
										form,
										{
											workshop: row.getAttribute('data-workshop'),
											block: block,
											day: day,
											location: form.querySelector('#event_location').value,
											button: 'set-workshop'
										},
										updateSchedule
									);
							});
						}, table);
					}
				);
		}
	}, true);
})();
