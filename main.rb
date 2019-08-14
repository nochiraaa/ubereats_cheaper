require 'selenium-webdriver'
require 'slack-notifier'
require 'pry'

# define methods
def puts_error_message(text)
	puts text
	exit
end

def is_cant_order_because_far_from_area?(driver)
	#配達エリアが遠い
	begin
		driver.find_element(:xpath, '//*[@id="wrapper"]/div[2]/div/div/div[3]/div/div')
		puts_error_message('配達エリアの対象外なようです・・・。')	
	rescue Selenium::WebDriver::Error::NoSuchElementError
		return true
	rescue => error
		puts_error_message('原因不明のエラーです。')
	end
end

def is_cant_order_because_anything?(driver)
	#現在注文できない
	begin
		driver.find_element(:xpath, '//*[@id="wrapper"]/div[2]/div/div/div[3]/div')
		puts_error_message('現在は利用不可能なようです・・・。')	
	rescue Selenium::WebDriver::Error::NoSuchElementError
		return true	
	rescue => error
		puts_error_message('原因不明のエラーです。')
	end
end

def catch_cant_order(driver)
	is_cant_order_because_far_from_area?(driver)
	is_cant_order_because_anything?(driver)
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
puts_error_message("'slack' or 'mac'を入力して下さい") if nil == (notification_type =~ /\A(slack|mac)+\z/)
postal_code = ARGV[1] || '1070062'
want_price = ARGV[2] || 1000
puts_error_message("希望配送手数料は数字で入力してください。") if nil == (want_price =~ /\A[0-9]+\z/)
want_price = want_price.to_i
puts_error_message("希望配送手数料は260円以上で入力してください。") if want_price < 260
restaurant_url = ARGV[3] || 'https://www.ubereats.com/ja-JP/tokyo/food-delivery/%E3%82%B7-%E3%82%A2%E3%83%AC%E3%82%A4-%E6%B8%8B%E8%B0%B7246%E5%BA%97-the-alley-shibuya-246/C7X1V9lWQ5KIoPq7YYLc4A/'
slack_webhook_url = ARGV[4] if notification_type == "slack"
puts_error_message("slackのwebhook urlが引数に設定されていません。") if notification_type == "slack" if slack_webhook_url.nil?

#(Selenium 4 & Chrome <75)の記法
ua = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36'
options_args = { args: ['disable-gpu', 'no-sandbox', 'disable-setuid-sandbox', 'disable-gpu', "user-agent=#{ua}"] }
options = Selenium::WebDriver::Chrome::Options.new(options: options_args)
driver = Selenium::WebDriver.for :chrome, options: options
driver.manage.timeouts.implicit_wait = 2 # タイムアウトの秒数を設定


# seleniumの処理
driver.navigate.to 'https://www.ubereats.com/ja-JP/tokyo/'
sleep 2

#お届け先を設定
begin
	form_input = driver.find_element(:xpath, '//*[@id="wrapper"]/div/div[1]/div/div/div/div/div[2]/div/div/div/input') 
	form_input.send_keys(postal_code)
	sleep 2
rescue Selenium::WebDriver::Error::NoSuchElementError
	puts_error_message('郵便番号を入力するフォームが見つかりませんでした。ネットワーク速度が遅いかもしれません。')
rescue => error
	puts_error_message('原因不明のエラーです。')
end

begin
	address_list_first = driver.find_element(:xpath, '//*[@id="wrapper"]/div/div[1]/div/div/div/div/div[2]/div/div/ul/button[1]') 
	address_list_first.click
	sleep 2
rescue Selenium::WebDriver::Error::NoSuchElementError
	puts_error_message('郵便番号から導かれる住所が見つかりませんでした。ネットワーク速度が遅いかもしれません。もしくは郵便番号が正しくありません。')
rescue => error
	puts_error_message('原因不明のエラーです。')
end

#1時間でタイムアウト
12.times do 
	driver.navigate.to restaurant_url

	catch_cant_order(driver)

	begin
		delivery_fee = driver.find_element(:xpath, '//*[@id="wrapper"]/div[2]/div/div/div/div[2]/div/div/div/div[5]/div').text.match(/[0-9]+/)[0].to_i
		restautant_title = driver.find_element(:xpath, '//*[@id="wrapper"]/div[2]/div/div/div/div[2]/h1').text
	rescue Selenium::WebDriver::Error::NoSuchElementError
		puts_error_message('配送手数料もしくはレストラン名が見つかりませんでした。ネットワーク速度が遅いかもしれません。')
	rescue => error
		puts_error_message('原因不明のエラーです。')
	end	

	if delivery_fee <= want_price
		text = "#{restautant_title}の配送手数料は#{delivery_fee}円だ！安いで！！頼むなら今や！"	
		send_notification(text, notification_type, slack_webhook_url)
		break
	else
		puts "#{restautant_title}の配送手数料は#{delivery_fee}ですね・・・。5分後に再チェックします。"
		sleep 300
	end
end