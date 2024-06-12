require 'telegram/bot'

Rails.application.config.after_initialize do
  puts "Running Telegram Bot Job!"
  TelegramBotWorkerJob.perform_async(Rails.application.credentials.dig(:telegram_bot))
end

Rails.application.config.after_initialize do
  token = Rails.application.credentials.dig(:telegram_bot)

  Telegram::Bot::Client.run(token) do |bot|
    Rails.application.config.telegram_bot = bot
    bot.api.get_updates(offset: -1)
  end
rescue Telegram::Bot::Exceptions::ResponseError => e
  Rails.logger.error e
  Rails.application.config.telegram_bot.stop
  Rails.application.config.telegram_bot.api.delete_webhook
end

Signal.trap("TERM") do
  puts "Shutting down bot..."
  Rails.application.config.telegram_bot.stop
  exit
end

Signal.trap("INT") do
  puts "Shutting down bot..."
  Rails.application.config.telegram_bot.stop
  exit
end
