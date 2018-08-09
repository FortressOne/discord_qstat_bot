class QstatRequest
  def initialize(endpoint)
    @result = JSON.parse(%x[qstat -json -P -qws #{endpoint}]).first
  end

  def output
    <<~HEREDOC
      **#{address} | #{map} | #{numplayers}/#{maxplayers}**
      #{player_table}
    HEREDOC
  end

  def address
    @result["address"]
  end

  def map
    @result["map"]
  end

  def numplayers
    @result["numplayers"]
  end

  def maxplayers
    @result["maxplayers"]
  end

  def player_table
    players && players.sort_by { |player| player.team.number }.map(&:to_row).join("\n")
  end

  def players
    @result["players"] && @result["players"].map do |player_data|
      Player.new(player_data)
    end
  end
end
