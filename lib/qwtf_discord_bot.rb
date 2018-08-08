require "qwtf_discord_bot/version"
require "discordrb"
require 'active_support/core_ext/string'

require "qstat_request"
require "player"
require "team"
require "emoji"

class QwtfDiscordBot
  TOKEN = ENV["QWTF_DISCORD_BOT_TOKEN"].strip
  CLIENT_ID = ENV["QWTF_DISCORD_BOT_CLIENT_ID"].strip
  CHANNEL_ID = ENV["QWTF_DISCORD_BOT_CHANNEL_ID"].strip
  HOSTNAME = "fortressone.ga"

  class Server
    def initialize
      @bot ||= Discordrb::Commands::CommandBot.new(
        token: TOKEN,
        client_id: CLIENT_ID,
        prefix: "!"
      )

      @bot.command :server do |event|
        QstatRequest.new(HOSTNAME).output
      end
    end

    def run
      @bot.run
    end
  end

  class Watcher
    THIRTY_SECONDS = 30
    TEN_MINUTES = 10 * 60

    def initialize
      @history = {}
    end

    def run
      every(THIRTY_SECONDS) do
        request = QstatRequest.new(HOSTNAME)
        numplayers = request.numplayers

        if request.players
          player_names = request.players.map(&:name)

          player_names.each do |name|
            report_joined(name, numplayers) unless seen_recently?(name)
            @history[name] = Time.now
          end
        end
      end
    end

    private

      def report_joined(name, numplayers)
        number_of_other_players = numplayers - 1

        Discordrb::API::Channel.create_message(
          "Bot #{TOKEN}",
          CHANNEL_ID,
          "**#{name}** has joined **#{number_of_other_players}** " \
          "#{"other player".pluralize(number_of_other_players)} on **#{HOSTNAME}**"
        )
      end

      def seen_recently?(name)
        last_seen = @history[name]
        last_seen && (Time.now - last_seen < TEN_MINUTES)
      end

      def every(n)
        loop do
          before = Time.now
          yield
          interval = n-(Time.now-before)
          sleep(interval) if interval > 0
        end
      end
  end
end
