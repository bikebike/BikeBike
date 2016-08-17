(function() {
	var searchControl = document.getElementById('search');

	function filterTable() {
		forEach(document.getElementById('search-rows').getElementsByTagName('tr'), function(tr) {
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

	searchControl.addEventListener('keyup', filterTable);
	searchControl.addEventListener('search', filterTable);
})();
