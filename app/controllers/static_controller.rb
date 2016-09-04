class StaticController < ApplicationController

  def index
    respond_to do |format|

	  	format.html {
        generate_checkers_board
	  	}

	  	format.js {
        @board = retrieve_board(board: params[:board])
        @player = params[:piece][0]
        @row = params[:piece][1].to_i
        @col = params[:piece][2].to_i
        @valid_moves = check_ai_piece_valid_moves(board: @board, player: @player, row: @row, col: @col)

        has_eating_move = false     # check if all valid moves has eating moves, if it does, delete all non-eating moves
        @valid_moves.each do |move|
          if (move[0][0].to_i - move[1][0].to_i).abs >= 2  # checks if move eats
            has_eating_move = true
          end
        end
        if has_eating_move
          @valid_moves.delete_if { |move| (move[0][0].to_i - move[1][0].to_i).abs < 2 }
        end

        ai_check_if_combo(board: @board, player: @player, base_arr: @valid_moves)
      }
  	end
  end


  def complete_move
    respond_to do |format|
      format.js {
        @board = retrieve_board(board: params[:board])
        @old_board = Marshal.load(Marshal.dump(@board))   # for undo move
        @player = params[:move][0]
        @old_row = params[:move][1]
        @old_col = params[:move][2]
        @row = params[:move][3]
        @col = params[:move][4]
        @valid_moves = ai_get_all_valid_moves(player: @player, board: @board)

        valid_move = []         # check if the selected move is valid (must eat)
        @valid_moves.each do |move|
          if move.last == @row + @col && move.first == @old_row + @old_col
            valid_move = move
          end
        end

        if valid_move.present?
          ai_move_piece(board: @board, move_arr: valid_move)
        else
          @error = true
        end

        @winner = game_ended?(board: @board, turn: "B")

        if params[:mode] == "ai" && !@winner
          @ai_move = true
        end
      }
    end
  end


  def undo
    respond_to do |format|
      format.js {
        @board = retrieve_board(board: params[:board])
        render partial: "undo.js.erb"
      }
    end
  end


  def ai_move
    @ai, @non_ai = "B", "W"
    @board = retrieve_board(board: params[:board])
    ai_minimax_search(max_depth: 3, board: @board, player: @ai)   # assigns an @choice variable to store the strongest move
    move = @choice    # redundant, but just to make clear
    ai_move_piece(board: @board, move_arr: move)    # updates @board with the move, which will be rendered

    @winner = game_ended?(board: @board, turn: @non_ai)
    @opponent_valid_moves = ai_get_all_valid_moves(player: @non_ai, board: @board)    # finds all valid moves for other player to check for must-eat move

    render partial: "ai_move.js.erb"
  end

  #==============================================================================# ========================================================================
  #============================== Secondary methods ==============================# ========================================================================
  #==============================================================================# ========================================================================

  private

  def generate_checkers_board
    @board = Array.new(8) {Array.new(8) { |index| ["",""] }}

    white_pawn = ["W", "pawn"]
    black_pawn = ["B", "pawn"]
    white_king = ["W", "king"]      # for testing purposes
    black_king = ["B", "king"]
    empty_cell = ["", ""]

    @board.map!.with_index do |cell, row|
      cell.map!.with_index do |cell, col|
        if (row%2 == 0 && col%8%2 != 0) || (row%2 != 0 && col%8%2 == 0)
          if row < 3
            cell = black_pawn
          elsif row > 4
            cell = white_pawn
          else
            cell = empty_cell
          end
        else
          cell = empty_cell
        end
      end
    end

  end


  def retrieve_board(board:)
    sanitized_board = []
    board.each do |row_key, row_value|
      row_arr = []
      row_value.each do |cell_key, cell_value|
        row_arr << cell_value
      end
      sanitized_board << row_arr
    end
    return sanitized_board
  end


  def ai_get_all_valid_moves(player:, board:)
    moves_arr = []

    board.each_with_index do |row, row_index|
      row.each_with_index do |cell, col_index|
        if cell.include? player
          temp_arr = check_ai_piece_valid_moves(board: board, player: player, col: col_index, row: row_index)
          temp_arr.each do |move|   # to flatten out the array
            moves_arr << move
          end
        end
      end
    end
    moves_arr.delete_if { |x| x.empty? }  # filter out pieces with no moves

    has_eating_move = false     # check if all valid moves has eating moves, if it does, delete all non-eating moves
    moves_arr.each do |move|
      if (move[0][0].to_i - move[1][0].to_i).abs >= 2  # checks if move eats
        has_eating_move = true
      end
    end
    if has_eating_move
      moves_arr.delete_if { |move| (move[0][0].to_i - move[1][0].to_i).abs < 2 }
    end

    ai_check_if_combo(player: player, board: board, base_arr: moves_arr) if moves_arr != [] && (moves_arr.first.first.first.to_i - moves_arr.first.last.first.to_i).abs == 2     # modifies and expands moves_arr if there are combo moves

    return moves_arr
  end



  def check_ai_piece_valid_moves(board:, player:, row:, col:)
    left = col - 1
    double_left = col - 2
    right = col + 1
    double_right = col + 2

    if player == "W"
      enemy = "B"
      front = row - 1
      double_front = row - 2
    else
      enemy = "W"
      front = row + 1
      double_front = row + 2
    end

    valid_moves = []   # nested array storing [old_pos, new_pos, new_pos#2...]

    # right movement
    if front <= 7 && front >= 0 && right <= 7
      if double_right <= 7 && double_front <= 7 && double_front >= 0 && board[front][right][0] == enemy && board[double_front][double_right][0] == ""
        valid_moves << [row.to_s + col.to_s, double_front.to_s + double_right.to_s]
      elsif board[front][right][0] == ""
        valid_moves << [row.to_s + col.to_s, front.to_s + right.to_s]
      end
    end

    # left movement
    if front <= 7 && front >= 0 && left >= 0
      if double_left >= 0 && double_front <= 7 && double_front >= 0 &&  board[front][left][0] == enemy && board[double_front][double_left][0] == ""
        valid_moves << [row.to_s + col.to_s, double_front.to_s + double_left.to_s]
      elsif board[front][left][0] == ""
        valid_moves << [row.to_s + col.to_s, front.to_s + left.to_s]
      end
    end

    # king backward movement, left and right
    if board[row][col][1] == "king"

      if player == "W"
        back = row + 1
        double_back = row + 2
      else
        back = row - 1
        double_back = row - 2
      end

      if back <= 7 && back >= 0 && right <= 7
        if double_right <= 7 && double_back <= 7 && double_back >= 0 && board[back][right][0] == enemy && board[double_back][double_right][0] == ""
          valid_moves << [row.to_s + col.to_s, double_back.to_s + double_right.to_s]
        elsif board[back][right][0] == ""
          valid_moves << [row.to_s + col.to_s, back.to_s + right.to_s]
        end
      end

      if back <= 7 && back >= 0 && left >= 0
        if double_left >= 0 && double_back <= 7 && double_back >= 0 && board[back][left][0] == enemy && board[double_back][double_left][0] == ""
          valid_moves << [row.to_s + col.to_s, double_back.to_s + double_left.to_s]
        elsif board[back][left][0] == ""
          valid_moves << [row.to_s + col.to_s, back.to_s + left.to_s]
        end
      end
    end

    return valid_moves
  end



  def ai_check_if_combo(board:, player:, base_arr:)
    return base_arr if (base_arr.first.first.first.to_i - base_arr.first.last.first.to_i).abs == 1
    base_arr.each_with_index do |move, index|
      combo = false
      row = move.last[0].to_i
      col = move.last[1].to_i

      left = col - 1
      double_left = col - 2
      right = col + 1
      double_right = col + 2

      if player == "W"
        enemy = "B"
        front = row - 1
        double_front = row - 2
      else
        enemy = "W"
        front = row + 1
        double_front = row + 2
      end

      if double_right <= 7 && double_front <= 7 && double_front >= 0 && board[front][right][0] == enemy && board[double_front][double_right][0] == "" && move.include?("#{double_front}#{double_right}") == false
        combo_move = move + [double_front.to_s + double_right.to_s]
        base_arr << combo_move
        combo = true
      end

      if double_left >= 0 && double_front <= 7 && double_front >= 0 && board[front][left][0] == enemy && board[double_front][double_left][0] == "" && move.include?("#{double_front}#{double_left}") == false
        combo_move = move + [double_front.to_s + double_left.to_s]
        base_arr << combo_move
        combo = true
      end

      if board[move.first.first.to_i][move.first.last.to_i][1] == "king"
        if player == "W"
          back = row + 1
          double_back = row + 2
        else
          back = row - 1
          double_back = row - 2
        end

        if double_right <= 7 && double_back <= 7 && double_back >= 0 && board[back][right][0] == enemy && board[double_back][double_right][0] == "" && move.include?("#{double_back}#{double_right}") == false
          combo_move = move + [double_back.to_s + double_right.to_s]
          base_arr << combo_move
          combo = true
        end

        if double_left >= 0 && double_back <= 7 && double_back >= 0 && board[back][left][0] == enemy && board[double_back][double_left][0] == "" && move.include?("#{double_back}#{double_left}") == false
          combo_move = move + [double_back.to_s + double_left.to_s]
          base_arr << combo_move
          combo = true
        end
      end

      base_arr.delete_at(index) if combo == true
    end

    return base_arr
  end



  def ai_move_piece(board:, move_arr:)    # move_arr ["00","22","44"]
    piece = board[move_arr.first.first.to_i][move_arr.first.last.to_i]
    move_arr.each_with_index do |move, index|
      next if index == 0
      old_row = move_arr[index - 1][0].to_i
      old_col = move_arr[index - 1][1].to_i
      new_row = move_arr[index][0].to_i
      new_col = move_arr[index][1].to_i

      # forward right eat
      if old_row - new_row == 2 && old_col - new_col == -2
        board[old_row - 1][old_col + 1] = ["",""]
      end
      # forward left eat
      if old_row - new_row == 2 && old_col - new_col == 2
        board[old_row - 1][old_col - 1] = ["",""]
      end
      # backward right eat
      if old_row - new_row == -2 && old_col - new_col == -2
        board[old_row + 1][old_col + 1] = ["",""]
      end
      # backward left eat
      if old_row - new_row == -2 && old_col - new_col == 2
        board[old_row + 1][old_col - 1] = ["",""]
      end

      board[old_row][old_col] = ["",""]
      board[new_row][new_col] = piece
    end

    ai_check_if_king(board: board, row: move_arr.last[0].to_i, col: move_arr.last[1].to_i)

  end



  def ai_check_if_king(board:, row:, col:)
    if board[row][col][0] == "B" && row == 7
      board[row][col][1] = "king"
    elsif board[row][col][0] == "W" && row == 0
      board[row][col][1] = "king"
    end
  end



  def ai_minimax_search(depth: 0, max_depth:, player:, board:)

    if depth >= max_depth || game_ended?(board: board, turn: player)
      return ai_evaluate_board(player: @ai, board: board)
    else
      depth += 1
      points = []   # array of points
      player == "B" ? enemy = "W" : enemy = "B"

      moves_arr = ai_get_all_valid_moves(board: board, player: player)

      moves_arr.each do |move|
        test_board = Marshal.load(Marshal.dump(board))
        ai_move_piece(board: test_board, move_arr: move)

        points << ai_minimax_search(depth: depth, max_depth: max_depth, player: enemy, board: test_board)
      end

      if player == @ai
        max_point_index = points.each_with_index.max.last
        @choice = moves_arr[max_point_index]
        return points[max_point_index]
      else
        min_point_index = points.each_with_index.min.last
        @choice = moves_arr[min_point_index]
        return points[min_point_index]
      end

    end

  end



  def ai_evaluate_board(player:, board:)
    player == "B" ? enemy = "W" : enemy = "B"
    winner = game_ended?(board: board, turn: player)

    if winner == "white"
      winner = "W"
    elsif winner == "black"
      winner = "B"
    end

    if winner == player
      return point = 1000
    elsif winner == enemy
      return point = -1000
    end

    pawn_value = 5.0
    king_value = 10.0
    neg_value = -1

    point = 0
    board.each_with_index do |row_arr, row_index|
      if row_index == 0 || row_index == 7
        row_value = 1.3
      elsif row_index == 1 || row_index == 6
        row_value = 1.2
      elsif row_index == 2 || row_index == 5
        row_value = 1.1
      else
        row_value = 1.0
      end

      row_arr.each_with_index do |piece, col_index|
        if piece.include?(player) && piece.include?("king")
          score = king_value*row_value
        elsif piece.include? player
          score = pawn_value*row_value
        elsif piece.include?(enemy) && piece.include?("king")
          score = neg_value*king_value*row_value
        elsif piece.include? enemy
          score = neg_value*pawn_value*row_value
        else
          score = 0
        end

        exposure = evaluate_exposure(player: piece.first, row: row_index, col: col_index, board: board) if piece.first.present?

        if exposure == "threatened"
          score /= 2
        elsif exposure == "defended"
          score *= 1.5
        end

        point += score
      end
    end
    return point
  end


  def evaluate_exposure(player:, row:, col:, board:)
    left = col - 1
    right = col + 1

    if player == "W"
      enemy = "B"
      front = row - 1
      back = row + 1
    else
      enemy = "W"
      front = row + 1
      back = row - 1
    end

    # front right enemy?
    if front <= 7 && front >= 0 && right <= 7 && board[front][right][0] == enemy
      if back <= 7 && back >= 0 && left >= 0 && board[back][left][0].empty?
        threatened = true
      elsif back >= 7 || back <= 0 || left <= 0 || board[back][left][0] == player
        defended = true
      end

    # front left enemy?
    elsif front <= 7 && front >= 0 && left >= 0 && board[front][left][0] == enemy
      if back <= 7 && back >= 0 && right <= 7 && board[back][right][0].empty?
        threatened = true
      elsif back >= 7 || back <= 0 || right >= 7 || board[back][right][0] == player
        defended = true
      end

    # back right enemy is king?
  elsif back <= 7 && back >= 0 && right <= 7 && board[back][right][0] == enemy && board[back][right][1] == "king"
      if front <= 7 && front >= 0 && left >= 0 && board[front][left][0].empty?
        threatened = true
      elsif front >= 7 || front <= 0 || left <= 0 || board[front][left][0] == player
        defended = true
      end

    # back left enemy is king?
    elsif back <= 7 && back >= 0 && left >= 0 && board[back][left][0] == enemy && board[back][left][1] == "king"
      if front <= 7 && front >= 0 && right <= 7 && board[front][right][0].empty?
        threatened = true
      elsif front >= 7 || front <= 0 || right >= 7 || board[front][right][0] == player
        defended = true
      end

    end

    if threatened                   # this way, threated takes precedence.
      exposure = "threatened"
    elsif defended
      exposure = "defended"
    else
      exposure = "neutral"
    end

    return exposure
  end



  def game_ended?(board:, turn:)     # returns the winner ("black"), or false
    white_present = false
    black_present = false
    board.each do |row|
      row.each do |piece|
        if piece.include?("W")
          white_present = true
        elsif piece.include?("B")
          black_present = true
        end
      end
    end
    if black_present && white_present
      white_moves_arr = ai_get_all_valid_moves(board: board, player: "W")
      black_moves_arr = ai_get_all_valid_moves(board: board, player: "B")
      if white_moves_arr.empty? && turn == "W"
        return "black"
      elsif black_moves_arr.empty? && turn == "B"
        return "white"
      else
        return false
      end
    else
      return "black" if black_present
      return "white" if white_present
    end
  end



end
