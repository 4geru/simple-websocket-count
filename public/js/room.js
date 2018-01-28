var countBox = document.getElementById("count");
var turnBox = document.getElementById("turn");


// ボードの中に入っているか判定
limitBoard = (pos) => {
  return Math.min(<%= @board_size %>, Math.max(0, pos))
}

getBoard = (x, y) => {
  table = document.getElementsByTagName('table')[0]
  return table.getElementsByTagName('tr')[y].
    getElementsByTagName('td')[x]
}

insideBoard = (x,y) => {
  if(x >= <%= @board_size %> || y >= <%= @board_size %>)return false
  if(x < 0 || y < 0)return false
  return true
}

window.onload = function(){
  initializeBoard()
  checkBoard()
  var count = new WebSocket('ws://' + window.location.host + "/websocket/<%= @room.id %>");

  // 接続が始まった時
  count.onopen = function() { count.send('{"type":"open"}'); };
  // 接続が終わった時
  count.onclose = function() { count.send('{"type":"close", "id": <%= @room.id %>}'); };
  // メッセージを受け取った時
  count.onmessage = function(m) {
    data = JSON.parse(m.data)
    if(data.type == 'count'){
      countBox.innerHTML = data.count         
    } else if(data.type == 'board'){
      document.getElementById(data.pos).innerHTML = '<div class=' + turn + '></div>'
    } else if(data.type == 'turn'){
      turn = data.turn == 'black' ? 'white' : 'black'
      turnBox.innerText = data.turn
    }
    checkBoard()
  }

  // ボタンが押されたら
  s = function(msg){
    if(document.getElementById(msg).innerHTML.match('red')){
      updateBoard(parseInt(msg[1]), parseInt(msg[0]))
      count.send(JSON.stringify({type:'turn'}));
    }
  }

  updateStone = (x, y, turn) => {
    pos = getBoard(x,y)
    pos.innerHTML = `<div class="${turn}"></div>`
    count.send(JSON.stringify({type:'board', pos: `${y}${x}`, turn: turn}));
  }
};
