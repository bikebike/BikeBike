# I18n
#= require i18n
#= require i18n/translations

'use strict'

$(document).ready ->
	$('#translation-control form').unbind('submit').bind('submit', (event)->
		event.preventDefault()
		event.stopPropagation()
		$form = $(this)
		serialized = $form.serialize()
		$form.find('select, button, textarea').prop 'disabled', true
		$.post $form.attr('action'), serialized,
			(json) ->
				if json.success
					$span = $('.translate-me[data-translate-key="' + json.key + '"]')
					$span.html(json.translation)
					$span.attr('data-translate-untranslated', json.translation)
					$span.removeClass 'untranslated'
				else if json.test
					console.log json.test
				$form.find('select, button, textarea').prop 'disabled', false
				return
		, 'json'
		return
	)
	$('.translate-me').click (event)->
		if event.altKey
			event.preventDefault()
			key = $(this).attr('data-translate-key')
			$('#translationkey').val key
			resetTranslation key
			$('#translationvalue').focus()
			return
	#$('#translationvalue, #translationkey').focus ->
	$('#translation-control *').focus ->
		key = $('#translationkey').val()
		selectTranslation key
		updateTranslation key
		return
	$('#translationkey').change (event)->
		#$('#translationvalue').val('')
		key = $('#translationkey').val()
		selectTranslation key
		resetTranslation key
		#$('#translation').focus()
		#console.log event
		return
	# $('#translationvalue, #translationkey').blur ->
	$('#translation-control *').blur ->
		selectTranslation()
		return
	$('#translationvalue').bind 'input propertychange', ()->
		updateTranslation $('#translationkey').val()
		return
	return

selectTranslation = (key)->
	$span = $('.translate-me.selected');
	$span.removeClass 'selected'
	$span.removeClass 'preview'
	$('#translatevars').hide()
	$('#translatepluralizations').hide()
	$('#translatevars ul').html ''
	$('#translationhascount').val('0')
	if key
		$target = $('.translate-me[data-translate-key="' + key + '"]')
		if !$target || !$target.length
			return
		vars = $target.addClass('selected').data().vars
		if vars
			keys = Object.keys(vars)
			if keys.length
				for i in [0...keys.length]
					$('#translatevars ul').append ('<li class="var-' + keys[i] + '" title="Value: ' + vars[keys[i]] + '">' + keys[i] + '</li>')
					if keys[i] == 'count'
						$('#translatepluralizations').show()
						$('#translationhascount').val('1')
				$('#translatevars').show()
	else
		$span.html ()->
			$(this).attr('data-translate-untranslated')
	return

updateTranslation = (key)->
	$span = $('.translate-me[data-translate-key="' + key + '"]')
	val = $('#translationvalue').val()
	is_preview = ($span.hasClass 'preview')
	$('#translatevars li').removeClass('used')
	if val
		if !is_preview
			$span.addClass 'preview'
		if !$span || !$span.length
			return
		vars = $span.data().vars
		keys = Object.keys(vars)
		for i in [0...keys.length]
			_var = new RegExp('%{' + keys[i] + '}')
			if val.match _var
				# console.log 'Match!'
				$('#translatevars li.var-' + keys[i]).addClass('used')
				val = val.replace _var, vars[keys[i]]
	else
		if is_preview
			$span.removeClass 'preview'
	$span.html (val || $span.attr('data-translate-untranslated'))
	return

resetTranslation = (key)->
	$target = $('.translate-me[data-translate-key="' + key + '"]')
	if $target && $target.length
		translated = $target.data().translateTranslated
		counts = ['zero', 'one', 'two', 'few', 'many']
		for i in counts
			val = translated[key + '.' + i]
			$('#translationvalue_' + i).val(val || '')
			$('#translationpluralization_' + i).prop('checked', !!val)
		val = (translated[key] || translated[key + '.other'])
		$('#translationvalue').val(val || '')
	return
