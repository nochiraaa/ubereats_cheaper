# frozen_string_literal: true

require 'selenium-webdriver'
require 'slack-notifier'
require 'pry'

# define methods
def exit_with_error(text)
	puts text
	exit
end

def cant_order_because_far_from_area?(driver)
	#配達エリアが遠い
	driver.find_element(:xpath, '//*[@id="wrapper"]/div[2]/div/div/div[3]/div/div')
	return  true
	rescue => error
		return false
end

def cant_order_because_anything?(driver)
	#現在注文できない
	driver.find_element(:xpath, '//*[@id="wrapper"]/div[2]/div/div/div[3]/div')
	return  true
	rescue => error
		return false
end

def catch_cant_order(driver)
  exit_with_error('配達エリアの対象外なようです・・・。') if cant_order_because_far_from_area?(driver)
  exit_with_error('現在は利用不可能なようです・・・。') if cant_order_because_anything?(driver)
end

def send_notification(text, notification_type, slack_webhook_url = nil)
	case notification_type

	when "mac" then
		system("osascript -e 'display notification \"#{text}\" with title \"UberEATS CHEAPER\" sound name \"Ping\"'")
	when "slack" then
		Slack::Notifier.new(slack_webhook_url).post text: text
	else
		system("osascript -e 'display notification \"#{text}\" with title \"UberEATS CHEAPER\" sound name \"Ping\"'")
	end
end

#初期値設定
notification_type = ARGV[0] || 'mac'
puts_error_message('"slack" or "mac"を入力して下さい') if nil == (notification_type =~ /\A(slack|mac)+\z/)
postal_code = ARGV[1] || '1070062'
want_price = ARGV[2] || 1000
puts_error_message('希望配送手数料は数字で入力してください。') if nil == (want_price =~ /\A[0-9]+\z/)
want_price = want_price.to_i
puts_error_message('希望配送手数料は260円以上で入力してください。') if want_price < 260
restaurant_url = ARGV[3] || 'https://www.ubereats.com/ja-JP/tokyo/food-delivery/%E3%82%B7-%E3%82%A2%E3%83%AC%E3%82%A4-%E6%B8%8B%E8%B0%B7246%E5%BA%97-the-alley-shibuya-246/C7X1V9lWQ5KIoPq7YYLc4A/'
slack_webhook_url = ARGV[4] if notification_type == 'slack'
puts_error_message('slackのwebhook urlが引数に設定されていません。') if notification_type == 'slack' if slack_webhook_url.nil?


# 郵便番号から住所候補を取得する
uri = URI.parse('https://www.ubereats.com/api/getLocationAutocompleteV1?localeCode=ja-JP')
request = Net::HTTP::Post.new(uri)
request['Accept-Language'] = 'ja,en-US;q=0.9,en;q=0.8"'
request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3'
request['query'] = "〒#{postal_code}"
request['x-csrf-token'] = 'x'
req_options = {
  use_ssl: uri.scheme == 'https',
}
response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end


if response.body
	# データを取得する
	address_data = response.body
else
	# error処理
end



# latitudeとlongitudeを取得する
uri = URI.parse('https://www.ubereats.com/api/getLocationDetailsV1?localeCode=ja-JP')
request = Net::HTTP::Post.new(uri)
request['Accept-Language'] = 'ja,en-US;q=0.9,en;q=0.8"'
request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3'
request['query'] = "〒#{postal_code}"
request['x-csrf-token'] = 'x'
request ['address_data'] = address_data
req_options = {
  use_ssl: uri.scheme == 'https',
}
response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end


if response.body
	# データを取得する
	address_data2 = response.body
	latitude = address_data['latitude']
	longitude = address_data['longitude']
else
	# error処理
end



# latitudeとlongitudeを取得する
uri = URI.parse('https://www.ubereats.com/api/getLocationDetailsV1?localeCode=ja-JP')
request = Net::HTTP::Post.new(uri)
request['Accept-Language'] = 'ja,en-US;q=0.9,en;q=0.8"'
request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3'
request["Cookie"] = "uev2.loc={%22address%22:{%22address1%22:%22%22%2C%22address2%22:%22%22%2C%22aptOrSuite%22:%22%22%2C%22city%22:%22%22%2C%22country%22:%22%22%2C%22eaterFormattedAddress%22:%22%22%2C%22postalCode%22:%22%22%2C%22region%22:%22%22%2C%22subtitle%22:%22%22%2C%22title%22:%22%22%2C%22uuid%22:%22%22}%2C%22latitude%22:#{latitude}%2C%22longitude%22:#{longitude}%2C%22reference%22:%22%22%2C%22referenceType%22:%22%22%2C%22type%22:%22%22}"
req_options = {
  use_ssl: uri.scheme == 'https',
}
response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end


if response.body
	# データを取得する
	html_data = response.body
	restautant_title = html_data['restautant_title_h2']
	delivery_fee = html_data['delivery_fee']
	if html_data['delivery_fee'] <= want_price
		text = "#{restautant_title}の配送手数料は#{delivery_fee}円だ！安いで！！頼むなら今や！"	
		send_notification(text, notification_type, slack_webhook_url)
		break
	else
		puts "#{restautant_title}の配送手数料は#{delivery_fee}ですね・・・。5分後に再チェックします。"
		sleep 300
	end
else
	# error処理
end

