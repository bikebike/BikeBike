Bike!Bike! translation and English copyright is being designed to operate on a volunteer basis.

Do not use any static text that will be seen by the public on the site. Instead use the single underscore
helper method. For example, on a page that includes a page header such as 'Organizations', simply enter:

	%h1
		<%= _ organizations.title ?>

Upon first viewing the page, the user (probably you) will see the resulting HTML:

	<h1><a class="translate-me" ... >organizations.title</a></h1>

Assuming that you're viewing the sire in English, clicking the link will then allow you to enter English
copy. Enter 'Organizations' and save it. The next time you see the page, you will see:
	
	<h1>Organizations</h1>

Once a spanish viewer sees the page they will see:

	<h1><a class="translate-me lang-eng" ... >Organizations</a></h1>

This will allow them to choose an appropriate translation. They may then enter 'Organizaciones'
which will result in subsequent Spanish viewers to see the translation.

When the text to be shown cannot be surrounded by HTML tags, for example for an <input> control,
the translation controls can be queued to be shown comtime afterwards using the double underscore
method, followed by the single underscore method. For example:

	%input{:name => "organization-name", :placeholder => <%= __ organizations.enter_name %>}
	<%= _ %>

Assuming that 'en.organizations.enter_name' = 'Enter the name of your organization', this willl
result in the following HTML:

	<input name="organization-name" placeholder="Enter the name of your organization" />

However, for a Spanish viewer, before a translation has been selected they should see:

	<input name="organization-name" placeholder="Enter the name of your organization" />
	<div class="untranslated-list">
		<a class="translate-me lang-eng">Enter the name of your organization</a>
	</div>

If multiple items are queued, they will all be shown inside this div. After a translation has been entered
by a Spanish speaking volunteer, subsequent volunteers will simply see:

	<input name="organization-name" placeholder="Escriba el nombre de su organización" />

Best practices:
	- Never edit en.yml, or any other files directly, always use the site tool to do this as it will
		help ensure proper testing of all pages and that all text will be translated.
	- Reuse locale keys as much as possible. Use concatenation of printf where it makes sense to do
		so. The less work volunteers have to do, the more likely that they will get it all done.
		