
module ScheduleHelper
	def get_schedule_data
		schedule          = Hash.new
		workshop_errors   = Hash.new
		workshop_warnings = Hash.new

		all_events = (@workshops + @events)
		conflicts = 0
		errors = 0

		(0...all_events.count).each do |i|
			w = all_events[i]

			if w.start_time.present? && w.end_time.present? && w.event_location_id.present?
				type = w.is_a?(Workshop) ? :workshop : :event

				hour = w.start_time.strftime('%H').to_i
				hour += 0.5 if w.start_time.strftime('%M').to_i > 15

				end_hour = w.end_time.strftime('%H').to_i
				end_hour += 0.5 if w.end_time.strftime('%M').to_i > 15

				day = w.conference_day

				schedule[day] ||= Hash.new
				schedule[day][:locations] ||= Hash.new
				schedule[day][:locations][w.event_location_id] ||= Hash.new

				conflict = nil
				(hour...end_hour).step(0.5).each do |h|
					h = h.to_i if h == h.to_i
					if !conflict && schedule[day][:locations][w.event_location_id][h].present?
						conflict = schedule[day][:locations][w.event_location_id][h]
					end
				end

				if conflict.present?
					w_conflict = get_workshop(conflict, @workshops, @events)
					workshop_errors[(w_conflict.is_a?(Workshop) ? 'w' : 'e') + w_conflict.id.to_s] = "Time conflict with &ldquo;<strong>#{w_conflict.title}</strong>&rdquo;".html_safe
					workshop_errors[(w.is_a?(Workshop) ? 'w' : 'e') + w.id.to_s] = "Time conflict with &ldquo;<strong>#{w.title}</strong>&rdquo;".html_safe
					errors += 1 if workshop_errors[(w_conflict.is_a?(Workshop) ? 'w' : 'e') + w_conflict.id.to_s].nil?
				else
					schedule[day][:start_time] = hour if schedule[day][:start_time].nil? || hour < schedule[day][:start_time]
					schedule[day][:end_time] = end_hour if schedule[day][:end_time].nil? || end_hour > schedule[day][:end_time]

					schedule[day][:locations][w.event_location_id][hour] = {
						:span => w.duration / 60.0,
						:type => w.is_a?(Event) ? w.event_type : :workshop
					}
					schedule[day][:locations][w.event_location_id][hour][:workshop] = i if type == :workshop
					schedule[day][:locations][w.event_location_id][hour][:event] = (i - @workshops.count) if type == :event
				end
			else
				workshop_warnings["w#{w.id}"] ||= Array.new
				workshop_warnings["w#{w.id}"] << (w.is_a?(Workshop) ? "This workshop is not scheduled" : "This event is not scheduled")
			end
		end

		schedule.each do |day, day_data|
			day_data[:locations].each do |location1, location_data1|
				location_data1.each do |time1, data1|
					day_data[:locations].each do |location2, location_data2|
						location_data2.each do |time2, data2|
							if data1[:workshop].present?
								if data2[:workshop].present?
									unless location1 == location2 && time1 == time2
										if workshop_errors[data1[:workshop]].nil?
											w1 = @workshops[data1[:workshop]]
											w2 = @workshops[data2[:workshop]]
											if time1 == time2
												w1.workshop_facilitators.each do |f|
													u = User.find(f.user_id)
													if w2.active_facilitator?(u)
														errors += 1 if workshop_errors[(w2.is_a?(Workshop) ? 'w' : 'e') + w2.id.to_s].nil?
														workshop_errors["w#{w1.id}"] = "This workshop shares facilitators with &ldquo;<strong>#{w2.title}</strong>&rdquo;".html_safe
													end
												end
												connection ||= ActiveRecord::Base.connection
												common_interest_count = connection.select_value("SELECT COUNT(w1.user_id) FROM workshop_interests AS w1 JOIN workshop_interests AS w2 ON w2.user_id=w1.user_id WHERE w1.workshop_id=#{w1.id} AND w2.workshop_id=#{w2.id}")
												common_interest_count = common_interest_count ? common_interest_count.to_i : 0
												if common_interest_count > 0
													conflicts += common_interest_count
													workshop_warnings["w#{w1.id}"] ||= Array.new
													workshop_warnings["w#{w1.id}"] << "<strong>#{common_interest_count}</strong> people are also interested in &ldquo;<strong>#{w2.title}</strong>&rdquo;".html_safe
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end

		{
			:schedule => schedule.sort,
			:errors   => workshop_errors,
			:warnings => workshop_warnings,
			:conflict_score => conflicts,
			:error_count => errors
		}
	end

	def get_workshop(workshop, workshops, events)
		workshop[:workshop] ? workshops[workshop[:workshop]] : (events[workshop[:event]] || :event)
	end

	def workshop_classes(workshop, show_interest)
		classes = [workshop.is_a?(Workshop) ? :workshop : workshop.event_type]
		if show_interest && workshop.is_a?(Workshop) && current_user && WorkshopInterest.where(:user_id => current_user.id)
			if workshop.interested?(current_user) || workshop.facilitator?(current_user)
				classes << 'interested'
			else
				classes << 'not-interested'
			end
		end
		
		return classes
	end

	def schedule_start_and_end_times(day_part, day_parts, day_schedule)
		start_time = [day_parts[day_parts.keys[day_part]], day_schedule[:start_time]].max
		end_time = [day_parts[day_parts.keys[day_part + 1]] || 24, day_schedule[:end_time]].min

		min_time = nil
		max_time = nil

		day_schedule[:locations].each do |location, location_schedule|
			location_schedule.each do |hour, workshop|
				t_start = hour
				t_end = hour + workshop[:span]
				if t_start >= start_time && t_end <= end_time
					min_time = [min_time || 24, t_start].min
					max_time = [max_time || 0, t_end].max
				end
			end
		end

		return nil unless min_time.present? && max_time.present?

		[min_time || 0, max_time || 24]
	end
end
