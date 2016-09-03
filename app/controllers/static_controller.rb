class StaticController < ApplicationController

  def index
    respond_to do |format|

	  	format.html {
        generate_checkers_board
	  	}

	  	format.js {
        @board = retrieve_board(board: params[:board])
        store_current_location
        check_valid_moves(type: @type, col: @col, row: @row)
      }
  	end
  end


  def complete_move
    respond_to do |format|
      format.js {
        store_old_location
        store_new_location

        @old_board = []
        params[:board].each do |row_key, row_value|
          row_arr = []
          row_value.each do |cell_key, cell_value|
            row_arr << cell_value
          end
          @old_board << row_arr
        end

        update_board(board: params[:board])
        check_if_combo
        check_if_king
        if params[:mode] == "ai"
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

    render partial: "ai_move.js.erb"
  end

  #==============================================================================# ========================================================================
  #============================== Secondary methods ==============================# ========================================================================
  #==============================================================================# ========================================================================

  private

  def generate_checkers_board
    @board = Array.new(8) {Array.new(8) { |index| ["",""] }}

    # white_pawn = ["W", "pawn"]
    # black_pawn = ["B", "pawn"]
    # white_king = ["W", "king"]
    # black_king = ["B", "king"]

    @board.map!.with_index do |cell, row|
      cell.map!.with_index do |cell, col|
        putter = "B" if row == 0 and col%2 != 0
        putter = "B" if row == 1 and col%2 == 0
        putter = "B" if row == 2 and col%2 != 0
        putter = "W" if row == 5 and col%2 == 0
        putter = "W" if row == 6 and col%2 != 0
        putter = "W" if row == 7 and col%2 == 0
        if putter == "B" || putter == "W"
          rank = "pawn"
        else
          rank = ""
        end
        cell = [putter, rank]
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


  def store_old_location
    @old_piece = params[:oldLoc]
    @old_type = params[:oldLoc][0]
    @old_row = params[:oldLoc][1].to_i
    @old_col = params[:oldLoc][2].to_i
  end


  def store_new_location
    @new_piece = params[:newLoc]
    @new_type = params[:newLoc][0]
    @new_row = params[:newLoc][1].to_i
    @new_col = params[:newLoc][2].to_i
  end


  def update_board(board:)
    @board = retrieve_board(board: board)
    piece = @board[@old_row][@old_col]
    @board[@old_row][@old_col] = ["", ""]
    @board[@new_row][@new_col] = piece
    if params[:eatenPiece]
      @board[params[:eatenPiece][1].to_i][params[:eatenPiece][2].to_i] = ["", ""]
    end
  end


  def store_current_location
    @piece = params[:piece]
    @type = params[:piece][0]
    @row = params[:piece][1].to_i
    @col = params[:piece][2].to_i
  end


  def check_valid_moves(type:, col:, row:)
    @complete_move_array = get_complete_move_array(type: type, col: col, row: row)
    @valid_move = @complete_move_array[0]
    @will_eat = @complete_move_array[1]
    @eaten_piece = @complete_move_array[2]
  end


  def get_complete_move_array(type:, col:, row:)
    left = col - 1
    double_left = col - 2
    right = col + 1
    double_right = col + 2

    if type == "W"
      enemy = "B"
      front = row - 1
      double_front = row - 2
    else
      enemy = "W"
      front = row + 1
      double_front = row + 2
    end

    valid_move = []
    will_eat = []
    eaten_piece = []

    # right movement
    if front <= 7 && front >= 0 && right <= 7
      if double_right <= 7 && double_front <= 7 && @board[front][right][0] == enemy && @board[double_front][double_right][0] == ""
        valid_move << type + (double_front).to_s + (double_right).to_s
        will_eat << true
        eaten_piece << enemy + front.to_s + right.to_s
      elsif @board[front][right][0] == ""
        valid_move << type + (front).to_s + (right).to_s
        eaten_piece << false
        will_eat << false
      end
    end

    # left movement
    if front <= 7 && front >= 0 && left >= 0
      if double_left >= 0 && double_front <= 7 && @board[front][left][0] == enemy && @board[double_front][double_left][0] == ""
        valid_move << type + (double_front).to_s + (double_left).to_s
        will_eat << true
        eaten_piece << enemy + front.to_s + left.to_s
      elsif @board[front][left][0] == ""
        valid_move << type + front.to_s + left.to_s
        eaten_piece << false
        will_eat << false
      end
    end

    # king backward movement, left and right
    if @board[row][col][1] == "king"

      if type == "W"
        back = row + 1
        double_back = row + 2
      else
        back = row - 1
        double_back = row - 2
      end

      if back <= 7 && back >= 0 && right <= 7
        if double_right <= 7 && double_back <= 7 && @board[back][right][0] == enemy && @board[double_back][double_right][0] == ""
          valid_move << type + (double_back).to_s + (double_right).to_s
          will_eat << true
          eaten_piece << enemy + back.to_s + right.to_s
        elsif @board[back][right][0] == ""
          valid_move << type + (back).to_s + (right).to_s
          will_eat << false
          eaten_piece << false
        end
      end

      if back <= 7 && back >= 0 && left >= 0
        if double_left >= 0 && double_back <= 7 && @board[back][left][0] == enemy && @board[double_back][double_left][0] == ""
          valid_move << type + (double_back).to_s + (double_left).to_s
          will_eat << true
          eaten_piece << enemy + back.to_s + left.to_s
        elsif @board[back][left][0] == ""
          valid_move << type + back.to_s + left.to_s
          will_eat << false
          eaten_piece << false
        end
      end
    end

    return [valid_move, will_eat, eaten_piece]
  end


  def check_if_combo
    @combo_move = false
    if params[:eatenPiece]
      @combo_valid_move = []
      @combo_eaten_piece = []
      @complete_combo_array = get_complete_move_array(type: @new_type, col: @new_col, row: @new_row)

      @complete_combo_array[2].each_with_index do |eaten_piece, index|
        if eaten_piece    # there is another piece to be eaten
          @combo_valid_move << @complete_combo_array[0][index]
          @combo_eaten_piece << @complete_combo_array[2][index]
          @combo_move = true
        end
      end
    end
  end


  def check_if_king
    if @new_type == "W" && @new_row == 0
      @board[@new_row][@new_col][1] = "king"
    elsif @new_type == "B" && @new_row == 7
      @board[@new_row][@new_col][1] = "king"
    end
  end

  #==============================================================================# ========================================================================
  #================================== AI logic ==================================# ========================================================================
  #==============================================================================# ========================================================================

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

    if winner == player
      return point = 1000
    elsif winner == enemy
      return point = -1000
    end

    point = 0
    board.each do |row|
      row.each do |piece|
        if piece.include?(player) && piece.include?("king")
          point += 3
        elsif piece.include? player
          point += 1
        elsif piece.include?(enemy) && piece.include?("king")
          point -= 3
        elsif piece.include? enemy
          point -= 1
        end
      end
    end
    return point
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
