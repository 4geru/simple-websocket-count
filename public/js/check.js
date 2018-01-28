// startx, starty, distx, disty
checkLine = (nx ,ny, dx, dy) => {
  turn = document.getElementById('turn').innerText;
  if(getBoard(nx,ny).innerHTML == `<div class="${turn}"></div>`) return false
  while(true){
    // ボードから外れた
    if(!insideBoard(nx, ny))return false
    pos = getBoard(nx,ny)
    // から枠だった
    if(pos.innerHTML == '' || pos.innerHTML == '<div class="red"></div>')return false
    if(pos.innerHTML == `<div class="${turn}"></div>`){
      return true
    }
    nx += dx;
    ny += dy;
  }
}

checkStone = (x, y) => {
  count = 0
  flag = false
  turn = document.getElementById('turn').innerText;
  for(var dx = -1; dx <= 1 ; dx ++){
    for(var dy = -1; dy <= 1 ; dy ++){
      if(dx == dy && dx == 0)continue;
      if(!insideBoard(x + dx) || !insideBoard(y + dy))continue;
      flag = checkLine(x + dx, y + dy, dx, dy) || flag
        
    }
  }
  const pos = getBoard(limitBoard(x), limitBoard(y))
  if(flag && pos.innerHTML == "")
    pos.innerHTML = '<div class="red"></div>'
  else if(pos.innerHTML == '<div class="red"></div>')
    pos.innerHTML = ''
}

// 置けるところ
checkBoard = () => {
  console.log('call checkBoard')
  table = document.getElementsByTagName('table')[0]
  tr = table.getElementsByTagName('tr')
  for(var i = 0 ; i < tr.length ; i ++  ){
    // i = 2;
    td  = tr[i].getElementsByTagName('td')
    // j = 1;
    for(var j = 0 ; j < td.length ; j ++ ){
      checkStone(j, i)
    }
  }
}
