(function() {
	window.onerror = function(message, url, lineNumber) {  
		//save error and send to server for example.
		var request = new XMLHttpRequest();
		request.open('POST', '/js_error', true);
		request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
		request.send(
			'message=' + encodeURI(message) +
			'&url=' + encodeURI(url) +
			'&lineNumber=' + encodeURI(lineNumber) +
			'&location=' + encodeURI(window.location.href)
		);
		return false;
	};
	window.forEach = function(a, f) { Array.prototype.forEach.call(a, f) };
	window.forEachElement = function(s, f, p) { forEach((p || document).querySelectorAll(s), f) };
	
	var overlay = document.getElementById('content-overlay');
	if (overlay) {
		var body = document.querySelector('body');
		var primaryContent = document.getElementById('primary-content');
		primaryContent.addEventListener('keydown', function(event) {
			if (body.classList.contains('has-overlay')) {
				event.stopPropagation();
				return false;
			}
		});
		document.addEventListener('focus', function(event) {
			if (overlay.querySelector('.dlg.open') && !overlay.querySelector('.dlg.open :focus')) {
				overlay.querySelector('.dlg.open').focus();
			}
		}, true);
		window.openOverlay = function(dlg, primaryContent, body) {
			primaryContent.setAttribute('aria-hidden', 'true');
			body.classList.add('has-overlay');
			var type = dlg.getAttribute('data-type');
			if (type) {
				body.classList.add('is-' + type + '-dlg');
			}
			dlg.removeAttribute('aria-hidden');
			dlg.setAttribute('role', 'alertdialog');
			dlg.setAttribute('tabindex', '0');
			dlg.focus();
			setTimeout(function() { dlg.classList.add('open'); }, 100);
		}
		window.closeOverlay = function(dlg, primaryContent, body) {
			setTimeout(function() {
					body.classList.remove('has-overlay');
					body.removeAttribute('style');
				}, 250);
			var type = dlg.getAttribute('data-type');
			if (type) {
				body.classList.remove('is-' + type + '-dlg');
			}
			primaryContent.removeAttribute('aria-hidden');
			dlg.setAttribute('aria-hidden', 'true');
			dlg.removeAttribute('tabindex');
			dlg.classList.remove('open');
			dlg.removeAttribute('role');
		}

		function openDlg(dlg, link) {
			document.getElementById('overlay').onclick =
				dlg.querySelector('.close').onclick = function() { closeDlg(dlg); };
			body.setAttribute('style', 'width: ' + body.clientWidth + 'px');
			var msg = link.querySelector('.message');
			if (msg) {
				dlg.querySelector('.message').innerHTML = msg.innerHTML
			}
			if (link.dataset.infoTitle) {
				dlg.querySelector('.title').innerHTML = decodeURI(link.dataset.infoTitle);
			}
			confirmBtn = dlg.querySelector('.confirm');
			if (confirmBtn) {
				confirmBtn.addEventListener('click', function(event) {
					event.preventDefault();
					if (link.tagName == 'BUTTON') {
						var form = link.parentElement
						while (form && form.tagName != 'FORM') {
							var form = form.parentElement
						}
						if (form) {
							var input = document.createElement('input');
							input.type = 'hidden';
							input.name = 'button';
							input.value = link.value;
							form.appendChild(input);
							form.submit();
						}
					} else {
						window.location.href = link.getAttribute('href');
					}
				});
			}
			window.openOverlay(dlg, primaryContent, body);
		}
		function closeDlg(dlg) {
			window.closeOverlay(dlg, primaryContent, body);
		}

		var confirmationDlg = document.getElementById('confirmation-dlg');
		forEachElement('[data-confirmation]', function(link) {
			link.addEventListener('click', function(event) {
				event.preventDefault();
				openDlg(confirmationDlg, link);
				return false;
			});
		});
		var infoDlg = document.getElementById('info-dlg');
		forEachElement('[data-info-text]', function(link) {
			link.addEventListener('click', function(event) {
				event.preventDefault();
				openDlg(infoDlg, link);
				return false;
			});
		});
		var loginDlg = document.getElementById('login-dlg');
		forEachElement('[data-sign-in]', function(link) {
			link.addEventListener('click', function(event) {
				event.preventDefault();
				openDlg(loginDlg, link);
				return false;
			});
		});
		var contactDlg = document.getElementById('contact-dlg');
		var contactLink = document.getElementById('contact-link');
		contactLink.addEventListener('click', function(event) {
			event.preventDefault();
			openDlg(contactDlg, contactLink);
			return false;
		});
	}
	
	var htmlNode = document.documentElement;
	document.addEventListener('keydown', function(event) {
		if (htmlNode.dataset.input != 'kb' &&
				((!["input", "textarea", "select", "option"].includes(event.target.nodeName.toLowerCase()) &&
				!event.target.attributes.contenteditable) || event.key == "Tab")) {
			htmlNode.setAttribute('data-input', 'kb');
		}
	});
	
	document.addEventListener('mousemove', function(event) {
		if (htmlNode.dataset.input != 'mouse' && (event.movementX || event.movementY)) {
			htmlNode.setAttribute('data-input', 'mouse');
		}
	});

	var errorField = document.querySelector('.input-field.has-error input, .input-field.has-error textarea');
	if (errorField) {
		errorField.focus();
	}
	
	window.initNodeFunctions = [ function(node) {
		forEachElement('.number-field,.email-field,.text-field,.password-field', function(field) {
			var input = field.querySelector('input');
			var positionLabel = function(input) { 
				field.classList[input.value ? 'remove' : 'add']('empty');
			}
			positionLabel(input);
			input.addEventListener('keyup', function(event) {
				positionLabel(event.target);
			});
			input.addEventListener('blur', function(event) {
				positionLabel(event.target);
				field.classList.remove('focused');
			});
			input.addEventListener('focus', function(event) {
				field.classList.add('focused');
			});
		}, node || document);
		forEachElement('form.js-xhr', function(form) {
			if (form.addEventListener) {
				form.addEventListener('submit', function(event) {
					event.preventDefault();
					form.classList.add('requesting');
					var data = new FormData(form);
					var request = new XMLHttpRequest();
					request.onreadystatechange = function() {
						if (request.readyState == 4) {
							form.classList.remove('requesting');
							if (request.status == 200) {
								var response = JSON.parse(request.responseText);
								for (var i = 0; i < response.length; i++) {
									var element;
									if (response[i].selector) {
										element = form.querySelector(response[i].selector);
									}
									if (response[i].globalSelector) {
										element = document.querySelector(response[i].globalSelector);
									}

									if (response[i].html) {
										element.innerHTML = response[i].html;
										window.initNode(element);
									}
									if (response[i].className) {
										element.className = response[i].className;
									}
								}
							}
						}
					}
					request.open('POST', form.getAttribute('action'), true);
					request.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
					request.send(data);
				}, false);
			}
		}, node || document);
		forEachElement('[data-opens]', function(control) {
			control.addEventListener('click', function(event) {
				var opens = document.querySelector(control.getAttribute('data-opens'));
				if (!opens.classList.contains('open')){
					event.preventDefault();
					opens.className += ' open';
					if (control.getAttribute('data-focus')) {
						var input = opens.querySelector(control.getAttribute('data-focus'));
						if (input) {
							input.focus();
						}
					}
					return false;
				}
			});
		});
	} ];
	window.initNode = function(node) {
		forEach(initNodeFunctions, function(fn) {
			fn(node);
		});
	};
	initNode();
})();
