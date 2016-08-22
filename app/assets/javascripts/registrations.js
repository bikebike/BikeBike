(function() {
	var searchControl = document.getElementById('search');

	function filterTable() {
		forEach(document.getElementById('search-table').getElementsByTagName('TBODY')[0].getElementsByTagName('TR'), function(tr) {
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
			/*row.removeAttribute('data-editing');
			forEach(row.getElementsByTagName('TD'), function(cell) {
				var input = cell.getElementsByClassName('cell-editor')[0];
				if (input) {
					cell.removeChild(input);
				}

			});*/
		}
	}

	function editTableCell(cell) {
		if (selectorMatches(cell, 'tr[data-key].editable td')) {
			editTableRow(cell.parentElement, cell);
		}
		/*var currentRow = document.querySelector('[data-key][data-editing="1"]');
		if (currentRow && !currentRow.contains(cell)) {
			saveRow(currentRow);
		}

		if (selectorMatches(cell, 'tr[data-key] td[name]')) {
			if (!cell.getElementsByClassName('cell-editor').length) {
				//var tr = cell.parentElement;

				//saveRow(document.querySelector('[data-key][data-editing="1"]'), tr);
				cell.parentElement.setAttribute('data-editing', "1");

				var value = cell.innerHTML;
				cell.innerHTML += '<textarea type="text" name="' + cell.getAttribute('name') + '" class="cell-editor">' + value + '</textarea>';
				cell.parentElement.classList.add();
				setTimeout(function() { cell.getElementsByClassName('cell-editor')[0].focus(); }, 100);
			}
		}*/
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
				(focusElement || editor.getElementsByClassName('cell-editor')[0]).focus();
			}
		}
	}
	document.addEventListener('click', function (event) { editTableCell(event.target); });
	if (document.observe) {
		document.observe("focusin", function (event) { editTableCell(event.target); });
	} else {
		document.addEventListener("focus", function (event) { editTableCell(event.target); }, true);
		// document.addEventListener("focus", function (event) { editTableCell(event.target); }, true);
	}

	searchControl.addEventListener('keyup', filterTable);
	searchControl.addEventListener('search', filterTable);
})();
