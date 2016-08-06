(function() {
	function updateTimes() {
		var updateIn = 0;
		forEachElement('time', function(time) {
			var date = new Date(time.getAttribute('datetime'));
			var timeAgo = ((new Date()) - date) / (1000);
			var unit = "seconds";
			var updateTime = 0;

			if (timeAgo >= 31536000) {
				timeAgo /= 31536000;
				unit = "over_x_years";
			} else if (timeAgo >= 172800) {
				timeAgo /= 172800;
				unit = "x_days";
			} else if (timeAgo >= 3600) {
				timeAgo /= 3600;
				unit = "x_hours";
				updateTime = 3600;
			} else if (timeAgo >= 60) {
				timeAgo /= 60;
				unit = "x_minutes"
				updateTime = 60;
			} else {
				timeAgo = 1;
				unit = "less_than_x_minutes";
				updateTime = 10;
			}

			if (updateTime > 0 && (updateIn < 1 || updateTime < updateIn)) {
				updateIn = updateTime;
			}
			
			time.setAttribute("title", date);
			time.innerHTML = I18n.t('datetime.distance_in_words.time_ago', {time: I18n.t('datetime.distance_in_words.' + unit, {count: Math.floor(timeAgo)})});
		});

		if (updateIn > 0) {
			window.setTimeout(updateTimes, updateIn + 1000);
		}
	}

	window.addEventListener("load", updateTimes, false);
})();