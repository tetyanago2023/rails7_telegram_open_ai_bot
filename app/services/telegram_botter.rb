require 'telegram/bot'
require "openai"

class TelegramBotter

  def ask_openai(message)
    prompt = message.text.gsub('/question', '').strip

    open_ai_key = Rails.application.credentials.dig(:rail7_openai_secretkey)

    client = OpenAI::Client.new(access_token: open_ai_key)

    response = client.chat(
      parameters: {
        model: 'gpt-4o',
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
        # Limit the response to 1 sentence
        max_tokens: 50,
      }
    )

    response
  end

  def start_bot(token)
    Telegram::Bot::Client.run(token) do |bot|
      Rails.application.config.telegram_bot = bot
      bot.api.get_updates(offset: -1)

      bot.listen do |message|
        puts "Received message: #{message}"
        if message.text.start_with?('/question')
          puts "You asked a question in the chat with id: #{message.chat.id}"
          response = ask_openai(message)
          if response
            bot.api.send_message(chat_id: message.chat.id, text: response.dig("choices", 0, "message", "content") || "No response")
          else
            bot.api.send_message(chat_id: message.chat.id, text: 'Error processing your request')
          end
        end
      end
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
end
