class TelegramBotWorkerJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(token)
    puts "Starting bot..."
    Rails.logger.info "Starting bot..."

    telegram_bot = TelegramBotter.new
    telegram_bot.start_bot(token)
  end
end
