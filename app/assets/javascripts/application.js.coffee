#= require jquery
#= require jquery_ujs
#= require jquery.ui.sortable
#= require jquery.turbolinks
#= require turbolinks
#= require foundation

# FRONT END

# JS HANDLEBARS TEMPLATES
# require handlebars.runtime
# require jquery_nested_form

# I18n
#= require i18n
#= require i18n/translations

# ALL THE REST
#= require_tree .

'use strict'

I18n.defaultLocale = '<%= I18n.default_locale %>'
I18n.locale = $('html').attr 'lang'

try Typekit.load() catch

startSpinner = ->
	$('#loading-spinner').show()

stopSpinner = ->
	$('#loading-spinner').fadeOut()

# Turbolinks Spinner
document.addEventListener 'page:fetch', startSpinner
document.addEventListener 'page:receive', stopSpinner

readURL = (input) ->
	reader = null
	if input.files && input.files[0]
		reader = new FileReader()
		reader.readAsDataURL input.files[0]
		reader.onload = (e) ->
			$(input).prev().attr('src', e.target.result)

createOverlay = () ->
	if $('#overlay').length > 0
		$('#overlay').remove()
	$('body').append('<div id="overlay" class="loading"><div id="overlay-inner"></div></div>')
	$('#overlay-dlg')

setOverlayHTML = (html) ->
	$('#overlay-inner').append('<div id="overlay-dlg">' + html + '</div>');
	$('#overlay').removeAttr('class').click(destroyOverlay)

destroyOverlay = () ->
	$('#overlay').remove()

selectA = (type, event, $emptyObj) ->
	event.preventDefault()
	# = $(this)
	$overlay = createOverlay()
	objs = []
	$('.' + type + '-select-field.added input.' + type + '-id').each () -> obj.push($(this).val())
	$.post $emptyObj.data().url + (if type == 'organization' then '/nonhosts' else '/nonmembers'), {added: objs},
		(html) ->
			setOverlayHTML(html).addClass('' + type + '-select')
			$('#select-' + type + '-list a').click (event) ->
				event.preventDefault()

				$this = $(this)
				$old_field = $emptyObj.closest('.field')
				$field = $old_field.clone()

				oldID = parseInt($old_field.find('input[type="hidden"]').attr('name').match(/\[(\d+)\]\[id\]/)[1])
				newID = oldID + 1

				$field.find('input.' + type + '-id').val($this.data().id)
				$field.find('.' + type + 'name').html($this.find('.' + type + 'name').html()).before('<img src="' + $this.find('img').attr('src') + '" />')
				$field.find('.select-' + type + '').remove()
				$field.removeClass('new').addClass('added')
				$old_field.html (i, html) ->
					pregex = new RegExp('\\[' + oldID + '\\]', 'g');
					aregex = new RegExp('_' + oldID + '_', 'g');
					html.replace(pregex, '[' + newID + ']').replace(aregex, '_' + newID + '_')
				$field.insertBefore($old_field)
				$('a.select-' + type + '').click (event) -> selectA(type, event, $(this))

				destroyOverlay()
				return
	, 'html'

updateFormField = () ->
	$form = $('form#new_registration_form_field')
	$field_type = $form.find('#registration_form_field_field_type')
	field_type = $field_type.val()
	$form.find('.registration-form-field-field').hide()
	$form.find('.registration-form-field-field.field-type-' + field_type).show()

updateFormFieldForm = () ->
	$('form #registration_form_field_field_type').change updateFormField
	updateFormField()
	$('form#new_registration_form_field').submit (event) ->
		event.preventDefault()
		$form = $(this)
		serialized = $form.serialize()
		$.post $form.attr('action'), serialized,
			(json) ->
				$form.replaceWith(json.form)
				$('#registration-form-field-list').html(json.list)
				updateFormFieldForm()
		, 'json'
updateFormFieldList = () ->
	$('#registration-form-field-list .add-form-field').click () ->
		$.post 'form/add-field', {field: $(this).data().id},
			(json) ->
				$('#conference-form').html(json.form)
				$('#registration-form-field-list').html(json.list)
				#console.log json
				updateFormFieldList()
				return
	$('#conference-form .remove-form-field').click () ->
		$.post 'form/remove-field', {field: $(this).data().id},
			(json) ->
				$('#conference-form').html(json.form)
				$('#registration-form-field-list').html(json.list)
				updateFormFieldList()
				return

$ ->
	$(document).foundation();
	$('.field.country-select select').change () ->
		$country = $(this)
		country = $country.val()
		$territory = $('.field.subregion-select select')
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

		return

	$('img + input[type="file"]').change () -> 
		readURL(this);

	$('a.select-user, a.select-organization').click (event) -> selectA($(this).attr('class').match(/(^|\s)select\-([^\s]+)/)[2], event, $(this))
	updateFormFieldForm()
	updateFormFieldList()

	$('ul.sortable').sortable
		handle: '.drag-sort',
		items: 'li',
		update: (event, props) ->
			$(this).children().each (index, child) ->
				$(child).find('.sortable-position').val(index + 1)
			url = $(this).data().url
			if url
				data = $(this).find('input, select, textarea').serialize()
				$.post url, data#,
				#	(json) ->
				#		console.log json
				#, 'json'
