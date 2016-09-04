module StaticHelper
  def full_name(player:)
    if player == "B"
      return "Black"
    else
      return "White"
    end
  end
end
