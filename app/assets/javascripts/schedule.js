(function() {
	var body = document.querySelector('body');
	var primaryContent = document.getElementById('primary-content');
	var eventDlg = document.getElementById('event-dlg');

	forEachElement('.event-detail-link', function(link) {
		var eventDetails = link.parentElement.querySelector('.event-details');
		var moreDetails = eventDlg.querySelector('.more-details');

		link.addEventListener('click', function(event) {
			event.preventDefault();
			eventDlg.querySelector('.event-details').innerHTML = eventDetails.innerHTML;
			var href = eventDetails.getAttribute('data-href');
			if (href) {
				moreDetails.setAttribute('href', href);
				moreDetails.classList.remove('hidden');
			} else {
				moreDetails.classList.add('hidden');
			}
			window.openOverlay(eventDlg, primaryContent, body);

			var closeDlg = function(event) {
				event.preventDefault();
				window.closeOverlay(eventDlg, primaryContent, body);
			};
			eventDlg.querySelector('.close-btn').onclick = closeDlg;
			document.getElementById('overlay').onclick = closeDlg;
		});
	});
})();
