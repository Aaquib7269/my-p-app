# require 'csv'

# # Country.destroy_all
# # State.destroy_all
# # City.destroy_all

# countries = File.read("#{Rails.root}/lib/countries.csv")
# states = File.read("#{Rails.root}/lib/states.csv")
# cities = File.read("#{Rails.root}/lib/cities.csv")

# countries_csv = CSV.parse(countries)
# states_csv = CSV.parse(states)
# cities_csv = CSV.parse(cities)

# countries_csv.each do |row|
# 	Country.find_or_create_by(:name => row[2].strip.gsub("'",''), :default_id => row[0], :shortcode => row[1].strip.gsub("'",''))
# end

# states_csv.each do |row|
# 	State.find_or_create_by(:name => row[1].strip.gsub("'",''), :default_id => row[0], :country => Country.find_by(:default_id => row[2]))
# end

# cities_csv.each do |row|
# 	City.find_or_create_by(:name => row[1].strip.gsub("'",''), :default_id => row[0], :state => State.where(:default_id => row[2].strip.to_i).count == 0 ? nil : State.find_by(:default_id => row[2].strip.to_i))
# end

dev_ios_app = Rpush::Apns::App.new
dev_ios_app.name = "dev_ios_app"
dev_ios_app.certificate = File.read("#{Rails.root}/public/certificates/dev.pem")
dev_ios_app.environment = "sandbox"
dev_ios_app.connections = 1
dev_ios_app.save!

prod_ios_app = Rpush::Apns::App.new
prod_ios_app.name = "prod_ios_app"
prod_ios_app.certificate = File.read("#{Rails.root}/public/certificates/prod.pem")
prod_ios_app.environment = "production"
prod_ios_app.connections = 1
prod_ios_app.save!

# GCM-KEY AIzaSyC7z7j42CVZrzshPZ_wo1LOjd613-TO7_Y
# GCM-Sender-ID 1061861855857


# /usr/lib64/httpd/modules/mod_h264_streaming.so