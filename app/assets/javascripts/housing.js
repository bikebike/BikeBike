(function() {
	function closeGuestSelector() {
		document.getElementById('guest-selector').classList.remove('open');
		document.body.classList.remove('modal-open');
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
				document.body.classList.add('modal-open');
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
})();
