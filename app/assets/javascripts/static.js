whiteTurn = true;
blackTurn = false;
noSelectedPiece = true;
mode = false;

  document.addEventListener("turbolinks:load", function() {
    $('.checkers-board').hide();
    $('.turn-board').hide();
    $('.undo-button').hide();

    $('.play-2p-button').click(function() {
      mode = "2p"
      $('.mode-picker').hide();
      $('.checkers-board').show();
      $('.turn-board').show();
      $('.undo-button').show();
    })

    $('.play-ai-button').click(function() {
      mode = "ai"
      $('.mode-picker').hide();
      $('.checkers-board').show();
      $('.turn-board').show();
      $('.undo-button').show();
    })

    $('.undo-button').click(function() {
      var old_board = $(".old-board").data('board');
      $.ajax({
        type: "GET",
        url: "/undo",
        data: { board: old_board },
        dataType: 'script'
      });
    })


      function addSuggestionPieces() {
        if (mode == "2p") {
          if ((whiteTurn) && (this.id.includes('W')) && (noSelectedPiece)) {
            noSelectedPiece = false;
            $(this).removeClass('checker-piece');
            $(this).addClass('selected-piece');
            var board = $(".checkers-board").data('board');
            var isKing = (this.classList.contains("king-piece"))
            $.ajax({
              type: "GET",
              url: "/",
              data: { mode: mode, piece: this.id, board: board, king: isKing },
              dataType: 'script'
            });
          }
          else if ((blackTurn) && (this.id.includes('B')) && (noSelectedPiece)) {
            noSelectedPiece = false;
            $(this).removeClass('checker-piece');
            $(this).addClass('selected-piece');
            var board = $(".checkers-board").data('board');
            var isKing = (this.classList.contains("king-piece"))
            $.ajax({
              type: "GET",
              url: "/",
              data: { mode: mode, piece: this.id, board: board, king: isKing },
              dataType: 'script'
            });
          }
        }

        else if (mode == "ai") {
          if ((whiteTurn) && (this.id.includes('W')) && (noSelectedPiece)) {
            noSelectedPiece = false;
            $(this).removeClass('checker-piece');
            $(this).addClass('selected-piece');
            var board = $(".checkers-board").data('board');
            var isKing = (this.classList.contains("king-piece"))
            $.ajax({
              type: "GET",
              url: "/",
              data: { mode: mode, piece: this.id, board: board, king: isKing },
              dataType: 'script'
            });
          }
        }
      }

      $(document).on('click', '.checker-piece', addSuggestionPieces)


      $(document).on('click', '.suggestion-piece', function () {
        noSelectedPiece = true;
        var board = $(".checkers-board").data('board');
        if (this.classList.contains("will-eat")) {
          var eatingMove = this.id
          $.ajax({
            type: "GET",
            url: "/complete_move",
            data: { mode: mode, newLoc: this.id, oldLoc: $(".selected-piece")[0].id, eatenPiece: $('.eaten-piece-' + eatingMove)[0].id, board: board },
            dataType: 'script'
          });
        }
        else {
          $.ajax({
            type: "GET",
            url: "/complete_move",
            data: { mode: mode, newLoc: this.id, oldLoc: $(".selected-piece")[0].id, board: board },
            format: 'js'
          });
        }
      })

      $(document).on('click', '.selected-piece', function () {
        noSelectedPiece = true;
        $('.suggestion-piece').remove();
        $(this).removeClass('selected-piece');
        $(this).addClass('checker-piece');
      })


  })
