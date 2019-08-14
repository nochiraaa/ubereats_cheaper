require 'selenium-webdriver'
require 'slack-notifier'
require 'pry'

notification_type = ARGV[0] || 'mac'
postal_code = ARGV[1] || '107-0062'
want_price = (ARGV[2] || 1000).to_i
exit if want_price.to_i == 0
restaurant_url = ARGV[3] || 'https://www.ubereats.com/ja-JP/tokyo/food-delivery/%E3%82%B7-%E3%82%A2%E3%83%AC%E3%82%A4-%E6%B8%8B%E8%B0%B7246%E5%BA%97-the-alley-shibuya-246/C7X1V9lWQ5KIoPq7YYLc4A/'
slack_webhook_url = ARGV[4] || 'https://hooks.slack.com/services/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' if notification_type == "slack"

ua = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36'
# options_args = { args: ['headless', 'disable-gpu', 'no-sandbox', 'disable-setuid-sandbox', 'disable-gpu', "user-agent=#{ua}"] }
options_args = { args: ['disable-gpu', 'no-sandbox', 'disable-setuid-sandbox', 'disable-gpu', "user-agent=#{ua}"] }

#(Selenium 4 & Chrome <75)の記法
options = Selenium::WebDriver::Chrome::Options.new(options: options_args)
driver = Selenium::WebDriver.for :chrome, options: options


#下記chrome操作
driver.navigate.to 'https://www.ubereats.com/ja-JP/tokyo/'

sleep 5

form_input = driver.find_element(:xpath, '//*[@id="wrapper"]/div/div[1]/div/div/div/div/div[2]/div/div/div/input') 
form_input.send_keys(postal_code)

sleep 2

address_list = driver.find_element(:xpath, '//*[@id="wrapper"]/div/div[1]/div/div/div/div/div[2]/div/div/ul') 
address_list_first = driver.find_element(:xpath, '//*[@id="wrapper"]/div/div[1]/div/div/div/div/div[2]/div/div/ul/button[1]') 
address_list_first.click

sleep 2


#1時間でタイムアウト
12.times do 
	driver.navigate.to restaurant_url
	sleep 5
	delivery_fee = driver.find_element(:xpath, '//*[@id="wrapper"]/div[2]/div/div/div/div[2]/div/div/div/div[5]/div').text.match(/[0-9]+/)[0].to_i
	restautant_title = driver.find_element(:xpath, '//*[@id="wrapper"]/div[2]/div/div/div/div[2]/h1').text

	if delivery_fee <= want_price
		text = "#{restautant_title}の配送手数料は#{delivery_fee}円だ！安いで！！頼むなら今や！"
		
		if notification_type == "slack"
			notifier = Slack::Notifier.new(slack_webhook_url)
			notifier.post text: text
		elsif notification_type == "mac"
			system("osascript -e 'display notification \"#{text}\" with title \"UBEREATS CHEAPER\" sound name \"Ping\"'")
		end

		break
	else
		puts "#{restautant_title}の配送手数料は#{delivery_fee}ですね・・・"
		sleep 300
	end
end
