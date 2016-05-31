(function() {
	Array.prototype.forEach.call(document.querySelectorAll('.number-field,.email-field,.text-field'), function(field) {
		var input = field.querySelector('input');
		var positionLabel = function(input) { 
			field.classList[input.value ? 'remove' : 'add']('empty');
		}
		positionLabel(input);
		input.addEventListener('keyup', function(event) { positionLabel(event.target); });
		input.addEventListener('blur', function(event) { field.classList.remove('focused'); });
		input.addEventListener('focus', function(event) { field.classList.add('focused'); });
	});
	var errorField = document.querySelector('.input-field.has-error input, .input-field.has-error textarea');
	if (errorField) {
		errorField.focus();
	}
})();
