FactoryGirl.define do
	factory :upcoming_conference, :class => 'Conference' do
		title				'My Bike!Bike!'
		slug				'MyBikeBike'
		info 				'Curabitur non nulla sit amet nisl tempus convallis quis ac lectus.'
		poster 				'poster.jpg'
		cover 				'cover.jpg'
		registration_open	false
		start_date 			Date.today - 30.days
		end_date 			Date.today - 26.days
		conference_type_id	(ConferenceType.find_by(:slug => 'bikebike') || ConferenceType.create(:slug => 'bikebike')).id
	end

	factory :org, :class => 'Organization' do
		name				'My Organization'
		info 				'Curabitur non nulla sit amet nisl tempus convallis quis ac lectus.'
		avatar 				'avatar.jpg'
		cover 				'cover.jpg'
	end
end

World(FactoryGirl::Syntax::Methods)