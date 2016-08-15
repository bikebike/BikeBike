(function() {
	function closeGuestSelector() {
		document.getElementById('guest-selector').classList.remove('open');
	}
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
			//data.push(key + '=' + encodeURI(params[key]));
			data.push(key + '=' + params[key]);
		}
		request.send(data.join('&'));
	}

	function initHostTable(table) {
		forEachElement('.select-guest', function(button) {
			button.addEventListener('click', function(event) {
				event.preventDefault();
				document.getElementById('guest-selector').classList.add('open');
				var table = document.getElementById('table');
				table.classList.add('loading');
				_post(
						document.getElementById('housing-table-form'),
						{
							host: button.getAttribute('data-host'),
							space: button.getAttribute('data-space'),
							button: 'get-guest-list'
						},
						function (response) {
							var table = document.getElementById('table');
							table.innerHTML = response;
							table.classList.remove('loading');
							forEachElement('tr.selectable', function(row) {
								row.addEventListener('click', function(event) {
									var table = document.getElementById('housing-table');
									table.classList.add('loading');
									closeGuestSelector();
									_post(
											document.getElementById('guest-list-table'),
											{
												host: row.getAttribute('data-host'),
												guest: row.getAttribute('data-guest'),
												space: row.getAttribute('data-space'),
												button: 'set-guest'
											},
											function(response) {
												table.innerHTML = response;
												table.classList.remove('loading');
												initHostTable(table);
											}
										)
								});
							}, table);
						}
					);
			});
		});

		forEachElement('.remove-guest', function(button) {
			button.addEventListener('click', function(event) {
				event.preventDefault();
				var table = document.getElementById('housing-table');
				table.classList.add('loading');
				_post(
						document.getElementById('housing-table-form'),
						{
							guest: button.getAttribute('data-guest'),
							button: 'remove-guest'
						},
						function (response) {
							table.innerHTML = response;
							table.classList.remove('loading');
							initHostTable(table);
						}
					);
			});
		});
	}
	initHostTable(document.getElementById('housing-table'));
	document.getElementById('guest-selector').addEventListener('click', function(event) {
		if (event.target.id == 'guest-selector') {
			closeGuestSelector();
		}
	});
	function closeOnTop() {
		document.documentElement.removeAttribute('data-ontop');
		document.getElementById('guest_id').value = '';
		var target = document.querySelector('.on-top-target');
		target.removeAttribute('style');
		document.querySelector('body').removeAttribute('style');
		forEachElement('.on-top-control', function(control) {
			control.classList.remove('on-top-control');
		});
	}
	forEachElement('#guests .guest', function(guest) {
		var button = guest.querySelector('.set-host');
		button.addEventListener('click', function(event) {
			var target = document.querySelector('.on-top-target');
			var body = document.querySelector('body');
			// maintain our current height
			body.setAttribute('style', 'height: ' + body.clientHeight + 'px');
			document.documentElement.setAttribute('data-ontop', 'set-host');
			guest.classList.add('on-top-control');
			target.setAttribute('style', 'bottom: ' + guest.clientHeight + 'px');
			document.getElementById('guest_id').value = guest.dataset.id;
		});
	});
	forEachElement('#hosts .host', function(host) {
		initHost(host);
	});

	function initHost(host) {
		forEachElement('.place-guest', function(button) {
			button.addEventListener('click', function(event) {
				var guest_id = document.getElementById('guest_id').value;
				if (guest_id) {
					var guest = document.getElementById('guest-' + guest_id);
					var form = document.getElementById('hosts');
					var data = new FormData(form);

					host.classList.add('requesting');
					if (guest.dataset.affectedHosts) {
						data.append('affected-hosts', guest.dataset.affectedHosts);
						forEach(guest.dataset.affectedHosts.split(','), function(host_id) {
							h = document.getElementById('host-' + host_id);
							if (h) {
								h.classList.add('requesting');
							}
						});
					}
					data.append('button', button.value);

					var request = new XMLHttpRequest();
					request.onreadystatechange = function() {
						if (request.readyState == 4) {
							if (request.status == 200) {
								var response = JSON.parse(request.responseText);
								for (var host_id in response.hosts) {
									host_element = document.getElementById('host-' + host_id);
									widget = response.hosts[host_id];
									host_element.className = widget.class;
									host_element.querySelector('.guests').innerHTML = widget.html;
									initHost(host_element);
									host_element.classList.remove('requesting');
								}
								for (var guest_id in response.affected_hosts) {
									guest_element = document.getElementById('guest-' + guest_id);
									if (guest_element) {
										guest_element.setAttribute('data-affected-hosts', response.affected_hosts[guest_id].join(','));
									}
								}
							}
						}
					}
					request.open('POST', form.getAttribute('action'), true);
					request.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
					request.send(data);
				}
			});
		}, host);
	}
	forEachElement('.on-top-close', function(button) {
		button.addEventListener('click', closeOnTop);
	});
})();
