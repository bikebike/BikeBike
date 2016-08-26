(function() {
	var searchControl = document.getElementById('search');

	function filterTable() {
		forEach(document.getElementById('search-table').getElementsByTagName('TBODY')[0].getElementsByTagName('TR'), function(tr) {
			if (tr.classList.contains('editable')) {
				tr.classList.remove('hidden');

				var value = searchControl.value;
				if (value) {
					var words = value.split(/\s+/);
					for (var i = 0; i < words.length; i++) {
						var word = new RegExp(words[i].replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"), "i");
						if (tr.innerHTML.search(word) == -1) {
							tr.classList.add('hidden');
						}
					}
				}
			}
		});
	}

	// ref = https://davidwalsh.name/element-matches-selector
	function selectorMatches(el, selector) {
		var p = Element.prototype;
		var f = p.matches || p.webkitMatchesSelector || p.mozMatchesSelector || p.msMatchesSelector || function(s) {
			return [].indexOf.call(document.querySelectorAll(s), this) !== -1;
		};
		return f.call(el, selector);
	}

	function saveRow(row) {
		if (row) {
			row.classList.remove('editing');
			var table = row.parentElement.parentElement;
			var editRow = row.nextSibling;
			var url = table.getAttribute('data-update-url');
			var data = new FormData();
			var request = new XMLHttpRequest();
			request.onreadystatechange = function() {
				if (request.readyState == 4) {
					row.classList.remove('requesting');
					if (request.status == 200 && request.responseText) {
						var tempTable = document.createElement('table');
						tempTable.innerHTML = request.responseText;
						var rows = tempTable.getElementsByTagName('tr');
						row.innerHTML = rows[0].innerHTML;
						editRow.innerHTML = rows[1].innerHTML;
					}
				}
			}
			request.open('POST', url, true);
			cells = editRow.getElementsByClassName('cell-editor');
			data.append('key', row.getAttribute('data-key'));
			data.append('button', 'update');
			var changed = false;
			for (var i = 0; i < cells.length; i++) {
				if (cells[i].value !== cells[i].getAttribute('data-value')) {
					data.append(cells[i].getAttribute('name'), cells[i].value);
					changed = true;
				}
			}
			if (changed) {
				row.classList.add('requesting');
				request.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
				request.send(data);
			}
		}
	}

	function editTableCell(cell) {
		if (selectorMatches(cell, 'tr[data-key].editable td')) {
			editTableRow(cell.parentElement, cell);
		} else if (!selectorMatches(cell, 'tr[data-key].editable + tr, tr[data-key].editable + tr *')) {
			var currentRow = document.querySelector('tr[data-key].editable.editing');
			if (currentRow) {
				saveRow(currentRow);
			}
		}
	}
	function editTableRow(row, cell) {
		if (selectorMatches(row, 'tr[data-key].editable')) {
			var key = row.getAttribute('data-key');
			var currentRow = document.querySelector('tr[data-key].editable.editing');
			if (currentRow && currentRow.getAttribute('data-key') !== key) {
				saveRow(currentRow);
			}
			var editor = row.nextSibling;
			if (!row.classList.contains('editing')) {
				row.classList.add('editing');
				var focusElement = null;
				if (cell) {
					focusElement = editor.querySelector('td[data-column-id="' + cell.getAttribute('data-column-id') + '"] .cell-editor');
				}
				focusElement = focusElement || editor.getElementsByClassName('cell-editor')[0];
				focusElement.focus();
				if (focusElement.tagName === 'TEXTAREA' || (focusElement.tagName === 'INPUT' && focusElement.type != 'number' && focusElement.type != 'email')) {
					focusElement.setSelectionRange(0, focusElement.value.length);
				}
			}
		}
	}
	document.addEventListener('click', function (event) { editTableCell(event.target); });
	document.addEventListener('keyup', function (event) {
		if (event.code === "Enter") {
			var currentRow = document.querySelector('tr[data-key].editable.editing');
			if (currentRow) {
				event.stopPropagation();
				event.preventDefault();
				var next = event.shiftKey ? 'previousSibling' : 'nextSibling';
				var cell = document.activeElement.parentElement.getAttribute('data-column-id');
				var row = currentRow[next] ? currentRow[next][next] : null;
				if (!row) {
					rows = currentRow.parentElement.children;
					row = event.shiftKey ? rows[rows.length - 2] : rows[0];
				}
				editTableRow(row, row.querySelector('[data-column-id="' + cell + '"]'));
			}
		} else if (event.code === "Escape") {
			var currentRow = document.querySelector('tr[data-key].editable.editing');
			if (currentRow) {
				event.stopPropagation();
				event.preventDefault();
				saveRow(currentRow);
			}
		}
	});
	if (document.observe) {
		document.observe("focusin", function (event) { editTableCell(event.target); });
	} else {
		document.addEventListener("focus", function (event) { editTableCell(event.target); }, true);
		// document.addEventListener("focus", function (event) { editTableCell(event.target); }, true);
	}

	searchControl.addEventListener('keyup', filterTable);
	searchControl.addEventListener('search', filterTable);

	forEachElement('[data-expands]', function(button) {
		button.addEventListener('click', function(event) {
			var element = document.getElementById(event.target.getAttribute('data-expands'));
			document.body.classList.add('expanded-element');
			element.classList.add('expanded');
		});
	});
	forEachElement('[data-contracts]', function(button) {
		button.addEventListener('click', function(event) {
			var element = document.getElementById(event.target.getAttribute('data-contracts'));
			document.body.classList.remove('expanded-element');
			element.classList.remove('expanded');
		});
	});
	forEachElement('[data-opens-modal]', function(button) {
		button.addEventListener('click', function(event) {
			var element = document.getElementById(event.target.getAttribute('data-opens-modal'));
			document.body.classList.add('modal-open');
			element.classList.add('open');
		});
	});
	forEachElement('[data-closes-modal]', function(element) {
		element.addEventListener('click', function(event) {
			document.getElementById(event.target.getAttribute('data-closes-modal')).classList.remove('open');
			document.body.classList.remove('modal-open');
		});
	});
})();
