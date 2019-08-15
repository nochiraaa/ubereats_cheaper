# frozen_string_literal: true

require 'selenium-webdriver'
require 'slack-notifier'

WAIT_TIME = 2
PROGRAM_TIME_OUT = 2
UBEREATS_TOP_URL = 'https://www.ubereats.com/ja-JP/tokyo/'
UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36'
DEFAULT_ERROR_MESSAGE = '原因不明のエラーです。'

def exit_with_error(text = DEFAULT_ERROR_MESSAGE)
  puts text
  exit 1
end

def order_available?(driver)
  driver.find_element(:css, '#wrapper div.az.b0.b1.d7.d8.b4')
  false
rescue StandardError
  true
end

def send_notification(text, notification_type, slack_webhook_url = nil)
  if notification_type == 'slack'
    Slack::Notifier.new(slack_webhook_url).post text: text
  else
    system("osascript -e 'display notification \"#{text}\" with title \"UberEATS CHEAPER\" sound name \"Ping\"'")
  end
end

# 初期値設定
notification_type = ARGV[0] || 'mac'
if notification_type.match(/\A(slack|mac)+\z/).nil?
  exit_with_error('"slack" or "mac"を入力して下さい')
end
postal_code = ARGV[1] || '1070062'
want_price = ARGV[2] || 1000
exit_with_error('希望配送手数料は数字で入力してください。') if want_price.to_s.match(/\A[0-9]+\z/).nil?
want_price = want_price.to_i
exit_with_error('希望配送手数料は260円以上で入力してください。') if want_price < 260
restaurant_url = ARGV[3] || 'https://www.ubereats.com/ja-JP/tokyo/food-delivery/%E3%82%B7-%E3%82%A2%E3%83%AC%E3%82%A4-%E6%B8%8B%E8%B0%B7246%E5%BA%97-the-alley-shibuya-246/C7X1V9lWQ5KIoPq7YYLc4A/'
slack_webhook_url = ARGV[4] if notification_type == 'slack'
if notification_type == 'slack' && slack_webhook_url.nil?
  exit_with_error('slackのwebhook urlが引数に設定されていません。')
end
recall_wait_time = 300

# (Selenium 4 & Chrome <75)の記法
ua = UA
options_args = { args: ['headless', 'disable-gpu', 'no-sandbox', 'disable-setuid-sandbox', 'disable-gpu', "user-agent=#{ua}"] }
options = Selenium::WebDriver::Chrome::Options.new(options: options_args)
driver = Selenium::WebDriver.for :chrome, options: options
driver.manage.timeouts.implicit_wait = 2 # タイムアウトの秒数を設定

driver.navigate.to UBEREATS_TOP_URL
sleep WAIT_TIME

# お届け先を設定
begin
  form_input = driver.find_element(:xpath, '//*[@id="wrapper"]/div/div[1]/div/div/div/div/div[2]/div/div/div/input')
  form_input.send_keys(postal_code)
  sleep WAIT_TIME
rescue Selenium::WebDriver::Error::NoSuchElementError
  exit_with_error('郵便番号を入力するフォームが見つかりませんでした。ネットワーク速度が遅いかもしれません。')
rescue StandardError
  exit_with_error
end

begin
  address_list_first = driver.find_element(:xpath, '//*[@id="wrapper"]/div/div[1]/div/div/div/div/div[2]/div/div/ul/button[1]')
  address_list_first.click
  sleep WAIT_TIME
rescue Selenium::WebDriver::Error::NoSuchElementError
  exit_with_error('郵便番号から導かれる住所が見つかりませんでした。ネットワーク速度が遅いかもしれません。もしくは郵便番号が正しくありません。')
rescue StandardError
  exit_with_error
end

12.times do # 1時間でタイムアウト
  driver.navigate.to restaurant_url

  unless order_available?(driver)
    exit_with_error(driver.find_element(:css, '#wrapper div.az.b0.b1.d7.d8.b4').text) 
  end

  begin
    delivery_fee = driver.find_element(:xpath, '//*[@id="wrapper"]/div[2]/div/div/div/div[2]/div/div/div/div[5]/div').text.match(/[0-9]+/)[0].to_i
    restautant_title = driver.find_element(:css, 'h1').text
  rescue Selenium::WebDriver::Error::NoSuchElementError
    exit_with_error('配送手数料もしくはレストラン名が見つかりませんでした。ネットワーク速度が遅いかもしれません。')
  rescue StandardError
    exit_with_error
  end

  if delivery_fee <= want_price
    text = "#{restautant_title}の配送手数料は#{delivery_fee}円だ！安いで！！頼むなら今や！"
    send_notification(text, notification_type, slack_webhook_url)
    break
  end

  puts "#{restautant_title}の配送手数料は#{delivery_fee}ですね・・・。5分後に再チェックします。"
  sleep recall_wait_time
end
