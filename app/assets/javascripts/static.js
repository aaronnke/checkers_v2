noSelectedPiece = true;
blackTurn = true;
whiteTurn = false;

  document.addEventListener("turbolinks:load", function() {
    $('.turn-board').hide();
    $('.undo-button').hide();
    $('.side-picker').hide();

    $('.play-2p-button').click(function() {
      mode = "2p";
      $('.mode-picker').hide();
      $('.turn-board').show();
      $('.undo-button').show();
    })


    $('.play-ai-button').click(function() {
      mode = "ai";
      $('.mode-picker').remove();
      $('.side-picker').show();
    })


    $('.black-side-button').click(function() {
      player = "B";
      $('.side-picker').remove();
      $('.turn-board').show();
      $('.undo-button').show();
      $.ajax({
        type: "GET",
        url: "/",
        data: { player: player, mode: mode },
        dataType: 'script'
      });
    })

    $('.white-side-button').click(function() {
      player = "W";
      $('.side-picker').remove();
      $('.turn-board').show();
      $('.undo-button').show();

      $.ajax({
        type: "GET",
        url: "/",
        data: { player: player, mode: mode },
        dataType: 'script'
      });
    })


    $('.undo-button').click(function() {
      var old_board = $(".old-board").data('board');
      $.ajax({
        type: "GET",
        url: "/undo",
        data: { board: old_board, player: player },
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
            $.ajax({
              type: "GET",
              url: "/",
              data: { mode: mode, piece: this.id, board: board},
              dataType: 'script'
            });
          }
          else if ((blackTurn) && (this.id.includes('B')) && (noSelectedPiece)) {
            noSelectedPiece = false;
            $(this).removeClass('checker-piece');
            $(this).addClass('selected-piece');
            var board = $(".checkers-board").data('board');
            $.ajax({
              type: "GET",
              url: "/",
              data: { mode: mode, piece: this.id, board: board},
              dataType: 'script'
            });
          }
        }

        else if (mode == "ai") {
          if (((whiteTurn) && (this.id.includes('W')) && (noSelectedPiece)) || ((blackTurn) && (this.id.includes('B')) && (noSelectedPiece))) {
            noSelectedPiece = false;
            $(this).removeClass('checker-piece');
            $(this).addClass('selected-piece');
            var board = $(".checkers-board").data('board');

            $.ajax({
              type: "GET",
              url: "/check_move",
              data: { mode: mode, piece: this.id, board: board},
              dataType: 'script'
            });

          }
        }
      }

      $(document).on('click', '.checker-piece', addSuggestionPieces)

      $(document).on('click', '.suggestion-piece', function () {
        noSelectedPiece = true;
        var board = $(".checkers-board").data('board');
        $.ajax({
          type: "GET",
          url: "/complete_move",
          data: { mode: mode, move: this.id, board: board, player: player },
          format: 'js'
        });
      })

      $(document).on('click', '.selected-piece', function () {
        noSelectedPiece = true;
        $('.suggestion-piece').remove();
        $(this).removeClass('selected-piece');
        $(this).addClass('checker-piece');
      })


  })
