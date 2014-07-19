#= require froala_editor.min.js
$ ->
	$('[data-editable]').editable({inlineMode: true, blockTags: ["n", "p", "h2", "blockquote", "pre"], buttons: ["formatBlock", "bold", "italic", "underline", "insertOrderedList", "insertUnorderedList", "sep", "createLink", "insertImage", "insertVideo", "html", "undo", "redo"]})
	$('[data-editor]').editable({inlineMode: false, blockTags: ["n", "p", "h2", "blockquote", "pre"], buttons: ["formatBlock", "bold", "italic", "underline", "insertOrderedList", "insertUnorderedList", "sep", "createLink", "html", "undo", "redo"]})
	$('.field.country-select-field select').change () ->
		$country = $(this)
		country = $country.val()
		$territory = $('.field.subregion-select-field select')
		if $territory.data().country == country
			$territory.removeClass('can cant').addClass('can')
			return
		
		$.post '/location/territories', {country: country},
			(json) ->
				$territory.html('')
				if json && Object.keys(json).length
					$.each json, (code, name) ->
						$territory.append($('<option>').text(name).attr('value', code))
						return
					$territory.removeClass('can cant').addClass('can')
					$territory.data().country = country
				else
					$territory.removeClass('can cant').addClass('cant')
				return
		, 'json'
	$('img + input[type="file"]').change () -> 
		readURL(this);
		return

readURL = (input) ->
	reader = null
	if input.files && input.files[0]
		reader = new FileReader()
		reader.readAsDataURL input.files[0]
		reader.onload = (e) ->
			$(input).prev().attr('src', e.target.result)
	return